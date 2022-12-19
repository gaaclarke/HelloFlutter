#!/bin/bash

set -e

xcodebuild
rsync -av --delete build/Release/FlutterUnity.bundle/ ../UnityProject/Assets/FlutterUnity/Editor/FlutterUnity.bundle/
