#!/usr/bin/env bash
# Arch Linux installer: builds and installs the plugin, then registers a pacman
# hook so the plugin is automatically rebuilt after every kwin upgrade.
#
# Usage:
#   ./install-arch.sh
#   BUILD_TYPE=Debug ./install-arch.sh
#
# Re-runs itself under sudo if not already root (needed to write to /etc and
# /usr/local).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ "$(id -u)" -ne 0 ]; then
    exec sudo --preserve-env=BUILD_DIR,BUILD_TYPE,JOBS,CMAKE_INSTALL_PREFIX \
        bash "$0" "$@"
fi

echo ">> Building and installing plugin"
"$SCRIPT_DIR/install-general.sh"

echo ">> Registering pacman hook"

# Record the source dir (so the hook can find it later) and the KWin version we
# just built against (so the runner can tell when a rebuild is actually needed).
install -d /etc/kwinpretilerestore
printf '%s\n' "$SCRIPT_DIR" > /etc/kwinpretilerestore/source_dir
kwin_wayland --version 2>/dev/null | awk 'NR==1 {print $NF}' \
    > /etc/kwinpretilerestore/built_version || true

# Install the shared self-gating rebuild runner to a fixed system path.
install -Dm755 "$SCRIPT_DIR/rebuild-hook.sh" \
    /usr/local/lib/kwinpretilerestore/rebuild-hook.sh

# Install the pacman hook definition.
install -Dm644 "$SCRIPT_DIR/kwinpretilerestore.hook" \
    /etc/pacman.d/hooks/kwinpretilerestore.hook

cat <<'EOF'

Pacman hook installed at /etc/pacman.d/hooks/kwinpretilerestore.hook

The plugin will be rebuilt automatically after each kwin upgrade.
Log out and back in now to load the freshly installed plugin.

To remove everything later, run ./uninstall-arch.sh
EOF
