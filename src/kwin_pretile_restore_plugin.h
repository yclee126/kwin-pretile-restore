#pragma once

#include <kwin/plugin.h>

#include <memory>

class PretileGeometryTracker;

class KwinPretileRestorePlugin : public KWin::Plugin
{
    Q_OBJECT

public:
    explicit KwinPretileRestorePlugin();
    ~KwinPretileRestorePlugin() override;

private:
    std::unique_ptr<PretileGeometryTracker> m_tracker;
};

class KwinPretileRestorePluginFactory : public KWin::PluginFactory
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID PluginFactory_iid FILE "metadata.json")
    Q_INTERFACES(KWin::PluginFactory)

public:
    std::unique_ptr<KWin::Plugin> create() const override;
};
