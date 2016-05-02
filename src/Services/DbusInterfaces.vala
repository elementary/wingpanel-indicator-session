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

/* To generate new UserBoxes for each user, and when a new one is added */
[DBus (name = "org.freedesktop.Accounts")]
interface AccountsInterface : Object {
    public abstract string[] list_cached_users () throws IOError;
    public signal void user_added (ObjectPath user_path);
    public signal void user_deleted (ObjectPath user_path);
}

/* Power and system control */
[DBus (name = "org.freedesktop.ScreenSaver")]
interface LockInterface : Object {
    public abstract void lock () throws IOError;
}

[DBus (name = "org.gnome.SessionManager")]
interface SessionInterface : Object {
    public signal void session_running ();
    public abstract void logout (uint mode) throws IOError;
}
[DBus (name = "org.freedesktop.login1.Manager")]
interface SystemInterface : Object {
    public abstract void suspend (bool interactive) throws IOError;
    public abstract void reboot (bool interactive) throws IOError;
    public abstract void power_off (bool interactive) throws IOError;

    public abstract string? get_user (uint32 uuid) throws IOError;
}

[DBus (name = "org.freedesktop.DisplayManager.Seat")]
interface SeatInterface : Object {
    //public abstract void SwitchToGreeter () throws IOError;
    public abstract void switch_to_guest (string session_name) throws IOError;
    public abstract void switch_to_user (string username, string session_name) throws IOError;
}

/* for User.vala, to get the user properties */
[DBus (name = "org.freedesktop.Accounts.User")]
interface UserInterface : Object {
    public signal void changed ();
}

[DBus (name = "org.freedesktop.DBus.Properties")]
interface PropertiesInterface : Object {
    public abstract Variant get (string interface, string propname) throws IOError;

    /* public abstract void Set (string interface, string propname, Variant value) throws IOError; */
    public signal void properties_changed ();
}
