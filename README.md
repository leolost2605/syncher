Important: Running with `G_MESSAGES_DEBUG=all` breaks the saved config files

## Building, Testing, and Installation

Run `flatpak-builder` to configure the build environment, download dependencies, build, and install

    flatpak-builder build io.github.leolost2605.syncher.yml --user --install --force-clean

execute with

    flatpak run io.github.leolost2605.syncher
