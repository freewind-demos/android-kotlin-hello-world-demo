#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="android-kotlin-hello-world-demo"
MODULE_DIR="app"
APPLICATION_ID="demos.android.kotlin.hello.world.demo"
ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="$ANDROID_HOME/platform-tools/adb"
APK_ROOT="$PWD/$MODULE_DIR/build/outputs/apk"

shopt -s globstar nullglob
apks=("$APK_ROOT"/**/*.apk)
shopt -u globstar nullglob

if [[ "${#apks[@]}" -eq 0 ]]; then
  echo "APK not found under: $APK_ROOT" >&2
  echo "Run ./android-build.sh first" >&2
  exit 1
fi

if [[ "${#apks[@]}" -ne 1 ]]; then
  echo "Expected exactly one APK under $APK_ROOT, got ${#apks[@]}:" >&2
  printf '%s\n' "${apks[@]}" >&2
  exit 1
fi

APK_PATH="${apks[0]}"

DEVICES=()
while IFS= read -r device; do
  DEVICES+=("$device")
done < <("$ADB" devices | awk '$1 !~ /^emulator-/ && $2 == "device" { print $1 }')

if [[ "${#DEVICES[@]}" -ne 1 ]]; then
  echo "Expected exactly one phone device, got ${#DEVICES[@]}" >&2
  "$ADB" devices >&2
  exit 1
fi

SERIAL="${DEVICES[0]}"
"$ADB" -s "$SERIAL" install -r "$APK_PATH"
"$ADB" -s "$SERIAL" shell monkey -p "$APPLICATION_ID" -c android.intent.category.LAUNCHER 1
echo "$SERIAL"
