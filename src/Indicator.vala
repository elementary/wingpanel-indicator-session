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

public class Session.Indicator : Wingpanel.Indicator {
	private Wingpanel.Widgets.DynamicIcon dynamic_icon;

	private Wingpanel.Widgets.IndicatorButton lock_screen;
	private Wingpanel.Widgets.IndicatorButton log_out;
	private Wingpanel.Widgets.IndicatorButton suspend;
	private Wingpanel.Widgets.IndicatorButton shutdown;

	private Gtk.Grid main_grid;

	private const string icon_name = "system-devices-panel";

	private string user_name;
	private string full_name;

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

	public override Gtk.Widget get_widget () {
		if (main_grid == null) {
			main_grid = new Gtk.Grid ();
			main_grid.set_orientation (Gtk.Orientation.VERTICAL);

			log_out = new Wingpanel.Widgets.IndicatorButton ("Log Out");
			lock_screen = new Wingpanel.Widgets.IndicatorButton ("Lock");
			shutdown = new Wingpanel.Widgets.IndicatorButton ("Shutdown");
			suspend = new Wingpanel.Widgets.IndicatorButton ("Suspend");

			// FIXME Get the username and fullname form the system
			full_name = "Felipe Escoto";
			user_name = "felipe";

			var user_box = new Session.Widgets.UserBox (user_name, full_name);

			var separator1 = new Wingpanel.Widgets.IndicatorSeparator ();
			var separator2 = new Wingpanel.Widgets.IndicatorSeparator ();

			main_grid.add (user_box);
			main_grid.add (separator1);
			main_grid.add (lock_screen);
			main_grid.add (log_out);
			main_grid.add (separator2);
			main_grid.add (suspend);
			main_grid.add (shutdown);
		}

		this.visible = true;
		return main_grid;
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
