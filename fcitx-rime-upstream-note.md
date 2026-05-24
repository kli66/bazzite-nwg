# Fcitx5 + Rime Upstream Layering Note

Target environment is Bluefin 43 / ostree-based, with Noctalia running under `niri`.

## Local Change Already Applied

- Added `spawn-at-startup "fcitx5" "-d"` to `/var/home/kai/.config/niri/config.kdl` so Fcitx5 starts with the compositor session.

## Current Local State

- Noctalia already has a tray widget, so Fcitx5 status/tray should surface there without shell-side plugin work.
- Existing Fcitx5 profile only had `keyboard-us`; Rime was not configured yet.
- Packages were not installed locally at the time of inspection; `fcitx5` binaries were missing.

## Upstream Image Layering

Layer these packages into the image:

```bash
fcitx5
fcitx5-autostart
fcitx5-rime
fcitx5-configtool
fcitx5-gtk
fcitx5-qt
fcitx5-qt6
librime-lua
```

Keep the `niri` autostart for `fcitx5 -d` unless the upstream image guarantees reliable XDG/session autostart under this compositor setup.

## Expected User Flow

After install/reboot:

1. Run `fcitx5-configtool`.
2. Add `Rime` as an active input method.
3. Keep `keyboard-us` as fallback.
4. Confirm the tray icon appears in Noctalia.

## rime-ice Install

`rime-ice` is not a separate Fcitx plugin package. It is a Rime schema/config bundle installed into Fcitx5's Rime user directory:

```bash
~/.local/share/fcitx5/rime
```

Recommended install sequence:

```bash
mkdir -p ~/.local/share/fcitx5
mv ~/.local/share/fcitx5/rime ~/.local/share/fcitx5/rime.bak.$(date +%F-%H%M%S) 2>/dev/null || true
git clone --depth 1 https://github.com/iDvel/rime-ice.git ~/.local/share/fcitx5/rime
```

Then restart/deploy Rime from Fcitx5 and select the `rime_ice` schema or one of its double-pinyin variants.

Using a clean directory is preferred because `rime-ice` can conflict with an existing mixed Rime config.

## Not Done In This Workspace

- Package layering/install
- Reboot/session restart
- Running `fcitx5-configtool`
- Verifying live IME behavior
