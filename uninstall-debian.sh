#!/usr/bin/env bash
# Remove the Debian/Ubuntu APT hook and its state, then uninstall the plugin.
#
# Usage:
#   ./uninstall-debian.sh
#   BUILD_DIR=out ./uninstall-debian.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ "$(id -u)" -ne 0 ]; then
    exec sudo --preserve-env=BUILD_DIR bash "$0" "$@"
fi

echo ">> Removing APT hook"
rm -f /etc/apt/apt.conf.d/99-kwinpretilerestore

echo ">> Removing hook runner and recorded state"
rm -rf /usr/local/lib/kwinpretilerestore
rm -rf /etc/kwinpretilerestore

echo ">> Uninstalling plugin"
"$SCRIPT_DIR/uninstall-general.sh"
