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

public class Session.Services.User : Object {
    private static string ACCOUNTS_INTERFACE = "org.freedesktop.Accounts";
    private static string USER_INTERFACE = "org.freedesktop.Accounts.User";
    private static string LOGIN_INTERFACE = "org.freedesktop.login1";
    private static string MANAGER = "/org/freedesktop/login1";

    public string user_path { get; private set; }
    public string real_name { get; private set; }
    public string user_name { get; private set; }
    public string icon_file { get; private set; }
    public uint64 Uid { get; private set; }
    public bool locked { get; private set; }

    private UserInterface? user_interface = null;
    private PropertiesInterface? user_properties = null;
    private PropertiesInterface? state_properties = null;
    private SystemInterface? system_interface = null;

    public signal void properties_updated ();

    public User (string user_path_) {
        this.user_path = user_path_;

        connect_to_bus ();
        connect_signals ();
        update_properties ();
        get_state ();

    }

    private bool connect_to_bus () {
        try {
            system_interface = Bus.get_proxy_sync (BusType.SYSTEM, LOGIN_INTERFACE, MANAGER, DBusProxyFlags.NONE);
            user_interface = Bus.get_proxy_sync (BusType.SYSTEM, ACCOUNTS_INTERFACE, user_path, DBusProxyFlags.NONE);
            user_properties = Bus.get_proxy_sync (BusType.SYSTEM, ACCOUNTS_INTERFACE, user_path, DBusProxyFlags.NONE);

            update_properties ();
            string? user_object_path = system_interface.get_user ((uint32)Uid);
            state_properties = Bus.get_proxy_sync (BusType.SYSTEM, LOGIN_INTERFACE, user_object_path, DBusProxyFlags.NONE);

            debug ("Connection to user account established. User path: %s", user_object_path);

            return user_interface != null & user_properties != null;
        } catch (Error e) {
            critical ("Connecting to Accounts failed: %s", e.message);
            return false;
        }
    }

    private void connect_signals () {
        user_interface.changed.connect (update_properties);
        user_properties.properties_changed.connect (update_properties);
        state_properties.properties_changed.connect (update_properties);
    }

    public bool get_state () {
        bool state = false;

        try {
            string status = state_properties.get (LOGIN_INTERFACE + ".User", "State").get_string ();

            if (status == "active" || status == "online") {
                state = true;
            }
        } catch (Error e) {
            critical ("Could not get users' state: %s", e.message);
        }

        return state;
    }

    public void update_properties () {
        try {
            real_name = user_properties.get (USER_INTERFACE, "RealName").get_string ();
            user_name = user_properties.get (USER_INTERFACE, "UserName").get_string ();
            icon_file = user_properties.get (USER_INTERFACE, "IconFile").get_string ();
            locked = user_properties.get (USER_INTERFACE, "Locked").get_boolean ();
            Uid = user_properties.get (USER_INTERFACE, "Uid").get_uint64 ();

            if (real_name == "") {
                real_name = user_name;
            }

            properties_updated ();
        } catch (Error e) {
            critical ("Updating device properties failed: %s", e.message);
        }
    }
}
