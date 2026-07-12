#!/usr/bin/env bash
# Debian / Ubuntu (Kubuntu) installer: builds and installs the plugin, then
# registers an APT hook so the plugin is automatically rebuilt after a kwin
# upgrade.
#
# Usage:
#   ./install-debian.sh
#   BUILD_TYPE=Debug ./install-debian.sh
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

echo ">> Registering APT hook"

# Record the source dir (so the hook can find it later) and the KWin version we
# just built against (so the runner can tell when a rebuild is actually needed).
install -d /etc/kwinpretilerestore
printf '%s\n' "$SCRIPT_DIR" > /etc/kwinpretilerestore/source_dir
kwin_wayland --version 2>/dev/null | awk 'NR==1 {print $NF}' \
    > /etc/kwinpretilerestore/built_version || true

# Install the shared self-gating rebuild runner to a fixed system path.
install -Dm755 "$SCRIPT_DIR/rebuild-hook.sh" \
    /usr/local/lib/kwinpretilerestore/rebuild-hook.sh

# APT hooks are built in -- just drop a config snippet. It fires on every apt
# transaction; the runner self-gates so it only rebuilds when KWin changed.
install -Dm644 "$SCRIPT_DIR/apt-hook.conf" \
    /etc/apt/apt.conf.d/99-kwinpretilerestore

cat <<'EOF'

APT hook installed at /etc/apt/apt.conf.d/99-kwinpretilerestore

The plugin will be rebuilt automatically after a kwin upgrade.
Log out and back in now to load the freshly installed plugin.

To remove everything later, run ./uninstall-debian.sh
EOF
