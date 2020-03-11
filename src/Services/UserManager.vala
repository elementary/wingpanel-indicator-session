/*
 * Copyright (c) 2011-2020 elementary, Inc. (https://elementary.io)
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

    public Session.Widgets.UserListBox user_grid { get; private set; }
    public Wingpanel.Widgets.Separator users_separator { get; construct; }

    private const uint NOBODY_USER_UID = 65534;
    private const uint RESERVED_UID_RANGE_END = 1000;

    private const string DM_DBUS_ID = "org.freedesktop.DisplayManager";
    private const string LOGIN_IFACE = "org.freedesktop.login1";
    private const string LOGIN_PATH = "/org/freedesktop/login1";

    private Act.UserManager manager;
    private List<Widgets.Userbox> userbox_list;
    private SeatInterface? dm_proxy = null;

    private static SystemInterface? login_proxy;

    static construct {
        try {
            login_proxy = Bus.get_proxy_sync (BusType.SYSTEM, LOGIN_IFACE, LOGIN_PATH, DBusProxyFlags.NONE);
        } catch (IOError e) {
            critical ("Failed to create login1 dbus proxy: %s", e.message);
        }
    }

    public static UserState get_user_state (uint32 uuid) {
        if (login_proxy == null) {
            return UserState.OFFLINE;
        }

        try {
            UserInfo[] users = login_proxy.list_users ();
            if (users == null) {
                return UserState.OFFLINE;
            }

            foreach (UserInfo user in users) {
                if (user.uid == uuid) {
                    if (user.user_object == null) {
                        return UserState.OFFLINE;
                    }
                    UserInterface? user_interface = Bus.get_proxy_sync (BusType.SYSTEM, LOGIN_IFACE, user.user_object, DBusProxyFlags.NONE);
                    if (user_interface == null) {
                        return UserState.OFFLINE;
                    }
                    return UserState.to_enum (user_interface.state);
                }
            }

        } catch (GLib.Error e) {
            critical ("Failed to get user state: %s", e.message);
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
        } catch (GLib.Error e) {
            critical ("Failed to get Guest state: %s", e.message);
        }

        return UserState.OFFLINE;
    }

    public UserManager (Wingpanel.Widgets.Separator users_separator) {
        Object (users_separator: users_separator);
    }

    construct {
        userbox_list = new List<Widgets.Userbox> ();

        users_separator.no_show_all = true;
        users_separator.visible = false;

        user_grid = new Session.Widgets.UserListBox ();
        user_grid.close.connect (() => close ());

        manager = Act.UserManager.get_default ();
        init_users ();

        manager.user_added.connect (add_user);
        manager.user_removed.connect (remove_user);
        manager.user_is_logged_in_changed.connect (update_user);

        manager.notify["is-loaded"].connect (() => {
            init_users ();
        });

        var seat_path = Environment.get_variable ("XDG_SEAT_PATH");

        if (seat_path != null) {
            try {
                dm_proxy = Bus.get_proxy_sync (BusType.SYSTEM, DM_DBUS_ID, seat_path, DBusProxyFlags.NONE);
                if (dm_proxy.has_guest_account) {
                    add_guest ();
                }
            } catch (IOError e) {
                critical ("UserManager error: %s", e.message);
            }
        }
    }

    private void init_users () {
        if (!manager.is_loaded) {
            return;
        }

        foreach (Act.User user in manager.list_users ()) {
            add_user (user);
        }
    }

    private void add_user (Act.User? user) {
        // Don't add any of the system reserved users
        var uid = user.get_uid ();
        if (uid < RESERVED_UID_RANGE_END || uid == NOBODY_USER_UID) {
            return;
        }

        var userbox = new Session.Widgets.Userbox (user);
        userbox_list.append (userbox);
        user_grid.add (userbox);

        users_separator.visible = true;
    }

    private Widgets.Userbox? get_userbox_from_user (Act.User user) {
        foreach (Widgets.Userbox userbox in userbox_list) {
            var _user = userbox.user;
            if (_user == null) {
                continue;
            }

            if (_user.get_user_name () == user.get_user_name ()) {
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

    private void add_guest () {
        var userbox = new Session.Widgets.Userbox.guest ();
        userbox_list.append (userbox);
        userbox.visible = true;

        user_grid.add_guest (userbox);

        users_separator.visible = true;
    }
}
