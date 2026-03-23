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
    pcmanfm \
    greetd \
    gtkgreet

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

### Sway + noctalia-shell install
# Detect Fedora version for COPR repo targeting
source /etc/os-release

# Enable required COPRs
dnf5 -y copr enable tofik/sway
dnf5 -y copr enable tofik/nwg-shell
# dnf5 -y copr enable erikreider/SwayNotificationCenter
# dnf5 -y copr enable mochaa/gtk-session-lock

# Enable Terra repository
dnf5 install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

# Install sway stack and theme tooling
dnf5 install -y sway noctalia-shell nwg-look adw-gtk3-theme ghostty

# Remove terminal packages pulled in by sway weak dependencies
foot_packages=()
for pkg in foot foot-client foot-server; do
    if rpm -q "$pkg" >/dev/null 2>&1; then
        foot_packages+=("$pkg")
    fi
done

if [ "${#foot_packages[@]}" -gt 0 ]; then
    dnf5 remove -y "${foot_packages[@]}"
fi

ghostty_desktop=''
for desktop in com.mitchellh.ghostty.desktop ghostty.desktop; do
    if [ -f "/usr/share/applications/${desktop}" ]; then
        ghostty_desktop="${desktop}"
        break
    fi
done

pcmanfm_desktop=''
for desktop in pcmanfm.desktop pcmanfm-qt.desktop; do
    if [ -f "/usr/share/applications/${desktop}" ]; then
        pcmanfm_desktop="${desktop}"
        break
    fi
done

mkdir -p /etc/xdg
cat > /etc/xdg/mimeapps.list <<EOF
[Default Applications]
inode/directory=${pcmanfm_desktop:-pcmanfm.desktop}
x-scheme-handler/terminal=${ghostty_desktop:-com.mitchellh.ghostty.desktop}
EOF

# Configure greetd + gtkgreet for graphical login on boot
mkdir -p /etc/greetd
cat > /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "sway --config /etc/greetd/sway-greetd.conf"
user = "greetd"
EOF

cat > /etc/greetd/sway-greetd.conf <<'EOF'
exec "env XDG_RUNTIME_DIR=/run/greetd dbus-run-session -- gtkgreet -l; swaymsg exit"
EOF

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
systemctl enable greetd.service
systemctl set-default graphical.target
