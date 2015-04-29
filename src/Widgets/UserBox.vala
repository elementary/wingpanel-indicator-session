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

	private Session.Widgets.SoftLabel fullname_label;
	private Gtk.Label status_label;

	public Gdk.Pixbuf pixbuf;

	public Gtk.Image? image;

	public UserBox (string user, string fullname) {
		status = _("Logged In");

		var picture_frame = new Gtk.AspectFrame (null, 0, 0, 1, true);
		fullname_label = new Session.Widgets.SoftLabel (fullname, 10);
		status_label = new Gtk.Label (status);

		try {
			pixbuf = new Gdk.Pixbuf.from_file (@"/var/lib/AccountsService/icons/$user");
			image = new Gtk.Image.from_pixbuf (pixbuf.scale_simple (48, 48, Gdk.InterpType.BILINEAR));
		} catch (Error e) {
			warning (e.message);
		}

		fullname_label.get_style_context ().add_class ("h2");

		status_label.get_style_context ().add_class ("h3");
		status_label.xalign = 0;

		if (image != null)
			picture_frame.add (image);

		picture_frame.set_border_width (0);

		this.attach (picture_frame, 0, 0, 3, 3);
		this.attach (fullname_label, 3, 0, 2, 1);
		this.attach (status_label, 3, 1, 2, 1);

		this.set_margin_top (1);
		this.set_margin_bottom (5);
		this.set_margin_left (6);

		picture_frame.set_margin_right (6);
		picture_frame.set_margin_top (6);
		picture_frame.set_shadow_type (Gtk.ShadowType.ETCHED_OUT);
	}

	public void set_username (string username) {

	}

	public string get_username () {
		return username;
	}

	public void set_fullname (string fullname) {

	}

	public string get_fullname () {
		return fullname;
	}
}
