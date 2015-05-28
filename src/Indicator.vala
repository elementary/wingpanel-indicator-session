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
}

public class Session.Indicator : Wingpanel.Indicator {
	private SuspendManager suspend_manager;
	private LockManager lock_manager;
	private UserManager user_manager;

	private Wingpanel.Widgets.DynamicIcon dynamic_icon;

	private Wingpanel.Widgets.IndicatorButton lock_screen;
	private Wingpanel.Widgets.IndicatorButton log_out;
	private Wingpanel.Widgets.IndicatorButton suspend;
	private Wingpanel.Widgets.IndicatorButton shutdown;

	private Session.Widgets.UserBox user_box;

	private Gtk.Grid main_grid;

	private const string icon_name = "system-shutdown-symbolic";

	public Indicator () {
		Object (code_name: Wingpanel.Indicator.SESSION,
				display_name: _("Session"),
				description:_("The session indicator"));
	}

	public override Gtk.Widget get_display_widget () {
		if (dynamic_icon == null)
			dynamic_icon = new Wingpanel.Widgets.DynamicIcon (icon_name);

		return dynamic_icon;
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

			log_out = new Wingpanel.Widgets.IndicatorButton (_("Log Out"));
			lock_screen = new Wingpanel.Widgets.IndicatorButton (_("Lock"));
			shutdown = new Wingpanel.Widgets.IndicatorButton (_("Shutdown"));
			suspend = new Wingpanel.Widgets.IndicatorButton (_("Suspend"));

			user_box = new Session.Widgets.UserBox (GLib.Environment.get_real_name () + " ", GLib.Environment.get_user_name ());

			var separator1 = new Wingpanel.Widgets.IndicatorSeparator ();
			var separator2 = new Wingpanel.Widgets.IndicatorSeparator ();

			main_grid.add (user_box);
			get_users ();
			main_grid.add (separator1);
			main_grid.add (lock_screen);
			main_grid.add (log_out);
			main_grid.add (separator2);
			main_grid.add (suspend);
			main_grid.add (shutdown);

			main_grid.set_margin_top (6);

			connections ();
		}

		this.visible = true;
		return main_grid;
	}

	private void get_users () {
		try {
			user_manager = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.Accounts", "/org/freedesktop/Accounts", DBusProxyFlags.NONE);
		} catch (IOError e) {
			stderr.printf ("ERROR: %s\n", e.message);
		}

		var current_user = GLib.Environment.get_user_name ();
		var users = user_manager.ListCachedUsers ();

		foreach (string user_address in users) {
			var user = new Session.Services.User (user_address);
			user.update_properties ();
			user.update_properties ();

			if (user.user_name != current_user) {
				//TODO Check logged in users
				var userbox = new Session.Widgets.UserBox (user.real_name, user.user_name, user.user_pic, "Logged off");
				main_grid.add (userbox);
			}
		}
	}

	public void connections () {
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

	public override void opened () {

	}

	public override void closed () {

	}
}

public Wingpanel.Indicator get_indicator (Module module) {
	debug ("Activating Session Indicator");
	var indicator = new Session.Indicator ();
	return indicator;
}
