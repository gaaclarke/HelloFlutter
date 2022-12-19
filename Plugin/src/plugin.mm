#import "flutter/embedder.h"
#import "unity/IUnityGraphics.h"
#import <Metal/Metal.h>
#include <cstdio>
#include <vector>

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API
UnityPluginLoad(IUnityInterfaces *unityInterfaces) {}

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginUnload() {
}

static id<MTLTexture> g_TextureHandle = nil;
static int g_TextureWidth = 0;
static int g_TextureHeight = 0;
static const double kPixelRatio = 2.0;

static FlutterEngine g_engine = nullptr;

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API
SetTextureFromUnity(void *textureHandle, int w, int h) {
  printf("set texture!\n");
  g_TextureHandle = (__bridge id<MTLTexture>)textureHandle;
  g_TextureWidth = w;
  g_TextureHeight = h;
}

static void SendWindowMetricsEvent(FlutterEngine engine) {
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = g_TextureWidth;
  event.height = g_TextureHeight;
  event.pixel_ratio = kPixelRatio;
  if (kSuccess != FlutterEngineSendWindowMetricsEvent(engine, &event)) {
    NSLog(@"unable to send window metrics");
  }
}

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API
SendPointerEvent(int32_t phase, double x, double y) {
  FlutterPointerEvent event = {};
  event.struct_size = sizeof(event);
  event.phase = static_cast<FlutterPointerPhase>(phase);
  event.x = x * g_TextureWidth;
  event.y = y * g_TextureHeight;
  event.timestamp =
      std::chrono::duration_cast<std::chrono::microseconds>(
          std::chrono::high_resolution_clock::now().time_since_epoch())
          .count();
  FlutterEngineSendPointerEvent(g_engine, &event, 1);
}

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API
StartFlutterEngine(const char *project_path, const char *icudtl_path) {
  uint64_t time = FlutterEngineGetCurrentTime();
  NSLog(@"StartFlutterEngine at %lld", time);

  if (g_engine == nullptr) {
    FlutterProjectArgs args = {
        .struct_size = sizeof(FlutterProjectArgs),
        .assets_path = project_path,
        .icu_data_path = icudtl_path,
    };
    FlutterRendererConfig config = {};
    config.type = kSoftware;
    config.software.struct_size = sizeof(config.software);
    config.software.surface_present_callback = [](void *user_data,
                                                  const void *allocation,
                                                  size_t row_bytes,
                                                  size_t height) {
      NSLog(@"Got software refresh %d %d", row_bytes, height);
      [g_TextureHandle
          replaceRegion:MTLRegionMake2D(0, 0, g_TextureWidth, g_TextureHeight)
            mipmapLevel:0
              withBytes:allocation
            bytesPerRow:row_bytes];
      return true;
    };
    FlutterEngineResult result = FlutterEngineRun(
        FLUTTER_ENGINE_VERSION, &config, &args, nullptr, &g_engine);
    if (result != kSuccess || g_engine == nullptr) {
      NSLog(@"Unable to start FlutterEngine");
      SendPointerEvent(kAdd, 0.0, 0.0);
    } else {
      NSLog(@"FlutterEngine started");
    }
  }
  if (g_engine) {
    SendWindowMetricsEvent(g_engine);
  }
}

static void UNITY_INTERFACE_API OnRenderEvent(int eventID) {}

extern "C" UnityRenderingEvent UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API
GetRenderEventFunc() {
  return OnRenderEvent;
}
