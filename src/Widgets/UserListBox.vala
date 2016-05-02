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

 public class Session.Widgets.UserListBox : Gtk.ListBox {
    private SeatInterface? seat = null;
    private string session_path;
    private bool has_guest;

    public UserListBox () {
        has_guest = false;
        session_path = Environment.get_variable ("XDG_SESSION_PATH");

        try {
            seat = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.DisplayManager", Environment.get_variable ("XDG_SEAT_PATH"), DBusProxyFlags.NONE);
        } catch (IOError e) {
            stderr.printf ("DisplayManager.Seat error: %s\n", e.message);
        }

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

        try {
            if (userbox.is_guest) {
                seat.switch_to_guest ("");
            } else {
                seat.switch_to_user (userbox.user.user_name, session_path);
            }            
        } catch (IOError e) {
            stderr.printf ("DisplayManager.Seat error: %s\n", e.message);
        }
    }
 }