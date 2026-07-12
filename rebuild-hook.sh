#!/usr/bin/env bash
# Self-gating rebuild runner for kwin-pretile-restore, invoked by the distro
# package hooks (pacman / APT) after a system transaction.
#
# KWin refuses to load a plugin whose embedded version does not match its own,
# so the plugin must be rebuilt after every KWin upgrade. This rebuilds and
# reinstalls it, but only when the running KWin version differs from the one it
# was last built against. That makes it safe to call after *any* transaction:
# APT's Post-Invoke fires on every apt run and becomes a cheap no-op here when
# KWin has not changed.
#
# Installed to /usr/local/lib/kwinpretilerestore/rebuild-hook.sh by the
# install-<distro>.sh scripts, which also record the source dir below.
set -euo pipefail

CONFIG_DIR=/etc/kwinpretilerestore
SOURCE_FILE="$CONFIG_DIR/source_dir"
STATE_FILE="$CONFIG_DIR/built_version"

if [ ! -r "$SOURCE_FILE" ]; then
    echo "kwin-pretile-restore: no source dir recorded at $SOURCE_FILE; skipping." >&2
    exit 0
fi
SOURCE_DIR="$(cat "$SOURCE_FILE")"

# "kwin 6.7.2" -> "6.7.2"; empty if kwin_wayland is unavailable.
kwin_version() {
    command -v kwin_wayland >/dev/null 2>&1 || return 0
    kwin_wayland --version 2>/dev/null | awk 'NR==1 {print $NF}'
}

current="$(kwin_version)"
built=""
[ -r "$STATE_FILE" ] && built="$(cat "$STATE_FILE")"

# No change since the last build -> nothing to do.
if [ -n "$current" ] && [ "$current" = "$built" ]; then
    exit 0
fi

if [ ! -x "$SOURCE_DIR/install-general.sh" ]; then
    echo "kwin-pretile-restore: $SOURCE_DIR/install-general.sh not found; skipping." >&2
    exit 0
fi

echo ">> kwin-pretile-restore: KWin ${built:-unknown} -> ${current:-unknown}; rebuilding"

# Never abort the package transaction if the build fails; log it and retry on
# the next upgrade instead.
if "$SOURCE_DIR/install-general.sh"; then
    [ -n "$current" ] && printf '%s\n' "$current" > "$STATE_FILE"
    echo ">> kwin-pretile-restore: rebuilt. Log out and back in to load it."
else
    echo "kwin-pretile-restore: rebuild failed; will retry after the next upgrade." >&2
fi
