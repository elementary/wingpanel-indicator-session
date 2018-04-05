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

public class Session.Indicator : Wingpanel.Indicator {
    private const string ICON_NAME = "system-shutdown-symbolic";

    private const string RESTART_CSS = """
        .compact-labels label {
            padding-bottom: 0;
            padding-top: 0;
        }
    """;

    private SystemInterface suspend_interface;
    private LockInterface lock_interface;
    private SeatInterface seat_interface;

    private Wingpanel.IndicatorManager.ServerType server_type;
    private Wingpanel.Widgets.OverlayIcon indicator_icon;
    private Wingpanel.Widgets.Separator users_separator;

    private Gtk.ModelButton user_settings;
    private Gtk.ModelButton lock_screen;
    private Gtk.ModelButton log_out;
    private Gtk.ModelButton suspend;
    private Gtk.Revealer restart_required_revealer;
    private Wingpanel.Widgets.Container shutdown;

    private Session.Services.UserManager manager;

    private Gtk.Grid main_grid;
    private Session.Widgets.EndSessionDialog? shutdown_dialog = null;

    public Indicator (Wingpanel.IndicatorManager.ServerType server_type) {
        Object (code_name: Wingpanel.Indicator.SESSION,
                display_name: _("Session"),
                description: _("The session indicator"));
        this.server_type = server_type;
    }

    public override Gtk.Widget get_display_widget () {
        if (indicator_icon == null) {
            indicator_icon = new Wingpanel.Widgets.OverlayIcon (ICON_NAME);
            indicator_icon.button_press_event.connect ((e) => {
                if (e.button == Gdk.BUTTON_MIDDLE) {
                    close ();
                    show_shutdown_dialog ();
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

            log_out = new Gtk.ModelButton ();
            log_out.text = _("Log Out…");

            lock_screen = new Gtk.ModelButton ();
            lock_screen.text = _("Lock");

            var shutdown_label = new Gtk.Label (_("Shut Down…"));
            shutdown_label.xalign = 0;
            shutdown_label.margin_start = shutdown_label.margin_end = 6;

            var restart_required_label = new Gtk.Label ("<small>%s</small>".printf (_("Restart required to complete updates")));
            restart_required_label.margin_start = restart_required_label.margin_end = 6;
            restart_required_label.use_markup = true;
            restart_required_label.get_style_context ().add_class ("attention");

            restart_required_revealer = new Gtk.Revealer ();
            restart_required_revealer.valign = Gtk.Align.CENTER;
            restart_required_revealer.add (restart_required_label);

            var shutdown_grid = new Gtk.Grid ();
            shutdown_grid.margin_top = shutdown_grid.margin_bottom = 3;
            shutdown_grid.orientation = Gtk.Orientation.VERTICAL;
            shutdown_grid.get_style_context ().add_class ("compact-labels");
            shutdown_grid.add (shutdown_label);
            shutdown_grid.add (restart_required_revealer);

            shutdown = new Wingpanel.Widgets.Container ();
            shutdown.content_widget.add (shutdown_grid);

            suspend = new Gtk.ModelButton ();
            suspend.text = _("Suspend");

            if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION) {
                users_separator = new Wingpanel.Widgets.Separator ();
                manager = new Session.Services.UserManager (users_separator);

                var scrolled_box = new Wingpanel.Widgets.AutomaticScrollBox (null, null);
                scrolled_box.hexpand = true;
                scrolled_box.max_height = 300;
                scrolled_box.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
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

                check_file_existance ();

                var restart_folder = File.new_for_path ("/var/run");

                try {
                    var monitor = restart_folder.monitor_directory (FileMonitorFlags.NONE, null);
                    monitor.changed.connect ((src, dest, event) => {
                        check_file_existance ();
                    });
                } catch (IOError e) {
                    critical (e.message);
                }
            }

            main_grid.add (suspend);
            main_grid.add (shutdown);

            connections ();

            var provider = new Gtk.CssProvider ();
            try {
                provider.load_from_data (RESTART_CSS, RESTART_CSS.length);
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (Error e) {
                critical (e.message);
            }
        }

        this.visible = true;

        return main_grid;
    }

    private void check_file_existance () {
        var restart_file = File.new_for_path ("/var/run/reboot-required");
        if (restart_file.query_exists ()) {
            restart_required_revealer.reveal_child = true;
        } else {
            restart_required_revealer.reveal_child = false;
        }
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
            try {
                AppInfo.launch_default_for_uri ("settings://accounts", null);
            } catch (Error e) {
                warning ("Failed to open user accounts settings: %s", e.message);
            }
        });

        lock_screen.clicked.connect (() => {
            try {
                lock_interface.lock ();
            } catch (IOError e) {
                stderr.printf ("%s\n", e.message);
            }
        });

        log_out.clicked.connect (() => {
            var dialog = new Session.Widgets.EndSessionDialog (Session.Widgets.EndSessionDialogType.LOGOUT);
            dialog.set_transient_for (indicator_icon.get_toplevel () as Gtk.Window);
            dialog.show_all ();
        });

        shutdown.clicked.connect (() => {
            close ();
            show_shutdown_dialog ();
        });

        suspend.clicked.connect (() => {
            try {
                suspend_interface.suspend (true);
            } catch (IOError e) {
                stderr.printf ("%s\n", e.message);
            }
        });
    }

    public override void opened () {
        manager.update_all ();
    }

    public override void closed () {}

    private void show_shutdown_dialog () {
        if (shutdown_dialog == null) {
            shutdown_dialog = new Session.Widgets.EndSessionDialog (Session.Widgets.EndSessionDialogType.RESTART);
            shutdown_dialog.destroy.connect (() => { shutdown_dialog = null; });
            shutdown_dialog.set_transient_for (indicator_icon.get_toplevel () as Gtk.Window);
            shutdown_dialog.show_all ();
        }

        shutdown_dialog.present ();
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug ("Activating Sample Indicator");
    var indicator = new Session.Indicator (server_type);

    return indicator;
}
