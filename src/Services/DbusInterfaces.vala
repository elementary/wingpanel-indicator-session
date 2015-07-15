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

// To generate new UserBoxes for each user, and when a new one is added
[DBus (name = "org.freedesktop.Accounts")]
interface UserManager : Object {
	public abstract string[] ListCachedUsers () throws IOError;
	public signal void UserAdded (ObjectPath user_path);
	public signal void UserDeleted (ObjectPath user_path);
}

// Power and system control
[DBus (name = "org.freedesktop.ScreenSaver")]
interface LockManager : Object {
	public abstract void Lock () throws IOError;
}

[DBus (name = "org.gnome.SessionManager")]
interface SessionManager : Object {
	public signal void SessionRunning ();
	public abstract void Logout (uint mode) throws IOError;
}
[DBus (name = "org.freedesktop.login1.Manager")]
interface SystemManager : Object {
	public abstract void Suspend (bool interactive) throws IOError;
	public abstract void Reboot (bool interactive) throws IOError;
	public abstract void PowerOff (bool interactive) throws IOError;
}

[DBus (name = "org.freedesktop.DisplayManager.Seat")]
interface SeatManager : Object {
	//public abstract void SwitchToGreeter () throws IOError;
	//public abstract void SwitchToGuest (string session_name) throws IOError;
	//public abstract void SwitchToUser (string username, string session_name) throws IOError;
}

// for User.vala, to get the user properties
[DBus (name = "org.freedesktop.Accounts.User")]
interface UserInterface : Object {
	public signal void Changed ();
}

[DBus (name = "org.freedesktop.DBus.Properties")]
interface Properties : Object {
	public abstract Variant Get (string interface, string propname) throws IOError;
	//public abstract void Set (string interface, string propname, Variant value) throws IOError;
	public signal void PropertiesChanged ();
}

