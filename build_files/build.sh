#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs packages from fedora repos
dnf5 install -y \
    tmux \
    neovim \
    ripgrep \
    fd-find \
    git-core \
    just \
    fzf \
    jq \
    yq \
    bat \
    bash-completion \
    openssh-clients \
    rsync \
    unzip \
    p7zip \
    curl \
    wget \
    podman \
    buildah \
    skopeo \
    distrobox \
    gcc \
    gcc-c++ \
    make \
    cmake \
    pkgconf-pkg-config \
    clang \
    lld \
    llvm \
    clang-tools-extra

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

### Niri + noctalia-shell install
# Detect Fedora version for COPR repo targeting
source /etc/os-release

# Enable required COPRs
dnf5 -y copr enable tofik/nwg-shell
# dnf5 -y copr enable solopasha/hyprland
# dnf5 -y copr enable erikreider/SwayNotificationCenter
# dnf5 -y copr enable mochaa/gtk-session-lock

# Enable Terra repository
dnf5 install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

# Install packages from Terra repository
dnf5 install -y ghostty wdisplays

# Install Hyprland before noctalia-shell
# dnf5 install -y hyprland

# Install niri stack and theme tooling
dnf5 install -y niri noctalia-shell nwg-look adw-gtk3-theme

# Install Clash Verge Rev (latest release)
## Dynamically resolve the download URL for the latest x86_64 RPM
CLASH_VERGE_URL=$(curl -s https://api.github.com/repos/clash-verge-rev/clash-verge-rev/releases/latest \
  | jq -r '.assets[] | select(.name | endswith(".x86_64.rpm")) | .browser_download_url')
## Download and install
curl -L -o /tmp/clash-verge-rev.rpm "$CLASH_VERGE_URL"
dnf5 install -y /tmp/clash-verge-rev.rpm

# Install Cursor (latest stable)
## Download from Cursor API (follows redirects)
curl -L -o /tmp/cursor.rpm https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest
dnf5 install -y /tmp/cursor.rpm

# Cleanup downloaded RPM files
rm -f /tmp/*.rpm

# Keep image cache clean.
dnf5 clean all

systemctl enable podman.socket
