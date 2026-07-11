set(kwinpretilerestore_SRCS
    kwin_pretile_restore_plugin.cpp
    pretile_geometry_tracker.cpp
)

add_library(kwinpretilerestore MODULE ${kwinpretilerestore_SRCS})

target_include_directories(kwinpretilerestore PRIVATE
    ${KWIN_INCLUDE_DIR}
    ${KWIN_INCLUDE_DIR}/kwin
)

if(KWIN_HAS_RECTF)
    target_compile_definitions(kwinpretilerestore PRIVATE KWIN_HAS_RECTF)
endif()

target_link_libraries(kwinpretilerestore PRIVATE
    Qt6::Core
    Qt6::DBus
    Qt6::Gui
    Qt6::Widgets
    KF6::ConfigCore
    KF6::WindowSystem
    ${KWIN_LIBRARY}
)

# KWin loads plugins from $libdir/kwin/plugins/.
install(TARGETS kwinpretilerestore
    DESTINATION ${KDE_INSTALL_PLUGINDIR}/kwin/plugins
)
