#!/bin/bash
set -e

cd "$1"   # GitHub workspace

mkdir -p app-store-screenshots

RUNTIME=$(xcrun simctl list runtimes available | grep -oE 'com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]+' | head -1)
if [ -z "$RUNTIME" ]; then
  RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-18-4"
fi

echo "Using runtime: $RUNTIME"
echo "APP_PATH: $2"
APP_PATH="$2"

# Array of "size:device_type" pairs
DEVICES=(
  "6.7:com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max"
  "6.5:com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro"
  "5.5:com.apple.CoreSimulator.SimDeviceType.iPhone-8-Plus"
)

SCENARIOS=("1" "2" "3")

for ENTRY in "${DEVICES[@]}"; do
  SIZE="${ENTRY%%:*}"
  DEV_TYPE="${ENTRY##*:}"
  echo "📱 Capturing $SIZE\" ($DEV_TYPE)"

  DEVICE=$(xcrun simctl create "Today-$SIZE" "$DEV_TYPE" "$RUNTIME" 2>/dev/null || echo "")
  if [ -z "$DEVICE" ]; then
    for TRY_TYPE in "iPhone-15-Pro" "iPhone-14-Pro" "iPhone-11" "iPhone-XS-Max"; do
      DEVICE=$(xcrun simctl create "Today-$SIZE" "com.apple.CoreSimulator.SimDeviceType.$TRY_TYPE" "$RUNTIME" 2>/dev/null || echo "")
      if [ -n "$DEVICE" ]; then break; fi
    done
  fi
  if [ -z "$DEVICE" ]; then
    DEVICE=$(xcrun simctl list devices available | grep -E "iPhone" | head -1 | grep -oE '\([A-F0-9-]{36}\)' | tr -d '()')
  fi
  if [ -z "$DEVICE" ]; then
    echo "  ⚠️ No device available, skipping $SIZE\""
    continue
  fi
  echo "  Using device: $DEVICE"

  xcrun simctl boot "$DEVICE" 2>/dev/null || true
  for i in 1 2 3 4 5 6 7 8 9 10; do
    if xcrun simctl list devices | grep "$DEVICE" | grep -q "(Booted)"; then
      echo "  ✅ Booted in $((i*3))s"
      break
    fi
    sleep 3
  done

  for SCENARIO in "${SCENARIOS[@]}"; do
    xcrun simctl terminate "$DEVICE" com.today.app 2>/dev/null || true
    xcrun simctl uninstall "$DEVICE" com.today.app 2>/dev/null || true
    xcrun simctl install "$DEVICE" "$APP_PATH" 2>&1 | head -1

    case $SCENARIO in
      1) NAME="FullList" ;;
      2) NAME="Minimal" ;;
      3) NAME="Empty" ;;
    esac

    SIMCTL_CHILD_SEED_SAMPLE_DATA=$SCENARIO xcrun simctl launch "$DEVICE" com.today.app 2>&1 | head -1
    sleep 8

    OUT="app-store-screenshots/${SIZE}-${NAME}.png"
    xcrun simctl io "$DEVICE" screenshot --type=png --mask=ignored "$OUT" 2>/dev/null
    if [ -f "$OUT" ]; then
      echo "  ✅ $OUT captured"
    else
      echo "  ⚠️ Failed: $OUT"
    fi
  done

  xcrun simctl shutdown "$DEVICE" 2>/dev/null || true
  xcrun simctl delete "$DEVICE" 2>/dev/null || true
done

# Resize to exact App Store dimensions
for f in app-store-screenshots/*.png; do
  [ -f "$f" ] || continue
  case "$(basename "$f" .png)" in
    6.5-*) DIM="1242 2688" ;;
    6.7-*) DIM="1290 2796" ;;
    5.5-*) DIM="1242 2208" ;;
    *) continue ;;
  esac
  W=$(echo $DIM | cut -d' ' -f1)
  H=$(echo $DIM | cut -d' ' -f2)
  sips -z "$H" "$W" "$f" --out "${f%.png}-resized.png" 2>/dev/null
  if [ -f "${f%.png}-resized.png" ]; then
    rm "$f"
    echo "  Resized: $(basename "$f") → ${W}×${H}"
  fi
done

echo "---Final screenshots---"
ls -la app-store-screenshots/ 2>/dev/null || echo "No screenshots generated"
