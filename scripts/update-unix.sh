#!/bin/bash
set -e

PORTABLE_ROOT="$1"
if [ -z "$PORTABLE_ROOT" ]; then
  echo "Usage: $0 <portable-root>"
  exit 1
fi

CACHE_DIR="$PORTABLE_ROOT/.cache"
SRC_DIR="$PORTABLE_ROOT/src"

# Detect platform
OS_RAW="$(uname -s)"
ARCH_RAW="$(uname -m)"
case "$OS_RAW" in
Linux*) PLATFORM="linux" ;;
Darwin*) PLATFORM="macos" ;;
*) exit 1 ;;
esac
case "$ARCH_RAW" in
x86_64 | amd64) ARCH="x64" ;;
aarch64 | arm64) ARCH="arm64" ;;
esac

RUNTIME_DIR="$CACHE_DIR/runtimes/${PLATFORM}-${ARCH}"
VENV_PATH_FILE="$RUNTIME_DIR/venv.path"
if [ -f "$VENV_PATH_FILE" ]; then
  VENV_DIR="$(cat "$VENV_PATH_FILE")"
else
  VENV_DIR="$RUNTIME_DIR/venv"
fi

SOURCE_URL="https://github.com/NousResearch/hermes-agent/archive/refs/heads/main.tar.gz"
SRC_ARCHIVE="$RUNTIME_DIR/source.tar.gz"
TMP_DIR="$RUNTIME_DIR/_tmp"

echo "正在从 GitHub 下载最新版 Hermes Agent..."
curl -fL --progress-bar "$SOURCE_URL" -o "$SRC_ARCHIVE"

echo "正在解压并安装最新版..."
rm -rf "$TMP_DIR/source"
mkdir -p "$TMP_DIR/source"
tar -xzf "$SRC_ARCHIVE" -C "$TMP_DIR/source" --strip-components=1
rm -rf "$SRC_DIR/hermes-agent"
mv "$TMP_DIR/source" "$SRC_DIR/hermes-agent"

# Run uv to update dependencies
VENV_PYTHON="$VENV_DIR/bin/python"
UV_EXE="$RUNTIME_DIR/uv/uv"

echo "正在更新依赖..."
if [ -x "$UV_EXE" ]; then
  "$UV_EXE" pip install --python "$VENV_PYTHON" --link-mode=copy -e "$SRC_DIR/hermes-agent[all]"
else
  "$VENV_PYTHON" -m pip install -e "$SRC_DIR/hermes-agent[all]"
fi

rm -rf "$TMP_DIR"
echo "Hermes 核心程序更新成功！"
