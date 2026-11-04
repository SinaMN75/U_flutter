// windows.h's min/max macros break the C++/WinRT headers.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <winrt/Windows.Devices.Bluetooth.Advertisement.h>
#include <winrt/Windows.Devices.Bluetooth.GenericAttributeProfile.h>
#include <winrt/Windows.Devices.Bluetooth.h>
#include <winrt/Windows.Devices.Radios.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Storage.Streams.h>

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cstdio>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

#include "../common/u_platform.h"
#include "u_ble.h"

namespace u {

namespace {

namespace bt = winrt::Windows::Devices::Bluetooth;
namespace adv = winrt::Windows::Devices::Bluetooth::Advertisement;
namespace gatt = winrt::Windows::Devices::Bluetooth::GenericAttributeProfile;
namespace radios = winrt::Windows::Devices::Radios;
namespace streams = winrt::Windows::Storage::Streams;
using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;
using Sink = flutter::EventSink<EncodableValue>;
using StreamError = std::unique_ptr<flutter::StreamHandlerError<EncodableValue>>;

const EncodableValue* Arg(const EncodableMap& args, const char* key) {
  const auto it = args.find(EncodableValue(key));
  return it == args.end() ? nullptr : &it->second;
}

std::string StringArg(const EncodableMap& args, const char* key) {
  const EncodableValue* value = Arg(args, key);
  const std::string* text = value ? std::get_if<std::string>(value) : nullptr;
  return text ? *text : std::string();
}

bool BoolArg(const EncodableMap& args, const char* key, bool fallback) {
  const EncodableValue* value = Arg(args, key);
  const bool* flag = value ? std::get_if<bool>(value) : nullptr;
  return flag ? *flag : fallback;
}

int64_t IntArg(const EncodableMap& args, const char* key, int64_t fallback) {
  const EncodableValue* value = Arg(args, key);
  if (value == nullptr) return fallback;
  if (const int32_t* i = std::get_if<int32_t>(value)) return *i;
  if (const int64_t* l = std::get_if<int64_t>(value)) return *l;
  return fallback;
}

std::string AddressText(uint64_t address) {
  char text[18];
  snprintf(text, sizeof(text), "%02X:%02X:%02X:%02X:%02X:%02X", static_cast<unsigned>((address >> 40) & 0xFF), static_cast<unsigned>((address >> 32) & 0xFF),
           static_cast<unsigned>((address >> 24) & 0xFF), static_cast<unsigned>((address >> 16) & 0xFF), static_cast<unsigned>((address >> 8) & 0xFF),
           static_cast<unsigned>(address & 0xFF));
  return text;
}

bool ParseAddress(const std::string& text, uint64_t& out) {
  unsigned b[6];
  if (sscanf_s(text.c_str(), "%2x:%2x:%2x:%2x:%2x:%2x", &b[0], &b[1], &b[2], &b[3], &b[4], &b[5]) != 6) return false;
  out = 0;
  for (unsigned part : b) out = (out << 8) | (part & 0xFF);
  return true;
}

// "{6F1C...}" → "6f1c...", the form UBle uses everywhere.
std::string GuidText(winrt::guid const& id) {
  std::string text = winrt::to_string(winrt::to_hstring(id));
  text.erase(std::remove(text.begin(), text.end(), '{'), text.end());
  text.erase(std::remove(text.begin(), text.end(), '}'), text.end());
  std::transform(text.begin(), text.end(), text.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  return text;
}

std::vector<uint8_t> Bytes(streams::IBuffer const& buffer) {
  std::vector<uint8_t> out(buffer.Length());
  if (!out.empty()) streams::DataReader::FromBuffer(buffer).ReadBytes(out);
  return out;
}

streams::IBuffer Buffer(const std::vector<uint8_t>& bytes) {
  streams::DataWriter writer;
  writer.WriteBytes(bytes);
  return writer.DetachBuffer();
}

std::string StateName() {
  try {
    const bt::BluetoothAdapter adapter = bt::BluetoothAdapter::GetDefaultAsync().get();
    if (adapter == nullptr || !adapter.IsLowEnergySupported()) return "unsupported";
    const radios::Radio radio = adapter.GetRadioAsync().get();
    if (radio == nullptr) return "unsupported";
    return radio.State() == radios::RadioState::On ? "poweredOn" : "poweredOff";
  } catch (winrt::hresult_error const& e) {
    return e.code() == E_ACCESSDENIED ? "unauthorized" : "unsupported";
  } catch (...) {
    return "unsupported";
  }
}

struct Link {
  bt::BluetoothLEDevice device{nullptr};
  gatt::GattSession session{nullptr};
  std::map<std::string, gatt::GattCharacteristic> characteristics;
  std::vector<std::pair<gatt::GattCharacteristic, winrt::event_token>> subscriptions;
  winrt::event_token status_token{};
};

class Ble {
 public:
  explicit Ble(flutter::PluginRegistrarWindows* registrar) {
    auto* messenger = registrar->messenger();
    const auto& codec = flutter::StandardMethodCodec::GetInstance();
    channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(messenger, "u/ble", &codec);
    channel_->SetMethodCallHandler([this](const auto& call, auto result) { Handle(call, std::move(result)); });
    scan_ = Stream(messenger, "u/ble/scan", [this](std::unique_ptr<Sink>&& sink) { scan_sink_ = std::move(sink); }, [this]() { scan_sink_.reset(); });
    events_ = Stream(messenger, "u/ble/events", [this](std::unique_ptr<Sink>&& sink) { events_sink_ = std::move(sink); }, [this]() { events_sink_.reset(); });
  }

  static Ble*& Instance() {
    static Ble* instance = nullptr;
    return instance;
  }

 private:
  static std::unique_ptr<flutter::EventChannel<EncodableValue>> Stream(flutter::BinaryMessenger* messenger, const char* name, std::function<void(std::unique_ptr<Sink>&&)> listen,
                                                                       std::function<void()> cancel) {
    auto channel = std::make_unique<flutter::EventChannel<EncodableValue>>(messenger, name, &flutter::StandardMethodCodec::GetInstance());
    channel->SetStreamHandler(std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
        [listen](const EncodableValue*, std::unique_ptr<Sink>&& sink) {
          listen(std::move(sink));
          return StreamError();
        },
        [cancel](const EncodableValue*) {
          cancel();
          return StreamError();
        }));
    return channel;
  }

  void Handle(const flutter::MethodCall<EncodableValue>& call, std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    static const EncodableMap kEmpty;
    const EncodableMap* maybe = std::get_if<EncodableMap>(call.arguments());
    const EncodableMap& args = maybe ? *maybe : kEmpty;
    const std::string& method = call.method_name();
    platform::SharedResult shared(std::move(result));
    if (method == "state" || method == "requestPermission") {
      platform::RunInBackground([shared]() {
        const std::string state = StateName();
        platform::Post([shared, state]() { shared->Success(EncodableValue(state)); });
      });
    } else if (method == "startScan") {
      StartScan(args, shared);
    } else if (method == "stopScan") {
      StopScan();
      shared->Success();
    } else if (method == "connect") {
      Connect(StringArg(args, "id"), IntArg(args, "timeout", 15000), shared);
    } else if (method == "disconnect") {
      Drop(StringArg(args, "id"));
      shared->Success();
    } else if (method == "setNotify") {
      SetNotify(StringArg(args, "id"), StringArg(args, "service"), StringArg(args, "characteristic"), BoolArg(args, "enable", true), shared);
    } else if (method == "write") {
      const EncodableValue* raw = Arg(args, "value");
      const std::vector<uint8_t>* bytes = raw ? std::get_if<std::vector<uint8_t>>(raw) : nullptr;
      Write(StringArg(args, "id"), StringArg(args, "service"), StringArg(args, "characteristic"), bytes ? *bytes : std::vector<uint8_t>(), BoolArg(args, "withResponse", true), shared);
    } else {
      shared->NotImplemented();
    }
  }

  void StartScan(const EncodableMap& args, platform::SharedResult result) {
    StopScan();
    std::vector<std::string> services;
    const EncodableValue* raw = Arg(args, "services");
    if (const EncodableList* list = raw ? std::get_if<EncodableList>(raw) : nullptr) {
      for (const EncodableValue& item : *list) {
        if (const std::string* text = std::get_if<std::string>(&item)) services.push_back(*text);
      }
    }
    platform::RunInBackground([this, services, result]() {
      const std::string state = StateName();
      platform::Post([this, services, result, state]() {
        if (state != "poweredOn") return result->Error(state);
        try {
          watcher_ = adv::BluetoothLEAdvertisementWatcher();
          watcher_.ScanningMode(adv::BluetoothLEScanningMode::Active);
          watcher_.Received([services](adv::BluetoothLEAdvertisementWatcher const&, adv::BluetoothLEAdvertisementReceivedEventArgs const& e) {
            EncodableList uuids;
            bool matches = services.empty();
            for (winrt::guid const& id : e.Advertisement().ServiceUuids()) {
              const std::string text = GuidText(id);
              if (std::find(services.begin(), services.end(), text) != services.end()) matches = true;
              uuids.push_back(EncodableValue(text));
            }
            if (!matches) return;
            EncodableMap manufacturer;
            for (adv::BluetoothLEManufacturerData const& data : e.Advertisement().ManufacturerData()) {
              manufacturer[EncodableValue(static_cast<int32_t>(data.CompanyId()))] = EncodableValue(Bytes(data.Data()));
            }
            EncodableValue device(EncodableMap{
                {EncodableValue("id"), EncodableValue(AddressText(e.BluetoothAddress()))},
                {EncodableValue("name"), EncodableValue(winrt::to_string(e.Advertisement().LocalName()))},
                {EncodableValue("rssi"), EncodableValue(static_cast<int32_t>(e.RawSignalStrengthInDBm()))},
                {EncodableValue("services"), EncodableValue(uuids)},
                {EncodableValue("manufacturerData"), EncodableValue(manufacturer)},
            });
            platform::Post([device]() {
              Ble* self = Instance();
              if (self != nullptr && self->scan_sink_) self->scan_sink_->Success(device);
            });
          });
          watcher_.Start();
          result->Success();
        } catch (...) {
          watcher_ = nullptr;
          result->Error("failed");
        }
      });
    });
  }

  void StopScan() {
    if (watcher_ == nullptr) return;
    try {
      watcher_.Stop();
    } catch (...) {
    }
    watcher_ = nullptr;
  }

  void Connect(const std::string& id, int64_t timeout_ms, platform::SharedResult result) {
    uint64_t address = 0;
    if (!ParseAddress(id, address)) return result->Error("notFound");
    platform::RunInBackground([this, id, address, timeout_ms, result]() {
      try {
        const std::string state = StateName();
        if (state != "poweredOn") return platform::Post([result, state]() { result->Error(state); });
        const bt::BluetoothLEDevice device = bt::BluetoothLEDevice::FromBluetoothAddressAsync(address).get();
        if (device == nullptr) return platform::Post([result]() { result->Error("notFound"); });
        const gatt::GattSession session = gatt::GattSession::FromDeviceIdAsync(device.BluetoothDeviceId()).get();
        session.MaintainConnection(true);
        auto pending = device.GetGattServicesAsync(bt::BluetoothCacheMode::Uncached);
        if (pending.wait_for(std::chrono::milliseconds(timeout_ms)) != winrt::Windows::Foundation::AsyncStatus::Completed) {
          pending.Cancel();
          session.Close();
          device.Close();
          return platform::Post([result]() { result->Error("timeout"); });
        }
        const gatt::GattDeviceServicesResult services = pending.GetResults();
        if (services.Status() != gatt::GattCommunicationStatus::Success) {
          session.Close();
          device.Close();
          return platform::Post([result]() { result->Error("failed"); });
        }
        Link link;
        link.device = device;
        link.session = session;
        for (gatt::GattDeviceService const& service : services.Services()) {
          const gatt::GattCharacteristicsResult found = service.GetCharacteristicsAsync(bt::BluetoothCacheMode::Uncached).get();
          if (found.Status() != gatt::GattCommunicationStatus::Success) continue;
          for (gatt::GattCharacteristic const& characteristic : found.Characteristics()) {
            link.characteristics.insert_or_assign(GuidText(service.Uuid()) + "|" + GuidText(characteristic.Uuid()), characteristic);
          }
        }
        link.status_token = device.ConnectionStatusChanged([id](bt::BluetoothLEDevice const& changed, winrt::Windows::Foundation::IInspectable const&) {
          if (changed.ConnectionStatus() != bt::BluetoothConnectionStatus::Disconnected) return;
          platform::Post([id]() {
            if (Ble* self = Instance()) self->Drop(id);
          });
        });
        const int32_t max_write = std::max<int32_t>(20, static_cast<int32_t>(session.MaxPduSize()) - 3);
        {
          std::lock_guard<std::mutex> lock(mutex_);
          links_.insert_or_assign(id, std::move(link));
        }
        platform::Post([result, max_write]() { result->Success(EncodableValue(max_write)); });
      } catch (winrt::hresult_error const& e) {
        const std::string code = e.code() == E_ACCESSDENIED ? "unauthorized" : "failed";
        platform::Post([result, code]() { result->Error(code); });
      } catch (...) {
        platform::Post([result]() { result->Error("failed"); });
      }
    });
  }

  // Closes the link (asked for or lost) and tells Dart once.
  void Drop(const std::string& id) {
    Link link;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      const auto it = links_.find(id);
      if (it == links_.end()) return;
      link = std::move(it->second);
      links_.erase(it);
    }
    try {
      for (auto& subscription : link.subscriptions) subscription.first.ValueChanged(subscription.second);
      if (link.device != nullptr) link.device.ConnectionStatusChanged(link.status_token);
      if (link.session != nullptr) link.session.Close();
      if (link.device != nullptr) link.device.Close();
    } catch (...) {
    }
    if (events_sink_) events_sink_->Success(EncodableValue(EncodableMap{{EncodableValue("event"), EncodableValue("disconnected")}, {EncodableValue("id"), EncodableValue(id)}}));
  }

  bool Find(const std::string& id, const std::string& service, const std::string& characteristic, gatt::GattCharacteristic& out) {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto link = links_.find(id);
    if (link == links_.end()) return false;
    const auto found = link->second.characteristics.find(service + "|" + characteristic);
    if (found == link->second.characteristics.end()) return false;
    out = found->second;
    return true;
  }

  void SetNotify(const std::string& id, const std::string& service, const std::string& characteristic, bool enable, platform::SharedResult result) {
    platform::RunInBackground([this, id, service, characteristic, enable, result]() {
      gatt::GattCharacteristic target{nullptr};
      if (!Find(id, service, characteristic, target)) return platform::Post([result]() { result->Error("notFound"); });
      try {
        gatt::GattClientCharacteristicConfigurationDescriptorValue value = gatt::GattClientCharacteristicConfigurationDescriptorValue::None;
        if (enable) {
          const bool notify = (target.CharacteristicProperties() & gatt::GattCharacteristicProperties::Notify) == gatt::GattCharacteristicProperties::Notify;
          value = notify ? gatt::GattClientCharacteristicConfigurationDescriptorValue::Notify : gatt::GattClientCharacteristicConfigurationDescriptorValue::Indicate;
          const winrt::event_token token = target.ValueChanged([id, service, characteristic](gatt::GattCharacteristic const&, gatt::GattValueChangedEventArgs const& e) {
            EncodableValue event(EncodableMap{
                {EncodableValue("event"), EncodableValue("value")},
                {EncodableValue("id"), EncodableValue(id)},
                {EncodableValue("service"), EncodableValue(service)},
                {EncodableValue("characteristic"), EncodableValue(characteristic)},
                {EncodableValue("value"), EncodableValue(Bytes(e.CharacteristicValue()))},
            });
            platform::Post([event]() {
              Ble* self = Instance();
              if (self != nullptr && self->events_sink_) self->events_sink_->Success(event);
            });
          });
          std::lock_guard<std::mutex> lock(mutex_);
          const auto link = links_.find(id);
          if (link != links_.end()) link->second.subscriptions.emplace_back(target, token);
        }
        const gatt::GattCommunicationStatus status = target.WriteClientCharacteristicConfigurationDescriptorAsync(value).get();
        const bool ok = status == gatt::GattCommunicationStatus::Success;
        platform::Post([result, ok]() { ok ? result->Success() : result->Error("failed"); });
      } catch (...) {
        platform::Post([result]() { result->Error("failed"); });
      }
    });
  }

  void Write(const std::string& id, const std::string& service, const std::string& characteristic, const std::vector<uint8_t>& value, bool with_response,
             platform::SharedResult result) {
    platform::RunInBackground([this, id, service, characteristic, value, with_response, result]() {
      gatt::GattCharacteristic target{nullptr};
      if (!Find(id, service, characteristic, target)) return platform::Post([result]() { result->Error("disconnected"); });
      try {
        const gatt::GattWriteResult written =
            target.WriteValueWithResultAsync(Buffer(value), with_response ? gatt::GattWriteOption::WriteWithResponse : gatt::GattWriteOption::WriteWithoutResponse).get();
        const bool ok = written.Status() == gatt::GattCommunicationStatus::Success;
        platform::Post([result, ok]() { ok ? result->Success() : result->Error("failed"); });
      } catch (...) {
        platform::Post([result]() { result->Error("failed"); });
      }
    });
  }

  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;
  std::unique_ptr<flutter::EventChannel<EncodableValue>> scan_;
  std::unique_ptr<flutter::EventChannel<EncodableValue>> events_;
  std::unique_ptr<Sink> scan_sink_;
  std::unique_ptr<Sink> events_sink_;
  adv::BluetoothLEAdvertisementWatcher watcher_{nullptr};
  std::mutex mutex_;
  std::map<std::string, Link> links_;
};

}  // namespace

void RegisterBle(flutter::PluginRegistrarWindows* registrar) {
  if (Ble::Instance() != nullptr) return;
  // Kept alive for the app's lifetime; background WinRT callbacks reach it through Instance().
  Ble::Instance() = new Ble(registrar);
}

}  // namespace u
