#!/bin/bash
set -e

function build() {
  local arch="$1"
  echo "* building for ${arch}"
  mkdir -p "build/${arch}"
  xcrun clang ips2crash.m \
    -o "build/${arch}/out" \
    -mmacosx-version-min=11.0 \
    -F/System/Library/PrivateFrameworks \
    -framework Foundation \
    -framework OSAnalytics \
    -arch "$arch"
  strip -x "build/${arch}/out"
}

rm -rf build
build arm64
build x86_64

echo "* creating fat binary"
lipo -create build/*/out -output build/ips2crash

echo "* compressing for release"
( cd build; tar -czf ips2crash.tar.gz ips2crash; )
