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

public enum UserState {
    ACTIVE,
    ONLINE,
    OFFLINE;

    public static UserState to_enum (string state) {
        switch (state) {
            case "active":
                return UserState.ACTIVE;
            case "online":
                return UserState.ONLINE;
        }

        return UserState.OFFLINE;
    }
}

public class Session.Services.UserManager : Object {
    public signal void close ();

    private const string LOGIN_IFACE = "org.freedesktop.login1";
    private const string LOGIN_PATH = "/org/freedesktop/login1";

    private signal void delete_user (ObjectPath user_path);
    private Act.UserManager manager;
    private List<Widgets.Userbox> userbox_list;
    private SeatInterface dm_proxy;
    private Wingpanel.Widgets.Separator users_separator;

    public Session.Widgets.UserListBox user_grid;
    
    public bool has_guest { public get; private set; default = false; }

    private static SystemInterface? login_proxy;

    static construct {
        try {
            login_proxy = Bus.get_proxy_sync (BusType.SYSTEM, LOGIN_IFACE, LOGIN_PATH, DBusProxyFlags.NONE);
        } catch (IOError e) {
            stderr.printf ("UserManager error: %s\n", e.message);
        }        
    }

    public static UserState get_user_state (uint32 uuid) {
        if (login_proxy == null) {
            return UserState.OFFLINE;
        }

        try {
            ObjectPath? path = login_proxy.get_user (uuid);
            if (path == null) {
                return UserState.OFFLINE;
            }

            UserInterface? user = Bus.get_proxy_sync (BusType.SYSTEM, LOGIN_IFACE, path, DBusProxyFlags.NONE);
            if (user == null) {
                return UserState.OFFLINE;
            }

            return UserState.to_enum (user.state);
        } catch (IOError e) {
            stderr.printf ("Error: %s\n", e.message);
        }

        return UserState.OFFLINE;
    }

    public static UserState get_guest_state () {
        if (login_proxy == null) {
            return UserState.OFFLINE;
        }

        try {
            UserInfo[] users = login_proxy.list_users ();
            foreach (UserInfo user in users) {
                var state = get_user_state (user.uid);
                if (user.user_name.has_prefix ("guest-")
                    && state == UserState.ACTIVE) {
                    return UserState.ACTIVE;
                }
            }
        } catch (IOError e) {
            stderr.printf ("Error: %s\n", e.message);
        }

        return UserState.OFFLINE;
    }

    public UserManager (Wingpanel.Widgets.Separator users_separator) {
        this.users_separator = users_separator;
        this.users_separator.set_no_show_all (true);
        this.users_separator.visible = false;

        init ();
    }

    private void init () {
        userbox_list = new List<Widgets.Userbox> ();
        user_grid = new Session.Widgets.UserListBox ();
        user_grid.close.connect (() => {
            close ();
        });

        manager = Act.UserManager.get_default ();
        connect_signals ();
        init_users ();

        try {
            dm_proxy = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.DisplayManager", Environment.get_variable ("XDG_SEAT_PATH"), DBusProxyFlags.NONE);
            has_guest = dm_proxy.has_guest_account;
        } catch (IOError e) {
            stderr.printf ("UserManager error: %s\n", e.message);
        }
    }

    private void connect_signals () {
        manager.user_added.connect (add_user);
        manager.user_removed.connect (remove_user);
        manager.user_is_logged_in_changed.connect (update_user);

        manager.notify["is-loaded"].connect (() => {
            if (manager.is_loaded) {
                init_users ();
            }
        });  
    }

    private void init_users () {
        foreach (Act.User user in manager.list_users ()) {
            add_user (user);
        }
    }

    private void add_user (Act.User user) {
        var userbox = new Session.Widgets.Userbox (user);
        userbox_list.append (userbox);

        user_grid.add (userbox);

        users_separator.visible = true;
    }

    private Widgets.Userbox? get_userbox_from_user (Act.User user) {
        foreach (Widgets.Userbox userbox in userbox_list) {
            if (userbox.user.get_user_name () == user.get_user_name ()) {
                return userbox;
            }
        } 

        return null;       
    }

    private void remove_user (Act.User user) {
        var userbox = get_userbox_from_user (user);
        if (userbox == null) {
            return;
        }

        userbox_list.remove (userbox);
        user_grid.remove (userbox);
    }

    private void update_user (Act.User user) {
        var userbox = get_userbox_from_user (user);
        if (userbox == null) {
            return;
        }

        userbox.update_state ();
    }

    public void update_all () {
        foreach (var userbox in userbox_list) {
            userbox.update_state ();
        }
    }

    public void add_guest (bool logged_in) {
        var userbox = new Session.Widgets.Userbox.from_data (_("Guest"), logged_in, true);
        userbox_list.append (userbox);
        userbox.visible = true;

        user_grid.add_guest (userbox);

        users_separator.visible = true;
    }
}
