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

public class Session.Widgets.UserBox : Gtk.Grid {
	public string status;
	public string username;
	public string fullname;

	private Gtk.Label fullname_label;
	private Gtk.Label status_label;

	public Gdk.Pixbuf pixbuf;

	public Gtk.Image? image;

	public UserBox () {
		username = GLib.Environment.get_user_name ();
		fullname = GLib.Environment.get_real_name ();

		status = _(@"Logged In");

		var picture_frame = new Gtk.AspectFrame (null, 0, 0, 1, true);
		fullname_label = new Gtk.Label (fullname);
		status_label = new Gtk.Label (status);

		try {
			pixbuf = new Gdk.Pixbuf.from_file (@"/var/lib/AccountsService/icons/$username");
			image = new Gtk.Image.from_pixbuf (pixbuf.scale_simple (40, 40, Gdk.InterpType.BILINEAR));
		} catch (Error e) {
			image = new Gtk.Image.from_icon_name ("avatar-default", Gtk.IconSize.DIALOG);
			warning (e.message);
		}

		fullname_label.get_style_context ().add_class ("h3");
		fullname_label.valign = Gtk.Align.END;
		//status_label.get_style_context ().add_class ("h3");
		status_label.halign = Gtk.Align.START;

		if (image != null)
			picture_frame.add (image);

		picture_frame.set_border_width (0);

		this.attach (picture_frame, 0, 0, 3, 3);
		this.attach (fullname_label, 3, 0, 2, 1);
		this.attach (status_label, 3, 1, 2, 1);

		this.set_margin_top (0);
		this.set_margin_bottom (5);
		this.set_margin_start (6);
		this.set_margin_end (6);


		picture_frame.set_margin_right (6);
		picture_frame.set_margin_top (6);
		picture_frame.set_shadow_type (Gtk.ShadowType.ETCHED_OUT);
	}

	public static Act.UserManager? usermanager = null;

	public static unowned Act.UserManager? get_usermanager () {
		if (usermanager != null && usermanager.is_loaded)
			return usermanager;

		usermanager = Act.UserManager.get_default ();
		return usermanager;
	}

	public static Act.User? current_user = null;

	public static unowned Act.User? get_current_user () {
		if (current_user != null)
			return current_user;

		current_user = get_usermanager ().get_user (GLib.Environment.get_user_name ());
		return current_user;
	}

	public void update () {
		try {
			pixbuf = new Gdk.Pixbuf.from_file (@"/var/lib/AccountsService/icons/$username");
			image = new Gtk.Image.from_pixbuf (pixbuf.scale_simple (40, 40, Gdk.InterpType.BILINEAR));
		} catch (Error e){
			image = new Gtk.Image.from_icon_name ("avatar-default", Gtk.IconSize.DIALOG);
		}
	}
}
