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

public class ShutdownAction : Object {
    public signal void terminate_finished ();

    private const int KILL_TIMEOUT_SECONDS = 6;

    private uint source_id = 0U;
    private ulong window_closed_id = 0UL;

    private Wnck.Screen screen;

    construct {
        screen = Wnck.Screen.get_default ();
    }

    public async void run () {
        if (screen == null) {
            return;
        }

        window_closed_id = screen.window_closed.connect (() => {
            var _windows = filter_normal_windows (screen.get_windows ());
            if (_windows.size == 0) {
                window_closed_id = 0UL;
                Idle.add (run.callback);
            }
        });

        var windows = filter_normal_windows (screen.get_windows ());
        request_close_windows (windows);

        int seconds_passed = 1;
        source_id = Timeout.add_seconds (1, () => {
            if (seconds_passed == KILL_TIMEOUT_SECONDS) {
                var _windows = filter_normal_windows (screen.get_windows ());
                force_close_windows (_windows);

                Idle.add (run.callback);
                source_id = 0U;
                return false;
            }
            
            seconds_passed++;
            return true;
        });

        yield;

        stop ();
        terminate_finished ();
    }

    public void stop () {
        if (source_id != 0U) {
            Source.remove (source_id);
            source_id = 0U;
        }
        
        if (window_closed_id != 0UL) {
            screen.disconnect (window_closed_id);
            window_closed_id = 0UL;
        }
    }

    public static void logout () {
        try {
            LogoutInterface? logout_iface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1/user/self");
            logout_iface.terminate ();
        } catch (Error e) {
            warning (e.message);
        }
    }

    public static void shutdown () {
        try {
            SystemInterface? system_iface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
            system_iface.power_off (false);
        } catch (Error e) {
            warning (e.message);
        }
    }

    public static void reboot () {
        try {
            SystemInterface? system_iface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
            system_iface.reboot (false);
        } catch (Error e) {
            warning (e.message);
        }
    }

    private static Gee.ArrayList<Wnck.Window> filter_normal_windows (List<Wnck.Window> windows) {
        var filtered = new Gee.ArrayList<Wnck.Window> ();
        windows.@foreach ((window) => {
            if (window.get_window_type () == Wnck.WindowType.NORMAL) {
                filtered.add (window);
            }
        });

        return filtered;
    }

    private static void request_close_windows (Gee.ArrayList<Wnck.Window> windows) {
        foreach (var window in windows) {
            window.close (Gtk.get_current_event_time ());
        }
    }

    private static void force_close_windows (Gee.ArrayList<Wnck.Window> windows) {
        foreach (var window in windows) {
            Posix.kill ((Posix.pid_t)window.get_pid (), Posix.SIGKILL);
        }
    }
}