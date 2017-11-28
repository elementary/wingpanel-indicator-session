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

public class OpenedAppsBox : Gtk.Box {
    private class ApplicationIcon : Gtk.Image {
        public Bamf.Application app { get; construct; }

        construct {
            icon_size = Gtk.IconSize.DIALOG;
            pixel_size = 48;

            update (app.get_icon ());
            app.icon_changed.connect (update);
        }

        public ApplicationIcon (Bamf.Application app) {
            Object (app: app);
        }

        private void update (string icon) {
            try {
                gicon = Icon.new_for_string (icon);
            } catch (Error e) {
                warning (e.message);
            }
        }
    }

    private const int MAX_APP_ICONS = 6;

    private Gee.LinkedList<ApplicationIcon> app_icons;
    private Gtk.Label apps_count_label;

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 6;

        app_icons = new Gee.LinkedList<ApplicationIcon> ();

        apps_count_label = new Gtk.Label (null);
        apps_count_label.margin_start = 3;

        var style_context = apps_count_label.get_style_context ();
        style_context.add_class ("h2");
        style_context.add_class ("h4");

        pack_end (apps_count_label, false, false);

        set_widget_visible (this, false);

        var matcher = Bamf.Matcher.get_default ();
        matcher.get_running_applications ().@foreach ((app) => {
            if (app.is_user_visible ()) {
                add_application (app);
            }
        });

        new Thread<void*> ("watch-matcher-signals", () => {
            matcher.view_opened.connect ((view) => {
                var app = view as Bamf.Application;
                if (app != null && app.is_user_visible ()) {
                    Idle.add (() => {
                        add_application (app);
                        return false;
                    });
                }
            });

            matcher.view_closed.connect ((view) => {
                var app = view as Bamf.Application;
                if (app != null) {
                    Idle.add (() => {
                        remove_application (app);
                        return false;
                    });
                }
            });

            var loop = new MainLoop ();
            destroy.connect (() => loop.quit ());

            loop.run ();
            return null;
        });
    }

    private void add_application (Bamf.Application app) {
        var app_icon = new ApplicationIcon (app);
        pack_start (app_icon, false, false);

        app_icons.add (app_icon);
        update_icons_count (app_icon);

        show_all ();
    }

    private void remove_application (Bamf.Application app) {
        ApplicationIcon? target = null;
        foreach (var app_icon in app_icons) {
            if (compare_application (app_icon.app, app)) {
                target = app_icon;
                break;
            }
        }

        if (target == null) {
            return;
        }

        app_icons.remove (target);
        target.destroy ();

        update_icons_count (null);
    }

    private void update_icons_count (ApplicationIcon? added) {
        uint icons_count = app_icons.size;
        if (icons_count > MAX_APP_ICONS) {
            apps_count_label.label = _("+%u").printf (icons_count - MAX_APP_ICONS);
            set_widget_visible (apps_count_label, true);

            if (added != null) {
                set_widget_visible (added, false);
            }

            uint visible_icons = get_visible_icons_count ();
            if (visible_icons < MAX_APP_ICONS) {
                set_widget_visible (app_icons[MAX_APP_ICONS - 1], true);
            }

            set_widget_visible (this, true);
        } else if (icons_count == 0) {
            set_widget_visible (this, false);
        } else {
            foreach (var app_icon in app_icons) {
                set_widget_visible (app_icon, true);
            }

            set_widget_visible (apps_count_label, false);
            set_widget_visible (this, true);
        }
    }

    private uint get_visible_icons_count () {
        uint visible_icons = 0U;
        foreach (var app_icon in app_icons) {
            if (app_icon.visible) {
                visible_icons++;
            }
        }

        return visible_icons;
    }

    private static void set_widget_visible (Gtk.Widget widget, bool visible) {
        widget.no_show_all = !visible;
        widget.visible = visible;
    }

    private static bool compare_application (Bamf.Application a, Bamf.Application b) {
        return a.path == b.path;
    }
}