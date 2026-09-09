#include "u_media.h"

#include <gst/app/gstappsink.h>
#include <gst/gst.h>
#include <gst/video/video.h>

#include <map>
#include <memory>
#include <string>

namespace {

struct UMediaPlayer;

std::map<int, UMediaPlayer*>* g_players = nullptr;
FlPluginRegistrar* g_registrar = nullptr;
FlMethodChannel* g_channel = nullptr;
FlMethodChannel* g_session_channel = nullptr;
int g_next_id = 1;

// === Texture ===

struct _UMediaTexture {
  FlPixelBufferTexture parent_instance;
  GMutex mutex;
  guint8* buffer;
  gsize buffer_size;
  guint32 width;
  guint32 height;
};

G_DECLARE_FINAL_TYPE(UMediaTexture, u_media_texture, U, MEDIA_TEXTURE, FlPixelBufferTexture)
G_DEFINE_TYPE(UMediaTexture, u_media_texture, fl_pixel_buffer_texture_get_type())

static gboolean u_media_texture_copy_pixels(FlPixelBufferTexture* texture,
                                            const uint8_t** out_buffer,
                                            uint32_t* width,
                                            uint32_t* height,
                                            GError** error) {
  UMediaTexture* self = U_MEDIA_TEXTURE(texture);
  g_mutex_lock(&self->mutex);
  if (self->buffer == nullptr || self->width == 0 || self->height == 0) {
    g_mutex_unlock(&self->mutex);
    g_set_error(error, g_quark_from_static_string("u-media"), 0, "No frame available");
    return FALSE;
  }
  *out_buffer = self->buffer;
  *width = self->width;
  *height = self->height;
  g_mutex_unlock(&self->mutex);
  return TRUE;
}

static void u_media_texture_dispose(GObject* object) {
  UMediaTexture* self = U_MEDIA_TEXTURE(object);
  g_mutex_lock(&self->mutex);
  g_clear_pointer(&self->buffer, g_free);
  self->buffer_size = 0;
  g_mutex_unlock(&self->mutex);
  g_mutex_clear(&self->mutex);
  G_OBJECT_CLASS(u_media_texture_parent_class)->dispose(object);
}

static void u_media_texture_class_init(UMediaTextureClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = u_media_texture_dispose;
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = u_media_texture_copy_pixels;
}

static void u_media_texture_init(UMediaTexture* self) {
  g_mutex_init(&self->mutex);
  self->buffer = nullptr;
  self->buffer_size = 0;
  self->width = 0;
  self->height = 0;
}

static UMediaTexture* u_media_texture_new() {
  return U_MEDIA_TEXTURE(g_object_new(u_media_texture_get_type(), nullptr));
}

static void u_media_texture_write(UMediaTexture* self, const guint8* data, gsize size, guint32 width, guint32 height) {
  g_mutex_lock(&self->mutex);
  if (self->buffer_size != size) {
    g_clear_pointer(&self->buffer, g_free);
    self->buffer = static_cast<guint8*>(g_malloc(size));
    self->buffer_size = size;
  }
  memcpy(self->buffer, data, size);
  self->width = width;
  self->height = height;
  g_mutex_unlock(&self->mutex);
}

// === Player ===

struct UMediaPlayer {
  int id = 0;
  bool is_video = false;
  int position_interval_ms = 250;
  bool announced = false;
  bool loop = false;

  GstElement* pipeline = nullptr;
  GstElement* appsink = nullptr;
  guint bus_watch_id = 0;
  guint position_timer_id = 0;

  UMediaTexture* texture = nullptr;
  int64_t texture_id = -1;

  FlEventChannel* events = nullptr;
  bool listening = false;
};

FlValue* new_map() { return fl_value_new_map(); }

void map_set_string(FlValue* map, const char* key, const char* value) {
  fl_value_set_string_take(map, key, fl_value_new_string(value));
}

void map_set_int(FlValue* map, const char* key, int64_t value) {
  fl_value_set_string_take(map, key, fl_value_new_int(value));
}

void map_set_bool(FlValue* map, const char* key, bool value) {
  fl_value_set_string_take(map, key, fl_value_new_bool(value));
}

void emit(UMediaPlayer* player, FlValue* payload) {
  if (player->events != nullptr && player->listening) {
    fl_event_channel_send(player->events, payload, nullptr, nullptr);
  }
  fl_value_unref(payload);
}

void emit_state(UMediaPlayer* player, const char* state) {
  FlValue* payload = new_map();
  map_set_string(payload, "event", "state");
  map_set_string(payload, "state", state);
  emit(player, payload);
}

void emit_error(UMediaPlayer* player, const char* code, const char* message) {
  FlValue* payload = new_map();
  map_set_string(payload, "event", "error");
  map_set_string(payload, "code", code);
  map_set_string(payload, "message", message);
  emit(player, payload);
}

int64_t position_ms(UMediaPlayer* player) {
  gint64 position = 0;
  if (player->pipeline != nullptr && gst_element_query_position(player->pipeline, GST_FORMAT_TIME, &position)) {
    return position / GST_MSECOND;
  }
  return 0;
}

int64_t duration_ms(UMediaPlayer* player) {
  gint64 duration = 0;
  if (player->pipeline != nullptr && gst_element_query_duration(player->pipeline, GST_FORMAT_TIME, &duration)) {
    return duration > 0 ? duration / GST_MSECOND : 0;
  }
  return 0;
}

gboolean on_position_timer(gpointer data) {
  auto* player = static_cast<UMediaPlayer*>(data);
  FlValue* payload = new_map();
  map_set_string(payload, "event", "position");
  map_set_int(payload, "positionMs", position_ms(player));
  map_set_int(payload, "bufferedMs", position_ms(player));
  emit(player, payload);
  return G_SOURCE_CONTINUE;
}

void start_timer(UMediaPlayer* player) {
  if (player->position_timer_id != 0) return;
  player->position_timer_id = g_timeout_add(player->position_interval_ms, on_position_timer, player);
}

void stop_timer(UMediaPlayer* player) {
  if (player->position_timer_id == 0) return;
  g_source_remove(player->position_timer_id);
  player->position_timer_id = 0;
}

void announce(UMediaPlayer* player) {
  if (player->announced) return;
  player->announced = true;

  gint width = 0;
  gint height = 0;
  if (player->appsink != nullptr) {
    GstSample* sample = gst_app_sink_try_pull_preroll(GST_APP_SINK(player->appsink), 0);
    if (sample != nullptr) {
      GstCaps* caps = gst_sample_get_caps(sample);
      GstVideoInfo info;
      if (caps != nullptr && gst_video_info_from_caps(&info, caps)) {
        width = GST_VIDEO_INFO_WIDTH(&info);
        height = GST_VIDEO_INFO_HEIGHT(&info);
      }
      gst_sample_unref(sample);
    }
  }

  const int64_t duration = duration_ms(player);
  FlValue* payload = new_map();
  map_set_string(payload, "event", "initialized");
  if (player->texture_id >= 0) {
    map_set_int(payload, "textureId", player->texture_id);
  } else {
    fl_value_set_string_take(payload, "textureId", fl_value_new_null());
  }
  map_set_int(payload, "durationMs", duration);
  map_set_int(payload, "width", width);
  map_set_int(payload, "height", height);
  map_set_int(payload, "rotation", 0);
  map_set_bool(payload, "isLive", duration <= 0);
  fl_value_set_string_take(payload, "tracks", fl_value_new_list());
  emit(player, payload);
}

GstFlowReturn on_new_sample(GstAppSink* sink, gpointer data) {
  auto* player = static_cast<UMediaPlayer*>(data);
  GstSample* sample = gst_app_sink_pull_sample(sink);
  if (sample == nullptr) return GST_FLOW_OK;

  GstCaps* caps = gst_sample_get_caps(sample);
  GstBuffer* buffer = gst_sample_get_buffer(sample);
  GstVideoInfo info;
  if (caps != nullptr && buffer != nullptr && gst_video_info_from_caps(&info, caps)) {
    GstMapInfo mapped;
    if (gst_buffer_map(buffer, &mapped, GST_MAP_READ)) {
      u_media_texture_write(player->texture, mapped.data, mapped.size, GST_VIDEO_INFO_WIDTH(&info),
                            GST_VIDEO_INFO_HEIGHT(&info));
      gst_buffer_unmap(buffer, &mapped);
      if (g_registrar != nullptr && player->texture_id >= 0) {
        FlTextureRegistrar* registrar = fl_plugin_registrar_get_texture_registrar(g_registrar);
        fl_texture_registrar_mark_texture_frame_available(registrar, FL_TEXTURE(player->texture));
      }
    }
  }
  gst_sample_unref(sample);
  return GST_FLOW_OK;
}

gboolean on_bus_message(GstBus*, GstMessage* message, gpointer data) {
  auto* player = static_cast<UMediaPlayer*>(data);
  switch (GST_MESSAGE_TYPE(message)) {
    case GST_MESSAGE_ASYNC_DONE:
      announce(player);
      break;
    case GST_MESSAGE_EOS:
      stop_timer(player);
      {
        FlValue* payload = new_map();
        map_set_string(payload, "event", "completed");
        emit(player, payload);
      }
      break;
    case GST_MESSAGE_BUFFERING: {
      gint percent = 0;
      gst_message_parse_buffering(message, &percent);
      emit_state(player, percent < 100 ? "buffering" : "playing");
      break;
    }
    case GST_MESSAGE_STATE_CHANGED: {
      if (GST_MESSAGE_SRC(message) != GST_OBJECT(player->pipeline)) break;
      GstState old_state;
      GstState new_state;
      gst_message_parse_state_changed(message, &old_state, &new_state, nullptr);
      if (new_state == GST_STATE_PLAYING) {
        announce(player);
        emit_state(player, "playing");
        start_timer(player);
      } else if (new_state == GST_STATE_PAUSED && old_state == GST_STATE_PLAYING) {
        emit_state(player, "paused");
        stop_timer(player);
      }
      break;
    }
    case GST_MESSAGE_ERROR: {
      GError* error = nullptr;
      gchar* debug = nullptr;
      gst_message_parse_error(message, &error, &debug);
      const char* code = "unknown";
      if (error != nullptr) {
        if (error->domain == GST_RESOURCE_ERROR) {
          code = error->code == GST_RESOURCE_ERROR_NOT_FOUND ? "notFound" : "network";
        } else if (error->domain == GST_STREAM_ERROR) {
          code = error->code == GST_STREAM_ERROR_CODEC_NOT_FOUND ? "unsupportedFormat" : "decoder";
        }
      }
      stop_timer(player);
      emit_error(player, code, error != nullptr && error->message != nullptr ? error->message : "Playback failed");
      if (error != nullptr) g_error_free(error);
      g_free(debug);
      break;
    }
    default:
      break;
  }
  return TRUE;
}

FlMethodErrorResponse* on_listen(FlEventChannel*, FlValue*, gpointer data) {
  static_cast<UMediaPlayer*>(data)->listening = true;
  return nullptr;
}

FlMethodErrorResponse* on_cancel(FlEventChannel*, FlValue*, gpointer data) {
  static_cast<UMediaPlayer*>(data)->listening = false;
  return nullptr;
}

UMediaPlayer* create_player(int id, bool is_video, FlValue* config) {
  auto* player = new UMediaPlayer();
  player->id = id;
  player->is_video = is_video;

  if (config != nullptr && fl_value_get_type(config) == FL_VALUE_TYPE_MAP) {
    FlValue* interval = fl_value_lookup_string(config, "positionUpdateMs");
    if (interval != nullptr && fl_value_get_type(interval) == FL_VALUE_TYPE_INT) {
      player->position_interval_ms = static_cast<int>(fl_value_get_int(interval));
    }
  }

  const std::string name = "u/media/events/" + std::to_string(id);
  player->events = fl_event_channel_new(fl_plugin_registrar_get_messenger(g_registrar), name.c_str(),
                                        FL_METHOD_CODEC(fl_standard_method_codec_new()));
  fl_event_channel_set_stream_handlers(player->events, on_listen, on_cancel, player, nullptr);

  player->pipeline = gst_element_factory_make("playbin", nullptr);
  if (player->pipeline == nullptr) return player;

  if (is_video) {
    player->texture = u_media_texture_new();
    FlTextureRegistrar* registrar = fl_plugin_registrar_get_texture_registrar(g_registrar);
    fl_texture_registrar_register_texture(registrar, FL_TEXTURE(player->texture));
    player->texture_id = static_cast<int64_t>(fl_texture_get_id(FL_TEXTURE(player->texture)));

    GstElement* bin = gst_parse_bin_from_description(
        "videoconvert ! video/x-raw,format=RGBA ! appsink name=usink sync=true max-buffers=2 drop=true", TRUE, nullptr);
    if (bin != nullptr) {
      player->appsink = gst_bin_get_by_name(GST_BIN(bin), "usink");
      if (player->appsink != nullptr) {
        gst_app_sink_set_emit_signals(GST_APP_SINK(player->appsink), FALSE);
        GstAppSinkCallbacks callbacks = {};
        callbacks.new_sample = on_new_sample;
        gst_app_sink_set_callbacks(GST_APP_SINK(player->appsink), &callbacks, player, nullptr);
      }
      g_object_set(player->pipeline, "video-sink", bin, nullptr);
    }
  } else {
    g_object_set(player->pipeline, "flags", 0x00000002 | 0x00000010, nullptr);
  }

  GstBus* bus = gst_element_get_bus(player->pipeline);
  player->bus_watch_id = gst_bus_add_watch(bus, on_bus_message, player);
  gst_object_unref(bus);
  return player;
}

void destroy_player(UMediaPlayer* player) {
  stop_timer(player);
  if (player->bus_watch_id != 0) {
    g_source_remove(player->bus_watch_id);
    player->bus_watch_id = 0;
  }
  if (player->pipeline != nullptr) {
    gst_element_set_state(player->pipeline, GST_STATE_NULL);
    gst_object_unref(player->pipeline);
    player->pipeline = nullptr;
  }
  if (player->appsink != nullptr) {
    gst_object_unref(player->appsink);
    player->appsink = nullptr;
  }
  if (player->texture != nullptr && g_registrar != nullptr) {
    FlTextureRegistrar* registrar = fl_plugin_registrar_get_texture_registrar(g_registrar);
    fl_texture_registrar_unregister_texture(registrar, FL_TEXTURE(player->texture));
    g_object_unref(player->texture);
    player->texture = nullptr;
  }
  if (player->events != nullptr) {
    g_object_unref(player->events);
    player->events = nullptr;
  }
  delete player;
}

std::string value_string(FlValue* map, const char* key) {
  if (map == nullptr || fl_value_get_type(map) != FL_VALUE_TYPE_MAP) return std::string();
  FlValue* value = fl_value_lookup_string(map, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_STRING) return std::string();
  return std::string(fl_value_get_string(value));
}

int64_t value_int(FlValue* map, const char* key, int64_t fallback) {
  if (map == nullptr || fl_value_get_type(map) != FL_VALUE_TYPE_MAP) return fallback;
  FlValue* value = fl_value_lookup_string(map, key);
  if (value == nullptr) return fallback;
  if (fl_value_get_type(value) == FL_VALUE_TYPE_INT) return fl_value_get_int(value);
  if (fl_value_get_type(value) == FL_VALUE_TYPE_FLOAT) return static_cast<int64_t>(fl_value_get_float(value));
  return fallback;
}

double value_double(FlValue* map, const char* key, double fallback) {
  if (map == nullptr || fl_value_get_type(map) != FL_VALUE_TYPE_MAP) return fallback;
  FlValue* value = fl_value_lookup_string(map, key);
  if (value == nullptr) return fallback;
  if (fl_value_get_type(value) == FL_VALUE_TYPE_FLOAT) return fl_value_get_float(value);
  if (fl_value_get_type(value) == FL_VALUE_TYPE_INT) return static_cast<double>(fl_value_get_int(value));
  return fallback;
}

bool value_bool(FlValue* map, const char* key, bool fallback) {
  if (map == nullptr || fl_value_get_type(map) != FL_VALUE_TYPE_MAP) return fallback;
  FlValue* value = fl_value_lookup_string(map, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_BOOL) return fallback;
  return fl_value_get_bool(value);
}

void seek_to(UMediaPlayer* player, int64_t ms) {
  if (player->pipeline == nullptr) return;
  gst_element_seek_simple(player->pipeline, GST_FORMAT_TIME,
                          static_cast<GstSeekFlags>(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_ACCURATE),
                          ms * GST_MSECOND);
}

void method_call_cb(FlMethodChannel*, FlMethodCall* method_call, gpointer) {
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);
  g_autoptr(FlMethodResponse) response = nullptr;

  if (g_strcmp0(method, "isAvailable") == 0) {
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  if (g_strcmp0(method, "create") == 0) {
    const int id = g_next_id++;
    const std::string kind = value_string(args, "kind");
    FlValue* config = args != nullptr ? fl_value_lookup_string(args, "config") : nullptr;
    (*g_players)[id] = create_player(id, kind != "audio", config);
    g_autoptr(FlValue) result = fl_value_new_int(id);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  const int id = static_cast<int>(value_int(args, "id", -1));
  auto found = g_players->find(id);
  if (found == g_players->end()) {
    response = FL_METHOD_RESPONSE(fl_method_error_response_new("ERROR_NOT_FOUND", "Player not found", nullptr));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }
  UMediaPlayer* player = found->second;

  if (g_strcmp0(method, "open") == 0) {
    FlValue* source = fl_value_lookup_string(args, "source");
    const std::string kind = value_string(source, "kind");
    std::string uri;
    if (kind == "network") {
      uri = value_string(source, "url");
    } else if (kind == "file") {
      g_autofree gchar* file_uri = g_filename_to_uri(value_string(source, "path").c_str(), nullptr, nullptr);
      if (file_uri != nullptr) uri = file_uri;
    } else if (kind == "content") {
      uri = value_string(source, "uri");
    } else if (kind == "asset") {
      g_autofree gchar* path = g_build_filename("data", "flutter_assets", value_string(source, "asset").c_str(), nullptr);
      g_autofree gchar* file_uri = g_filename_to_uri(path, nullptr, nullptr);
      if (file_uri != nullptr) uri = file_uri;
    }

    if (uri.empty() || player->pipeline == nullptr) {
      emit_error(player, "notFound", "Unsupported source");
    } else {
      player->announced = false;
      gst_element_set_state(player->pipeline, GST_STATE_NULL);
      g_object_set(player->pipeline, "uri", uri.c_str(), nullptr);
      gst_element_set_state(player->pipeline, GST_STATE_PAUSED);
      emit_state(player, "loading");
      const int64_t resume = value_int(args, "resumeMs", 0);
      if (resume > 0) seek_to(player, resume);
      if (value_bool(args, "autoPlay", false)) gst_element_set_state(player->pipeline, GST_STATE_PLAYING);
    }
  } else if (g_strcmp0(method, "play") == 0) {
    if (player->pipeline != nullptr) gst_element_set_state(player->pipeline, GST_STATE_PLAYING);
    start_timer(player);
  } else if (g_strcmp0(method, "pause") == 0) {
    if (player->pipeline != nullptr) gst_element_set_state(player->pipeline, GST_STATE_PAUSED);
    stop_timer(player);
  } else if (g_strcmp0(method, "stop") == 0) {
    if (player->pipeline != nullptr) gst_element_set_state(player->pipeline, GST_STATE_NULL);
    stop_timer(player);
    emit_state(player, "idle");
  } else if (g_strcmp0(method, "seek") == 0) {
    seek_to(player, value_int(args, "positionMs", 0));
  } else if (g_strcmp0(method, "stepFrame") == 0) {
    seek_to(player, position_ms(player) + 33 * value_int(args, "frames", 1));
  } else if (g_strcmp0(method, "setSpeed") == 0) {
    const double speed = value_double(args, "speed", 1.0);
    if (player->pipeline != nullptr) {
      gst_element_seek(player->pipeline, speed, GST_FORMAT_TIME, GST_SEEK_FLAG_FLUSH, GST_SEEK_TYPE_SET,
                       position_ms(player) * GST_MSECOND, GST_SEEK_TYPE_END, 0);
    }
  } else if (g_strcmp0(method, "setVolume") == 0) {
    if (player->pipeline != nullptr) g_object_set(player->pipeline, "volume", value_double(args, "volume", 1.0), nullptr);
  } else if (g_strcmp0(method, "setMuted") == 0) {
    if (player->pipeline != nullptr) g_object_set(player->pipeline, "mute", value_bool(args, "muted", false), nullptr);
  } else if (g_strcmp0(method, "setRepeat") == 0) {
    player->loop = value_string(args, "mode") == "one";
  } else if (g_strcmp0(method, "selectTrack") == 0) {
    const std::string track_id = value_string(args, "trackId");
    const size_t colon = track_id.find(':');
    if (colon != std::string::npos && player->pipeline != nullptr) {
      const std::string kind = track_id.substr(0, colon);
      const int index = atoi(track_id.substr(colon + 1).c_str());
      if (kind == "audio") g_object_set(player->pipeline, "current-audio", index, nullptr);
      if (kind == "subtitle") g_object_set(player->pipeline, "current-text", index, nullptr);
    }
  } else if (g_strcmp0(method, "dispose") == 0) {
    destroy_player(player);
    g_players->erase(found);
  } else if (g_strcmp0(method, "enterPip") == 0) {
    g_autoptr(FlValue) result = fl_value_new_bool(FALSE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  fl_method_call_respond(method_call, response, nullptr);
}

void session_call_cb(FlMethodChannel*, FlMethodCall* method_call, gpointer) {
  g_autoptr(FlMethodResponse) response = nullptr;
  if (g_strcmp0(fl_method_call_get_name(method_call), "requestFocus") == 0) {
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  }
  fl_method_call_respond(method_call, response, nullptr);
}

}  // namespace

void u_media_register(FlPluginRegistrar* registrar) {
  if (!gst_is_initialized()) gst_init(nullptr, nullptr);
  g_registrar = registrar;
  if (g_players == nullptr) g_players = new std::map<int, UMediaPlayer*>();

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_channel = fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar), "u/media", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(g_channel, method_call_cb, nullptr, nullptr);

  g_autoptr(FlStandardMethodCodec) session_codec = fl_standard_method_codec_new();
  g_session_channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar), "u/media_session", FL_METHOD_CODEC(session_codec));
  fl_method_channel_set_method_call_handler(g_session_channel, session_call_cb, nullptr, nullptr);
}

void u_media_unregister(void) {
  if (g_players != nullptr) {
    for (auto& entry : *g_players) destroy_player(entry.second);
    g_players->clear();
  }
  g_clear_object(&g_channel);
  g_clear_object(&g_session_channel);
  g_registrar = nullptr;
}
