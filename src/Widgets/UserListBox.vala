/*
 * Copyright (c) 2011-2017 elementary LLC. (http://launchpad.net/wingpanel)
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
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

 public class Session.Widgets.UserListBox : Gtk.ListBox {
    public signal void close ();

    private SeatInterface? seat = null;
    private string session_path;
    private bool has_guest;

    private const string DM_DBUS_ID = "org.freedesktop.DisplayManager";

    public UserListBox () {
        has_guest = false;
        selection_mode = Gtk.SelectionMode.NONE;
        session_path = Environment.get_variable ("XDG_SESSION_PATH");

        var seat_path = Environment.get_variable ("XDG_SEAT_PATH");
        if (seat_path != null) {
            try {
                seat = Bus.get_proxy_sync (BusType.SYSTEM, DM_DBUS_ID, seat_path, DBusProxyFlags.NONE);
            } catch (IOError e) {
                stderr.printf ("DisplayManager.Seat error: %s\n", e.message);
            }
        }

        this.set_sort_func (sort_func);
        this.set_activate_on_single_click (true);
    }

    public void add_guest (Userbox user) {
        if (!has_guest) {
            this.add (user);
            has_guest = true;
        }
    }

    public override void row_activated (Gtk.ListBoxRow row) {
        var userbox = (Userbox)row;
        if (userbox == null
            || seat == null
            || session_path == "") {
            return;
        }

        close ();
        try {
            if (userbox.is_guest) {
                seat.switch_to_guest ("");
            } else {
                var user = userbox.user;
                if (user != null) {
                    seat.switch_to_user (user.get_user_name (), session_path);
                }
            }
        } catch (GLib.Error e) {
            stderr.printf ("DisplayManager.Seat error: %s\n", e.message);
        }
    }

    // We could use here Act.User.collate () but we want to show the logged user first
    public int sort_func (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        var userbox1 = (Userbox)row1;
        var userbox2 = (Userbox)row2;

        if (userbox1.get_user_state () == UserState.ACTIVE) {
            return -1;
        } else if (userbox2.get_user_state () == UserState.ACTIVE) {
            return 1;
        }

        if (userbox1.is_guest && !userbox2.is_guest) {
            return 1;
        } else if (!userbox1.is_guest && userbox2.is_guest) {
            return -1;
        }

        return 0;
    }
}
