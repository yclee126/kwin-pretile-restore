#include "pretile_geometry_tracker.h"

#include <kwin/window.h>
#include <kwin/workspace.h>

#include <KConfigGroup>

#include <QLoggingCategory>
#include <QPointer>

Q_LOGGING_CATEGORY(LOG_KPR, "kwin.pretilerestore", QtWarningMsg)

namespace
{
constexpr auto s_geometryKey = "Geometry";
constexpr auto s_armedKey = "Armed";
}

PretileGeometryTracker::PretileGeometryTracker()
    : m_config(KSharedConfig::openConfig(QStringLiteral("kwinpretilerestorerc")))
{
    auto *workspace = KWin::Workspace::self();
    if (!workspace) {
        qCWarning(LOG_KPR) << "No Workspace at construction; tracker inactive";
        return;
    }
    connect(workspace, &KWin::Workspace::windowAdded, this, &PretileGeometryTracker::onWindowAdded);
    connect(workspace, &KWin::Workspace::windowRemoved, this, &PretileGeometryTracker::onWindowRemoved);
}

PretileGeometryTracker::~PretileGeometryTracker() = default;

bool PretileGeometryTracker::isManaged(const KWin::Window *window)
{
    // Only ordinary top-level app windows. Excludes dialogs, popups, utility
    // and toolbar windows, and any transient child - those legitimately share
    // an app's resourceClass but want their own size.
    return window && window->isNormalWindow() && !window->isTransient()
        && !window->resourceClass().isEmpty();
}

bool PretileGeometryTracker::isTiled(const KWin::Window *window)
{
    return window->quickTileMode() != KWin::QuickTileMode(KWin::QuickTileFlag::None);
}

QRectF PretileGeometryTracker::clampToScreen(KWin::Window *window, const QRectF &geometry) const
{
    auto *workspace = KWin::Workspace::self();
    if (!workspace) {
        return geometry;
    }
    const QRectF area = workspace->clientArea(KWin::PlacementArea, window);
    if (area.isEmpty()) {
        return geometry;
    }

    QRectF result = geometry;
    // Never larger than the available area.
    result.setWidth(std::min(result.width(), area.width()));
    result.setHeight(std::min(result.height(), area.height()));
    // Nudge fully on-screen, keeping size.
    if (result.left() < area.left()) {
        result.moveLeft(area.left());
    }
    if (result.top() < area.top()) {
        result.moveTop(area.top());
    }
    if (result.right() > area.right()) {
        result.moveRight(area.right());
    }
    if (result.bottom() > area.bottom()) {
        result.moveBottom(area.bottom());
    }
    return result;
}

void PretileGeometryTracker::onWindowAdded(KWin::Window *window)
{
    if (!isManaged(window)) {
        return;
    }

    const QString key = window->resourceClass();
    KConfigGroup group = m_config->group(key);
    if (!group.exists() || !group.readEntry(s_armedKey, false)) {
        return;
    }

    const QRect saved = group.readEntry(s_geometryKey, QRect());
    if (!saved.isValid()) {
        return;
    }

    const QRectF target = clampToScreen(window, QRectF(saved));
    qCDebug(LOG_KPR) << "Restoring geometry for" << key << target << "(app opened at" << window->frameGeometry() << ")";

    // The app sets its own (tiled) size right after map; apply one event-loop
    // turn later so we win. Bound to the window as context so a destroyed
    // window cancels the pending call.
    QPointer<KWin::Window> guard(window);
    QMetaObject::invokeMethod(
        window,
        [guard, target]() {
            if (guard) {
                guard->moveResize(KWin::RectF(target));
            }
        },
        Qt::QueuedConnection);
}

void PretileGeometryTracker::onWindowRemoved(KWin::Window *window)
{
    if (!isManaged(window)) {
        return;
    }

    const bool tiled = isTiled(window);
    // When tiled, geometryRestore() is the floating geometry KWin would snap
    // back to on untile; when floating, the frame geometry already is it.
    const QRectF floating = tiled ? QRectF(window->geometryRestore()) : QRectF(window->frameGeometry());

    const QString key = window->resourceClass();
    KConfigGroup group = m_config->group(key);
    group.writeEntry(s_geometryKey, floating.toRect());
    group.writeEntry(s_armedKey, tiled);
    m_config->sync();

    qCDebug(LOG_KPR) << "Saved geometry for" << key << floating << "tiled=" << tiled;
}
