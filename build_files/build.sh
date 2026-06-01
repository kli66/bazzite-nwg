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
    clang-tools-extra \
    fcitx5 \
    fcitx5-rime \
    fcitx5-chinese-addons \
    fcitx5-configtool \
    fcitx5-gtk \
    fcitx5-qt \
    fcitx5-qt6 \
    librime-lua \
    wdisplays

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

# Enable Ghostty COPR repository for this Fedora release
curl -fsSL "https://copr.fedorainfracloud.org/coprs/scottames/ghostty/repo/fedora-${VERSION_ID}/scottames-ghostty-fedora-${VERSION_ID}.repo" \
    | tee /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:scottames:ghostty.repo > /dev/null

# Install Ghostty from COPR
dnf5 install -y ghostty

# Install Terra repository configuration for packages required by the Niri/Noctalia stack
dnf5 install -y --nogpgcheck --repofrompath 'terra-bootstrap,https://repos.fyralabs.com/terra$releasever' --repo terra-bootstrap terra-release

# The Terra repo files are present on Bazzite, but not enabled in CI by default.
sed -i 's/^enabled=0/enabled=1/' /etc/yum.repos.d/terra*.repo

# Emit CI diagnostics so repo visibility issues are obvious in build logs.
rpm -q terra-release
rpm -ql terra-release | grep '\.repo' || true
ls -l /etc/yum.repos.d
dnf5 repolist --enabled
dnf5 repoquery --available noctalia-shell --refresh || true

# Install Hyprland before noctalia-shell
# dnf5 install -y hyprland

# Install niri stack and theme tooling
dnf5 install -y niri noctalia-shell nwg-look adw-gtk3-theme

# Disable Terra again so it does not remain enabled in the final image.
sed -i 's/^enabled=1/enabled=0/' /etc/yum.repos.d/terra*.repo

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
