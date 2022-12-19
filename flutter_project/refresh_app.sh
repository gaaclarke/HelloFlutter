#!/bin/bash

set -e

flutter build bundle
rsync -av --delete build/flutter_assets/ ../UnityProject/Assets/StreamingAssets/flutter_assets
