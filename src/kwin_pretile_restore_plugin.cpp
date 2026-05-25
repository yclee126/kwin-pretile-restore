#include "kwin_pretile_restore_plugin.h"

#include "pretile_geometry_tracker.h"

KwinPretileRestorePlugin::KwinPretileRestorePlugin()
    : m_tracker(std::make_unique<PretileGeometryTracker>())
{
}

KwinPretileRestorePlugin::~KwinPretileRestorePlugin() = default;

std::unique_ptr<KWin::Plugin> KwinPretileRestorePluginFactory::create() const
{
    return std::make_unique<KwinPretileRestorePlugin>();
}
