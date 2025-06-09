# AW1KBUILDER

## Overview

AW1KBUILDER is a beginner-friendly OpenWrt build script designed for quick deployment and daily use. It comes with a full set of pre-configured packages and system tweaks, making it ideal for users who want a plug-and-play solution without needing to configure everything from scratch.

## Features

- Beginner Friendly: Automates the entire build process — from dependencies to final firmware output.
- Ready-to-use Preset: Comes with essential packages and system configurations tailored for optimal performance and modem support.
- Customizable via Menuconfig: Offers flexibility to add, remove, or update packages and kernel versions via `make menuconfig`.

## Preset Tweaks

- BBR congestion control
- ZRAM swap enabled
- CPU frequency scaling (all cores active)
- TTL 64 (for modem/router compatibility)
- Quectel-CM protocol support

## Preset Packages

- **System tools:** `htop`, `traffic monitor`, `RAM releaser`, `terminal access`
- **Modem tools:** `3GInfo Lite`, `modem band selector`, `SMS tools`
- **Extras:** `Argon theme`, `SFTP (OpenSSH) support`

## Default WiFi Settings

- **SSID:** `AW1K` / `AW1K 5G`
- **Password:** `nialwrt123`

## Requirements

- Internet connection
- Ubuntu 22.04 LTS or newer
- Adequate disk space and RAM
- Basic terminal usage knowledge

## Quick Installation

```bash
wget https://raw.githubusercontent.com/nialwrt/aw1kbuilder/main/aw1kbuilder.sh && chmod +x aw1kbuilder.sh && ./aw1kbuilder.sh
