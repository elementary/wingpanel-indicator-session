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

[DBus (name = "org.freedesktop.login1.Manager")]
interface SuspendManager : Object {
	public abstract void Suspend (bool interactive) throws IOError;
}

[DBus (name = "org.freedesktop.ScreenSaver")]
interface LockManager : Object {
	public abstract void Lock () throws IOError;
}

[DBus (name = "org.freedesktop.Accounts")]
interface UserManager : Object {
	public abstract string[] ListCachedUsers () throws IOError;
	public signal void UserAdded (string user_path);
}

public class Session.Indicator : Wingpanel.Indicator {
	private SuspendManager suspend_manager;
	private LockManager lock_manager;
	private UserManager user_manager;

	private Wingpanel.Widgets.OverlayIcon indicator_icon;
	//private Gtk.Label dynamic_icon;
	
	private Wingpanel.Widgets.Button lock_screen;
	private Wingpanel.Widgets.Button log_out;
	private Wingpanel.Widgets.Button suspend;
	private Wingpanel.Widgets.Button shutdown;

	private Wingpanel.Widgets.Separator separator1;
	private Wingpanel.Widgets.Separator separator2;

	private Gtk.Grid main_grid;

	private const string icon_name = "system-shutdown-symbolic";
	
	private Wingpanel.IndicatorManager.ServerType server_type;


	public Indicator (Wingpanel.IndicatorManager.ServerType server_type) {
		Object (code_name: Wingpanel.Indicator.SESSION,
				display_name: _("Session"),
				description:_("The session indicator"));
		this.server_type = server_type;
	}

	public override Gtk.Widget get_display_widget () {
		if (indicator_icon == null) {
			indicator_icon = new Wingpanel.Widgets.OverlayIcon (icon_name);
		}
		
		return indicator_icon;
	}

	public override Gtk.Widget? get_widget () {
		if (main_grid == null) {
			try {
				suspend_manager = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
			} catch (IOError e) {
				stderr.printf ("%s\n", e.message);
			}

			try {
				lock_manager = Bus.get_proxy_sync (BusType.SESSION, "org.freedesktop.ScreenSaver", "/org/freedesktop/ScreenSaver");
			} catch (IOError e) {
				stderr.printf ("%s\n", e.message);
				lock_screen.set_sensitive (false);
			}

			main_grid = new Gtk.Grid ();
			main_grid.set_orientation (Gtk.Orientation.VERTICAL);

			log_out = new Wingpanel.Widgets.Button (_("Log Out"));
			lock_screen = new Wingpanel.Widgets.Button (_("Lock"));
			shutdown = new Wingpanel.Widgets.Button (_("Shutdown"));
			suspend = new Wingpanel.Widgets.Button (_("Suspend"));

			separator1 = new Wingpanel.Widgets.Separator ();
			separator2 = new Wingpanel.Widgets.Separator ();
						
			if (server_type != Wingpanel.IndicatorManager.ServerType.GREETER) {
				get_users (); 
				main_grid.add (separator1); 
				main_grid.add (lock_screen);
				main_grid.add (log_out);
				main_grid.add (separator2);
			}
			
			main_grid.add (suspend);
			main_grid.add (shutdown);

			main_grid.set_margin_top (6);

			connections ();
		} 

		this.visible = true;
		return main_grid;
	}

	private void get_users () {
		string[] users;
		string current_user = GLib.Environment.get_user_name ();
		
		try {
			user_manager = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.Accounts", "/org/freedesktop/Accounts", DBusProxyFlags.NONE);
			
			users = user_manager.ListCachedUsers ();
			
			//look for current user's user adress			
			foreach (string user_address in users) {
				new_user (user_address, current_user, true);
			}
			
			//load the rest of the users
			foreach (string user_address in users) {
				new_user (user_address, current_user, false);
			}
			
		} catch (IOError e) {
			stderr.printf ("ERROR: %s\n", e.message);
		}
	}

	public void new_user (string user_address, string? current_user, bool searching, bool from_user_added = false) {
		var user = new Session.Services.User (user_address);
		
		user.update_properties ();
		user.update_properties ();
		
		var userbox = new Session.Widgets.UserBox (user.real_name, user.user_name, user.icon_file, "Logged off");
		
		user.properties_updated.connect (() => {
			if (user.locked == false) 
				userbox.visible = true;
			else 
				userbox.visible = false;
				
			userbox.update (user.real_name, user.icon_file);
			userbox.update_state (user.state);
		});
		
		user.update_properties ();
		
		if (searching == true && current_user == user.user_name) 
			main_grid.add (userbox);
		else if (searching == false && current_user != user.user_name)
			main_grid.add (userbox);
		else 
			userbox.destroy ();
			
	}

	public void connections () {
		user_manager.UserAdded.connect ((user_path) => {
			new_user (user_path, GLib.Environment.get_user_name (), false, true);
		});
	
		lock_screen.clicked.connect (() => {
			try {
				lock_manager.Lock ();
			} catch (IOError e) {
				stderr.printf ("%s\n", e.message);
			}
			close ();
		});

		log_out.clicked.connect (() => {
			new Session.Widgets.EndSessionDialog (Session.Widgets.EndSessionDialogType.LOGOUT);
			close ();
		});

		shutdown.clicked.connect (() => {
			new Session.Widgets.EndSessionDialog (Session.Widgets.EndSessionDialogType.RESTART);
			close ();
		});

		suspend.clicked.connect (() => {
			try {
				suspend_manager.Suspend (true);
			} catch (IOError e) {
				stderr.printf ("%s\n", e.message);
			}
			close ();
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
