# kwin-pretile-restore

A KWin plugin for KDE Plasma 6 (Wayland) that restores floating ("normal") window size after being closed in a tiled state.

![Demo](demo.webp)

## The problem

If you reopen an app you tiled last time, the new window often retains the tiled window size, which is quite inconvenient. To be fair, MS Windows treats a tiled state like a maximized state, so querying window geometry for saving reports the floating size. In KDE Plasma, querying window geometry reports the literal window size, which makes apps store the tiled window size instead.

## How it works

This plugin watches windows being closed and opened and manually restores the size from its own saved list.

- **On close:** If the window was tiled, its floating geometry is saved and marked for restore. If it was not tiled, the mark is cleared.
- **On open (primary):** If it was marked for restore, the new window is resized back to the saved geometry right after it opens.
- **On open (secondary):** Some programs even save their window size while it's running, so it checks if any opened window has a tiled state. If it finds the new window's geometry is the same as the tiled one, it restores the saved geometry even if it's not marked.

The list is at `~/.config/kwinpretilerestorerc`, one entry per app.

## Build & install

### Requirements

- KDE Plasma 6 on Wayland
- KWin 6.x (bundled with KDE Plasma 6)

To check your KWin version: `kwin_wayland --version`

### Tested on

- Kubuntu 26.04 LTS with KWin 6.6.4 / 6.6.5
- Arch Linux with KWin 6.7.2
- Fedora 40 KDE Spin with KWin 6.0.0 (no automated reinstall script)

### Build dependencies

| Distribution | Command |
|---|---|
| **Arch Linux (CachyOS)** | `sudo pacman -S base-devel cmake pkgconf extra-cmake-modules qt6-base kwin kconfig kwindowsystem` |
| **Debian (Ubuntu)** | `sudo apt install build-essential cmake pkg-config extra-cmake-modules kwin-dev libkf6config-dev libkf6windowsystem-dev qt6-base-dev` |
| **Fedora** | `sudo dnf install gcc-c++ cmake pkgconf extra-cmake-modules kwin-devel kf6-kconfig-devel kf6-kwindowsystem-devel qt6-qtbase-devel` |
| **openSUSE** | `sudo zypper install gcc-c++ cmake pkgconf extra-cmake-modules kwin6-devel kf6-kconfig-devel kf6-kwindowsystem-devel qt6-base-devel` |

### Installation scripts

KWin rejects plugins not compiled for its version number, which means every KWin upgrade will break this plugin. For convenience, these distro-specific scripts automatically re-install this plugin for you after each KWin upgrade.

Clone this repository to a **permanent location** so the auto scripts work correctly.

```bash
git clone https://github.com/yclee126/kwin-pretile-restore.git
cd kwin-pretile-restore
```

And pick an installation script matching your distro. Note that only Debian and Arch Linux hooks are available at the moment.

| Distribution | Command | Auto-rebuild |
|---|---|---|
| **Arch Linux (CachyOS)** | `./install-arch.sh` | Yes (pacman hook) |
| **Debian (Ubuntu)** | `./install-debian.sh` | Yes (APT hook) |
| **Others** | `./install-general.sh` | No (need to manually re-install) |

After it completes, log out and back in. (KWin only loads plugins at startup)

To remove it, run the counterpart `uninstall` script.

### How the automatic scripts work

- **Arch** — A pacman hook (`/etc/pacman.d/hooks/`) triggered on upgrades of the `kwin` package.
- **Debian** — An APT `DPkg::Post-Invoke` snippet (`/etc/apt/apt.conf.d/`). It runs after every apt transaction, but only rebuilds when the running KWin version differs from the one last built against, which is saved to `/etc/kwinpretilerestore/built_version`.

## Debugging

Add to `~/.config/QtProject/qtlogging.ini`:

```ini
[Rules]
kwin.pretilerestore*=true
```

Log out and back in, then watch:

```bash
journalctl --user _COMM=kwin_wayland -f
```

## License

GPL-2.0+
