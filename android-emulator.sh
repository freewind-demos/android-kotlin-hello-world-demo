#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="android-kotlin-hello-world-demo"
MODULE_DIR="app"
APPLICATION_ID="demos.android.kotlin.hello.world.demo"
AVD_NAME="Pixel_7_API_35"
ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="$ANDROID_HOME/platform-tools/adb"
EMULATOR="$ANDROID_HOME/emulator/emulator"
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

find_emulator() {
  "$ADB" devices | awk '$1 ~ /^emulator-/ && $2 == "device" { print $1; exit }'
}

SERIAL="$(find_emulator)"

if [[ -z "$SERIAL" ]]; then
  CPU_BRAND="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)"
  HV_SUPPORT="$(sysctl -n kern.hv_support 2>/dev/null || echo 0)"
  EMULATOR_ARGS=(-avd "$AVD_NAME" -no-snapshot -netdelay none -netspeed full)

  if [[ "$HV_SUPPORT" != "1" || "$CPU_BRAND" == *AMD* ]]; then
    EMULATOR_ARGS+=(-no-accel -gpu swiftshader_indirect -no-audio)
  fi

  "$EMULATOR" "${EMULATOR_ARGS[@]}" >/tmp/android-emulator-"$PROJECT_NAME".log 2>&1 &

  for _ in $(seq 1 120); do
    SERIAL="$(find_emulator)"
    [[ -n "$SERIAL" ]] && break
    sleep 2
  done
fi

if [[ -z "$SERIAL" ]]; then
  echo "No emulator device found" >&2
  exit 1
fi

"$ADB" -s "$SERIAL" wait-for-device

BOOTED_OK=0
for _ in $(seq 1 120); do
  BOOTED="$("$ADB" -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
  if [[ "$BOOTED" == "1" ]]; then
    BOOTED_OK=1
    break
  fi
  sleep 2
done

if [[ "$BOOTED_OK" != "1" ]]; then
  echo "Emulator boot timeout: $SERIAL" >&2
  exit 1
fi

"$ADB" -s "$SERIAL" install -r "$APK_PATH"
"$ADB" -s "$SERIAL" shell monkey -p "$APPLICATION_ID" -c android.intent.category.LAUNCHER 1
echo "$SERIAL"
