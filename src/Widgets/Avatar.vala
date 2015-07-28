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

public class Session.Widgets.Avatar : Gtk.EventBox {

	private new int margin;

	private Gdk.Pixbuf pixbuf;

	public Avatar (Gdk.Pixbuf? pixbuf, int margin) {
		this.pixbuf = pixbuf;
		this.margin = margin;

		this.valign = Gtk.Align.START;
		this.visible_window = false;
		this.get_style_context ().add_class ("avatar");

		draw_connection ();
	}

	public void set_pixbuf (Gdk.Pixbuf pixbuf) {
		this.pixbuf = pixbuf;
		refresh_size_request ();
	}

	public void set_margin (int margin) {
		this.margin = margin;
		refresh_size_request ();
	}

	private void refresh_size_request () {
		this.set_size_request (pixbuf.width + 2 * margin, pixbuf.height + 2 * margin);
	}

	private void draw_connection () {
		this.draw.connect ((ctx) => {
			if (pixbuf != null) {
				debug (@"Redrawing CSS image...\n");

				int width = this.get_allocated_width () - this.margin * 2;
				int height = this.get_allocated_height () - this.margin * 2;

				var style_context = this.get_style_context ();
				var border_radius = style_context.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, Gtk.StateFlags.NORMAL);

				if (border_radius.get_int () >= width/2) {
					border_radius.set_int (width / 2);
				}

				Granite.Drawing.Utilities.cairo_rounded_rectangle
						(ctx, this.margin, this.margin, width, height, (int) border_radius);
				Gdk.cairo_set_source_pixbuf (ctx, this.pixbuf, this.margin, margin);
				ctx.fill_preserve ();
				style_context.render_background (ctx, this.margin, this.margin, width, height);
				style_context.render_frame (ctx, this.margin, this.margin, width, height);

			}

			return false;
		});
	}
}
