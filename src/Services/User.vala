/*-
 * Copyright (c) 2015 Wingpanel Developers (http://launchpad.net/wingpanel)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class Session.Services.User : Object {
	private const string ACCOUNTS_INTERFACE = "org.freedesktop.Accounts";
	private const string USER_INTERFACE = "org.freedesktop.Accounts.User";
	private const string LOGIN_INTERFACE = "org.freedesktop.login1";
	private const string STATE = "/org/freedesktop/login1/user/";

	private string user_path;
	public string real_name;
	public string user_name;
	public string icon_file;
	public uint64 Uid;
	public bool state;
	public bool locked;

	private UserInterface? user = null;
	private Properties? user_properties = null;
	private Properties? state_properties = null;

	public signal void properties_updated ();

	public User (string user_path_) {
		this.user_path = user_path_;

		if (connect_to_bus ()) {
			update_properties ();
			get_state ();
			connect_signals ();
		}
	}

	private bool connect_to_bus () {
		try {
			user = Bus.get_proxy_sync (BusType.SYSTEM, ACCOUNTS_INTERFACE, user_path, DBusProxyFlags.NONE);
			user_properties = Bus.get_proxy_sync (BusType.SYSTEM, ACCOUNTS_INTERFACE, user_path, DBusProxyFlags.NONE);

			debug ("Connection to user account established");

			return user != null & user_properties != null;;
		} catch (Error e) {
			critical ("Connecting to Accounts failed: %s", e.message);

			return false;
		}
	}

	private void connect_signals () {
		user.Changed.connect (update_properties);
		user_properties.PropertiesChanged.connect (update_properties);
		state_properties.PropertiesChanged.connect (update_properties);
	}

	public bool get_state () {
		string status;
		
		if (state_properties == null) {
			try {
				state_properties = Bus.get_proxy_sync (BusType.SYSTEM, LOGIN_INTERFACE, STATE + Uid.to_string (), DBusProxyFlags.NONE);
				
			} catch (Error e) {
				return false;
			}
		} 
		
		try {
			status = state_properties.Get (LOGIN_INTERFACE + ".User", "State").get_string ();	
		} catch (Error e) {
			return false;
		}
		
		if (status == "active" || status == "online") 
			return true;
		else 
			return false;
	}

	public void update_properties () {
		try {
			real_name = user_properties.Get (USER_INTERFACE, "RealName").get_string ();
			user_name = user_properties.Get (USER_INTERFACE, "UserName").get_string ();
			icon_file  = user_properties.Get (USER_INTERFACE, "IconFile").get_string ();
			locked  = user_properties.Get (USER_INTERFACE, "Locked").get_boolean ();
			Uid = user_properties.Get (USER_INTERFACE, "Uid").get_uint64 ();
			state = get_state ();
			properties_updated ();
		} catch (Error e) {
			critical ("Updating device properties failed: %s", e.message);
		}
	}
}
