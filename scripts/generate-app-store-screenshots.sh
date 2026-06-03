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
  "6.7:com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max:1290:2796"
  "6.5:com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro:1242:2688"
  "5.5:com.apple.CoreSimulator.SimDeviceType.iPhone-8-Plus:1242:2208"
)

SCENARIOS=("1" "2" "3")

for ENTRY in "${DEVICES[@]}"; do
  IFS=':' read -r SIZE DEV_TYPE TARGET_W TARGET_H <<< "$ENTRY"
  echo "📱 Capturing $SIZE\" (target ${TARGET_W}×${TARGET_H})"

  DEVICE=$(xcrun simctl create "Today-$SIZE" "$DEV_TYPE" "$RUNTIME" 2>/dev/null || echo "")
  if [ -z "$DEVICE" ]; then
    for TRY_TYPE in "iPhone-15-Pro" "iPhone-14-Pro" "iPhone-11" "iPhone-XS-Max" "iPhone-13"; do
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
    sleep 6

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

# Resize to exact App Store dimensions (use target dims from device list)
for ENTRY in "${DEVICES[@]}"; do
  IFS=':' read -r SIZE _ TARGET_W TARGET_H <<< "$ENTRY"
  for f in app-store-screenshots/${SIZE}-*.png; do
    [ -f "$f" ] || continue
    OUT="${f%.png}-resized.png"
    sips -z "$TARGET_H" "$TARGET_W" "$f" --out "$OUT" 2>/dev/null
    if [ -f "$OUT" ]; then
      # Verify the resized file actually has the target dimensions
      ACTUAL_W=$(sips -g pixelWidth "$OUT" 2>/dev/null | tail -1 | awk -F': ' '{print $2}')
      ACTUAL_H=$(sips -g pixelHeight "$OUT" 2>/dev/null | tail -1 | awk -F': ' '{print $2}')
      if [ "$ACTUAL_W" = "$TARGET_W" ] && [ "$ACTUAL_H" = "$TARGET_H" ]; then
        rm "$f"
        echo "  Resized $(basename "$f") → ${TARGET_W}×${TARGET_H} ✅"
      else
        echo "  ⚠️ Resize failed for $(basename "$f"): got ${ACTUAL_W}×${ACTUAL_H}"
      fi
    fi
  done
done

echo "---Final App Store screenshots---"
ls -la app-store-screenshots/ 2>/dev/null || echo "No screenshots generated"
