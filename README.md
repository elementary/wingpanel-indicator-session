# Wingpanel Session Indicator
[![l10n](https://l10n.elementary.io/widgets/wingpanel/wingpanel-indicator-session/svg-badge.svg)](https://l10n.elementary.io/projects/wingpanel/wingpanel-indicator-session)

![Screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

    libaccountsservice-dev
    libgirepository1.0-dev
    libglib2.0-dev
    libgranite-dev
    libgtk-3-dev
    libwingpanel-2.0-dev
    meson
    valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
