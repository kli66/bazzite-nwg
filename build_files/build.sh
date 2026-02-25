#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux 

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


#### Example for enabling a System Unit File

systemctl enable podman.socket
