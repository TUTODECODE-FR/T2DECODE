#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap for T2DECODE.
# Installs the Linux desktop toolchain and the Flutter SDK pinned in .flutter-version.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ ! -f .flutter-version ]]; then
  echo "Run this install from the T2DECODE repository root." >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  git \
  unzip \
  xz-utils \
  zip \
  clang \
  g++-14 \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  liblzma-dev \
  libsecret-1-dev \
  mesa-utils \
  python3

if apt-cache show libstdc++-12-dev >/dev/null 2>&1; then
  sudo apt-get install -y --no-install-recommends libstdc++-12-dev
fi

FLUTTER_ROOT=/opt/flutter
VERSION="$(tr -d '[:space:]' < .flutter-version)"
INSTALLED=""
if [[ -f "${FLUTTER_ROOT}/.installed-version" ]]; then
  INSTALLED="$(tr -d '[:space:]' < "${FLUTTER_ROOT}/.installed-version")"
fi

if [[ ! -x "${FLUTTER_ROOT}/bin/flutter" || "${INSTALLED}" != "${VERSION}" ]]; then
  tmp="$(mktemp)"
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${VERSION}-stable.tar.xz" -o "${tmp}"
  sudo rm -rf "${FLUTTER_ROOT}"
  sudo tar -xJf "${tmp}" -C /opt
  rm -f "${tmp}"
  echo "${VERSION}" | sudo tee "${FLUTTER_ROOT}/.installed-version" >/dev/null
  sudo chown -R "$(id -u):$(id -g)" "${FLUTTER_ROOT}"
fi

sudo ln -sfn "${FLUTTER_ROOT}/bin/flutter" /usr/local/bin/flutter
sudo ln -sfn "${FLUTTER_ROOT}/bin/dart" /usr/local/bin/dart

if ! git config --global --get-all safe.directory 2>/dev/null | grep -qx "${FLUTTER_ROOT}"; then
  git config --global --add safe.directory "${FLUTTER_ROOT}"
fi

flutter config --no-analytics
flutter config --enable-linux-desktop
flutter precache --linux
flutter pub get
echo "INSTALL_OK version=${VERSION}"
