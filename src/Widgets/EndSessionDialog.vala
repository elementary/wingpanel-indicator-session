/*
 * Copyright (c) 2011-2015 Tom Beckmann
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

/*
 * docs taken from unity indicator-session's
 * src/backend-dbus/org.gnome.SessionManager.EndSessionDialog.xml
 */
public enum Session.Widgets.EndSessionDialogType {
    LOGOUT = 0,
    SHUTDOWN = 1,
    RESTART = 2
}

public class Session.Widgets.EndSessionDialog : Gtk.Dialog {
    private LogoutInterface logout_interface;
    private SystemInterface system_interface;

    public EndSessionDialogType dialog_type { get; construct; }

    public EndSessionDialog (Session.Widgets.EndSessionDialogType type) {
        Object (
            dialog_type: type,
            title: "",
            deletable: false,
            resizable: false,
            skip_taskbar_hint: true,
            skip_pager_hint: true,
            type_hint: Gdk.WindowTypeHint.DIALOG
        );
    }

    construct {
        try {
            if (dialog_type == Session.Widgets.EndSessionDialogType.LOGOUT) {
                logout_interface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1/user/self");
            } else {
                system_interface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
            }
        } catch (IOError e) {
            stderr.printf ("%s\n", e.message);
        }

        string icon_name, heading_text, button_text, content_text;

        switch (dialog_type) {
            case EndSessionDialogType.LOGOUT:
                icon_name = "system-log-out";
                heading_text = _("Are you sure you want to Log Out?");
                content_text = _("This will close all open applications.");
                button_text = _("Log Out");
                break;
            case EndSessionDialogType.SHUTDOWN:
            case EndSessionDialogType.RESTART:
                icon_name = "system-shutdown";
                heading_text = _("Are you sure you want to Shut Down?");
                content_text = _("This will close all open applications and turn off this device.");
                button_text = _("Shut Down");
                break;
            default:
                warn_if_reached ();
                break;
        }

        set_position (Gtk.WindowPosition.CENTER_ALWAYS);
        set_keep_above (true);
        stick ();

        var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        var heading = new Gtk.Label (heading_text);
        heading.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);
        heading.xalign = 0;

        var secondary_label = new Gtk.Label (content_text);
        secondary_label.xalign = 0;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 6;
        grid.margin_start = grid.margin_end = grid.margin_bottom = 12;
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (heading, 1, 0, 1, 1);
        grid.attach (secondary_label, 1, 1, 1, 1);

        /*
         * the indicator does not have a separate item for restart, that's
         * why we show both shutdown and restart for the restart action
         * (which is sent for shutdown as described above)
         */
        if (dialog_type == EndSessionDialogType.RESTART) {
            var confirm_restart = add_button (_("Restart"), Gtk.ResponseType.OK) as Gtk.Button;
            confirm_restart.clicked.connect (() => {
                try {
                    system_interface.reboot (false);
                } catch (IOError e) {
                    stderr.printf ("%s\n", e.message);
                }

                destroy ();
            });
        }

        var cancel = add_button (_("Cancel"), Gtk.ResponseType.CANCEL) as Gtk.Button;
        cancel.clicked.connect (() => { destroy (); });

        var confirm = add_button (button_text, Gtk.ResponseType.OK) as Gtk.Button;
        confirm.get_style_context ().add_class ("destructive-action");
        confirm.clicked.connect (() => {
            if (dialog_type == EndSessionDialogType.RESTART || dialog_type == EndSessionDialogType.SHUTDOWN) {
                try {
                    system_interface.power_off (false);
                } catch (IOError e) {
                    stderr.printf ("%s\n", e.message);
                }
            } else {
                try {
                    logout_interface.terminate ();
                } catch (IOError e) {
                    stderr.printf ("%s\n", e.message);
                }
                destroy ();
            }
        });

        set_default (confirm);

        get_content_area ().add (grid);

        var action_area = get_action_area ();
        action_area.margin = 6;
    }
}
