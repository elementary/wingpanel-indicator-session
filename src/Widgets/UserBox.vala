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
	private const string LOGGED_IN = _("Logged in");
	private const string LOGGED_OFF = _("Logged out");

	public string status = null;
	public string username = null;
	public string fullname = null;
	public string iconfile = null;

	private Gtk.Label fullname_label;
	private Gtk.Label status_label;

	public Gdk.Pixbuf pixbuf;

	public Gtk.Image? image;

	public UserBox (string fullname_, string username_, string iconfile_ = "", string status = "Logged in") {
		fullname = fullname_;
		username = username_;

		if (iconfile_ == "")
			iconfile = @"/var/lib/AccountsService/icons/$username";
		else
			iconfile = iconfile_;

		this.status = status;

		fullname_label = new Gtk.Label ("<b>" + fullname + "</b>");
		status_label = new Gtk.Label (status);

		try {
			pixbuf = new Gdk.Pixbuf.from_file (iconfile);
			image = new Gtk.Image.from_pixbuf (pixbuf.scale_simple (40, 40, Gdk.InterpType.BILINEAR));

		} catch (Error e) {
			image = new Gtk.Image.from_icon_name ("avatar-default", Gtk.IconSize.DIALOG);
		}

		fullname_label.use_markup = true;
		fullname_label.get_style_context ().add_class ("h3");
		fullname_label.valign = Gtk.Align.END;
		fullname_label.halign = Gtk.Align.START;

		status_label.halign = Gtk.Align.START;

		image.set_margin_right (6);
		image.set_margin_top (6);

		this.attach (image, 0, 0, 3, 3);
		this.attach (fullname_label, 3, 0, 2, 1);
		this.attach (status_label, 3, 1, 2, 1);

		this.set_margin_top (0);
		this.set_margin_bottom (5);
		this.set_margin_start (6);
		this.set_margin_end (6);
	}

	public void update (string? name, string icon) {
		this.fullname_label.label = "<b>" + name + "</b>";
		
		try {
			pixbuf = new Gdk.Pixbuf.from_file (icon);
			image.set_from_pixbuf (pixbuf.scale_simple (40, 40, Gdk.InterpType.BILINEAR));
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
