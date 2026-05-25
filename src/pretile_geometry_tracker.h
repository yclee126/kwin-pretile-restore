#pragma once

#include <KSharedConfig>

#include <QObject>
#include <QRectF>

namespace KWin
{
class Window;
}

// Watches window lifecycle and restores an app's pre-tiling geometry on reopen.
//
// Strategy (most-recent-close wins): when a normal window closes we record its
// floating geometry plus whether it was tiled at close time, keyed by app
// (resourceClass). On the next open of that app we re-apply the saved geometry
// only if the most recent close was tiled — a clean (floating) close disarms
// the restore, so we never fight an app whose own size memory is already good.
class PretileGeometryTracker : public QObject
{
    Q_OBJECT

public:
    PretileGeometryTracker();
    ~PretileGeometryTracker() override;

private:
    void onWindowAdded(KWin::Window *window);
    void onWindowRemoved(KWin::Window *window);

    static bool isManaged(const KWin::Window *window);
    static bool isTiled(const KWin::Window *window);

    QRectF clampToScreen(KWin::Window *window, const QRectF &geometry) const;

    KSharedConfig::Ptr m_config;
};
