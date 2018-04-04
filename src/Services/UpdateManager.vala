/*
* Copyright (c) 2018 elementary LLC. (https://elementary.io)
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

public class Session.Services.UpdateManager : Object {
    public bool restart_required { public get; private set; default = false; }

    construct {
        check_file_existance ();

        var restart_folder = File.new_for_path ("/var/run/");

        try {
            var monitor = restart_folder.monitor_directory (FileMonitorFlags.NONE, null);
            monitor.changed.connect ((src, dest, event) => {
                check_file_existance ();
            });
        } catch (IOError e) {
            critical (e.message);
        }
    }

    private void check_file_existance () {
        var restart_file = File.new_for_path ("/var/run/reboot-required");
        if (restart_file.query_exists ()) {
            restart_required = true;
        } else if (restart_required) {
            restart_required = false;
        }
    }
}
