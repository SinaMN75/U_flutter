// windows.h's min/max macros break the C++/WinRT headers.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <winrt/Windows.Devices.Geolocation.Geofencing.h>
#include <winrt/Windows.Devices.Geolocation.h>
#include <winrt/Windows.Devices.Sensors.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <chrono>
#include <cmath>
#include <memory>
#include <string>
#include <vector>

#include "../common/u_platform.h"
#include "u_location.h"

namespace u {

namespace {

namespace geo = winrt::Windows::Devices::Geolocation;
namespace fencing = winrt::Windows::Devices::Geolocation::Geofencing;
namespace sensors = winrt::Windows::Devices::Sensors;
using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;
using platform::Narrow;
using platform::Widen;
using Sink = flutter::EventSink<EncodableValue>;
using StreamError = std::unique_ptr<flutter::StreamHandlerError<EncodableValue>>;

const EncodableValue* Arg(const EncodableMap& args, const char* key) {
  const auto it = args.find(EncodableValue(key));
  return it == args.end() ? nullptr : &it->second;
}

double DoubleArg(const EncodableMap& args, const char* key, double fallback) {
  const EncodableValue* value = Arg(args, key);
  if (value == nullptr) return fallback;
  if (const double* d = std::get_if<double>(value)) return *d;
  if (const int32_t* i = std::get_if<int32_t>(value)) return *i;
  if (const int64_t* l = std::get_if<int64_t>(value)) return static_cast<double>(*l);
  return fallback;
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

int64_t UnixMillis(winrt::Windows::Foundation::DateTime time) {
  return std::chrono::duration_cast<std::chrono::milliseconds>(winrt::clock::to_sys(time).time_since_epoch()).count();
}

int64_t NowMillis() { return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count(); }

uint32_t AccuracyMeters(const std::string& accuracy) {
  if (accuracy == "lowest") return 3000;
  if (accuracy == "low") return 1000;
  if (accuracy == "balanced") return 100;
  if (accuracy == "best" || accuracy == "navigation") return 1;
  return 10;
}

void PutOptional(EncodableMap& map, const char* key, winrt::Windows::Foundation::IReference<double> const& value) {
  if (value == nullptr) return;
  const double v = value.Value();
  if (!std::isnan(v)) map[EncodableValue(key)] = EncodableValue(v);
}

EncodableMap ToMap(geo::Geoposition const& position) {
  const geo::Geocoordinate coordinate = position.Coordinate();
  const geo::BasicGeoposition point = coordinate.Point().Position();
  EncodableMap map{
      {EncodableValue("latitude"), EncodableValue(point.Latitude)},
      {EncodableValue("longitude"), EncodableValue(point.Longitude)},
      {EncodableValue("time"), EncodableValue(UnixMillis(coordinate.Timestamp()))},
      {EncodableValue("accuracy"), EncodableValue(coordinate.Accuracy())},
  };
  if (coordinate.AltitudeAccuracy() != nullptr) map[EncodableValue("altitude")] = EncodableValue(point.Altitude);
  PutOptional(map, "altitudeAccuracy", coordinate.AltitudeAccuracy());
  PutOptional(map, "heading", coordinate.Heading());
  PutOptional(map, "speed", coordinate.Speed());
  const char* source = "default";
  switch (coordinate.PositionSource()) {
    case geo::PositionSource::Satellite: source = "gps"; break;
    case geo::PositionSource::WiFi: source = "wifi"; break;
    case geo::PositionSource::Cellular: source = "cellular"; break;
    case geo::PositionSource::IPAddress: source = "ip"; break;
    case geo::PositionSource::Obfuscated: source = "obfuscated"; break;
    default: break;
  }
  map[EncodableValue("source")] = EncodableValue(source);
  return map;
}

// WinRT failures mapped to ULocationError names.
std::string ErrorCode(winrt::hresult const& code) {
  if (code == E_ACCESSDENIED) return "permissionDenied";
  if (code == HRESULT_FROM_WIN32(ERROR_TIMEOUT) || code == HRESULT_FROM_WIN32(WAIT_TIMEOUT)) return "timeout";
  return "unavailable";
}

class Location {
 public:
  explicit Location(flutter::PluginRegistrarWindows* registrar) {
    auto* messenger = registrar->messenger();
    const auto& codec = flutter::StandardMethodCodec::GetInstance();
    channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(messenger, "u/location", &codec);
    channel_->SetMethodCallHandler([this](const auto& call, auto result) { Handle(call, std::move(result)); });
    updates_ = Stream(messenger, "u/location/updates",
                      [this](const EncodableValue* args, std::unique_ptr<Sink>&& sink) { return StartUpdates(args, std::move(sink)); },
                      [this]() { StopUpdates(); });
    heading_ = Stream(messenger, "u/location/heading",
                      [this](const EncodableValue*, std::unique_ptr<Sink>&& sink) { return StartHeading(std::move(sink)); },
                      [this]() { StopHeading(); });
    geofence_ = Stream(messenger, "u/location/geofence",
                       [this](const EncodableValue*, std::unique_ptr<Sink>&& sink) {
                         geofence_sink_ = std::move(sink);
                         for (const EncodableValue& event : queued_) geofence_sink_->Success(event);
                         queued_.clear();
                         return StreamError();
                       },
                       [this]() { geofence_sink_.reset(); });
    visits_ = Stream(messenger, "u/location/visits", [](const EncodableValue*, std::unique_ptr<Sink>&&) { return StreamError(); }, []() {});
    WatchGeofences();
  }

 private:
  using ListenFn = std::function<StreamError(const EncodableValue*, std::unique_ptr<Sink>&&)>;

  static std::unique_ptr<flutter::EventChannel<EncodableValue>> Stream(flutter::BinaryMessenger* messenger, const char* name, ListenFn listen, std::function<void()> cancel) {
    auto channel = std::make_unique<flutter::EventChannel<EncodableValue>>(messenger, name, &flutter::StandardMethodCodec::GetInstance());
    channel->SetStreamHandler(std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
        [listen](const EncodableValue* args, std::unique_ptr<Sink>&& sink) { return listen(args, std::move(sink)); },
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
    if (method == "permission" || method == "requestPermission") {
      Permission(shared);
    } else if (method == "current") {
      Current(args, shared);
    } else if (method == "addGeofence") {
      shared->Success(EncodableValue(AddGeofence(args)));
    } else if (method == "removeGeofence") {
      RemoveGeofence(StringArg(args, "id"));
      shared->Success();
    } else if (method == "clearGeofences") {
      try {
        fencing::GeofenceMonitor::Current().Geofences().Clear();
      } catch (...) {
      }
      shared->Success();
    } else if (method == "geofences") {
      shared->Success(EncodableValue(Geofences()));
    } else if (method == "reverseGeocode" || method == "geocode") {
      shared->Success(EncodableValue(EncodableList()));
    } else if (method == "lastKnown") {
      shared->Success();
    } else if (method == "requestPrecise" || method == "geocodingAvailable") {
      shared->Success(EncodableValue(method == "requestPrecise"));
    } else {
      shared->NotImplemented();
    }
  }

  // RequestAccessAsync must not block the platform (STA) thread.
  void Permission(platform::SharedResult result) {
    platform::RunInBackground([result]() {
      std::string status = "notDetermined";
      bool enabled = true;
      try {
        switch (geo::Geolocator::RequestAccessAsync().get()) {
          case geo::GeolocationAccessStatus::Allowed: status = "always"; break;
          case geo::GeolocationAccessStatus::Denied: status = "deniedForever"; break;
          default: break;
        }
        const geo::PositionStatus state = geo::Geolocator().LocationStatus();
        enabled = state != geo::PositionStatus::Disabled && state != geo::PositionStatus::NotAvailable;
      } catch (...) {
        status = "unsupported";
        enabled = false;
      }
      platform::Post([result, status, enabled]() {
        result->Success(EncodableValue(EncodableMap{
            {EncodableValue("status"), EncodableValue(status)},
            {EncodableValue("precise"), EncodableValue(true)},
            {EncodableValue("serviceEnabled"), EncodableValue(enabled)},
        }));
      });
    });
  }

  void Current(const EncodableMap& args, platform::SharedResult result) {
    const uint32_t accuracy = AccuracyMeters(StringArg(args, "accuracy"));
    const auto timeout = std::chrono::milliseconds(static_cast<int64_t>(DoubleArg(args, "timeoutMs", 20000)));
    const auto max_age = std::chrono::milliseconds(static_cast<int64_t>(DoubleArg(args, "maxAgeMs", 0)));
    platform::RunInBackground([result, accuracy, timeout, max_age]() {
      try {
        geo::Geolocator locator;
        locator.DesiredAccuracyInMeters(accuracy);
        const geo::Geoposition position = locator.GetGeopositionAsync(max_age, timeout).get();
        EncodableMap map = ToMap(position);
        platform::Post([result, map]() { result->Success(EncodableValue(map)); });
      } catch (winrt::hresult_error const& e) {
        const std::string code = ErrorCode(e.code());
        platform::Post([result, code]() { result->Error(code); });
      } catch (...) {
        platform::Post([result]() { result->Error("unavailable"); });
      }
    });
  }

  StreamError StartUpdates(const EncodableValue* raw, std::unique_ptr<Sink>&& sink) {
    StopUpdates();
    static const EncodableMap kEmpty;
    const EncodableMap* maybe = raw ? std::get_if<EncodableMap>(raw) : nullptr;
    const EncodableMap& args = maybe ? *maybe : kEmpty;
    updates_sink_ = std::move(sink);
    try {
      geo::Geolocator locator;
      locator.DesiredAccuracyInMeters(AccuracyMeters(StringArg(args, "accuracy")));
      const double distance = DoubleArg(args, "distanceFilter", 0);
      if (distance > 0) {
        locator.MovementThreshold(distance);
      } else {
        locator.ReportInterval(static_cast<uint32_t>(DoubleArg(args, "intervalMs", 5000)));
      }
      position_token_ = locator.PositionChanged([](geo::Geolocator const&, geo::PositionChangedEventArgs const& event) {
        EncodableMap map = ToMap(event.Position());
        platform::Post([map]() { Instance()->EmitUpdate(EncodableValue(map)); });
      });
      status_token_ = locator.StatusChanged([](geo::Geolocator const&, geo::StatusChangedEventArgs const& event) {
        if (event.Status() != geo::PositionStatus::Disabled) return;
        platform::Post([]() { Instance()->EmitUpdateError("serviceDisabled"); });
      });
      locator_ = locator;
    } catch (...) {
      updates_sink_.reset();
      return std::make_unique<flutter::StreamHandlerError<EncodableValue>>("unavailable", "Geolocation is not available", nullptr);
    }
    return StreamError();
  }

  void StopUpdates() {
    if (locator_) {
      try {
        locator_.PositionChanged(position_token_);
        locator_.StatusChanged(status_token_);
      } catch (...) {
      }
      locator_ = nullptr;
    }
    updates_sink_.reset();
  }

  void EmitUpdate(const EncodableValue& value) {
    if (updates_sink_) updates_sink_->Success(value);
  }

  void EmitUpdateError(const std::string& code) {
    if (updates_sink_) updates_sink_->Error(code);
  }

  StreamError StartHeading(std::unique_ptr<Sink>&& sink) {
    StopHeading();
    try {
      sensors::Compass compass = sensors::Compass::GetDefault();
      if (!compass) return std::make_unique<flutter::StreamHandlerError<EncodableValue>>("unsupported", "No compass on this device", nullptr);
      heading_sink_ = std::move(sink);
      compass.ReportInterval((std::max)(compass.MinimumReportInterval(), 50u));
      heading_token_ = compass.ReadingChanged([](sensors::Compass const&, sensors::CompassReadingChangedEventArgs const& event) {
        const sensors::CompassReading reading = event.Reading();
        EncodableMap map{
            {EncodableValue("magnetic"), EncodableValue(reading.HeadingMagneticNorth())},
            {EncodableValue("time"), EncodableValue(UnixMillis(reading.Timestamp()))},
        };
        PutOptional(map, "true", reading.HeadingTrueNorth());
        platform::Post([map]() {
          if (Instance()->heading_sink_) Instance()->heading_sink_->Success(EncodableValue(map));
        });
      });
      compass_ = compass;
    } catch (...) {
      heading_sink_.reset();
      return std::make_unique<flutter::StreamHandlerError<EncodableValue>>("unsupported", "No compass on this device", nullptr);
    }
    return StreamError();
  }

  void StopHeading() {
    if (compass_) {
      try {
        compass_.ReadingChanged(heading_token_);
      } catch (...) {
      }
      compass_ = nullptr;
    }
    heading_sink_.reset();
  }

  bool AddGeofence(const EncodableMap& args) {
    try {
      const std::wstring id = Widen(StringArg(args, "id"));
      if (id.empty()) return false;
      RemoveGeofence(Narrow(id));
      geo::BasicGeoposition center{DoubleArg(args, "latitude", 0), DoubleArg(args, "longitude", 0), 0};
      fencing::MonitoredGeofenceStates states = fencing::MonitoredGeofenceStates::None;
      if (BoolArg(args, "onEnter", true)) states = states | fencing::MonitoredGeofenceStates::Entered;
      if (BoolArg(args, "onExit", true)) states = states | fencing::MonitoredGeofenceStates::Exited;
      fencing::Geofence fence(winrt::hstring(id), geo::Geocircle(center, DoubleArg(args, "radius", 100)), states, false);
      fencing::GeofenceMonitor::Current().Geofences().Append(fence);
      return true;
    } catch (...) {
      return false;
    }
  }

  void RemoveGeofence(const std::string& id) {
    try {
      auto fences = fencing::GeofenceMonitor::Current().Geofences();
      const winrt::hstring target(Widen(id));
      for (uint32_t i = 0; i < fences.Size(); i++) {
        if (fences.GetAt(i).Id() == target) {
          fences.RemoveAt(i);
          return;
        }
      }
    } catch (...) {
    }
  }

  EncodableList Geofences() {
    EncodableList out;
    try {
      for (const fencing::Geofence& fence : fencing::GeofenceMonitor::Current().Geofences()) {
        EncodableMap map{{EncodableValue("id"), EncodableValue(Narrow(std::wstring(fence.Id())))}};
        if (const geo::Geocircle circle = fence.Geoshape().try_as<geo::Geocircle>()) {
          map[EncodableValue("latitude")] = EncodableValue(circle.Center().Latitude);
          map[EncodableValue("longitude")] = EncodableValue(circle.Center().Longitude);
          map[EncodableValue("radius")] = EncodableValue(circle.Radius());
        }
        out.push_back(EncodableValue(map));
      }
    } catch (...) {
    }
    return out;
  }

  void WatchGeofences() {
    try {
      fencing::GeofenceMonitor::Current().GeofenceStateChanged([](fencing::GeofenceMonitor const& monitor, winrt::Windows::Foundation::IInspectable const&) {
        for (const fencing::GeofenceStateChangeReport& report : monitor.ReadReports()) {
          const fencing::GeofenceState state = report.NewState();
          if (state != fencing::GeofenceState::Entered && state != fencing::GeofenceState::Exited) continue;
          EncodableMap event{
              {EncodableValue("id"), EncodableValue(Narrow(std::wstring(report.Geofence().Id())))},
              {EncodableValue("transition"), EncodableValue(state == fencing::GeofenceState::Entered ? "enter" : "exit")},
              {EncodableValue("time"), EncodableValue(NowMillis())},
          };
          platform::Post([event]() { Instance()->EmitGeofence(EncodableValue(event)); });
        }
      });
    } catch (...) {
      // No location capability / geofencing unavailable: addGeofence reports false.
    }
  }

  void EmitGeofence(const EncodableValue& event) {
    if (geofence_sink_) {
      geofence_sink_->Success(event);
    } else {
      queued_.push_back(event);
    }
  }

 public:
  static Location*& Instance() {
    static Location* instance = nullptr;
    return instance;
  }

 private:
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;
  std::unique_ptr<flutter::EventChannel<EncodableValue>> updates_;
  std::unique_ptr<flutter::EventChannel<EncodableValue>> heading_;
  std::unique_ptr<flutter::EventChannel<EncodableValue>> geofence_;
  std::unique_ptr<flutter::EventChannel<EncodableValue>> visits_;
  std::unique_ptr<Sink> updates_sink_;
  std::unique_ptr<Sink> heading_sink_;
  std::unique_ptr<Sink> geofence_sink_;
  EncodableList queued_;
  geo::Geolocator locator_{nullptr};
  sensors::Compass compass_{nullptr};
  winrt::event_token position_token_{};
  winrt::event_token status_token_{};
  winrt::event_token heading_token_{};
};

}  // namespace

void RegisterLocation(flutter::PluginRegistrarWindows* registrar) {
  if (Location::Instance() != nullptr) return;
  // Kept alive for the app's lifetime; background WinRT callbacks reach it through Instance().
  Location::Instance() = new Location(registrar);
}

}  // namespace u
