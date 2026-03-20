#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux emacs ripgrep fd-find

# Keep a full developer toolchain in the final image
dnf5 group install -y "Development Tools"

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

### Sway + nwg-shell install
# Detect Fedora version for COPR repo targeting
source /etc/os-release

# Enable required COPRs
dnf5 -y copr enable tofik/sway
dnf5 -y copr enable tofik/nwg-shell
dnf5 -y copr enable erikreider/SwayNotificationCenter
dnf5 -y copr enable mochaa/gtk-session-lock

# Install sway and nwg-shell
# File manager, text editor, and web browser are intentionally omitted —
# they are provided by the bazzite KDE environment.
dnf5 install -y sway nwg-shell

# Seed default nwg-shell + sway configs for new users via /etc/skel.
# nwg-shell-installer has no -d flag; redirect its XDG/HOME env vars instead.
# -s skips the reboot that -w (web mode) would otherwise trigger at the end.
mkdir -p /etc/skel/.config /etc/skel/.local/share
HOME=/etc/skel \
    XDG_CONFIG_HOME=/etc/skel/.config \
    XDG_DATA_HOME=/etc/skel/.local/share \
    nwg-shell-installer -w -s

### Install Clash Verge Rev (latest release)
# Dynamically resolve the download URL for the latest x86_64 RPM
CLASH_VERGE_URL=$(curl -s https://api.github.com/repos/clash-verge-rev/clash-verge-rev/releases/latest \
  | jq -r '.assets[] | select(.name | endswith(".x86_64.rpm")) | .browser_download_url')
# Download and install
curl -L -o /tmp/clash-verge-rev.rpm "$CLASH_VERGE_URL"
dnf5 install -y /tmp/clash-verge-rev.rpm

### Install Cursor (latest stable)
# Download from Cursor API (follows redirects)
curl -L -o /tmp/cursor.rpm https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest
dnf5 install -y /tmp/cursor.rpm

### Cleanup downloaded RPM files
rm -f /tmp/*.rpm

### Install Krohnkite (dynamic tiling KWin script) from git
# Build dependencies
dnf5 install -y npm git-core go-task

# Clone, build the .kwinscript package, and install system-wide
git clone https://codeberg.org/anametologin/Krohnkite.git /tmp/krohnkite-build
pushd /tmp/krohnkite-build
# npm needs a writable HOME for its cache; /root may not exist during image build
# Use kwin-pkg (not package) to build the pkg/ directory without zipping into
# a .kwinscript file — we install directly from pkg/ so the zip is unnecessary.
HOME=/tmp go-task kwin-pkg
# Install the built package contents to the system-wide KWin scripts directory
# so it is available for all users out of the box.
mkdir -p /usr/share/kwin/scripts/krohnkite
cp -r pkg/* /usr/share/kwin/scripts/krohnkite/
popd

### Install Kara (KDE Plasma 6 panel widget) from git for new users
# Build dependencies (Fedora)
dnf5 install -y \
    cmake \
    extra-cmake-modules \
    gcc-c++ \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    kf6-ki18n-devel \
    kf6-kservice-devel \
    kf6-kwindowsystem-devel \
    libplasma-devel \
    plasma-activities-devel \
    kwin-devel \
    wayland-devel \
    libepoxy-devel \
    libdrm-devel \
    plasma-workspace-devel \
    kf6-kitemmodels-devel

# Clone and run upstream installer. HOME is /etc/skel so new users inherit setup.
git clone https://github.com/dhruv8sh/kara.git /tmp/kara-build
pushd /tmp/kara-build
HOME=/etc/skel bash ./install.sh
popd

# Clean up build trees and build-only dependencies
rm -rf /tmp/krohnkite-build /tmp/kara-build
dnf5 remove -y \
    npm \
    go-task \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    kf6-ki18n-devel \
    kf6-kservice-devel \
    kf6-kwindowsystem-devel \
    libplasma-devel \
    plasma-activities-devel \
    kwin-devel \
    wayland-devel \
    libepoxy-devel \
    libdrm-devel \
    plasma-workspace-devel \
    kf6-kitemmodels-devel
dnf5 clean all

#### Example for enabling a System Unit File

systemctl enable podman.socket
