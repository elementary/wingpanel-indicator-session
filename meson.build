project(
    'session',
    'vala', 'c',
    version: '2.2.4'
)

i18n = import('i18n')
gettext_name = meson.project_name() + '-indicator'

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

wingpanel_dep = dependency('wingpanel-2.0')

shared_module(
    meson.project_name(),
    'src/Indicator.vala',
    'src/Widgets/EndSessionDialog.vala',
    'src/Widgets/UserBox.vala',
    'src/Widgets/UserListBox.vala',
    'src/Services/DbusInterfaces.vala',
    'src/Services/UserManager.vala',
    'src/Services/EndSessionDialogServer.vala',
    dependencies: [
        dependency('accountsservice'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite', version: '>=5.2.0'),
        dependency('gtk+-3.0'),
        wingpanel_dep
    ],
    install: true,
    install_dir : wingpanel_dep.get_pkgconfig_variable('indicatorsdir')
)

subdir('po')
