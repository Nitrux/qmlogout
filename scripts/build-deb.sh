#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024-2025 <Nitrux Latinoamericana S.C. <hello@nxos.org>>


# -- Exit on errors.

set -e


# -- Prepare source.

SRC_DIR="$(pwd)"

BUILD_WORK_DIR="$(mktemp -d)"

cp -r "$SRC_DIR"/* "$BUILD_WORK_DIR/"

cd "$BUILD_WORK_DIR"


# -- Configure build.

MESON_ARGS=(--prefix=/usr --buildtype=release)

DEB_ARCH="$(dpkg --print-architecture)"

if [ "$DEB_ARCH" = "amd64" ]; then
    MESON_ARGS+=("-Dcpp_args=-march=x86-64-v3")
fi

meson setup .build "${MESON_ARGS[@]}"


# -- Compile source.

ninja -C .build -k 0 -j "$(nproc)"


# -- Create a temporary DESTDIR for packaging.

DESTDIR="$(pwd)/pkg"
rm -rf "$DESTDIR"


# -- Install binary to DESTDIR.

DESTDIR="$DESTDIR" ninja -C .build install



# -- Create DEBIAN control file.

mkdir -p "$DESTDIR/DEBIAN"

PKGNAME="qmlogout"
VERSION="${PACKAGE_VERSION:-0.0.1}"
MAINTAINER="uri_herrera@nxos.org"
ARCHITECTURE="$(dpkg --print-architecture)"
DESCRIPTION="Native QML logout menu for Wayland environments."

cat > "$DESTDIR/DEBIAN/control" <<EOF
Package: $PKGNAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCHITECTURE
Maintainer: $MAINTAINER
Description: $DESCRIPTION
Depends: libkf6coreaddons6, liblayershellqtinterface6, libqt6core6t64, libqt6gui6, libqt6qml6, libqt6quick6, libqt6quickcontrols2-6, libqt6waylandclient6, mauikit (>= 4.0.4), qt6-wayland
EOF



cd "$(dirname "$DESTDIR")"

dpkg-deb --build "$(basename "$DESTDIR")" "${PKGNAME}_${VERSION}_${ARCHITECTURE}.deb"


# -- Move .deb to ./build/ for CI consistency.

TARGET_DIR="${GITHUB_WORKSPACE:-$SRC_DIR}/build"

mkdir -p "$TARGET_DIR"

mv "${PKGNAME}_${VERSION}_${ARCHITECTURE}.deb" "$TARGET_DIR/"

echo "Debian package created: $(pwd)/build/${PKGNAME}_${VERSION}_${ARCHITECTURE}.deb"
