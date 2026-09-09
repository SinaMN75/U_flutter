#ifndef FLUTTER_PLUGIN_U_MEDIA_H_
#define FLUTTER_PLUGIN_U_MEDIA_H_

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>

#include <d3d11.h>
#include <mfapi.h>
#include <mfmediaengine.h>
#include <windows.h>
#include <wrl.h>

#include <map>
#include <memory>
#include <mutex>
#include <string>

namespace u {

using Microsoft::WRL::ComPtr;

class UMediaPlayer;

class UMediaEngineNotify : public IMFMediaEngineNotify {
 public:
  explicit UMediaEngineNotify(UMediaPlayer* owner) : owner_(owner) {}

  void Detach();

  STDMETHODIMP QueryInterface(REFIID riid, void** object) override;
  STDMETHODIMP_(ULONG) AddRef() override;
  STDMETHODIMP_(ULONG) Release() override;
  STDMETHODIMP EventNotify(DWORD event, DWORD_PTR param1, DWORD param2) override;

 private:
  long reference_count_ = 1;
  std::mutex mutex_;
  UMediaPlayer* owner_ = nullptr;
};

class UMediaPlayer {
 public:
  UMediaPlayer(int id,
               flutter::BinaryMessenger* messenger,
               flutter::TextureRegistrar* textures,
               const flutter::EncodableMap& config,
               bool is_video);
  ~UMediaPlayer();

  int64_t texture_id() const { return texture_id_; }

  bool Open(const flutter::EncodableMap& source, bool auto_play, int64_t resume_ms);
  void Play();
  void Pause();
  void Stop();
  void Seek(int64_t position_ms);
  void SetSpeed(double speed);
  void SetVolume(double volume);
  void SetMuted(bool muted);
  void SetRepeat(const std::string& mode);
  int64_t PositionMs();

  void OnEngineEvent(DWORD event, DWORD_PTR param1, DWORD param2);

 private:
  bool EnsureDevice();
  bool EnsureTexture(UINT width, UINT height);
  void Emit(const flutter::EncodableMap& payload);
  void EmitPosition();
  void EmitError(const std::string& code, const std::string& message);
  void StartTicker();
  void StopTicker();
  void RenderFrame();

  int id_ = 0;
  bool is_video_ = false;
  flutter::TextureRegistrar* textures_ = nullptr;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
  std::mutex sink_mutex_;

  ComPtr<ID3D11Device> device_;
  ComPtr<ID3D11DeviceContext> context_;
  ComPtr<IMFDXGIDeviceManager> dxgi_manager_;
  ComPtr<IMFMediaEngine> engine_;
  ComPtr<IMFMediaEngineEx> engine_ex_;
  ComPtr<UMediaEngineNotify> notify_;
  ComPtr<ID3D11Texture2D> texture_;
  HANDLE shared_handle_ = nullptr;

  std::unique_ptr<FlutterDesktopGpuSurfaceDescriptor> descriptor_;
  std::unique_ptr<flutter::TextureVariant> texture_variant_;
  int64_t texture_id_ = -1;

  UINT width_ = 0;
  UINT height_ = 0;
  HWND window_ = nullptr;
  int position_interval_ms_ = 250;
  bool announced_ = false;
  bool loop_ = false;
};

class UMedia {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit UMedia(flutter::PluginRegistrarWindows* registrar);
  ~UMedia();

 private:
  void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::PluginRegistrarWindows* registrar_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> session_channel_;
  std::map<int, std::unique_ptr<UMediaPlayer>> players_;
  int next_id_ = 1;
};

}  // namespace u

#endif  // FLUTTER_PLUGIN_U_MEDIA_H_
