/*
 * Copyright (c) 2011-2017 elementary LLC. (http://launchpad.net/wingpanel)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class ShutdownAppsDialog : Granite.MessageDialog {
    private class ApplicationIcon : Gtk.Image {
        construct {
            icon_size = Gtk.IconSize.LARGE_TOOLBAR;
        }

        public ApplicationIcon (Wnck.Application app) {
            unowned string app_icon_name = app.get_icon_name ();
            if (app_icon_name != null) {
                icon_name = app_icon_name;
            } else {
                pixbuf = app.get_icon ();
            }
        }
    }

    public ShutdownAppsDialog () {
        base (_("Are you sure you want to Shut Down?"),
            _("This will close any open apps and turn off your device. The following apps are still running:"),
            new ThemedIcon ("system-shutdown"));
    }

    construct {
        var screen = Wnck.Screen.get_default ();
        screen.application_opened.connect (add_application);
        screen.application_closed.connect (remove_application);
    }

    private void add_application (Wnck.Application app) {

    }

    private void remove_application (Wnck.Application app) {

    }
}