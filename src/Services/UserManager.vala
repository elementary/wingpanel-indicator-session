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

public class Session.Services.UserManager : Object {
    private signal void delete_user (ObjectPath user_path);
    private AccountsInterface accounts_interface;
    private PropertiesInterface state_properties;

    public Gtk.Grid user_grid;
    public Session.Widgets.Userbox current_user;
    
    public bool has_guest {public get; private set; default = false;}

    public UserManager () {
        init ();
    }

    private void init () {
        user_grid = new Gtk.Grid ();
        user_grid.set_orientation (Gtk.Orientation.VERTICAL);

        try {
            accounts_interface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.Accounts", "/org/freedesktop/Accounts", DBusProxyFlags.NONE);
            state_properties = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.DisplayManager", "/org/freedesktop/DisplayManager/Seat0", DBusProxyFlags.NONE);
            has_guest = state_properties.get ("org.freedesktop.DisplayManager.Seat", "HasGuestAccount").get_boolean ();

            connect_signals ();
            init_users ();
        } catch (IOError e) {
            stderr.printf ("UserManager error: %s\n", e.message);
        }
    }

    private void connect_signals () {
        accounts_interface.user_added.connect ((user_path) => {
            var user = new_user (user_path);

            if (user != null) {
                user_grid.add (user);
            }
        });

        accounts_interface.user_deleted.connect ((user_path) => {
            delete_user (user_path);
        });
    }

    private void init_users () {
        string current_user = GLib.Environment.get_user_name ();

        try {
            var users = accounts_interface.list_cached_users ();
            foreach (string user_address in users) {
                var userbox = new_user (user_address);

                if (userbox.user.user_name == current_user) {
                    this.current_user = userbox;
                } else {
                    user_grid.add (userbox);
                }
            }
        } catch (IOError e) {
            stderr.printf ("ERROR: %s\n", e.message);
        }
    }

    private Session.Widgets.Userbox new_user (string user_address) {
        var user = new Session.Services.User (user_address);
        var userbox = new Session.Widgets.Userbox (user);

        delete_user.connect ((user_path) => {
            if (userbox.user.user_path == user_path) {
                user_grid.remove (userbox);
            }
        });

        return userbox;
    }

    public Session.Widgets.Userbox guest (bool logged_in) {
        var userbox = new Session.Widgets.Userbox.from_data (_("Guest"), logged_in);
        userbox.visible = true;

        return userbox;
    }
}
