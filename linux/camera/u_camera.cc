#include "camera/u_camera.h"

#include <dirent.h>
#include <fcntl.h>
#include <linux/videodev2.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>

#include <algorithm>
#include <cstring>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

// =============================================================================
// u_camera — V4L2 camera for Linux.
//
// Preview is delivered as an FlPixelBufferTexture, analysis frames as an 8-bit
// luminance plane, and stills as PNG encoded in-process, so the plugin needs no
// image library at runtime. Video recording is reported as unsupported here;
// everything else in the Dart API works.
// =============================================================================

namespace {

constexpr int kBufferCount = 4;

struct UMappedBuffer {
  void* start = nullptr;
  size_t length = 0;
};

// --- Minimal PNG writer (stored deflate blocks, no zlib dependency) ----------

void PushBigEndian32(std::vector<uint8_t>& out, uint32_t value) {
  out.push_back(static_cast<uint8_t>((value >> 24) & 0xFF));
  out.push_back(static_cast<uint8_t>((value >> 16) & 0xFF));
  out.push_back(static_cast<uint8_t>((value >> 8) & 0xFF));
  out.push_back(static_cast<uint8_t>(value & 0xFF));
}

uint32_t Crc32(const uint8_t* data, size_t length, uint32_t seed = 0xFFFFFFFFu) {
  static uint32_t table[256];
  static bool ready = false;
  if (!ready) {
    for (uint32_t i = 0; i < 256; i++) {
      uint32_t c = i;
      for (int k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320u ^ (c >> 1)) : (c >> 1);
      table[i] = c;
    }
    ready = true;
  }
  uint32_t crc = seed;
  for (size_t i = 0; i < length; i++) crc = table[(crc ^ data[i]) & 0xFF] ^ (crc >> 8);
  return crc;
}

uint32_t Adler32(const uint8_t* data, size_t length) {
  uint32_t a = 1;
  uint32_t b = 0;
  for (size_t i = 0; i < length; i++) {
    a = (a + data[i]) % 65521;
    b = (b + a) % 65521;
  }
  return (b << 16) | a;
}

void AppendChunk(std::vector<uint8_t>& out, const char* type, const std::vector<uint8_t>& body) {
  PushBigEndian32(out, static_cast<uint32_t>(body.size()));
  const size_t start = out.size();
  out.insert(out.end(), type, type + 4);
  out.insert(out.end(), body.begin(), body.end());
  const uint32_t crc = Crc32(out.data() + start, out.size() - start) ^ 0xFFFFFFFFu;
  PushBigEndian32(out, crc);
}

std::vector<uint8_t> EncodePng(const uint8_t* rgba, int width, int height) {
  std::vector<uint8_t> raw;
  raw.reserve(static_cast<size_t>(height) * (1 + width * 3));
  for (int y = 0; y < height; y++) {
    raw.push_back(0);
    const uint8_t* row = rgba + static_cast<size_t>(y) * width * 4;
    for (int x = 0; x < width; x++) {
      raw.push_back(row[x * 4 + 0]);
      raw.push_back(row[x * 4 + 1]);
      raw.push_back(row[x * 4 + 2]);
    }
  }

  std::vector<uint8_t> deflated;
  deflated.push_back(0x78);
  deflated.push_back(0x01);
  size_t offset = 0;
  while (offset < raw.size()) {
    const size_t block = std::min<size_t>(65535, raw.size() - offset);
    const bool last = offset + block >= raw.size();
    deflated.push_back(last ? 1 : 0);
    deflated.push_back(static_cast<uint8_t>(block & 0xFF));
    deflated.push_back(static_cast<uint8_t>((block >> 8) & 0xFF));
    deflated.push_back(static_cast<uint8_t>((~block) & 0xFF));
    deflated.push_back(static_cast<uint8_t>(((~block) >> 8) & 0xFF));
    deflated.insert(deflated.end(), raw.begin() + offset, raw.begin() + offset + block);
    offset += block;
  }
  const uint32_t adler = Adler32(raw.data(), raw.size());
  PushBigEndian32(deflated, adler);

  std::vector<uint8_t> png = {0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A};
  std::vector<uint8_t> header;
  PushBigEndian32(header, static_cast<uint32_t>(width));
  PushBigEndian32(header, static_cast<uint32_t>(height));
  header.push_back(8);
  header.push_back(2);
  header.push_back(0);
  header.push_back(0);
  header.push_back(0);
  AppendChunk(png, "IHDR", header);
  AppendChunk(png, "IDAT", deflated);
  AppendChunk(png, "IEND", {});
  return png;
}

// --- Pixel conversions ------------------------------------------------------

void YuyvToRgba(const uint8_t* src, uint8_t* dst, int width, int height) {
  const int pairs = width * height / 2;
  for (int i = 0; i < pairs; i++) {
    const int y0 = src[i * 4 + 0];
    const int u = src[i * 4 + 1] - 128;
    const int y1 = src[i * 4 + 2];
    const int v = src[i * 4 + 3] - 128;
    const int r0 = std::clamp(y0 + ((91881 * v) >> 16), 0, 255);
    const int g0 = std::clamp(y0 - ((22554 * u + 46802 * v) >> 16), 0, 255);
    const int b0 = std::clamp(y0 + ((116130 * u) >> 16), 0, 255);
    const int r1 = std::clamp(y1 + ((91881 * v) >> 16), 0, 255);
    const int g1 = std::clamp(y1 - ((22554 * u + 46802 * v) >> 16), 0, 255);
    const int b1 = std::clamp(y1 + ((116130 * u) >> 16), 0, 255);
    dst[i * 8 + 0] = static_cast<uint8_t>(r0);
    dst[i * 8 + 1] = static_cast<uint8_t>(g0);
    dst[i * 8 + 2] = static_cast<uint8_t>(b0);
    dst[i * 8 + 3] = 255;
    dst[i * 8 + 4] = static_cast<uint8_t>(r1);
    dst[i * 8 + 5] = static_cast<uint8_t>(g1);
    dst[i * 8 + 6] = static_cast<uint8_t>(b1);
    dst[i * 8 + 7] = 255;
  }
}

void YuyvToGray(const uint8_t* src, uint8_t* dst, int width, int height) {
  const int count = width * height;
  for (int i = 0; i < count; i++) dst[i] = src[i * 2];
}

void RgbaToGray(const uint8_t* src, uint8_t* dst, int width, int height) {
  const int count = width * height;
  for (int i = 0; i < count; i++) {
    dst[i] = static_cast<uint8_t>((src[i * 4] * 77 + src[i * 4 + 1] * 151 + src[i * 4 + 2] * 28) >> 8);
  }
}

FlValue* MakeRange(double min, double max, bool supported) {
  FlValue* value = fl_value_new_map();
  fl_value_set_string_take(value, "min", fl_value_new_float(min));
  fl_value_set_string_take(value, "max", fl_value_new_float(max));
  fl_value_set_string_take(value, "step", fl_value_new_float(0));
  fl_value_set_string_take(value, "supported", fl_value_new_bool(supported));
  return value;
}

FlValue* MakeSize(int width, int height) {
  FlValue* value = fl_value_new_map();
  fl_value_set_string_take(value, "width", fl_value_new_int(width));
  fl_value_set_string_take(value, "height", fl_value_new_int(height));
  return value;
}

std::string LookupString(FlValue* map, const char* key, const std::string& fallback) {
  if (map == nullptr || fl_value_get_type(map) != FL_VALUE_TYPE_MAP) return fallback;
  FlValue* value = fl_value_lookup_string(map, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_STRING) return fallback;
  return fl_value_get_string(value);
}

int64_t LookupInt(FlValue* map, const char* key, int64_t fallback) {
  if (map == nullptr || fl_value_get_type(map) != FL_VALUE_TYPE_MAP) return fallback;
  FlValue* value = fl_value_lookup_string(map, key);
  if (value == nullptr) return fallback;
  if (fl_value_get_type(value) == FL_VALUE_TYPE_INT) return fl_value_get_int(value);
  if (fl_value_get_type(value) == FL_VALUE_TYPE_FLOAT) return static_cast<int64_t>(fl_value_get_float(value));
  return fallback;
}

}  // namespace

// --- Texture ----------------------------------------------------------------

G_DECLARE_FINAL_TYPE(UCameraTexture, u_camera_texture, U, CAMERA_TEXTURE, FlPixelBufferTexture)

struct _UCameraTexture {
  FlPixelBufferTexture parent_instance;
  std::mutex* lock;
  std::vector<uint8_t>* pixels;
  uint32_t width;
  uint32_t height;
};

G_DEFINE_TYPE(UCameraTexture, u_camera_texture, fl_pixel_buffer_texture_get_type())

static gboolean u_camera_texture_copy_pixels(FlPixelBufferTexture* texture,
                                             const uint8_t** out_buffer,
                                             uint32_t* width,
                                             uint32_t* height,
                                             GError** error) {
  UCameraTexture* self = U_CAMERA_TEXTURE(texture);
  if (self->pixels == nullptr || self->pixels->empty()) return FALSE;
  std::lock_guard<std::mutex> guard(*self->lock);
  *out_buffer = self->pixels->data();
  *width = self->width;
  *height = self->height;
  return TRUE;
}

static void u_camera_texture_dispose(GObject* object) {
  UCameraTexture* self = U_CAMERA_TEXTURE(object);
  delete self->pixels;
  delete self->lock;
  self->pixels = nullptr;
  self->lock = nullptr;
  G_OBJECT_CLASS(u_camera_texture_parent_class)->dispose(object);
}

static void u_camera_texture_class_init(UCameraTextureClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = u_camera_texture_dispose;
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = u_camera_texture_copy_pixels;
}

static void u_camera_texture_init(UCameraTexture* self) {
  self->pixels = new std::vector<uint8_t>();
  self->lock = new std::mutex();
  self->width = 0;
  self->height = 0;
}

// --- Session ----------------------------------------------------------------

namespace {

class USession {
 public:
  USession(int id, FlBinaryMessenger* messenger, FlTextureRegistrar* registrar, const std::string& device_path)
      : id_(id), registrar_(registrar), device_path_(device_path) {
    g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
    std::string event_name = "u/camera/events/" + std::to_string(id);
    std::string frame_name = "u/camera/frames/" + std::to_string(id);
    event_channel_ = fl_event_channel_new(messenger, event_name.c_str(), FL_METHOD_CODEC(codec));
    frame_channel_ = fl_event_channel_new(messenger, frame_name.c_str(), FL_METHOD_CODEC(codec));
    fl_event_channel_set_stream_handlers(event_channel_, OnListenEvents, OnCancelEvents, this, nullptr);
    fl_event_channel_set_stream_handlers(frame_channel_, OnListenFrames, OnCancelFrames, this, nullptr);
    texture_ = U_CAMERA_TEXTURE(g_object_new(u_camera_texture_get_type(), nullptr));
  }

  ~USession() { Close(); }

  bool Open(int requested_width, int requested_height, std::string* error) {
    fd_ = open(device_path_.c_str(), O_RDWR | O_NONBLOCK);
    if (fd_ < 0) {
      *error = "notFound";
      return false;
    }

    v4l2_capability capability{};
    if (ioctl(fd_, VIDIOC_QUERYCAP, &capability) < 0 || !(capability.capabilities & V4L2_CAP_VIDEO_CAPTURE)) {
      *error = "unsupported";
      return false;
    }

    v4l2_format format{};
    format.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    format.fmt.pix.width = requested_width;
    format.fmt.pix.height = requested_height;
    format.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
    format.fmt.pix.field = V4L2_FIELD_ANY;
    if (ioctl(fd_, VIDIOC_S_FMT, &format) < 0) {
      *error = "configuration";
      return false;
    }
    width_ = static_cast<int>(format.fmt.pix.width);
    height_ = static_cast<int>(format.fmt.pix.height);
    pixel_format_ = format.fmt.pix.pixelformat;

    v4l2_requestbuffers request{};
    request.count = kBufferCount;
    request.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    request.memory = V4L2_MEMORY_MMAP;
    if (ioctl(fd_, VIDIOC_REQBUFS, &request) < 0) {
      *error = "configuration";
      return false;
    }

    buffers_.resize(request.count);
    for (unsigned int i = 0; i < request.count; i++) {
      v4l2_buffer buffer{};
      buffer.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      buffer.memory = V4L2_MEMORY_MMAP;
      buffer.index = i;
      if (ioctl(fd_, VIDIOC_QUERYBUF, &buffer) < 0) {
        *error = "configuration";
        return false;
      }
      buffers_[i].length = buffer.length;
      buffers_[i].start = mmap(nullptr, buffer.length, PROT_READ | PROT_WRITE, MAP_SHARED, fd_, buffer.m.offset);
      if (buffers_[i].start == MAP_FAILED) {
        *error = "configuration";
        return false;
      }
      if (ioctl(fd_, VIDIOC_QBUF, &buffer) < 0) {
        *error = "configuration";
        return false;
      }
    }

    v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    if (ioctl(fd_, VIDIOC_STREAMON, &type) < 0) {
      *error = "inUse";
      return false;
    }

    rgba_.assign(static_cast<size_t>(width_) * height_ * 4, 0);
    texture_->width = static_cast<uint32_t>(width_);
    texture_->height = static_cast<uint32_t>(height_);
    texture_->pixels->assign(rgba_.size(), 0);
    fl_texture_registrar_register_texture(registrar_, FL_TEXTURE(texture_));

    running_ = true;
    worker_ = std::thread([this] { Loop(); });
    return true;
  }

  void Close() {
    running_ = false;
    if (worker_.joinable()) worker_.join();
    if (fd_ >= 0) {
      v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      ioctl(fd_, VIDIOC_STREAMOFF, &type);
      for (auto& buffer : buffers_) {
        if (buffer.start != nullptr && buffer.start != MAP_FAILED) munmap(buffer.start, buffer.length);
      }
      buffers_.clear();
      close(fd_);
      fd_ = -1;
    }
    if (texture_ != nullptr) {
      fl_texture_registrar_unregister_texture(registrar_, FL_TEXTURE(texture_));
      g_clear_object(&texture_);
    }
    if (event_channel_ != nullptr) g_clear_object(&event_channel_);
    if (frame_channel_ != nullptr) g_clear_object(&frame_channel_);
  }

  int64_t texture_id() const { return reinterpret_cast<int64_t>(texture_); }

  int width() const { return width_; }

  int height() const { return height_; }

  void StartImageStream(const std::string& format, double max_fps) {
    frame_format_ = format;
    if (max_fps > 0) frame_interval_us_ = static_cast<int64_t>(1000000.0 / max_fps);
    streaming_ = true;
  }

  void StopImageStream() { streaming_ = false; }

  void SetPaused(bool paused) { paused_ = paused; }

  bool TakePhoto(std::vector<uint8_t>* png, int* out_width, int* out_height) {
    std::lock_guard<std::mutex> guard(rgba_lock_);
    if (rgba_.empty()) return false;
    *png = EncodePng(rgba_.data(), width_, height_);
    *out_width = width_;
    *out_height = height_;
    return true;
  }

  FlValue* Describe(const std::string& device_name) {
    FlValue* map = fl_value_new_map();
    fl_value_set_string_take(map, "sessionId", fl_value_new_int(id_));
    fl_value_set_string_take(map, "textureId", fl_value_new_int(texture_id()));
    fl_value_set_string_take(map, "previewSize", MakeSize(width_, height_));
    fl_value_set_string_take(map, "sensorOrientation", fl_value_new_int(0));
    fl_value_set_string_take(map, "mirrored", fl_value_new_bool(false));
    fl_value_set_string_take(map, "zoom", fl_value_new_float(1));

    FlValue* device = fl_value_new_map();
    fl_value_set_string_take(device, "id", fl_value_new_string(device_path_.c_str()));
    fl_value_set_string_take(device, "name", fl_value_new_string(device_name.c_str()));
    fl_value_set_string_take(device, "facing", fl_value_new_string("external"));
    fl_value_set_string_take(device, "lens", fl_value_new_string("wide"));
    fl_value_set_string_take(device, "sensorOrientation", fl_value_new_int(0));
    fl_value_set_string_take(device, "hasFlash", fl_value_new_bool(false));
    fl_value_set_string_take(device, "minZoom", fl_value_new_float(1));
    fl_value_set_string_take(device, "maxZoom", fl_value_new_float(1));
    fl_value_set_string_take(map, "device", device);

    FlValue* capabilities = fl_value_new_map();
    fl_value_set_string_take(capabilities, "flash", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "torch", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "zoom", MakeRange(1, 1, false));
    fl_value_set_string_take(capabilities, "exposureOffset", MakeRange(0, 0, false));
    fl_value_set_string_take(capabilities, "iso", MakeRange(0, 0, false));
    fl_value_set_string_take(capabilities, "exposureDuration", MakeRange(0, 0, false));
    fl_value_set_string_take(capabilities, "focusDistance", MakeRange(0, 0, false));
    fl_value_set_string_take(capabilities, "temperature", MakeRange(0, 0, false));
    fl_value_set_string_take(capabilities, "focusPoint", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "exposurePoint", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "manualFocus", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "manualExposure", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "whiteBalance", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "stabilization", fl_value_new_list());
    fl_value_set_string_take(capabilities, "hdr", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "nightMode", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "rawCapture", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "depthCapture", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "videoRecording", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "pauseRecording", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "audioRecording", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "imageStream", fl_value_new_bool(true));
    fl_value_set_string_take(capabilities, "platformScanning", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "multiCamera", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "pictureInPicture", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "lensSwitching", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "orientationLock", fl_value_new_bool(false));
    fl_value_set_string_take(capabilities, "snapshot", fl_value_new_bool(true));
    fl_value_set_string_take(capabilities, "photoFormats", fl_value_new_list());
    fl_value_set_string_take(capabilities, "frameFormats", fl_value_new_list());
    fl_value_set_string_take(capabilities, "maxFps", fl_value_new_float(30));
    fl_value_set_string_take(map, "capabilities", capabilities);
    return map;
  }

 private:
  static FlMethodErrorResponse* OnListenEvents(FlEventChannel*, FlValue*, gpointer user_data) {
    static_cast<USession*>(user_data)->events_active_ = true;
    return nullptr;
  }

  static FlMethodErrorResponse* OnCancelEvents(FlEventChannel*, FlValue*, gpointer user_data) {
    static_cast<USession*>(user_data)->events_active_ = false;
    return nullptr;
  }

  static FlMethodErrorResponse* OnListenFrames(FlEventChannel*, FlValue*, gpointer user_data) {
    static_cast<USession*>(user_data)->frames_active_ = true;
    return nullptr;
  }

  static FlMethodErrorResponse* OnCancelFrames(FlEventChannel*, FlValue*, gpointer user_data) {
    static_cast<USession*>(user_data)->frames_active_ = false;
    return nullptr;
  }

  struct FrameMessage {
    USession* session;
    std::vector<uint8_t> gray;
    int width;
    int height;
  };

  static gboolean DeliverFrame(gpointer data) {
    std::unique_ptr<FrameMessage> message(static_cast<FrameMessage*>(data));
    USession* session = message->session;
    if (!session->frames_active_ || session->frame_channel_ == nullptr) return G_SOURCE_REMOVE;

    g_autoptr(FlValue) map = fl_value_new_map();
    g_autoptr(FlValue) planes = fl_value_new_list();
    fl_value_append_take(planes, fl_value_new_uint8_list(message->gray.data(), message->gray.size()));
    fl_value_set_string(map, "planes", planes);
    fl_value_set_string_take(map, "format", fl_value_new_string("gray8"));
    fl_value_set_string_take(map, "width", fl_value_new_int(message->width));
    fl_value_set_string_take(map, "height", fl_value_new_int(message->height));
    g_autoptr(FlValue) strides = fl_value_new_list();
    fl_value_append_take(strides, fl_value_new_int(message->width));
    fl_value_set_string(map, "rowStrides", strides);
    g_autoptr(FlValue) pixel_strides = fl_value_new_list();
    fl_value_append_take(pixel_strides, fl_value_new_int(1));
    fl_value_set_string(map, "pixelStrides", pixel_strides);
    fl_value_set_string_take(map, "rotation", fl_value_new_int(0));
    fl_value_set_string_take(map, "mirrored", fl_value_new_bool(false));
    fl_event_channel_send(session->frame_channel_, map, nullptr, nullptr);
    return G_SOURCE_REMOVE;
  }

  static gboolean MarkTextureReady(gpointer data) {
    USession* session = static_cast<USession*>(data);
    if (session->texture_ != nullptr) {
      fl_texture_registrar_mark_texture_frame_available(session->registrar_, FL_TEXTURE(session->texture_));
    }
    return G_SOURCE_REMOVE;
  }

  void Loop() {
    while (running_) {
      if (paused_) {
        usleep(20000);
        continue;
      }

      v4l2_buffer buffer{};
      buffer.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      buffer.memory = V4L2_MEMORY_MMAP;
      if (ioctl(fd_, VIDIOC_DQBUF, &buffer) < 0) {
        usleep(5000);
        continue;
      }

      const uint8_t* source = static_cast<const uint8_t*>(buffers_[buffer.index].start);
      {
        std::lock_guard<std::mutex> guard(rgba_lock_);
        if (pixel_format_ == V4L2_PIX_FMT_YUYV) {
          YuyvToRgba(source, rgba_.data(), width_, height_);
        } else {
          const size_t copy = std::min(rgba_.size(), static_cast<size_t>(buffer.bytesused));
          std::memcpy(rgba_.data(), source, copy);
        }
        std::lock_guard<std::mutex> texture_guard(*texture_->lock);
        std::memcpy(texture_->pixels->data(), rgba_.data(), rgba_.size());
      }
      g_idle_add(MarkTextureReady, this);

      if (streaming_ && frames_active_) {
        const int64_t now = g_get_monotonic_time();
        if (now - last_frame_us_ >= frame_interval_us_) {
          last_frame_us_ = now;
          auto* message = new FrameMessage{this, std::vector<uint8_t>(static_cast<size_t>(width_) * height_), width_, height_};
          if (pixel_format_ == V4L2_PIX_FMT_YUYV) {
            YuyvToGray(source, message->gray.data(), width_, height_);
          } else {
            std::lock_guard<std::mutex> guard(rgba_lock_);
            RgbaToGray(rgba_.data(), message->gray.data(), width_, height_);
          }
          g_idle_add(DeliverFrame, message);
        }
      }

      ioctl(fd_, VIDIOC_QBUF, &buffer);
    }
  }

  int id_;
  FlTextureRegistrar* registrar_;
  std::string device_path_;
  FlEventChannel* event_channel_ = nullptr;
  FlEventChannel* frame_channel_ = nullptr;
  UCameraTexture* texture_ = nullptr;
  int fd_ = -1;
  int width_ = 0;
  int height_ = 0;
  uint32_t pixel_format_ = 0;
  std::vector<UMappedBuffer> buffers_;
  std::vector<uint8_t> rgba_;
  std::mutex rgba_lock_;
  std::thread worker_;
  bool running_ = false;
  bool paused_ = false;
  bool streaming_ = false;
  bool events_active_ = false;
  bool frames_active_ = false;
  std::string frame_format_ = "gray8";
  int64_t frame_interval_us_ = 80000;
  int64_t last_frame_us_ = 0;
};

struct UCameraPlugin {
  FlBinaryMessenger* messenger = nullptr;
  FlTextureRegistrar* registrar = nullptr;
  FlMethodChannel* channel = nullptr;
  std::map<int, std::unique_ptr<USession>> sessions;
  int next_id = 1;
};

UCameraPlugin* g_plugin = nullptr;

std::vector<std::pair<std::string, std::string>> EnumerateDevices() {
  std::vector<std::pair<std::string, std::string>> devices;
  DIR* dir = opendir("/dev");
  if (dir == nullptr) return devices;
  dirent* entry = nullptr;
  while ((entry = readdir(dir)) != nullptr) {
    if (std::strncmp(entry->d_name, "video", 5) != 0) continue;
    const std::string path = std::string("/dev/") + entry->d_name;
    const int fd = open(path.c_str(), O_RDWR | O_NONBLOCK);
    if (fd < 0) continue;
    v4l2_capability capability{};
    if (ioctl(fd, VIDIOC_QUERYCAP, &capability) == 0 && (capability.capabilities & V4L2_CAP_VIDEO_CAPTURE)) {
      devices.emplace_back(path, reinterpret_cast<const char*>(capability.card));
    }
    close(fd);
  }
  closedir(dir);
  std::sort(devices.begin(), devices.end());
  return devices;
}

FlValue* DescribeDevice(const std::string& path, const std::string& name) {
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "id", fl_value_new_string(path.c_str()));
  fl_value_set_string_take(map, "name", fl_value_new_string(name.c_str()));
  fl_value_set_string_take(map, "facing", fl_value_new_string("external"));
  fl_value_set_string_take(map, "lens", fl_value_new_string("wide"));
  fl_value_set_string_take(map, "sensorOrientation", fl_value_new_int(0));
  fl_value_set_string_take(map, "hasFlash", fl_value_new_bool(false));
  fl_value_set_string_take(map, "isLogical", fl_value_new_bool(false));
  fl_value_set_string_take(map, "minZoom", fl_value_new_float(1));
  fl_value_set_string_take(map, "maxZoom", fl_value_new_float(1));
  fl_value_set_string_take(map, "neutralZoom", fl_value_new_float(1));
  fl_value_set_string_take(map, "formats", fl_value_new_list());
  return map;
}

void HandleMethodCall(FlMethodChannel*, FlMethodCall* method_call, gpointer) {
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);
  g_autoptr(FlMethodResponse) response = nullptr;

  if (std::strcmp(method, "isSupported") == 0) {
    g_autoptr(FlValue) value = fl_value_new_bool(!EnumerateDevices().empty());
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  } else if (std::strcmp(method, "availableCameras") == 0) {
    g_autoptr(FlValue) list = fl_value_new_list();
    for (const auto& device : EnumerateDevices()) {
      fl_value_append_take(list, DescribeDevice(device.first, device.second));
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(list));
  } else if (std::strcmp(method, "permissionStatus") == 0 || std::strcmp(method, "requestPermission") == 0) {
    g_autoptr(FlValue) map = fl_value_new_map();
    fl_value_set_string_take(map, "camera", fl_value_new_string("granted"));
    fl_value_set_string_take(map, "microphone", fl_value_new_string("granted"));
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(map));
  } else if (std::strcmp(method, "openSettings") == 0) {
    g_autoptr(FlValue) value = fl_value_new_bool(FALSE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  } else if (std::strcmp(method, "create") == 0) {
    FlValue* config = args == nullptr ? nullptr : fl_value_lookup_string(args, "config");
    std::string device_id = LookupString(config, "deviceId", "");
    std::string device_name = "Camera";
    const auto devices = EnumerateDevices();
    if (device_id.empty()) {
      if (devices.empty()) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("notFound", "No camera found", nullptr));
        fl_method_call_respond(method_call, response, nullptr);
        return;
      }
      device_id = devices.front().first;
      device_name = devices.front().second;
    } else {
      for (const auto& device : devices) {
        if (device.first == device_id) device_name = device.second;
      }
    }

    const std::string resolution = LookupString(config, "resolution", "high");
    int requested_width = 1280;
    int requested_height = 720;
    if (resolution == "low") {
      requested_width = 320;
      requested_height = 240;
    } else if (resolution == "medium") {
      requested_width = 640;
      requested_height = 480;
    } else if (resolution == "veryHigh" || resolution == "ultraHigh" || resolution == "max") {
      requested_width = 1920;
      requested_height = 1080;
    }

    const int id = g_plugin->next_id++;
    auto session = std::make_unique<USession>(id, g_plugin->messenger, g_plugin->registrar, device_id);
    std::string error;
    if (!session->Open(requested_width, requested_height, &error)) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(error.c_str(), "Unable to open camera", nullptr));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }
    g_autoptr(FlValue) description = session->Describe(device_name);
    g_plugin->sessions[id] = std::move(session);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(description));
  } else {
    const int id = static_cast<int>(LookupInt(args, "sessionId", -1));
    auto found = g_plugin->sessions.find(id);
    if (found == g_plugin->sessions.end()) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("notFound", "Camera session not found", nullptr));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }
    USession* session = found->second.get();

    if (std::strcmp(method, "dispose") == 0) {
      g_plugin->sessions.erase(found);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    } else if (std::strcmp(method, "startImageStream") == 0) {
      FlValue* fps = args == nullptr ? nullptr : fl_value_lookup_string(args, "maxFps");
      const double max_fps = fps != nullptr && fl_value_get_type(fps) == FL_VALUE_TYPE_FLOAT ? fl_value_get_float(fps) : 12.0;
      session->StartImageStream(LookupString(args, "format", "gray8"), max_fps);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    } else if (std::strcmp(method, "stopImageStream") == 0) {
      session->StopImageStream();
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    } else if (std::strcmp(method, "setPreviewPaused") == 0) {
      FlValue* paused = args == nullptr ? nullptr : fl_value_lookup_string(args, "paused");
      session->SetPaused(paused != nullptr && fl_value_get_type(paused) == FL_VALUE_TYPE_BOOL && fl_value_get_bool(paused));
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    } else if (std::strcmp(method, "takePhoto") == 0 || std::strcmp(method, "takeSnapshot") == 0) {
      std::vector<uint8_t> png;
      int width = 0;
      int height = 0;
      if (!session->TakePhoto(&png, &width, &height)) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("capture", "No frame available", nullptr));
      } else {
        std::string path = LookupString(args, "path", "");
        if (!path.empty()) {
          FILE* file = fopen(path.c_str(), "wb");
          if (file != nullptr) {
            fwrite(png.data(), 1, png.size(), file);
            fclose(file);
          }
        }
        g_autoptr(FlValue) map = fl_value_new_map();
        fl_value_set_string_take(map, "path", path.empty() ? fl_value_new_null() : fl_value_new_string(path.c_str()));
        fl_value_set_string_take(map, "bytes", fl_value_new_uint8_list(png.data(), png.size()));
        fl_value_set_string_take(map, "width", fl_value_new_int(width));
        fl_value_set_string_take(map, "height", fl_value_new_int(height));
        fl_value_set_string_take(map, "format", fl_value_new_string("png"));
        fl_value_set_string_take(map, "orientation", fl_value_new_int(0));
        fl_value_set_string_take(map, "sizeInBytes", fl_value_new_int(static_cast<int64_t>(png.size())));
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(map));
      }
    } else if (std::strcmp(method, "startRecording") == 0 || std::strcmp(method, "stopRecording") == 0) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("unsupported", "Video recording is not available on Linux", nullptr));
    } else {
      // Every remaining control (flash, zoom, focus, ...) is a no-op on a
      // generic V4L2 webcam; report success so Dart can keep its state.
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    }
  }

  fl_method_call_respond(method_call, response, nullptr);
}

}  // namespace

void u_camera_register(FlPluginRegistrar* registrar) {
  if (g_plugin != nullptr) return;
  g_plugin = new UCameraPlugin();
  g_plugin->messenger = fl_plugin_registrar_get_messenger(registrar);
  g_plugin->registrar = fl_plugin_registrar_get_texture_registrar(registrar);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_plugin->channel = fl_method_channel_new(g_plugin->messenger, "u/camera", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(g_plugin->channel, HandleMethodCall, nullptr, nullptr);
}
