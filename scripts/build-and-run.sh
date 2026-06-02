#!/bin/bash
# ============================================================
# Today iOS App — 全自动构建 & 模拟器运行脚本
# 在 GitHub Actions macOS runner 上执行
# ============================================================
set -e

echo "=============================="
echo "📱 Today iOS App Builder"
echo "=============================="

# 1. 检查环境
echo ""
echo "=== Step 1: Check Environment ==="
xcodebuild -version
swift --version

# 2. 列出可用模拟器
echo ""
echo "=== Step 2: Available Simulators ==="
xcrun simctl list devices available

# 3. 构建 App
echo ""
echo "=== Step 3: Build Today App ==="
xcodebuild build \
  -project "Today.xcodeproj" \
  -scheme "Today" \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGN_ENTITLEMENTS="" 2>&1 | tee build.log

BUILD_STATUS=${PIPESTATUS[0]}
if [ $BUILD_STATUS -ne 0 ]; then
  echo "❌ Build failed! Check build.log"
  exit 1
fi
echo "✅ Build succeeded!"

# 4. 找到 .app 包
APP_PATH=$(find / -name "Today.app" -path "*/Debug-iphonesimulator/*" -type d 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
  APP_PATH=$(find . -name "Today.app" -path "*/Debug-iphonesimulator/*" -type d | head -1)
fi
echo "📦 App bundle at: $APP_PATH"

# 5. 启动模拟器并安装 App
echo ""
echo "=== Step 4: Boot Simulator & Install ==="

# 创建或复用模拟器
DEVICE_NAME="Today-Test-Device"
EXISTING_UDID=$(xcrun simctl list devices | grep "$DEVICE_NAME" | grep -v "unavailable" | awk -F'[()]' '{print $2}' | head -1)

if [ -z "$EXISTING_UDID" ]; then
  echo "Creating new simulator..."
  DEVICE_ID=$(xcrun simctl create "$DEVICE_NAME" com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro)
  echo "Created device with UDID: $DEVICE_ID"
else
  DEVICE_ID="$EXISTING_UDID"
  echo "Using existing device: $DEVICE_ID"
fi

# Boot
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || echo "Already booted"
xcrun simctl install "$DEVICE_ID" "$APP_PATH"
echo "✅ App installed on simulator"

# 6. 启动 App
echo ""
echo "=== Step 5: Launch App ==="
xcrun simctl launch "$DEVICE_ID" com.today.app
echo "✅ App launched!"

# 7. 截图
echo ""
echo "=== Step 6: Screenshot ==="
sleep 3
xcrun simctl screenshot booted Today_Screenshot.png
echo "✅ Screenshot saved: Today_Screenshot.png"

echo ""
echo "=============================="
echo "🎉 Today App 构建并运行成功!"
echo "=============================="
