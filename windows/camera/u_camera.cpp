#include "camera/u_camera.h"

#include <windows.h>

#include <mfapi.h>
#include <mferror.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <shlwapi.h>
#include <wincodec.h>

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>

#include <algorithm>
#include <atomic>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

// =============================================================================
// u_camera — Media Foundation camera for Windows.
//
// Preview is copied into a Flutter PixelBufferTexture, analysis frames go out
// as an 8-bit luminance plane, and stills are encoded with WIC (part of the
// OS). Video recording uses the Media Foundation sink writer.
// =============================================================================

namespace u {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

template <class T>
void SafeRelease(T** value) {
  if (*value != nullptr) {
    (*value)->Release();
    *value = nullptr;
  }
}

std::string ToUtf8(const std::wstring& text) {
  if (text.empty()) return std::string();
  const int size = WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), nullptr, 0, nullptr, nullptr);
  std::string out(size, 0);
  WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), out.data(), size, nullptr, nullptr);
  return out;
}

std::wstring ToWide(const std::string& text) {
  if (text.empty()) return std::wstring();
  const int size = MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), nullptr, 0);
  std::wstring out(size, 0);
  MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), out.data(), size);
  return out;
}

const EncodableValue* Lookup(const EncodableMap* map, const char* key) {
  if (map == nullptr) return nullptr;
  const auto found = map->find(EncodableValue(key));
  return found == map->end() ? nullptr : &found->second;
}

std::string LookupString(const EncodableMap* map, const char* key, const std::string& fallback) {
  const EncodableValue* value = Lookup(map, key);
  if (value == nullptr) return fallback;
  if (const auto* text = std::get_if<std::string>(value)) return *text;
  return fallback;
}

int64_t LookupInt(const EncodableMap* map, const char* key, int64_t fallback) {
  const EncodableValue* value = Lookup(map, key);
  if (value == nullptr) return fallback;
  if (const auto* number = std::get_if<int32_t>(value)) return *number;
  if (const auto* number = std::get_if<int64_t>(value)) return *number;
  if (const auto* number = std::get_if<double>(value)) return static_cast<int64_t>(*number);
  return fallback;
}

double LookupDouble(const EncodableMap* map, const char* key, double fallback) {
  const EncodableValue* value = Lookup(map, key);
  if (value == nullptr) return fallback;
  if (const auto* number = std::get_if<double>(value)) return *number;
  if (const auto* number = std::get_if<int32_t>(value)) return static_cast<double>(*number);
  if (const auto* number = std::get_if<int64_t>(value)) return static_cast<double>(*number);
  return fallback;
}

bool LookupBool(const EncodableMap* map, const char* key, bool fallback) {
  const EncodableValue* value = Lookup(map, key);
  if (value == nullptr) return fallback;
  if (const auto* flag = std::get_if<bool>(value)) return *flag;
  return fallback;
}

EncodableValue MakeRange(double min, double max, bool supported) {
  return EncodableValue(EncodableMap{
      {EncodableValue("min"), EncodableValue(min)},
      {EncodableValue("max"), EncodableValue(max)},
      {EncodableValue("step"), EncodableValue(0.0)},
      {EncodableValue("supported"), EncodableValue(supported)},
  });
}

EncodableValue MakeSize(int width, int height) {
  return EncodableValue(EncodableMap{
      {EncodableValue("width"), EncodableValue(width)},
      {EncodableValue("height"), EncodableValue(height)},
  });
}

void Nv12ToRgba(const uint8_t* source, uint8_t* destination, int width, int height, int stride) {
  const uint8_t* chroma = source + static_cast<size_t>(stride) * height;
  for (int y = 0; y < height; y++) {
    const uint8_t* luma_row = source + static_cast<size_t>(y) * stride;
    const uint8_t* chroma_row = chroma + static_cast<size_t>(y / 2) * stride;
    uint8_t* out = destination + static_cast<size_t>(y) * width * 4;
    for (int x = 0; x < width; x++) {
      const int luma = luma_row[x];
      const int u = chroma_row[(x & ~1)] - 128;
      const int v = chroma_row[(x & ~1) + 1] - 128;
      out[x * 4 + 0] = static_cast<uint8_t>(std::clamp(luma + ((91881 * v) >> 16), 0, 255));
      out[x * 4 + 1] = static_cast<uint8_t>(std::clamp(luma - ((22554 * u + 46802 * v) >> 16), 0, 255));
      out[x * 4 + 2] = static_cast<uint8_t>(std::clamp(luma + ((116130 * u) >> 16), 0, 255));
      out[x * 4 + 3] = 255;
    }
  }
}

void RgbaToGray(const uint8_t* source, uint8_t* destination, int width, int height) {
  const int count = width * height;
  for (int i = 0; i < count; i++) {
    destination[i] = static_cast<uint8_t>((source[i * 4] * 77 + source[i * 4 + 1] * 151 + source[i * 4 + 2] * 28) >> 8);
  }
}

std::vector<uint8_t> EncodeWithWic(const uint8_t* rgba, int width, int height, const GUID& container, double quality) {
  std::vector<uint8_t> out;
  IWICImagingFactory* factory = nullptr;
  if (FAILED(CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&factory)))) return out;

  IStream* stream = nullptr;
  IWICBitmapEncoder* encoder = nullptr;
  IWICBitmapFrameEncode* frame = nullptr;
  IPropertyBag2* properties = nullptr;

  if (SUCCEEDED(CreateStreamOnHGlobal(nullptr, TRUE, &stream)) &&
      SUCCEEDED(factory->CreateEncoder(container, nullptr, &encoder)) &&
      SUCCEEDED(encoder->Initialize(stream, WICBitmapEncoderNoCache)) &&
      SUCCEEDED(encoder->CreateNewFrame(&frame, &properties))) {
    if (container == GUID_ContainerFormatJpeg && properties != nullptr) {
      PROPBAG2 option = {};
      option.pstrName = const_cast<LPOLESTR>(L"ImageQuality");
      VARIANT value;
      VariantInit(&value);
      value.vt = VT_R4;
      value.fltVal = static_cast<float>(quality);
      properties->Write(1, &option, &value);
    }
    if (SUCCEEDED(frame->Initialize(properties))) {
      frame->SetSize(width, height);
      WICPixelFormatGUID format = GUID_WICPixelFormat32bppRGBA;
      frame->SetPixelFormat(&format);
      frame->WritePixels(height, width * 4, width * 4 * height, const_cast<BYTE*>(rgba));
      frame->Commit();
      encoder->Commit();

      HGLOBAL handle = nullptr;
      if (SUCCEEDED(GetHGlobalFromStream(stream, &handle))) {
        const SIZE_T size = GlobalSize(handle);
        void* data = GlobalLock(handle);
        if (data != nullptr) {
          out.assign(static_cast<uint8_t*>(data), static_cast<uint8_t*>(data) + size);
          GlobalUnlock(handle);
        }
      }
    }
  }

  SafeRelease(&properties);
  SafeRelease(&frame);
  SafeRelease(&encoder);
  SafeRelease(&stream);
  SafeRelease(&factory);
  return out;
}

struct DeviceInfo {
  std::wstring symbolic_link;
  std::string name;
};

std::vector<DeviceInfo> EnumerateDevices() {
  std::vector<DeviceInfo> devices;
  IMFAttributes* attributes = nullptr;
  if (FAILED(MFCreateAttributes(&attributes, 1))) return devices;
  attributes->SetGUID(MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE, MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID);

  IMFActivate** activates = nullptr;
  UINT32 count = 0;
  if (SUCCEEDED(MFEnumDeviceSources(attributes, &activates, &count))) {
    for (UINT32 i = 0; i < count; i++) {
      WCHAR* link = nullptr;
      UINT32 link_length = 0;
      WCHAR* name = nullptr;
      UINT32 name_length = 0;
      DeviceInfo info;
      if (SUCCEEDED(activates[i]->GetAllocatedString(MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_SYMBOLIC_LINK, &link, &link_length))) {
        info.symbolic_link.assign(link, link_length);
        CoTaskMemFree(link);
      }
      if (SUCCEEDED(activates[i]->GetAllocatedString(MF_DEVSOURCE_ATTRIBUTE_FRIENDLY_NAME, &name, &name_length))) {
        info.name = ToUtf8(std::wstring(name, name_length));
        CoTaskMemFree(name);
      }
      if (!info.symbolic_link.empty()) devices.push_back(info);
      activates[i]->Release();
    }
    CoTaskMemFree(activates);
  }
  SafeRelease(&attributes);
  return devices;
}

EncodableValue DescribeDevice(const DeviceInfo& info) {
  return EncodableValue(EncodableMap{
      {EncodableValue("id"), EncodableValue(ToUtf8(info.symbolic_link))},
      {EncodableValue("name"), EncodableValue(info.name)},
      {EncodableValue("facing"), EncodableValue("external")},
      {EncodableValue("lens"), EncodableValue("wide")},
      {EncodableValue("sensorOrientation"), EncodableValue(0)},
      {EncodableValue("hasFlash"), EncodableValue(false)},
      {EncodableValue("isLogical"), EncodableValue(false)},
      {EncodableValue("minZoom"), EncodableValue(1.0)},
      {EncodableValue("maxZoom"), EncodableValue(1.0)},
      {EncodableValue("neutralZoom"), EncodableValue(1.0)},
      {EncodableValue("formats"), EncodableValue(EncodableList{})},
  });
}

class Session {
 public:
  Session(int id, flutter::BinaryMessenger* messenger, flutter::TextureRegistrar* textures)
      : id_(id), messenger_(messenger), textures_(textures) {}

  ~Session() { Close(); }

  bool Open(const std::wstring& symbolic_link, int requested_width, int requested_height, std::string* error) {
    IMFAttributes* attributes = nullptr;
    if (FAILED(MFCreateAttributes(&attributes, 2))) {
      *error = "configuration";
      return false;
    }
    attributes->SetGUID(MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE, MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID);
    attributes->SetString(MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_SYMBOLIC_LINK, symbolic_link.c_str());

    IMFMediaSource* source = nullptr;
    HRESULT hr = MFCreateDeviceSource(attributes, &source);
    SafeRelease(&attributes);
    if (FAILED(hr)) {
      *error = "notFound";
      return false;
    }

    hr = MFCreateSourceReaderFromMediaSource(source, nullptr, &reader_);
    SafeRelease(&source);
    if (FAILED(hr)) {
      *error = "configuration";
      return false;
    }

    if (!SelectFormat(requested_width, requested_height)) {
      *error = "configuration";
      return false;
    }

    rgba_.assign(static_cast<size_t>(width_) * height_ * 4, 0);
    buffer_ = std::make_unique<flutter::TextureVariant>(flutter::PixelBufferTexture(
        [this](size_t, size_t) -> const FlutterDesktopPixelBuffer* {
          std::lock_guard<std::mutex> guard(pixel_lock_);
          descriptor_.buffer = rgba_.data();
          descriptor_.width = static_cast<size_t>(width_);
          descriptor_.height = static_cast<size_t>(height_);
          return &descriptor_;
        }));
    texture_id_ = textures_->RegisterTexture(buffer_.get());

    auto event_handler = std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
        [this](const EncodableValue*, std::unique_ptr<flutter::EventSink<EncodableValue>>&& events) {
          event_sink_ = std::move(events);
          return nullptr;
        },
        [this](const EncodableValue*) {
          event_sink_.reset();
          return nullptr;
        });
    event_channel_ = std::make_unique<flutter::EventChannel<EncodableValue>>(
        messenger_, "u/camera/events/" + std::to_string(id_), &flutter::StandardMethodCodec::GetInstance());
    event_channel_->SetStreamHandler(std::move(event_handler));

    auto frame_handler = std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
        [this](const EncodableValue*, std::unique_ptr<flutter::EventSink<EncodableValue>>&& events) {
          frame_sink_ = std::move(events);
          return nullptr;
        },
        [this](const EncodableValue*) {
          frame_sink_.reset();
          return nullptr;
        });
    frame_channel_ = std::make_unique<flutter::EventChannel<EncodableValue>>(
        messenger_, "u/camera/frames/" + std::to_string(id_), &flutter::StandardMethodCodec::GetInstance());
    frame_channel_->SetStreamHandler(std::move(frame_handler));

    running_ = true;
    worker_ = std::thread([this] { Loop(); });
    return true;
  }

  void Close() {
    running_ = false;
    if (worker_.joinable()) worker_.join();
    StopRecordingInternal();
    SafeRelease(&reader_);
    if (texture_id_ != -1) {
      textures_->UnregisterTexture(texture_id_);
      texture_id_ = -1;
    }
    event_channel_.reset();
    frame_channel_.reset();
    buffer_.reset();
  }

  int64_t texture_id() const { return texture_id_; }

  int width() const { return width_; }

  int height() const { return height_; }

  void StartImageStream(const std::string& format, double max_fps) {
    frame_format_ = format;
    if (max_fps > 0) frame_interval_ms_ = static_cast<int64_t>(1000.0 / max_fps);
    streaming_ = true;
  }

  void StopImageStream() { streaming_ = false; }

  void SetPaused(bool paused) { paused_ = paused; }

  std::vector<uint8_t> Capture(const std::string& format, double quality, int* out_width, int* out_height) {
    std::lock_guard<std::mutex> guard(pixel_lock_);
    *out_width = width_;
    *out_height = height_;
    if (rgba_.empty()) return {};
    const GUID container = format == "png" ? GUID_ContainerFormatPng : GUID_ContainerFormatJpeg;
    return EncodeWithWic(rgba_.data(), width_, height_, container, quality);
  }

  bool StartRecording(const std::string& path, int bitrate) {
    if (writer_ != nullptr) return false;
    IMFSinkWriter* writer = nullptr;
    if (FAILED(MFCreateSinkWriterFromURL(ToWide(path).c_str(), nullptr, nullptr, &writer))) return false;

    IMFMediaType* out_type = nullptr;
    if (FAILED(MFCreateMediaType(&out_type))) {
      SafeRelease(&writer);
      return false;
    }
    out_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
    out_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_H264);
    out_type->SetUINT32(MF_MT_AVG_BITRATE, static_cast<UINT32>(bitrate));
    out_type->SetUINT32(MF_MT_INTERLACE_MODE, MFVideoInterlace_Progressive);
    MFSetAttributeSize(out_type, MF_MT_FRAME_SIZE, width_, height_);
    MFSetAttributeRatio(out_type, MF_MT_FRAME_RATE, 30, 1);
    MFSetAttributeRatio(out_type, MF_MT_PIXEL_ASPECT_RATIO, 1, 1);

    DWORD stream_index = 0;
    HRESULT hr = writer->AddStream(out_type, &stream_index);
    SafeRelease(&out_type);
    if (FAILED(hr)) {
      SafeRelease(&writer);
      return false;
    }

    IMFMediaType* in_type = nullptr;
    if (FAILED(MFCreateMediaType(&in_type))) {
      SafeRelease(&writer);
      return false;
    }
    in_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
    in_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_RGB32);
    in_type->SetUINT32(MF_MT_INTERLACE_MODE, MFVideoInterlace_Progressive);
    MFSetAttributeSize(in_type, MF_MT_FRAME_SIZE, width_, height_);
    MFSetAttributeRatio(in_type, MF_MT_FRAME_RATE, 30, 1);
    MFSetAttributeRatio(in_type, MF_MT_PIXEL_ASPECT_RATIO, 1, 1);
    hr = writer->SetInputMediaType(stream_index, in_type, nullptr);
    SafeRelease(&in_type);
    if (FAILED(hr)) {
      SafeRelease(&writer);
      return false;
    }

    if (FAILED(writer->BeginWriting())) {
      SafeRelease(&writer);
      return false;
    }
    writer_ = writer;
    stream_index_ = stream_index;
    recording_path_ = path;
    recording_started_ = GetTickCount64();
    recording_time_ = 0;
    return true;
  }

  bool StopRecording(std::string* path, int64_t* duration_ms) {
    if (writer_ == nullptr) return false;
    *path = recording_path_;
    *duration_ms = static_cast<int64_t>(GetTickCount64() - recording_started_);
    StopRecordingInternal();
    return true;
  }

  EncodableValue Describe(const std::string& device_name, const std::string& device_id) {
    return EncodableValue(EncodableMap{
        {EncodableValue("sessionId"), EncodableValue(id_)},
        {EncodableValue("textureId"), EncodableValue(texture_id_)},
        {EncodableValue("previewSize"), MakeSize(width_, height_)},
        {EncodableValue("sensorOrientation"), EncodableValue(0)},
        {EncodableValue("mirrored"), EncodableValue(false)},
        {EncodableValue("zoom"), EncodableValue(1.0)},
        {EncodableValue("device"),
         EncodableValue(EncodableMap{
             {EncodableValue("id"), EncodableValue(device_id)},
             {EncodableValue("name"), EncodableValue(device_name)},
             {EncodableValue("facing"), EncodableValue("external")},
             {EncodableValue("lens"), EncodableValue("wide")},
             {EncodableValue("sensorOrientation"), EncodableValue(0)},
             {EncodableValue("hasFlash"), EncodableValue(false)},
             {EncodableValue("minZoom"), EncodableValue(1.0)},
             {EncodableValue("maxZoom"), EncodableValue(1.0)},
         })},
        {EncodableValue("capabilities"),
         EncodableValue(EncodableMap{
             {EncodableValue("flash"), EncodableValue(false)},
             {EncodableValue("torch"), EncodableValue(false)},
             {EncodableValue("zoom"), MakeRange(1, 1, false)},
             {EncodableValue("exposureOffset"), MakeRange(0, 0, false)},
             {EncodableValue("iso"), MakeRange(0, 0, false)},
             {EncodableValue("exposureDuration"), MakeRange(0, 0, false)},
             {EncodableValue("focusDistance"), MakeRange(0, 0, false)},
             {EncodableValue("temperature"), MakeRange(0, 0, false)},
             {EncodableValue("focusPoint"), EncodableValue(false)},
             {EncodableValue("exposurePoint"), EncodableValue(false)},
             {EncodableValue("manualFocus"), EncodableValue(false)},
             {EncodableValue("manualExposure"), EncodableValue(false)},
             {EncodableValue("whiteBalance"), EncodableValue(false)},
             {EncodableValue("stabilization"), EncodableValue(EncodableList{})},
             {EncodableValue("hdr"), EncodableValue(false)},
             {EncodableValue("nightMode"), EncodableValue(false)},
             {EncodableValue("rawCapture"), EncodableValue(false)},
             {EncodableValue("depthCapture"), EncodableValue(false)},
             {EncodableValue("videoRecording"), EncodableValue(true)},
             {EncodableValue("pauseRecording"), EncodableValue(false)},
             {EncodableValue("audioRecording"), EncodableValue(false)},
             {EncodableValue("imageStream"), EncodableValue(true)},
             {EncodableValue("platformScanning"), EncodableValue(false)},
             {EncodableValue("multiCamera"), EncodableValue(false)},
             {EncodableValue("pictureInPicture"), EncodableValue(false)},
             {EncodableValue("lensSwitching"), EncodableValue(false)},
             {EncodableValue("orientationLock"), EncodableValue(false)},
             {EncodableValue("snapshot"), EncodableValue(true)},
             {EncodableValue("videoCodecs"), EncodableValue(EncodableList{EncodableValue("h264")})},
             {EncodableValue("photoFormats"), EncodableValue(EncodableList{EncodableValue("jpeg"), EncodableValue("png")})},
             {EncodableValue("frameFormats"), EncodableValue(EncodableList{EncodableValue("gray8"), EncodableValue("rgba8888")})},
             {EncodableValue("maxFps"), EncodableValue(30.0)},
         })},
    });
  }

 private:
  bool SelectFormat(int requested_width, int requested_height) {
    IMFMediaType* best = nullptr;
    int best_score = -1;
    for (DWORD index = 0;; index++) {
      IMFMediaType* type = nullptr;
      if (FAILED(reader_->GetNativeMediaType(MF_SOURCE_READER_FIRST_VIDEO_STREAM, index, &type))) break;
      UINT32 width = 0;
      UINT32 height = 0;
      if (SUCCEEDED(MFGetAttributeSize(type, MF_MT_FRAME_SIZE, &width, &height))) {
        const int score = -std::abs(static_cast<int>(width) - requested_width) - std::abs(static_cast<int>(height) - requested_height);
        if (score > best_score) {
          best_score = score;
          SafeRelease(&best);
          best = type;
          best->AddRef();
        }
      }
      SafeRelease(&type);
    }
    if (best == nullptr) return false;

    UINT32 width = 0;
    UINT32 height = 0;
    MFGetAttributeSize(best, MF_MT_FRAME_SIZE, &width, &height);
    width_ = static_cast<int>(width);
    height_ = static_cast<int>(height);
    SafeRelease(&best);

    IMFMediaType* output = nullptr;
    if (FAILED(MFCreateMediaType(&output))) return false;
    output->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
    output->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_RGB32);
    const HRESULT hr = reader_->SetCurrentMediaType(MF_SOURCE_READER_FIRST_VIDEO_STREAM, nullptr, output);
    SafeRelease(&output);
    return SUCCEEDED(hr);
  }

  void StopRecordingInternal() {
    if (writer_ == nullptr) return;
    writer_->Finalize();
    SafeRelease(&writer_);
    recording_path_.clear();
  }

  void Loop() {
    while (running_) {
      if (paused_) {
        Sleep(20);
        continue;
      }

      DWORD stream_flags = 0;
      LONGLONG timestamp = 0;
      IMFSample* sample = nullptr;
      if (FAILED(reader_->ReadSample(MF_SOURCE_READER_FIRST_VIDEO_STREAM, 0, nullptr, &stream_flags, &timestamp, &sample))) {
        Sleep(5);
        continue;
      }
      if (sample == nullptr) {
        Sleep(5);
        continue;
      }

      IMFMediaBuffer* media_buffer = nullptr;
      if (SUCCEEDED(sample->ConvertToContiguousBuffer(&media_buffer))) {
        BYTE* data = nullptr;
        DWORD max_length = 0;
        DWORD current_length = 0;
        if (SUCCEEDED(media_buffer->Lock(&data, &max_length, &current_length))) {
          {
            std::lock_guard<std::mutex> guard(pixel_lock_);
            const size_t expected = static_cast<size_t>(width_) * height_ * 4;
            const size_t copy = std::min<size_t>(expected, current_length);
            // Media Foundation hands back BGRA rows bottom-up for RGB32.
            for (int y = 0; y < height_; y++) {
              const uint8_t* row = data + static_cast<size_t>(height_ - 1 - y) * width_ * 4;
              uint8_t* out = rgba_.data() + static_cast<size_t>(y) * width_ * 4;
              if (static_cast<size_t>((height_ - y) * width_ * 4) > copy) continue;
              for (int x = 0; x < width_; x++) {
                out[x * 4 + 0] = row[x * 4 + 2];
                out[x * 4 + 1] = row[x * 4 + 1];
                out[x * 4 + 2] = row[x * 4 + 0];
                out[x * 4 + 3] = 255;
              }
            }
          }
          if (writer_ != nullptr) WriteRecordingFrame(data, current_length, timestamp);
          media_buffer->Unlock();
        }
        SafeRelease(&media_buffer);
      }
      SafeRelease(&sample);

      textures_->MarkTextureFrameAvailable(texture_id_);
      EmitFrameIfDue();
    }
  }

  void WriteRecordingFrame(const BYTE* data, DWORD length, LONGLONG timestamp) {
    IMFMediaBuffer* buffer = nullptr;
    if (FAILED(MFCreateMemoryBuffer(length, &buffer))) return;
    BYTE* target = nullptr;
    DWORD max_length = 0;
    DWORD current = 0;
    if (SUCCEEDED(buffer->Lock(&target, &max_length, &current))) {
      memcpy(target, data, length);
      buffer->Unlock();
      buffer->SetCurrentLength(length);
      IMFSample* sample = nullptr;
      if (SUCCEEDED(MFCreateSample(&sample))) {
        sample->AddBuffer(buffer);
        sample->SetSampleTime(recording_time_);
        sample->SetSampleDuration(333333);
        recording_time_ += 333333;
        writer_->WriteSample(stream_index_, sample);
        SafeRelease(&sample);
      }
    }
    SafeRelease(&buffer);
  }

  void EmitFrameIfDue() {
    if (!streaming_ || frame_sink_ == nullptr) return;
    const int64_t now = static_cast<int64_t>(GetTickCount64());
    if (now - last_frame_ms_ < frame_interval_ms_) return;
    last_frame_ms_ = now;

    std::vector<uint8_t> gray(static_cast<size_t>(width_) * height_);
    {
      std::lock_guard<std::mutex> guard(pixel_lock_);
      RgbaToGray(rgba_.data(), gray.data(), width_, height_);
    }
    frame_sink_->Success(EncodableValue(EncodableMap{
        {EncodableValue("planes"), EncodableValue(EncodableList{EncodableValue(gray)})},
        {EncodableValue("format"), EncodableValue("gray8")},
        {EncodableValue("width"), EncodableValue(width_)},
        {EncodableValue("height"), EncodableValue(height_)},
        {EncodableValue("rowStrides"), EncodableValue(EncodableList{EncodableValue(width_)})},
        {EncodableValue("pixelStrides"), EncodableValue(EncodableList{EncodableValue(1)})},
        {EncodableValue("rotation"), EncodableValue(0)},
        {EncodableValue("mirrored"), EncodableValue(false)},
    }));
  }

  int id_;
  flutter::BinaryMessenger* messenger_;
  flutter::TextureRegistrar* textures_;
  IMFSourceReader* reader_ = nullptr;
  IMFSinkWriter* writer_ = nullptr;
  DWORD stream_index_ = 0;
  std::string recording_path_;
  ULONGLONG recording_started_ = 0;
  LONGLONG recording_time_ = 0;

  std::unique_ptr<flutter::TextureVariant> buffer_;
  FlutterDesktopPixelBuffer descriptor_ = {};
  int64_t texture_id_ = -1;

  std::unique_ptr<flutter::EventChannel<EncodableValue>> event_channel_;
  std::unique_ptr<flutter::EventChannel<EncodableValue>> frame_channel_;
  std::unique_ptr<flutter::EventSink<EncodableValue>> event_sink_;
  std::unique_ptr<flutter::EventSink<EncodableValue>> frame_sink_;

  int width_ = 0;
  int height_ = 0;
  std::vector<uint8_t> rgba_;
  std::mutex pixel_lock_;
  std::thread worker_;
  std::atomic<bool> running_{false};
  std::atomic<bool> paused_{false};
  std::atomic<bool> streaming_{false};
  std::string frame_format_ = "gray8";
  int64_t frame_interval_ms_ = 80;
  int64_t last_frame_ms_ = 0;
};

class CameraPlugin {
 public:
  CameraPlugin(flutter::BinaryMessenger* messenger, flutter::TextureRegistrar* textures)
      : messenger_(messenger), textures_(textures) {
    MFStartup(MF_VERSION);
  }

  ~CameraPlugin() {
    sessions_.clear();
    MFShutdown();
  }

  void HandleMethodCall(const flutter::MethodCall<EncodableValue>& call,
                        std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    const auto* args = std::get_if<EncodableMap>(call.arguments());
    const std::string& method = call.method_name();

    if (method == "isSupported") {
      result->Success(EncodableValue(!EnumerateDevices().empty()));
      return;
    }
    if (method == "availableCameras") {
      EncodableList list;
      for (const auto& device : EnumerateDevices()) list.push_back(DescribeDevice(device));
      result->Success(EncodableValue(list));
      return;
    }
    if (method == "permissionStatus" || method == "requestPermission") {
      result->Success(EncodableValue(EncodableMap{
          {EncodableValue("camera"), EncodableValue("granted")},
          {EncodableValue("microphone"), EncodableValue("granted")},
      }));
      return;
    }
    if (method == "openSettings") {
      ShellExecuteW(nullptr, L"open", L"ms-settings:privacy-webcam", nullptr, nullptr, SW_SHOWNORMAL);
      result->Success(EncodableValue(true));
      return;
    }
    if (method == "create") {
      CreateSession(args, std::move(result));
      return;
    }

    const int id = static_cast<int>(LookupInt(args, "sessionId", -1));
    const auto found = sessions_.find(id);
    if (found == sessions_.end()) {
      result->Error("notFound", "Camera session not found");
      return;
    }
    Session* session = found->second.get();

    if (method == "dispose") {
      sessions_.erase(found);
      result->Success();
    } else if (method == "startImageStream") {
      session->StartImageStream(LookupString(args, "format", "gray8"), LookupDouble(args, "maxFps", 12));
      result->Success();
    } else if (method == "stopImageStream") {
      session->StopImageStream();
      result->Success();
    } else if (method == "setPreviewPaused") {
      session->SetPaused(LookupBool(args, "paused", false));
      result->Success();
    } else if (method == "takePhoto" || method == "takeSnapshot") {
      int width = 0;
      int height = 0;
      const std::string format = LookupString(args, "format", "jpeg");
      std::vector<uint8_t> encoded = session->Capture(format, LookupDouble(args, "quality", 92) / 100.0, &width, &height);
      if (encoded.empty()) {
        result->Error("capture", "No frame available");
        return;
      }
      const std::string path = LookupString(args, "path", "");
      if (!path.empty()) {
        FILE* file = nullptr;
        if (fopen_s(&file, path.c_str(), "wb") == 0 && file != nullptr) {
          fwrite(encoded.data(), 1, encoded.size(), file);
          fclose(file);
        }
      }
      result->Success(EncodableValue(EncodableMap{
          {EncodableValue("path"), path.empty() ? EncodableValue() : EncodableValue(path)},
          {EncodableValue("bytes"), EncodableValue(encoded)},
          {EncodableValue("width"), EncodableValue(width)},
          {EncodableValue("height"), EncodableValue(height)},
          {EncodableValue("format"), EncodableValue(format == "png" ? "png" : "jpeg")},
          {EncodableValue("orientation"), EncodableValue(0)},
          {EncodableValue("sizeInBytes"), EncodableValue(static_cast<int64_t>(encoded.size()))},
      }));
    } else if (method == "startRecording") {
      std::string path = LookupString(args, "path", "");
      if (path.empty()) {
        wchar_t temp[MAX_PATH];
        GetTempPathW(MAX_PATH, temp);
        path = ToUtf8(std::wstring(temp)) + "u_camera_" + std::to_string(GetTickCount64()) + ".mp4";
      }
      if (session->StartRecording(path, static_cast<int>(LookupInt(args, "bitrate", 6000000)))) {
        result->Success();
      } else {
        result->Error("recording", "Unable to start recording");
      }
    } else if (method == "stopRecording") {
      std::string path;
      int64_t duration = 0;
      if (!session->StopRecording(&path, &duration)) {
        result->Error("recording", "Not recording");
        return;
      }
      result->Success(EncodableValue(EncodableMap{
          {EncodableValue("path"), EncodableValue(path)},
          {EncodableValue("durationMs"), EncodableValue(duration)},
          {EncodableValue("width"), EncodableValue(session->width())},
          {EncodableValue("height"), EncodableValue(session->height())},
          {EncodableValue("sizeInBytes"), EncodableValue(0)},
          {EncodableValue("container"), EncodableValue("mp4")},
      }));
    } else {
      // Remaining controls have no Media Foundation equivalent on a generic
      // webcam; succeed so the Dart-side state stays consistent.
      result->Success();
    }
  }

 private:
  void CreateSession(const EncodableMap* args, std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    const EncodableValue* config_value = Lookup(args, "config");
    const auto* config = config_value == nullptr ? nullptr : std::get_if<EncodableMap>(config_value);

    const auto devices = EnumerateDevices();
    if (devices.empty()) {
      result->Error("notFound", "No camera found");
      return;
    }
    const std::string requested = LookupString(config, "deviceId", "");
    DeviceInfo chosen = devices.front();
    for (const auto& device : devices) {
      if (ToUtf8(device.symbolic_link) == requested) chosen = device;
    }

    const std::string resolution = LookupString(config, "resolution", "high");
    int width = 1280;
    int height = 720;
    if (resolution == "low") {
      width = 320;
      height = 240;
    } else if (resolution == "medium") {
      width = 640;
      height = 480;
    } else if (resolution == "veryHigh" || resolution == "ultraHigh" || resolution == "max") {
      width = 1920;
      height = 1080;
    }

    const int id = next_id_++;
    auto session = std::make_unique<Session>(id, messenger_, textures_);
    std::string error;
    if (!session->Open(chosen.symbolic_link, width, height, &error)) {
      result->Error(error, "Unable to open camera");
      return;
    }
    EncodableValue description = session->Describe(chosen.name, ToUtf8(chosen.symbolic_link));
    sessions_[id] = std::move(session);
    result->Success(description);
  }

  flutter::BinaryMessenger* messenger_;
  flutter::TextureRegistrar* textures_;
  std::map<int, std::unique_ptr<Session>> sessions_;
  int next_id_ = 1;
};

std::unique_ptr<CameraPlugin> g_plugin;
std::unique_ptr<flutter::MethodChannel<EncodableValue>> g_channel;

}  // namespace

void UCamera::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
  if (g_plugin != nullptr) return;
  g_plugin = std::make_unique<CameraPlugin>(registrar->messenger(), registrar->texture_registrar());
  g_channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), "u/camera", &flutter::StandardMethodCodec::GetInstance());
  g_channel->SetMethodCallHandler([](const auto& call, auto result) {
    g_plugin->HandleMethodCall(call, std::move(result));
  });
}

}  // namespace u
