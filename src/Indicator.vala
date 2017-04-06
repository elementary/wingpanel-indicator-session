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

    private SystemInterface suspend_interface;
    private LockInterface lock_interface;
    private SeatInterface seat_interface;

    private Wingpanel.IndicatorManager.ServerType server_type;
    private Wingpanel.Widgets.OverlayIcon indicator_icon;
    private Wingpanel.Widgets.Separator users_separator;
    private Wingpanel.Widgets.Button lock_screen;
    private Wingpanel.Widgets.Button log_out;
    private Wingpanel.Widgets.Button suspend;
    private Wingpanel.Widgets.Button shutdown;
    private Wingpanel.Widgets.Button? settings = null;
    private GLib.AppInfo? settings_appinfo;

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

            log_out = new Wingpanel.Widgets.Button (_("Log Out…"));
            lock_screen = new Wingpanel.Widgets.Button (_("Lock"));
            shutdown = new Wingpanel.Widgets.Button (_("Shutdown…"));
            suspend = new Wingpanel.Widgets.Button (_("Suspend"));

            if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION) {
                users_separator = new Wingpanel.Widgets.Separator ();
                manager = new Session.Services.UserManager (users_separator);

                var scrolled_box = new Wingpanel.Widgets.AutomaticScrollBox (null, null);
                scrolled_box.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
                scrolled_box.add (manager.user_grid);

                main_grid.add (scrolled_box);

                if (manager.has_guest) {
                    manager.add_guest (false);
                }

                main_grid.add (users_separator);

                settings_appinfo = GLib.AppInfo.get_default_for_uri_scheme ("settings");
                if (settings_appinfo != null) {
                    settings = new Wingpanel.Widgets.Button (settings_appinfo.get_display_name ());
                    main_grid.add (settings);
                    main_grid.add (new Wingpanel.Widgets.Separator ());
                }

                main_grid.add (lock_screen);
                main_grid.add (log_out);
                main_grid.add (new Wingpanel.Widgets.Separator ());
            }

            main_grid.add (suspend);
            main_grid.add (shutdown);
            main_grid.margin_top = 6;

            connections ();
        }

        this.visible = true;

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

        lock_screen.clicked.connect (() => {
            close ();
            try {
                lock_interface.lock ();
            } catch (IOError e) {
                stderr.printf ("%s\n", e.message);
            }
        });

        log_out.clicked.connect (() => {
            close ();
            var dialog = new Session.Widgets.EndSessionDialog (Session.Widgets.EndSessionDialogType.LOGOUT);
            dialog.set_transient_for (indicator_icon.get_toplevel () as Gtk.Window);
            dialog.show_all ();
        });

        shutdown.clicked.connect (() => {
            close ();
            show_shutdown_dialog ();
        });

        suspend.clicked.connect (() => {
            close ();
            try {
                suspend_interface.suspend (true);
            } catch (IOError e) {
                stderr.printf ("%s\n", e.message);
            }
        });

        if (settings != null && settings_appinfo != null) {
            settings.clicked.connect (() => {
                close ();
                try {
                    settings_appinfo.launch (null, null);
                } catch (Error e) {
                    warning (e.message);
                }
            });
        }
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
