#!/bin/bash

set -euo pipefail

source_dir="${RIME_ICE_SOURCE_DIR:-/usr/share/bazzite-nwg/rime-ice}"
target_home="${1:-${HOME:-}}"

if [[ -z "${target_home}" ]]; then
    echo "Usage: install-rime-ice.sh <target-home>" >&2
    exit 1
fi

if [[ ! -d "${source_dir}" ]]; then
    echo "Missing bundled rime-ice data at ${source_dir}" >&2
    exit 1
fi

target_base="${target_home}/.local/share/fcitx5"
target_dir="${target_base}/rime"

mkdir -p "${target_base}"

if [[ -e "${target_dir}" || -L "${target_dir}" ]]; then
    backup_dir="${target_dir}.bak.$(date +%F-%H%M%S)"
    mv "${target_dir}" "${backup_dir}"
    echo "Backed up existing Rime config to ${backup_dir}"
fi

cp -a "${source_dir}" "${target_dir}"
echo "Installed rime-ice into ${target_dir}"
