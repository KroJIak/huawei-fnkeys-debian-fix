# Huawei MateBook 14s Fn keys fix (Debian GNOME X11)

[Русская версия](docs/README-RU.md)

![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-13-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![GNOME](https://img.shields.io/badge/GNOME-48-4A86CF?style=for-the-badge&logo=gnome&logoColor=white)
![Xorg](https://img.shields.io/badge/Xorg-X11-FF6600?style=for-the-badge&logo=xorg&logoColor=white)
![systemd](https://img.shields.io/badge/systemd-service-DA2525?style=for-the-badge&logo=linux&logoColor=white)

This project fixes volume key lag (Fn+F5/F6) on Huawei MateBook 14s running Debian 13 GNOME X11 by blocking duplicate events from Huawei WMI hotkeys while keeping all other Fn keys working.

## What is included

- `install.sh` - installs input-remapper, creates the preset, and enables autoload.
- Input-remapper preset that disables only XF86AudioLowerVolume and XF86AudioRaiseVolume on Huawei WMI hotkeys.
- Optional daemon setup for automatic loading on boot.

## Requirements

- Debian 13
- GNOME on Xorg (X11 session)
- `sudo` access for package installation

## Problem

On Huawei MateBook 14s with Debian 13 GNOME X11, pressing Fn+F5/F6 causes a visible lag. One physical key generates two input events:

- Standard keyboard device (AT Translated Set 2 keyboard)
- Huawei WMI hotkeys

GNOME processes both events, showing the volume overlay twice and applying the volume change twice, which causes stutter.

## Goal

Make volume keys work smoothly without breaking other Huawei Fn keys:

- Fn + Mute
- Fn + Mic Mute
- Fn + Airplane mode
- Fn + Settings
- Fn + Brightness

## Solution

Use input-remapper to disable only the duplicate volume events from Huawei WMI hotkeys while leaving the standard keyboard events intact.

## Install

```bash
./install.sh
```

Options:

- `--debug` - show full command output (no log files).
- `-y`, `--yes` - auto-accept prompts.

After installation you should have smooth volume changes with all other Fn keys preserved.

## Alternative solutions

| Method | Description | Pros | Cons |
|-------|-------------|------|------|
| **xorg.conf.d** | Disable Huawei WMI device entirely | No extra software, works at X11 level | Breaks all Huawei Fn keys | 
| **xmodmap** | Set NoSymbol for keycodes 122/123 | Simple autostart script | Global change, breaks volume everywhere | 
| **udev hwdb** | Set KEYBOARD_KEY_72=reserved | Kernel-level mapping | Does not block X11 events, requires reboot | 
| **input-remapper** | Disable only volume events | Precise control, GUI, daemon, autoload | Extra process (~38MB RAM) |

## Verification

```bash
sudo systemctl status input-remapper-daemon.service
input-remapper-control --list-presets
xinput test "Huawei WMI hotkeys"
```

Fn+F5/F6 should trigger no events on the Huawei WMI device and volume changes should be smooth.
