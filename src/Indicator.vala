/*
 * Copyright (c) 2011-2019 elementary, Inc. (https://elementary.io)
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

public class Session.Indicator : Wingpanel.Indicator {
    private const string ICON_NAME = "system-shutdown-symbolic";
    private const string KEYBINDING_SCHEMA = "org.gnome.settings-daemon.plugins.media-keys";

    private SystemInterface suspend_interface;
    private LockInterface lock_interface;
    private SeatInterface seat_interface;

    private Wingpanel.IndicatorManager.ServerType server_type;
    private Wingpanel.Widgets.OverlayIcon indicator_icon;
    private Wingpanel.Widgets.Separator users_separator;

    private ModelButtonGrid lock_screen_grid;
    private ModelButtonGrid log_out_grid;

    private Gtk.ModelButton user_settings;
    private Gtk.ModelButton lock_screen;
    private Gtk.Button suspend;
    private Gtk.Button shutdown;

    private Session.Services.UserManager manager;
    private Widgets.EndSessionDialog? current_dialog = null;

    private Gtk.Grid main_grid;

    private static GLib.Settings? keybinding_settings;
    private static Gtk.CssProvider css_provider;

    public Indicator (Wingpanel.IndicatorManager.ServerType server_type) {
        Object (code_name: Wingpanel.Indicator.SESSION,
                display_name: _("Session"),
                description: _("The session indicator"));
        this.server_type = server_type;
        this.visible = true;

        EndSessionDialogServer.init ();
        EndSessionDialogServer.get_default ().show_dialog.connect ((type) => show_dialog ((Widgets.EndSessionDialogType)type));
    }

    static construct {
        if (SettingsSchemaSource.get_default ().lookup (KEYBINDING_SCHEMA, true) != null) {
            keybinding_settings = new GLib.Settings (KEYBINDING_SCHEMA);
        }

        css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/desktop/wingpanel/session/SystemButtons.css");
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/io/elementary/desktop/wingpanel/session");
    }

    public override Gtk.Widget get_display_widget () {
        if (indicator_icon == null) {
            indicator_icon = new Wingpanel.Widgets.OverlayIcon (ICON_NAME);
            indicator_icon.button_press_event.connect ((e) => {
                if (e.button == Gdk.BUTTON_MIDDLE) {
                    close ();
                    show_dialog (Widgets.EndSessionDialogType.RESTART);
                    return Gdk.EVENT_STOP;
                }

                return Gdk.EVENT_PROPAGATE;
            });
        }

        return indicator_icon;
    }

    public override Gtk.Widget? get_widget () {
        if (main_grid == null) {
            init_interfaces ();

            main_grid = new Gtk.Grid ();
            main_grid.set_orientation (Gtk.Orientation.VERTICAL);

            user_settings = new Gtk.ModelButton ();
            user_settings.text = _("User Accounts Settings…");

            log_out_grid = new ModelButtonGrid (_("Log Out…"), "logout");

            var log_out = new Gtk.ModelButton ();
            log_out.get_child ().destroy ();
            log_out.add (log_out_grid);

            lock_screen_grid = new ModelButtonGrid (_("Lock"), "screensaver");

            lock_screen = new Gtk.ModelButton ();
            lock_screen.get_child ().destroy ();
            lock_screen.add (lock_screen_grid);

            shutdown = new Gtk.Button ();
            shutdown.halign = Gtk.Align.CENTER;
            string shutdown_text = _("Shut Down…");
            var shutdown_label = new Gtk.Label (("<small>%s</small>").printf(shutdown_text));
            shutdown_label.use_markup = true;
            shutdown_label.width_chars = 10;
            var shutdown_image = new Gtk.Image.from_icon_name ("system-shutdown-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            shutdown_image.halign = Gtk.Align.CENTER;
            shutdown_image.margin = 5;
            shutdown_image.margin_top = 0;
            var shutdown_image_style_context = shutdown_image.get_style_context ();
            shutdown_image_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            var shutdown_grid = new Gtk.Grid ();
            var shutdown_grid_style_context = shutdown_grid.get_style_context ();
            shutdown_grid_style_context.add_class ("circle-image");
            shutdown_grid_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            shutdown_grid.orientation = Gtk.Orientation.VERTICAL;
            shutdown_grid.add (shutdown_image);
            shutdown_grid.add (shutdown_label);
            shutdown.add (shutdown_grid);
            shutdown.set_image_position (Gtk.PositionType.TOP);

            var shutdown_style_context = shutdown.get_style_context ();
            shutdown_style_context.add_class (Gtk.STYLE_CLASS_FLAT);
            shutdown_style_context.add_class ("power-selection");
            shutdown_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            suspend = new Gtk.Button ();
            suspend.halign = Gtk.Align.CENTER;
            string suspend_text = _("Suspend");
            var suspend_label = new Gtk.Label (("<small>%s</small>").printf(suspend_text));
            suspend_label.use_markup = true;
            suspend_label.width_chars = 10;
            var suspend_image = new Gtk.Image.from_icon_name ("system-suspend-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            suspend_image.halign = Gtk.Align.CENTER;
            suspend_image.margin = 5;
            suspend_image.margin_top = 0;
            var suspend_image_style_context = suspend_image.get_style_context ();
            suspend_image_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            var suspend_grid = new Gtk.Grid ();
            var suspend_grid_style_context = suspend_grid.get_style_context ();
            suspend_grid_style_context.add_class ("circle-image");
            suspend_grid_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            suspend_grid.orientation = Gtk.Orientation.VERTICAL;
            suspend_grid.add (suspend_image);
            suspend_grid.add (suspend_label);
            suspend.add (suspend_grid);
            suspend.set_image_position (Gtk.PositionType.TOP);

            var suspend_style_context = suspend.get_style_context ();
            suspend_style_context.add_class (Gtk.STYLE_CLASS_FLAT);
            suspend_style_context.add_class ("power-selection");
            suspend_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            var suspend_shutdown_box = new Gtk.Grid ();
            suspend_shutdown_box.hexpand = true;
            suspend_shutdown_box.column_homogeneous = true;
            suspend_shutdown_box.add (suspend);
            suspend_shutdown_box.add (shutdown);

            if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION) {
                users_separator = new Wingpanel.Widgets.Separator ();
                manager = new Session.Services.UserManager (users_separator);

                var scrolled_box = new Gtk.ScrolledWindow (null, null);
                scrolled_box.hexpand = true;
                scrolled_box.hscrollbar_policy = Gtk.PolicyType.NEVER;
                scrolled_box.max_content_height = 300;
                scrolled_box.propagate_natural_height = true;
                scrolled_box.add (manager.user_grid);

                main_grid.add (scrolled_box);

                if (manager.has_guest) {
                    manager.add_guest (false);
                }

                main_grid.add (user_settings);
                main_grid.add (users_separator);
                main_grid.add (lock_screen);
                main_grid.add (log_out);
                main_grid.add (new Wingpanel.Widgets.Separator ());
            }

            main_grid.add (suspend_shutdown_box);

            connections ();

            log_out.clicked.connect (() => show_dialog (Widgets.EndSessionDialogType.LOGOUT));

            lock_screen.clicked.connect (() => {
                close ();

                try {
                    lock_interface.lock ();
                } catch (GLib.Error e) {
                    stderr.printf ("%s\n", e.message);
                }
            });
        }

        return main_grid;
    }

    private void init_interfaces () {
        try {
            suspend_interface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
        } catch (IOError e) {
            stderr.printf ("%s\n", e.message);
            suspend.set_sensitive (false);
        }

        if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION) {
            try {
                lock_interface = Bus.get_proxy_sync (BusType.SESSION, "org.freedesktop.ScreenSaver", "/org/freedesktop/ScreenSaver");
            } catch (IOError e) {
                stderr.printf ("%s\n", e.message);
                lock_screen.set_sensitive (false);
            }

            try {
                seat_interface = Bus.get_proxy_sync (BusType.SESSION, "org.freedesktop.DisplayManager", "/org/freedesktop/DisplayManager/Seat0");
            } catch (IOError e) {
                stderr.printf ("%s\n", e.message);
                lock_screen.set_sensitive (false);
            }
        }
    }

    public void connections () {
        manager.close.connect (() => close ());

        user_settings.clicked.connect (() => {
            close ();

            try {
                AppInfo.launch_default_for_uri ("settings://accounts", null);
            } catch (Error e) {
                warning ("Failed to open user accounts settings: %s", e.message);
            }
        });

        shutdown.clicked.connect (() => show_dialog (Widgets.EndSessionDialogType.RESTART));

        suspend.clicked.connect (() => {
            close ();

            try {
                suspend_interface.suspend (true);
            } catch (GLib.Error e) {
                stderr.printf ("%s\n", e.message);
            }
        });
    }

    public override void opened () {
        manager.update_all ();
        main_grid.show_all ();
    }

    public override void closed () {}

    private void show_dialog (Widgets.EndSessionDialogType type) {
        close ();

        if (current_dialog != null) {
            if (current_dialog.dialog_type != type) {
                current_dialog.destroy ();
            } else {
                return;
            }
        }

        current_dialog = new Widgets.EndSessionDialog (type);
        current_dialog.destroy.connect (() => current_dialog = null);
        current_dialog.set_transient_for (indicator_icon.get_toplevel () as Gtk.Window);
        current_dialog.show_all ();
    }

    private class ModelButtonGrid : Gtk.Grid {
        public string accel_key { get; construct; }
        public string text { get; construct; }

        private Gtk.Label accel;

        public ModelButtonGrid (string text, string accel_key) {
            Object (
                accel_key: accel_key,
                text: text
            );
        }

        construct {
            var label = new Gtk.Label (text);
            label.hexpand = true;
            label.xalign = 0;

            accel = new Gtk.Label (null);
            accel.get_style_context ().add_class (Gtk.STYLE_CLASS_ACCELERATOR);

            column_spacing = 6;
            add (label);
            add (accel);

            if (keybinding_settings != null) {
                update_accel ();

                keybinding_settings.changed.connect ((key) => {
                    if (key == accel_key) {
                        update_accel ();
                    }
                });
            }
        }

        private void update_accel () {
            accel.label = Granite.accel_to_string (keybinding_settings.get_string (accel_key));
        }
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug ("Activating Sample Indicator");
    var indicator = new Session.Indicator (server_type);

    return indicator;
}
