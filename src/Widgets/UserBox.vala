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

	public Userbox (string user_path, string fullname, string username, string iconfile_ = "") {
		//stderr.printf (@"Found user: $fullname : $username\n");
		this.user_path = user_path;
		
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
			image = new Gtk.Image.from_pixbuf ( mask_pixbuf (pixbuf));

		} catch (Error e) {
			image = new Gtk.Image.from_icon_name ("avatar-default", Gtk.IconSize.DIALOG);
		}

		status_label.halign = Gtk.Align.START;
		image.set_margin_end (6);

		this.attach (image, 0, 0, 3, 3);
		this.attach (fullname_label, 3, 0, 2, 1);
		this.attach (status_label, 3, 1, 2, 1);

		this.set_margin_top (0);
		this.set_margin_bottom (0);
		this.set_margin_start (3);
		this.set_margin_end (0);
	}

	public Gdk.Pixbuf? mask_pixbuf (Gdk.Pixbuf pixbuf) {
        var size = ICON_SIZE;
        var mask_offset = 4;
        var mask_size_offset = mask_offset * 2;
        var mask_size = ICON_SIZE;
        var offset_x = mask_offset;
        var offset_y = mask_offset + 1;
        size = size - mask_size_offset;

        var input = pixbuf.scale_simple (size, size, Gdk.InterpType.BILINEAR);
        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, mask_size, mask_size);
        var cr = new Cairo.Context (surface);

        Granite.Drawing.Utilities.cairo_rounded_rectangle (cr,
            offset_x, offset_y, size, size, 4);
        cr.clip ();

        Gdk.cairo_set_source_pixbuf (cr, input, offset_x, offset_y);
        cr.paint ();

        cr.reset_clip ();

        var mask = new Cairo.ImageSurface.from_png ("/usr/share/gala/image-mask.png");
        cr.set_source_surface (mask, 0, 0);
        cr.paint ();

        return Gdk.pixbuf_get_from_surface (surface, 0, 0, mask_size, mask_size);
    }

	public void update (string? fullname, string icon) {
		this.fullname_label.set_label ("<b>" + fullname + "</b>");
				
		try {
			pixbuf = new Gdk.Pixbuf.from_file (icon);
			image.set_from_pixbuf (mask_pixbuf (pixbuf));
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
