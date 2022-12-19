#!/bin/bash

set -e

./refresh_embedder.sh
pushd .
cd Plugin
./refresh_plugin.sh
popd
pushd .
cd flutter_project
./refresh_app.sh
popd
