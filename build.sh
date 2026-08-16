#!/usr/bin/env bash
set -euo pipefail

if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
fi

export PATH="$HOME/flutter/bin:$PATH"
flutter config --enable-web
flutter pub get
flutter build web --release --pwa-strategy=none --no-web-resources-cdn
