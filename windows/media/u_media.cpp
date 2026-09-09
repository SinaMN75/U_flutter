#include "u_media.h"

#include <mferror.h>
#include <shlwapi.h>

#include <atomic>
#include <cmath>
#include <string>
#include <vector>

#pragma comment(lib, "mf.lib")
#pragma comment(lib, "mfplat.lib")
#pragma comment(lib, "mfuuid.lib")
#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")

namespace u {

namespace {

constexpr UINT kEngineEventMessage = WM_USER + 21;
constexpr UINT_PTR kFrameTimer = 1;
constexpr UINT_PTR kPositionTimer = 2;
constexpr wchar_t kWindowClass[] = L"UMediaPlayerMessageWindow";

std::atomic<int> g_mf_refs{0};

void EnsureMediaFoundation() {
  if (g_mf_refs.fetch_add(1) == 0) {
    MFStartup(MF_VERSION, MFSTARTUP_LITE);
  }
}

void ReleaseMediaFoundation() {
  if (g_mf_refs.fetch_sub(1) == 1) {
    MFShutdown();
  }
}

std::wstring Widen(const std::string& value) {
  if (value.empty()) return std::wstring();
  const int size = MultiByteToWideChar(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()), nullptr, 0);
  std::wstring result(size, 0);
  MultiByteToWideChar(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()), result.data(), size);
  return result;
}

const flutter::EncodableValue* Find(const flutter::EncodableMap& map, const char* key) {
  const auto it = map.find(flutter::EncodableValue(key));
  return it == map.end() ? nullptr : &it->second;
}

std::string StringAt(const flutter::EncodableMap& map, const char* key, const std::string& fallback = "") {
  const flutter::EncodableValue* value = Find(map, key);
  if (value == nullptr) return fallback;
  if (const auto* text = std::get_if<std::string>(value)) return *text;
  return fallback;
}

int64_t IntAt(const flutter::EncodableMap& map, const char* key, int64_t fallback) {
  const flutter::EncodableValue* value = Find(map, key);
  if (value == nullptr) return fallback;
  if (const auto* number = std::get_if<int32_t>(value)) return *number;
  if (const auto* number = std::get_if<int64_t>(value)) return *number;
  if (const auto* number = std::get_if<double>(value)) return static_cast<int64_t>(*number);
  return fallback;
}

double DoubleAt(const flutter::EncodableMap& map, const char* key, double fallback) {
  const flutter::EncodableValue* value = Find(map, key);
  if (value == nullptr) return fallback;
  if (const auto* number = std::get_if<double>(value)) return *number;
  if (const auto* number = std::get_if<int32_t>(value)) return static_cast<double>(*number);
  if (const auto* number = std::get_if<int64_t>(value)) return static_cast<double>(*number);
  return fallback;
}

bool BoolAt(const flutter::EncodableMap& map, const char* key, bool fallback) {
  const flutter::EncodableValue* value = Find(map, key);
  if (value == nullptr) return fallback;
  if (const auto* flag = std::get_if<bool>(value)) return *flag;
  return fallback;
}

flutter::EncodableMap MapAt(const flutter::EncodableMap& map, const char* key) {
  const flutter::EncodableValue* value = Find(map, key);
  if (value == nullptr) return flutter::EncodableMap();
  if (const auto* inner = std::get_if<flutter::EncodableMap>(value)) return *inner;
  return flutter::EncodableMap();
}

LRESULT CALLBACK MessageWindowProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
  auto* player = reinterpret_cast<UMediaPlayer*>(GetWindowLongPtr(window, GWLP_USERDATA));
  if (player != nullptr) {
    if (message == kEngineEventMessage) {
      player->OnEngineEvent(static_cast<DWORD>(wparam), 0, static_cast<DWORD>(lparam));
      return 0;
    }
    if (message == WM_TIMER) {
      player->OnEngineEvent(static_cast<DWORD>(0xF000 + wparam), 0, 0);
      return 0;
    }
  }
  return DefWindowProc(window, message, wparam, lparam);
}

HWND CreateMessageWindow(void* owner) {
  static bool registered = false;
  HINSTANCE instance = GetModuleHandle(nullptr);
  if (!registered) {
    WNDCLASSEX descriptor = {};
    descriptor.cbSize = sizeof(WNDCLASSEX);
    descriptor.lpfnWndProc = MessageWindowProc;
    descriptor.hInstance = instance;
    descriptor.lpszClassName = kWindowClass;
    RegisterClassEx(&descriptor);
    registered = true;
  }
  HWND window = CreateWindowEx(0, kWindowClass, L"", 0, 0, 0, 0, 0, HWND_MESSAGE, nullptr, instance, nullptr);
  if (window != nullptr) SetWindowLongPtr(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(owner));
  return window;
}

}  // namespace

// === UMediaEngineNotify ===

void UMediaEngineNotify::Detach() {
  std::lock_guard<std::mutex> lock(mutex_);
  owner_ = nullptr;
}

STDMETHODIMP UMediaEngineNotify::QueryInterface(REFIID riid, void** object) {
  if (object == nullptr) return E_POINTER;
  if (riid == __uuidof(IMFMediaEngineNotify) || riid == IID_IUnknown) {
    *object = static_cast<IMFMediaEngineNotify*>(this);
    AddRef();
    return S_OK;
  }
  *object = nullptr;
  return E_NOINTERFACE;
}

STDMETHODIMP_(ULONG) UMediaEngineNotify::AddRef() { return InterlockedIncrement(&reference_count_); }

STDMETHODIMP_(ULONG) UMediaEngineNotify::Release() {
  const ULONG count = InterlockedDecrement(&reference_count_);
  if (count == 0) delete this;
  return count;
}

STDMETHODIMP UMediaEngineNotify::EventNotify(DWORD event, DWORD_PTR param1, DWORD param2) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (owner_ != nullptr) owner_->OnEngineEvent(event, param1, param2);
  return S_OK;
}

// === UMediaPlayer ===

UMediaPlayer::UMediaPlayer(int id,
                           flutter::BinaryMessenger* messenger,
                           flutter::TextureRegistrar* textures,
                           const flutter::EncodableMap& config,
                           bool is_video)
    : id_(id), is_video_(is_video), textures_(textures) {
  EnsureMediaFoundation();
  position_interval_ms_ = static_cast<int>(IntAt(config, "positionUpdateMs", 250));

  event_channel_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      messenger, "u/media/events/" + std::to_string(id), &flutter::StandardMethodCodec::GetInstance());
  event_channel_->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [this](const flutter::EncodableValue*, std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            std::lock_guard<std::mutex> lock(sink_mutex_);
            sink_ = std::move(events);
            return nullptr;
          },
          [this](const flutter::EncodableValue*)
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            std::lock_guard<std::mutex> lock(sink_mutex_);
            sink_.reset();
            return nullptr;
          }));

  window_ = CreateMessageWindow(this);
}

UMediaPlayer::~UMediaPlayer() {
  StopTicker();
  if (notify_) notify_->Detach();
  if (engine_) {
    engine_->Shutdown();
    engine_.Reset();
  }
  engine_ex_.Reset();
  if (texture_id_ >= 0 && textures_ != nullptr) textures_->UnregisterTexture(texture_id_);
  texture_id_ = -1;
  if (shared_handle_ != nullptr) {
    CloseHandle(shared_handle_);
    shared_handle_ = nullptr;
  }
  if (window_ != nullptr) {
    DestroyWindow(window_);
    window_ = nullptr;
  }
  {
    std::lock_guard<std::mutex> lock(sink_mutex_);
    sink_.reset();
  }
  if (event_channel_) event_channel_->SetStreamHandler(nullptr);
  ReleaseMediaFoundation();
}

void UMediaPlayer::Emit(const flutter::EncodableMap& payload) {
  std::lock_guard<std::mutex> lock(sink_mutex_);
  if (sink_) sink_->Success(flutter::EncodableValue(payload));
}

void UMediaPlayer::EmitError(const std::string& code, const std::string& message) {
  Emit(flutter::EncodableMap{
      {flutter::EncodableValue("event"), flutter::EncodableValue("error")},
      {flutter::EncodableValue("code"), flutter::EncodableValue(code)},
      {flutter::EncodableValue("message"), flutter::EncodableValue(message)},
  });
}

bool UMediaPlayer::EnsureDevice() {
  if (device_) return true;

  const D3D_FEATURE_LEVEL levels[] = {D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_1,
                                      D3D_FEATURE_LEVEL_10_0};
  UINT flags = D3D11_CREATE_DEVICE_BGRA_SUPPORT | D3D11_CREATE_DEVICE_VIDEO_SUPPORT;
  HRESULT hr = D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, flags, levels, ARRAYSIZE(levels),
                                 D3D11_SDK_VERSION, &device_, nullptr, &context_);
  if (FAILED(hr)) {
    flags = D3D11_CREATE_DEVICE_BGRA_SUPPORT;
    hr = D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_WARP, nullptr, flags, levels, ARRAYSIZE(levels),
                           D3D11_SDK_VERSION, &device_, nullptr, &context_);
  }
  if (FAILED(hr)) return false;

  ComPtr<ID3D10Multithread> multithread;
  if (SUCCEEDED(device_.As(&multithread))) multithread->SetMultithreadProtected(TRUE);

  UINT token = 0;
  if (FAILED(MFCreateDXGIDeviceManager(&token, &dxgi_manager_))) return false;
  return SUCCEEDED(dxgi_manager_->ResetDevice(device_.Get(), token));
}

bool UMediaPlayer::EnsureTexture(UINT width, UINT height) {
  if (!is_video_ || width == 0 || height == 0) return false;
  if (texture_ && width_ == width && height_ == height) return true;
  if (!EnsureDevice()) return false;

  width_ = width;
  height_ = height;
  texture_.Reset();
  if (shared_handle_ != nullptr) {
    CloseHandle(shared_handle_);
    shared_handle_ = nullptr;
  }

  D3D11_TEXTURE2D_DESC description = {};
  description.Width = width;
  description.Height = height;
  description.MipLevels = 1;
  description.ArraySize = 1;
  description.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
  description.SampleDesc.Count = 1;
  description.Usage = D3D11_USAGE_DEFAULT;
  description.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
  description.MiscFlags = D3D11_RESOURCE_MISC_SHARED;

  if (FAILED(device_->CreateTexture2D(&description, nullptr, &texture_))) return false;

  ComPtr<IDXGIResource> resource;
  if (FAILED(texture_.As(&resource))) return false;
  if (FAILED(resource->GetSharedHandle(&shared_handle_))) return false;

  if (texture_id_ < 0) {
    descriptor_ = std::make_unique<FlutterDesktopGpuSurfaceDescriptor>();
    texture_variant_ = std::make_unique<flutter::TextureVariant>(flutter::GpuSurfaceTexture(
        kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle,
        [this](size_t, size_t) -> const FlutterDesktopGpuSurfaceDescriptor* {
          descriptor_->struct_size = sizeof(FlutterDesktopGpuSurfaceDescriptor);
          descriptor_->handle = shared_handle_;
          descriptor_->width = width_;
          descriptor_->height = height_;
          descriptor_->visible_width = width_;
          descriptor_->visible_height = height_;
          descriptor_->format = kFlutterDesktopPixelFormatBGRA8888;
          descriptor_->release_callback = nullptr;
          descriptor_->release_context = nullptr;
          return descriptor_.get();
        }));
    texture_id_ = textures_->RegisterTexture(texture_variant_.get());
  }
  return true;
}

bool UMediaPlayer::Open(const flutter::EncodableMap& source, bool auto_play, int64_t resume_ms) {
  if (!EnsureDevice()) {
    EmitError("decoder", "Direct3D device could not be created");
    return false;
  }

  announced_ = false;

  if (engine_) {
    engine_->Shutdown();
    engine_.Reset();
    engine_ex_.Reset();
  }
  if (notify_) {
    notify_->Detach();
    notify_.Reset();
  }

  ComPtr<IMFMediaEngineClassFactory> factory;
  if (FAILED(CoCreateInstance(CLSID_MFMediaEngineClassFactory, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&factory)))) {
    EmitError("decoder", "Media Engine is unavailable");
    return false;
  }

  notify_.Attach(new UMediaEngineNotify(this));

  ComPtr<IMFAttributes> attributes;
  if (FAILED(MFCreateAttributes(&attributes, 4))) return false;
  attributes->SetUnknown(MF_MEDIA_ENGINE_CALLBACK, notify_.Get());
  if (is_video_ && dxgi_manager_) attributes->SetUnknown(MF_MEDIA_ENGINE_DXGI_MANAGER, dxgi_manager_.Get());
  attributes->SetUINT32(MF_MEDIA_ENGINE_VIDEO_OUTPUT_FORMAT, DXGI_FORMAT_B8G8R8A8_UNORM);

  if (FAILED(factory->CreateInstance(is_video_ ? 0 : MF_MEDIA_ENGINE_AUDIOONLY, attributes.Get(), &engine_))) {
    EmitError("decoder", "Media Engine instance could not be created");
    return false;
  }
  engine_.As(&engine_ex_);

  const std::string kind = StringAt(source, "kind");
  std::string location;
  if (kind == "network") {
    location = StringAt(source, "url");
  } else if (kind == "file") {
    location = StringAt(source, "path");
  } else if (kind == "content") {
    location = StringAt(source, "uri");
  } else if (kind == "asset") {
    location = "data/flutter_assets/" + StringAt(source, "asset");
  }

  if (location.empty()) {
    EmitError("notFound", "Unsupported source");
    return false;
  }

  const std::wstring wide = Widen(location);
  BSTR url = SysAllocString(wide.c_str());
  const HRESULT hr = engine_->SetSource(url);
  SysFreeString(url);
  if (FAILED(hr)) {
    EmitError("unsupportedFormat", "Source could not be opened");
    return false;
  }

  if (resume_ms > 0) engine_->SetCurrentTime(static_cast<double>(resume_ms) / 1000.0);
  Emit(flutter::EncodableMap{{flutter::EncodableValue("event"), flutter::EncodableValue("state")},
                             {flutter::EncodableValue("state"), flutter::EncodableValue("loading")}});
  if (auto_play) Play();
  return true;
}

void UMediaPlayer::Play() {
  if (!engine_) return;
  engine_->Play();
  StartTicker();
}

void UMediaPlayer::Pause() {
  if (!engine_) return;
  engine_->Pause();
  EmitPosition();
}

void UMediaPlayer::Stop() {
  if (!engine_) return;
  engine_->Pause();
  engine_->SetCurrentTime(0);
  StopTicker();
  Emit(flutter::EncodableMap{{flutter::EncodableValue("event"), flutter::EncodableValue("state")},
                             {flutter::EncodableValue("state"), flutter::EncodableValue("idle")}});
}

void UMediaPlayer::Seek(int64_t position_ms) {
  if (!engine_) return;
  engine_->SetCurrentTime(static_cast<double>(position_ms) / 1000.0);
  EmitPosition();
}

void UMediaPlayer::SetSpeed(double speed) {
  if (engine_) engine_->SetPlaybackRate(speed);
}

void UMediaPlayer::SetVolume(double volume) {
  if (engine_) engine_->SetVolume(volume < 0 ? 0 : (volume > 1 ? 1 : volume));
}

void UMediaPlayer::SetMuted(bool muted) {
  if (engine_) engine_->SetMuted(muted);
}

void UMediaPlayer::SetRepeat(const std::string& mode) {
  loop_ = mode == "one";
  if (engine_) engine_->SetLoop(loop_);
}

int64_t UMediaPlayer::PositionMs() {
  if (!engine_) return 0;
  return static_cast<int64_t>(engine_->GetCurrentTime() * 1000.0);
}

void UMediaPlayer::StartTicker() {
  if (window_ == nullptr) return;
  if (is_video_) SetTimer(window_, kFrameTimer, 16, nullptr);
  SetTimer(window_, kPositionTimer, static_cast<UINT>(position_interval_ms_), nullptr);
}

void UMediaPlayer::StopTicker() {
  if (window_ == nullptr) return;
  KillTimer(window_, kFrameTimer);
  KillTimer(window_, kPositionTimer);
}

void UMediaPlayer::EmitPosition() {
  if (!engine_) return;
  double buffered = 0;
  ComPtr<IMFMediaTimeRange> ranges;
  if (SUCCEEDED(engine_->GetBuffered(&ranges)) && ranges) {
    const DWORD count = ranges->GetLength();
    if (count > 0) {
      double start = 0;
      double end = 0;
      if (SUCCEEDED(ranges->GetStart(count - 1, &start)) && SUCCEEDED(ranges->GetEnd(count - 1, &end))) buffered = end;
    }
  }
  Emit(flutter::EncodableMap{
      {flutter::EncodableValue("event"), flutter::EncodableValue("position")},
      {flutter::EncodableValue("positionMs"), flutter::EncodableValue(PositionMs())},
      {flutter::EncodableValue("bufferedMs"), flutter::EncodableValue(static_cast<int64_t>(buffered * 1000.0))},
  });
}

void UMediaPlayer::RenderFrame() {
  if (!engine_ || !is_video_ || !texture_) return;
  LONGLONG pts = 0;
  if (engine_->OnVideoStreamTick(&pts) != S_OK) return;

  const MFVideoNormalizedRect rect{0, 0, 1, 1};
  const RECT destination{0, 0, static_cast<LONG>(width_), static_cast<LONG>(height_)};
  const MFARGB background{0, 0, 0, 255};
  if (SUCCEEDED(engine_->TransferVideoFrame(texture_.Get(), &rect, &destination, &background))) {
    if (context_) context_->Flush();
    textures_->MarkTextureFrameAvailable(texture_id_);
  }
}

void UMediaPlayer::OnEngineEvent(DWORD event, DWORD_PTR, DWORD param2) {
  if (event == 0xF000 + kFrameTimer) {
    RenderFrame();
    return;
  }
  if (event == 0xF000 + kPositionTimer) {
    EmitPosition();
    return;
  }

  if (window_ != nullptr && GetCurrentThreadId() != GetWindowThreadProcessId(window_, nullptr)) {
    PostMessage(window_, kEngineEventMessage, static_cast<WPARAM>(event), static_cast<LPARAM>(param2));
    return;
  }

  switch (event) {
    case MF_MEDIA_ENGINE_EVENT_LOADEDMETADATA: {
      DWORD width = 0;
      DWORD height = 0;
      if (engine_) engine_->GetNativeVideoSize(&width, &height);
      if (is_video_) EnsureTexture(width, height);
      const double duration = engine_ ? engine_->GetDuration() : 0;
      const bool live = std::isnan(duration) || std::isinf(duration) || duration <= 0;
      announced_ = true;
      Emit(flutter::EncodableMap{
          {flutter::EncodableValue("event"), flutter::EncodableValue("initialized")},
          {flutter::EncodableValue("textureId"),
           texture_id_ >= 0 ? flutter::EncodableValue(texture_id_) : flutter::EncodableValue()},
          {flutter::EncodableValue("durationMs"),
           flutter::EncodableValue(live ? int64_t{0} : static_cast<int64_t>(duration * 1000.0))},
          {flutter::EncodableValue("width"), flutter::EncodableValue(static_cast<int64_t>(width))},
          {flutter::EncodableValue("height"), flutter::EncodableValue(static_cast<int64_t>(height))},
          {flutter::EncodableValue("rotation"), flutter::EncodableValue(int64_t{0})},
          {flutter::EncodableValue("isLive"), flutter::EncodableValue(live)},
          {flutter::EncodableValue("tracks"), flutter::EncodableValue(flutter::EncodableList())},
      });
      break;
    }
    case MF_MEDIA_ENGINE_EVENT_PLAYING:
      Emit(flutter::EncodableMap{{flutter::EncodableValue("event"), flutter::EncodableValue("state")},
                                 {flutter::EncodableValue("state"), flutter::EncodableValue("playing")}});
      StartTicker();
      break;
    case MF_MEDIA_ENGINE_EVENT_PAUSE:
      Emit(flutter::EncodableMap{{flutter::EncodableValue("event"), flutter::EncodableValue("state")},
                                 {flutter::EncodableValue("state"), flutter::EncodableValue("paused")}});
      break;
    case MF_MEDIA_ENGINE_EVENT_WAITING:
    case MF_MEDIA_ENGINE_EVENT_BUFFERINGSTARTED:
      Emit(flutter::EncodableMap{{flutter::EncodableValue("event"), flutter::EncodableValue("state")},
                                 {flutter::EncodableValue("state"), flutter::EncodableValue("buffering")}});
      break;
    case MF_MEDIA_ENGINE_EVENT_ENDED:
      StopTicker();
      Emit(flutter::EncodableMap{{flutter::EncodableValue("event"), flutter::EncodableValue("completed")}});
      break;
    case MF_MEDIA_ENGINE_EVENT_ERROR: {
      std::string code = "unknown";
      switch (param2) {
        case MF_MEDIA_ENGINE_ERR_NETWORK:
          code = "network";
          break;
        case MF_MEDIA_ENGINE_ERR_DECODE:
          code = "decoder";
          break;
        case MF_MEDIA_ENGINE_ERR_SRC_NOT_SUPPORTED:
          code = "unsupportedFormat";
          break;
        case MF_MEDIA_ENGINE_ERR_ABORTED:
          code = "aborted";
          break;
        case MF_MEDIA_ENGINE_ERR_ENCRYPTED:
          code = "drm";
          break;
        default:
          break;
      }
      StopTicker();
      EmitError(code, "Media Engine reported an error");
      break;
    }
    default:
      break;
  }
}

// === UMedia ===

void UMedia::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
  static std::unique_ptr<UMedia> instance;
  instance = std::make_unique<UMedia>(registrar);
}

UMedia::UMedia(flutter::PluginRegistrarWindows* registrar) : registrar_(registrar) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "u/media", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) { HandleMethodCall(call, std::move(result)); });

  session_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "u/media_session", &flutter::StandardMethodCodec::GetInstance());
  session_channel_->SetMethodCallHandler([](const auto& call, auto result) {
    if (call.method_name() == "requestFocus") {
      result->Success(flutter::EncodableValue(true));
    } else if (call.method_name() == "abandonFocus") {
      result->Success();
    } else {
      result->NotImplemented();
    }
  });
}

UMedia::~UMedia() {
  players_.clear();
  if (channel_) channel_->SetMethodCallHandler(nullptr);
  if (session_channel_) session_channel_->SetMethodCallHandler(nullptr);
}

void UMedia::HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                              std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();

  if (method == "isAvailable") {
    result->Success(flutter::EncodableValue(true));
    return;
  }

  const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
  const flutter::EncodableMap empty;
  const flutter::EncodableMap& map = arguments == nullptr ? empty : *arguments;

  if (method == "create") {
    const int id = next_id_++;
    players_[id] = std::make_unique<UMediaPlayer>(id, registrar_->messenger(), registrar_->texture_registrar(),
                                                  MapAt(map, "config"), StringAt(map, "kind", "video") == "video");
    result->Success(flutter::EncodableValue(id));
    return;
  }

  const int id = static_cast<int>(IntAt(map, "id", -1));
  const auto found = players_.find(id);
  if (found == players_.end()) {
    result->Error("ERROR_NOT_FOUND", "Player not found");
    return;
  }
  UMediaPlayer* player = found->second.get();

  if (method == "open") {
    player->Open(MapAt(map, "source"), BoolAt(map, "autoPlay", false), IntAt(map, "resumeMs", 0));
    result->Success();
  } else if (method == "play") {
    player->Play();
    result->Success();
  } else if (method == "pause") {
    player->Pause();
    result->Success();
  } else if (method == "stop") {
    player->Stop();
    result->Success();
  } else if (method == "seek") {
    player->Seek(IntAt(map, "positionMs", 0));
    result->Success();
  } else if (method == "stepFrame") {
    player->Seek(player->PositionMs() + 33 * IntAt(map, "frames", 1));
    result->Success();
  } else if (method == "setSpeed") {
    player->SetSpeed(DoubleAt(map, "speed", 1.0));
    result->Success();
  } else if (method == "setVolume") {
    player->SetVolume(DoubleAt(map, "volume", 1.0));
    result->Success();
  } else if (method == "setMuted") {
    player->SetMuted(BoolAt(map, "muted", false));
    result->Success();
  } else if (method == "setRepeat") {
    player->SetRepeat(StringAt(map, "mode", "off"));
    result->Success();
  } else if (method == "dispose") {
    players_.erase(found);
    result->Success();
  } else if (method == "selectTrack" || method == "setAutoQuality" || method == "setMaxHeight" ||
             method == "setAudioDelay" || method == "setNotification" || method == "exitPip") {
    result->Success();
  } else if (method == "enterPip") {
    result->Success(flutter::EncodableValue(false));
  } else if (method == "screenshot") {
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace u
