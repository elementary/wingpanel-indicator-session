/*
 * Copyright (c) 2011-2015 Wingpanel Developers (http://launchpad.net/wingpanel)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

public class Session.Widgets.Userbox : Gtk.Grid {
    private const string LOGGED_IN = _("Logged in");
    private const string LOGGED_OFF = _("Logged out");

    private const int ICON_SIZE = 42;

    private string iconfile = null;
    public string user_path = null;

    private Granite.Widgets.Avatar avatar;
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
        avatar = new Granite.Widgets.Avatar ();
        try {
            var pixbuf = new Gdk.Pixbuf.from_file (iconfile);
            pixbuf = pixbuf.scale_simple (ICON_SIZE, ICON_SIZE, Gdk.InterpType.BILINEAR);
            avatar.pixbuf = pixbuf;
            avatar.set_margin_start (8);
            avatar.set_margin_end (8);
        } catch (Error e) {
            avatar.show_default (ICON_SIZE + 4);
            avatar.set_margin_start (6);
            avatar.set_margin_end (6);
        }

        this.attach (avatar, 0, 0, 3, 3);
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
            avatar.pixbuf = pixbuf;
            avatar.set_margin_start (8);
            avatar.set_margin_end (8);
        } catch (Error e) {
            avatar.show_default (ICON_SIZE + 4);
            avatar.set_margin_start (6);
            avatar.set_margin_end (6);
        }
    }

    public void update_state (bool logged_in) {
        if (logged_in) {
            status_label.label = LOGGED_IN;
        } else {
            status_label.label = LOGGED_OFF;
        }
    }
}