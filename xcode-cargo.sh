#!/usr/bin/env zsh

ARCH="aarch64"
OS=""
case "$PLATFORM_NAME" in
  "iphonesimulator") OS="ios-sim" ;;
  "iphoneos") OS="ios" ;;
  "macosx") OS="darwin" ;;
esac
TARGET="${ARCH}-apple-${OS}"


cargo build --release --target="${TARGET}"
