#!/bin/bash
set -e

# Clone Flutter SDK if not exists
if [ ! -d "flutter_sdk" ]; then
  git clone https://github.com/flutter/flutter.git -b stable flutter_sdk
fi

# Add Flutter to PATH
export PATH="$PATH:$PWD/flutter_sdk/bin"

# Configure Flutter
flutter config --no-analytics
flutter doctor

# Get dependencies and build
flutter pub get
flutter build web --release

echo "Build completed successfully!"