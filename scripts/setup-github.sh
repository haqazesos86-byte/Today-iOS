#!/bin/bash
# ============================================================
# Git 初始化 & 推送到 GitHub — 一键脚本
# 用法: bash scripts/setup-github.sh <your-github-username>
# ============================================================
set -e

if [ -z "$1" ]; then
  echo "⚠️  请提供 GitHub 用户名: bash scripts/setup-github.sh <你的用户名>"
  exit 1
fi

GITHUB_USER=$1
REPO_NAME="Today-iOS"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=============================="
echo "🚀 初始化 Git 并推送到 GitHub"
echo "仓库: $GITHUB_USER/$REPO_NAME"
echo "目录: $REPO_DIR"
echo "=============================="

cd "$REPO_DIR"

# 1. 初始化 Git
if [ ! -d ".git" ]; then
  echo ""
  echo "=== Step 1: git init ==="
  git init
  git checkout -b main
else
  echo "✓ Git already initialized"
fi

# 2. 创建 .gitignore
echo ""
echo "=== Step 2: Create .gitignore ==="
cat > .gitignore << 'GITIGNORE'
# Xcode
*.xcworkspace
xcuserdata/
DerivedData/
*.hmap
*.ipa
*.xcuserstate

# Swift Package Manager
.build/
Package.resolved

# macOS
.DS_Store
*.swp
*.lock

# Build artifacts
/build/
*.log

# Screenshots
*_Screenshot.png
GITIGNORE
echo "✅ .gitignore created"

# 3. 添加到 Git
echo ""
echo "=== Step 3: git add ==="
git add -A
git status

# 4. Commit
echo ""
echo "=== Step 4: git commit ==="
git commit -m "🎉 Today iOS App — 极简每日待办清单

- iOS 17+ SwiftUI SwiftData
- 零层级、零 tab、零圆角设计
- 左右滑动切换日期 + 弹簧动画
- Widget 小组件 + Apple Watch 扩展
- GitHub Actions 自动构建 + 模拟器截图" 2>/dev/null || echo "✓ No changes to commit"

# 5. 在 GitHub 创建仓库
echo ""
echo "=== Step 5: Create GitHub repo ==="
if command -v gh &> /dev/null; then
  gh repo create "$REPO_NAME" --public --source=. --remote=origin --push 2>&1 || {
    echo "⚠️  gh repo create failed, trying manual push..."
    git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git" 2>/dev/null || true
    git push -u origin main
  }
else
  echo "⚠️  'gh' CLI not found. Please create repo manually:"
  echo "   1. Go to https://github.com/new"
  echo "   Repository name: $REPO_NAME"
  echo "   Visibility: Public"
  echo ""
  echo "   2. Then run:"
  echo "   git remote add origin https://github.com/$GITHUB_USER/$REPO_NAME.git"
  echo "   git push -u origin main"
fi

echo ""
echo "=============================="
echo "🎉 完成!"
echo "=============================="
echo ""
echo "GitHub Actions 会自动运行构建:"
echo "https://github.com/$GITHUB_USER/$REPO_NAME/actions"
echo ""
echo "构建完成后,截图会作为 Artifact 发布,可下载查看"
