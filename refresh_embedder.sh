FLUTTER_ENGINE_PATH="$HOME/dev/engine"

pushd .
cd ~/dev/engine/src
# gclient sync
autoninja -C out/host_debug_unopt_arm64/ FlutterEmbedder.framework
autoninja -C out/host_debug_unopt/ FlutterEmbedder.framework
popd

lipo -create \
  -arch x86_64 "$FLUTTER_ENGINE_PATH/src/out/host_debug_unopt/FlutterEmbedder.framework/Versions/A/FlutterEmbedder" \
  -arch arm64 "$FLUTTER_ENGINE_PATH/src/out/host_debug_unopt_arm64/FlutterEmbedder.framework/FlutterEmbedder" \
  -output "./UnityProject/Assets/FlutterUnity/libFlutterEmbedder.dylib"
install_name_tool -id libFlutterEmbedder.dylib ./UnityProject/Assets/FlutterUnity/libFlutterEmbedder.dylib
cp $FLUTTER_ENGINE_PATH/src/out/host_debug_unopt/icudtl.dat ./UnityProject/Assets/StreamingAssets/icudtl.dat
cp $FLUTTER_ENGINE_PATH/src/flutter/shell/platform/embedder/embedder.h ./Plugin/src/flutter/embedder.h
