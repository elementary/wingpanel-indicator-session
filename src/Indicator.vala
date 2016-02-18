/*
 * Copyright (c) 2011-2015 Wingpanel Developers (http://launchpad.net/wingpanel)
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
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

public class Session.Indicator : Wingpanel.Indicator {
    private const string ICON_NAME = "system-shutdown-symbolic";

    private SystemInterface suspend_interface;
    private LockInterface lock_interface;
    private SeatInterface seat_interface;

    private Wingpanel.IndicatorManager.ServerType server_type;
    private Wingpanel.Widgets.OverlayIcon indicator_icon;
    private Wingpanel.Widgets.Button lock_screen;
    private Wingpanel.Widgets.Button log_out;
    private Wingpanel.Widgets.Button suspend;
    private Wingpanel.Widgets.Button shutdown;
    private Session.Services.UserManager manager;

    private Gtk.Grid main_grid;

    public Indicator (Wingpanel.IndicatorManager.ServerType server_type) {
        Object (code_name: Wingpanel.Indicator.SESSION,
                display_name: _("Session"),
                description: _("The session indicator"));
        this.server_type = server_type;
    }

    public override Gtk.Widget get_display_widget () {
        if (indicator_icon == null) {
            indicator_icon = new Wingpanel.Widgets.OverlayIcon (ICON_NAME);
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
                manager = new Session.Services.UserManager ();
                main_grid.add (manager.current_user);
                main_grid.add (manager.user_grid);

                if (manager.has_guest) {
                    manager.user_grid.add (manager.guest (false));
                }

                main_grid.add (new Wingpanel.Widgets.Separator ());
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

    public void connections () {
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
            var dialog = new Session.Widgets.EndSessionDialog (Session.Widgets.EndSessionDialogType.RESTART);
            dialog.set_transient_for (indicator_icon.get_toplevel () as Gtk.Window);
            dialog.show_all ();
        });

        suspend.clicked.connect (() => {
            close ();
            try {
                suspend_interface.suspend (true);
            } catch (IOError e) {
                stderr.printf ("%s\n", e.message);
            }
        });
    }

    public override void opened () {}

    public override void closed () {}
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug ("Activating Sample Indicator");
    var indicator = new Session.Indicator (server_type);

    return indicator;
}
