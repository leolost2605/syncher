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
    'src' / 'HomeView.vala',
    'src' / 'Window.vala',
    'src' / 'PreferencesWindow.vala',
    'src' / 'ProgressView.vala',
    'src' / 'ProgressWidget.vala',
    'src' / 'Services' / 'SyncherService.vala',
    dependencies: [
        dependency('gtk4'),
        dependency('granite-7'),
        dependency('libadwaita-1')
    ],
    install: true
)

# Install our .desktop file so the Applications Menu will see it
install_data(
    'data' / meson.project_name() + '.desktop',
    install_dir: get_option('datadir') / 'applications'
)

# Install our .appdata.xml file so AppCenter will see it
install_data(
    'data' / meson.project_name() + '.appdata.xml',
    install_dir: get_option('datadir') / 'metainfo'
)

# Install our icons in all the required sizes
icon_sizes = ['16', '24', '32', '48', '64', '128']
foreach i : icon_sizes
    install_data(
        'data' / i + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i / 'apps',
        rename: meson.project_name() + '.svg'
    )
    install_data(
        'data' / i + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i + '@2' / 'apps',
        rename: meson.project_name() + '.svg'
    )
endforeach

gnome.post_install(glib_compile_schemas: true)

subdir('data')
