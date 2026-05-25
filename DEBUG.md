# Debugging

## Enable debug logging

Log lines are emitted at QtWarningMsg level so they are silent by default. You can enable them by adding a new Qt logging rule.

Add the following line under the `[Rules]` section of `~/.config/QtProject/qtlogging.ini`:

```
kwin.pretilerestore*=true
```

If the file or section doesn't exist, create them:

```ini
[Rules]
kwin.pretilerestore*=true
```

Log out and back in for the change to take effect.

## Watch the output

```bash
journalctl --user _COMM=kwin_wayland -f
```

## Disable debug logging

Remove the `kwin.pretilerestore*=true` line from `qtlogging.ini`, then log out and back in.
