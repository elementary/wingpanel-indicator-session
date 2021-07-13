project(
    'session',
    'vala', 'c',
    version: '2.3.0'
)

i18n = import('i18n')
gettext_name = meson.project_name() + '-indicator'

prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')
add_project_arguments('-DG_LOG_DOMAIN="io.elementary.wingpanel.session"', language:'c')

wingpanel_dep = dependency('wingpanel')
wingpanel_indicatorsdir = wingpanel_dep.get_pkgconfig_variable('indicatorsdir', define_variable: ['libdir', libdir])

config_data = configuration_data()
config_data.set('GETTEXT_PACKAGE', meson.project_name())
config_vala = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

shared_module(
    meson.project_name(),
    'src/Indicator.vala',
    'src/Widgets/EndSessionDialog.vala',
    'src/Widgets/UserBox.vala',
    'src/Widgets/UserListBox.vala',
    'src/Services/DbusInterfaces.vala',
    'src/Services/UserManager.vala',
    'src/Services/EndSessionDialogServer.vala',
    config_vala,
    dependencies: [
        dependency('accountsservice'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite', version: '>=5.3.0'),
        dependency('gtk+-3.0'),
        dependency('libhandy-1', version: '>=0.90.0'),
        wingpanel_dep
    ],
    install: true,
    install_dir : wingpanel_indicatorsdir
)

subdir('data')
subdir('po')
