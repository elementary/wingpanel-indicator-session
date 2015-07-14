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

	private const int ICON_SIZE = 48;
	private const int MAX_WIDTH_TITLE = 200;

	private string status = "";
	private string iconfile = null;
	public string user_path = null;

	private Gtk.Label fullname_label;
	private Gtk.Label status_label;

	public Gdk.Pixbuf pixbuf;
	public Gdk.Pixbuf pixbuf_mask;

	public Gtk.Image? image;
	public Gtk.Image? image_mask;
	public Gtk.Overlay overlay;
	public Gtk.EventBox imagebox ;

	public Userbox (string user_path, string fullname, string username, string iconfile_ = "") {
		//stderr.printf (@"Found user: $fullname : $username\n");
		this.user_path = user_path;
		this.imagebox = new Gtk.EventBox ();

		if (iconfile_ == "") {
			iconfile = @"/var/lib/AccountsService/icons/$username";
		} else {
			iconfile = iconfile_;
		}


		fullname_label = new Gtk.Label ("<b>" + fullname + "</b>");
		status_label = new Gtk.Label (status);

		fullname_label.use_markup = true;
		fullname_label.get_style_context ().add_class ("h3");
		fullname_label.valign = Gtk.Align.END;
		fullname_label.halign = Gtk.Align.START;

		try {
			pixbuf = new Gdk.Pixbuf.from_file (iconfile);
			this.attach (imagebox, 0, 0, 3, 3);
		} catch (Error e) {
			image = new Gtk.Image.from_icon_name ("avatar-default", Gtk.IconSize.DIALOG);
			this.attach (image, 0, 0, 3, 3);
		}

		status_label.halign = Gtk.Align.START;
		image.set_margin_end (12);
		image.set_margin_start (12);

		this.attach (fullname_label, 3, 0, 2, 1);
		this.attach (status_label, 3, 1, 2, 1);

		this.set_margin_top (0);
		this.set_margin_bottom (0);
		this.set_margin_start (0);
		this.set_margin_end (0);
	}

	public void avatar (Gdk.Pixbuf image) {
		int MARGIN = 12;

		if (image != null) {
			imagebox.set_size_request (image.width + 2 * MARGIN, image.height + 2 * MARGIN);

       	 	imagebox.valign = Gtk.Align.START;
       		imagebox.visible_window = false;

			imagebox.get_style_context ().add_class ("avatar");

			imagebox.draw.connect ((ctx) => {
				int width = imagebox.get_allocated_width () - MARGIN * 2;
				int height = imagebox.get_allocated_height () - MARGIN * 2;

				var style_context = imagebox.get_style_context ();
				var border_radius = style_context.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, Gtk.StateFlags.NORMAL);
				if (border_radius.get_int () >= width/2) {
					border_radius.set_int (width / 2);
				}

				Granite.Drawing.Utilities.cairo_rounded_rectangle (ctx, MARGIN, MARGIN, width, height, (int) border_radius);
				Gdk.cairo_set_source_pixbuf (ctx, image, MARGIN, MARGIN);
				ctx.fill_preserve ();
				style_context.render_background (ctx, MARGIN, MARGIN, width, height);
				style_context.render_frame (ctx, MARGIN, MARGIN, width, height);

				return false;
			});
		}
	}

	public void update (string? fullname, string icon) {
		this.fullname_label.set_label ("<b>" + fullname + "</b>");

		try {
			pixbuf = new Gdk.Pixbuf.from_file (icon);
			avatar (pixbuf.scale_simple (ICON_SIZE, ICON_SIZE, Gdk.InterpType.BILINEAR));
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
