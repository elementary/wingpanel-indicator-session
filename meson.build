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

deps = [
    dependency('accountsservice'),
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('granite'),
    dependency('gtk+-3.0'),
    meson.get_compiler('vala').find_library('posix'),
    wingpanel_dep
]

sources = [
    'src/Indicator.vala',
    'src/Widgets/EndSessionDialog.vala',
    'src/Widgets/UserBox.vala',
    'src/Widgets/UserListBox.vala',
    'src/Services/DbusInterfaces.vala',
    'src/Services/UserManager.vala',
    'src/Services/ShutdownAction.vala',
    'src/Services/EndSessionDialogServer.vala',
]

if get_option('enable-show-apps')
    deps += dependency('libwnck-3.0')
    deps += dependency('libbamf3')
    sources += 'src/Widgets/OpenedAppsBox.vala'
    add_global_arguments('--define=HAVE_BAMF_WNCK', language: 'vala')
    add_global_arguments('-DWNCK_I_KNOW_THIS_IS_UNSTABLE', language: 'c')
endif

shared_module(
    meson.project_name(),
    sources,
    dependencies: deps,
    install: true,
    install_dir : wingpanel_dep.get_pkgconfig_variable('indicatorsdir')
)

subdir('po')
