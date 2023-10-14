# project name and programming language
project('io.github.leolost2605.syncher', 'vala', 'c')

gnome = import('gnome')
# Include the translations module
i18n = import('i18n')

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    'src' / 'Application.vala',
    'src' / 'ErrorView.vala',
    'src' / 'HomeView.vala',
    'src' / 'Window.vala',
    'src' / 'WelcomeView.vala',
    'src' / 'PreferencesWindow.vala',
    'src' / 'ProgressView.vala',
    'src' / 'ProgressWidget.vala',
    'src' / 'Core' / 'SyncherService.vala',
    'src' / 'Core' / 'Module.vala',
    'src' / 'Modules' / 'AppModule.vala',
    'src' / 'Modules' / 'DconfModule.vala',
    'src' / 'Modules' / 'RepoModule.vala',
    dependencies: [
        dependency('gtk4'),
        dependency('granite-7'),
        dependency('libadwaita-1')
    ],
    install: true
)

gnome.post_install(glib_compile_schemas: true)

subdir('po')
subdir('data')
