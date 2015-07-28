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

public class Session.Widgets.Userbox : Gtk.Grid {
	private const string LOGGED_IN = _("Logged in");
	private const string LOGGED_OFF = _("Logged out");

	private const int ICON_SIZE = 42;

	private string iconfile = null;
	public string user_path = null;

	private Session.Widgets.Avatar avatar;
	private Gtk.Label fullname_label;
	private Gtk.Label status_label;

	public Gtk.Image? image;

	public Userbox (string user_path, string fullname, string username, string iconfile_ = "") {
		debug (@"Creating userbox for: $fullname : $username\n");

		this.user_path = user_path;

		if (iconfile_ == "") {
			iconfile = @"/var/lib/AccountsService/icons/$username";
		} else {
			iconfile = iconfile_;
		}

		fullname_label = new Gtk.Label ("<b>" + fullname + "</b>");

		fullname_label.use_markup = true;
		fullname_label.get_style_context ().add_class ("h3");
		fullname_label.valign = Gtk.Align.END;
		fullname_label.halign = Gtk.Align.START;

		status_label = new Gtk.Label (LOGGED_OFF);
		status_label.halign = Gtk.Align.START;

		try {
			var pixbuf = new Gdk.Pixbuf.from_file (iconfile);
			pixbuf = pixbuf.scale_simple (ICON_SIZE, ICON_SIZE, Gdk.InterpType.BILINEAR);
			avatar = new Session.Widgets.Avatar (pixbuf, 12);
			this.attach (avatar, 0, 0, 3, 3);

		} catch (Error e) {
			image = new Gtk.Image.from_icon_name ("avatar-default", Gtk.IconSize.DIALOG);
			this.attach (image, 0, 0, 3, 3);
		}

		image.set_margin_end (9);
		image.set_margin_start (9);

		this.attach (fullname_label, 3, 0, 2, 1);
		this.attach (status_label, 3, 1, 2, 1);

		this.set_margin_top (0);
		this.set_margin_bottom (0);
		this.set_margin_start (0);
		this.set_margin_end (0);
	}

	public void update (string? fullname, string icon) {
		this.fullname_label.set_label ("<b>" + fullname + "</b>");

		try {
			var pixbuf = new Gdk.Pixbuf.from_file (icon);
			pixbuf = pixbuf.scale_simple (ICON_SIZE, ICON_SIZE, Gdk.InterpType.BILINEAR);
			avatar.set_pixbuf (pixbuf);

		} catch (Error e){
			image.set_from_icon_name ("avatar-default", Gtk.IconSize.DIALOG);
		}
	}

	public void update_state (bool logged_in) {
		if (logged_in)
			status_label.label = LOGGED_IN;
		else
			status_label.label = LOGGED_OFF;
	}
}
