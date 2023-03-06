/*
 * Copyright (c) 2011-2019 elementary, Inc. (https://elementary.io)
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

public class Session.Indicator : Wingpanel.Indicator {
    private const string ICON_NAME = "system-shutdown-symbolic";
    private const string KEYBINDING_SCHEMA = "org.gnome.settings-daemon.plugins.media-keys";

    private LockInterface lock_interface;
    private SessionInterface session_interface;
    private SystemInterface system_interface;

    private Wingpanel.IndicatorManager.ServerType server_type;
    private Gtk.Image indicator_icon;

    private Gtk.Button lock_button;
    private Gtk.Button logout_button;
    private Gtk.Button shutdown_button;

    private Session.Services.UserManager manager;
    private Widgets.EndSessionDialog? current_dialog = null;

    private Gtk.Box? main_box;
    private string active_user_real_name;

    private static GLib.Settings? keybinding_settings;

    public Indicator (Wingpanel.IndicatorManager.ServerType server_type) {
        GLib.Intl.bindtextdomain (Session.GETTEXT_PACKAGE, Session.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Session.GETTEXT_PACKAGE, "UTF-8");

        Object (code_name: Wingpanel.Indicator.SESSION);
        this.server_type = server_type;
        this.visible = true;

        unowned var icon_theme = Gtk.IconTheme.get_default ();
        icon_theme.add_resource_path ("/io/elementary/wingpanel/session");

        EndSessionDialogServer.init ();
        EndSessionDialogServer.get_default ().show_dialog.connect ((type) => show_dialog ((Widgets.EndSessionDialogType)type));

        manager = new Session.Services.UserManager ();
    }

    static construct {
        if (SettingsSchemaSource.get_default ().lookup (KEYBINDING_SCHEMA, true) != null) {
            keybinding_settings = new GLib.Settings (KEYBINDING_SCHEMA);
        }
    }

    public override Gtk.Widget get_display_widget () {
        if (indicator_icon == null) {
            indicator_icon = new Gtk.Image () {
                icon_name = ICON_NAME,
                pixel_size = 24
            };

            manager.changed.connect (() => {
                update_tooltip.begin ();
            });

            indicator_icon.button_press_event.connect ((e) => {
                if (e.button == Gdk.BUTTON_MIDDLE) {
                    if (session_interface == null) {
                        init_interfaces.begin ((obj, res) => {
                            init_interfaces.end (res);
                            show_shutdown_dialog ();
                        });
                    } else {
                        show_shutdown_dialog ();
                    }

                    return Gdk.EVENT_STOP;
                }

                return Gdk.EVENT_PROPAGATE;
            });
        }

        return indicator_icon;
    }

    public override Gtk.Widget? get_widget () {
        if (main_box == null) {
            init_interfaces.begin ();

            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("io/elementary/wingpanel/session/Indicator.css");

            var settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic", Gtk.IconSize.MENU) {
                halign = Gtk.Align.START,
                hexpand = true,
                tooltip_text = _("System Settings…")
            };
            settings_button.get_style_context ().add_class ("circular");
            settings_button.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            logout_button = new Gtk.Button.from_icon_name ("system-log-out-symbolic", Gtk.IconSize.MENU) {
                sensitive = false,
                tooltip_text = _("Log Out…")
            };
            logout_button.get_style_context ().add_class ("circular");
            logout_button.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            var suspend_button = new Gtk.Button.from_icon_name ("system-suspend-symbolic", Gtk.IconSize.MENU) {
                tooltip_text = _("Suspend")
            };
            suspend_button.get_style_context ().add_class ("circular");
            suspend_button.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            lock_button = new Gtk.Button.from_icon_name ("system-lock-screen-symbolic", Gtk.IconSize.MENU) {
                sensitive = false,
                tooltip_text = _("Lock")
            };
            lock_button.get_style_context ().add_class ("circular");
            lock_button.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            shutdown_button = new Gtk.Button.from_icon_name ("system-shutdown-symbolic", Gtk.IconSize.MENU) {
                tooltip_text = _("Shut Down…")
            };
            shutdown_button.get_style_context ().add_class ("circular");
            shutdown_button.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
                margin_top = 6,
                margin_end = 12,
                margin_bottom = 6,
                margin_start = 12
            };

            if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION) {
                if (!is_running_in_demo_mode ()) {
                    var users_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
                        margin_top = 3,
                        margin_bottom = 3
                    };

                    var scrolled_box = new Gtk.ScrolledWindow (null, null) {
                        hexpand = true,
                        hscrollbar_policy = Gtk.PolicyType.NEVER,
                        max_content_height = 300,
                        propagate_natural_height = true
                    };
                    scrolled_box.add (manager.user_grid);

                    main_box.add (scrolled_box);
                    main_box.add (users_separator);
                }

                button_box.add (settings_button);
                button_box.add (logout_button);
                button_box.add (suspend_button);
            } else {
                button_box.halign = Gtk.Align.END;
                button_box.hexpand = true;
            }

            button_box.add (lock_button);
            button_box.add (shutdown_button);

            main_box.add (button_box);

            if (keybinding_settings != null) {
                logout_button.tooltip_markup = Granite.markup_accel_tooltip (keybinding_settings.get_strv ("logout"), _("Log Out…"));
                lock_button.tooltip_markup = Granite.markup_accel_tooltip (keybinding_settings.get_strv ("screensaver"), _("Lock"));

                keybinding_settings.changed["logout"].connect (() => {
                    logout_button.tooltip_markup = Granite.markup_accel_tooltip (keybinding_settings.get_strv ("logout"), _("Log Out…"));
                });

                keybinding_settings.changed["screensaver"].connect (() => {
                    lock_button.tooltip_markup = Granite.markup_accel_tooltip (keybinding_settings.get_strv ("screensaver"), _("Lock"));
                });
            }

            var screensaver_settings = new Settings ("io.elementary.desktop.screensaver");
            screensaver_settings.bind ("lock-on-suspend", suspend_button, "no-show-all", SettingsBindFlags.GET);
            screensaver_settings.bind ("lock-on-suspend", suspend_button, "visible", SettingsBindFlags.GET | SettingsBindFlags.INVERT_BOOLEAN);

            manager.close.connect (() => close ());

            settings_button.clicked.connect (() => {
                close ();

                try {
                    AppInfo.launch_default_for_uri ("settings://", null);
                } catch (Error e) {
                    warning ("Failed to open user accounts settings: %s", e.message);
                }
            });

            shutdown_button.clicked.connect (() => {
                show_shutdown_dialog ();
            });

            logout_button.clicked.connect (() => {
                session_interface.logout.begin (0, (obj, res) => {
                    try {
                        session_interface.logout.end (res);
                    } catch (Error e) {
                        if (!(e is GLib.IOError.CANCELLED)) {
                            warning ("Unable to open logout dialog: %s", e.message);
                        }
                    }
                });
            });

            lock_button.clicked.connect (() => {
                close ();

                try {
                    if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION) {
                        lock_interface.lock ();
                    } else {
                        system_interface.suspend (true);
                    }
                } catch (GLib.Error e) {
                    critical ("Unable to lock: %s", e.message);
                }
            });

            suspend_button.clicked.connect (() => {
                close ();

                try {
                    system_interface.suspend (true);
                } catch (GLib.Error e) {
                    critical ("Unable to lock: %s", e.message);
                }
            });
        }

        return main_box;
    }

    private void show_shutdown_dialog () {
        close ();

        if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION) {
            // Ask gnome-session to "reboot" which throws the EndSessionDialog
            // Our "reboot" dialog also has a shutdown button to give the choice between reboot/shutdown
            session_interface.reboot.begin ((obj, res) => {
                try {
                    session_interface.reboot.end (res);
                } catch (Error e) {
                    if (!(e is GLib.IOError.CANCELLED)) {
                        critical ("Unable to open shutdown dialog: %s", e.message);
                    }
                }
            });
        } else {
            show_dialog (Widgets.EndSessionDialogType.RESTART);
        }
    }

    private async void init_interfaces () {
        try {
            system_interface = yield Bus.get_proxy (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
            if (server_type == Wingpanel.IndicatorManager.ServerType.GREETER) {
                lock_button.sensitive = true;
            }
        } catch (IOError e) {
            critical ("Unable to connect to the login interface: %s", e.message);
        }

        if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION) {
            try {
                lock_interface = yield Bus.get_proxy (BusType.SESSION, "org.gnome.ScreenSaver", "/org/gnome/ScreenSaver");
                lock_button.sensitive = true;
            } catch (IOError e) {
                warning ("Unable to connect to lock interface: %s", e.message);
            }

            try {
                session_interface = yield Bus.get_proxy (BusType.SESSION, "org.gnome.SessionManager", "/org/gnome/SessionManager");
                shutdown_button.sensitive = true;
                logout_button.sensitive = true;
            } catch (IOError e) {
                critical ("Unable to connect to GNOME session interface: %s", e.message);
            }
        }
    }

    public override void opened () {
        if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION && !is_running_in_demo_mode ()) {
            manager.update_all ();
        }

        main_box.show_all ();
    }

    public override void closed () {}

    private void show_dialog (Widgets.EndSessionDialogType type) {
        close ();

        if (current_dialog != null) {
            if (current_dialog.dialog_type != type) {
                current_dialog.destroy ();
            } else {
                return;
            }
        }

        unowned EndSessionDialogServer server = EndSessionDialogServer.get_default ();

        current_dialog = new Widgets.EndSessionDialog (type) {
            transient_for = (Gtk.Window) indicator_icon.get_toplevel ()
        };
        current_dialog.destroy.connect (() => {
            server.closed ();
            current_dialog = null;
        });

        current_dialog.cancelled.connect (() => {
            server.canceled ();
        });

        current_dialog.logout.connect (() => {
            server.confirmed_logout ();
        });

        current_dialog.shutdown.connect (() => {
            if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION) {
                server.confirmed_shutdown ();
            } else {
                try {
                    system_interface.power_off (false);
                } catch (Error e) {
                    warning ("Unable to shutdown: %s", e.message);
                }
            }
        });

        current_dialog.reboot.connect (() => {
            if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION) {
                server.confirmed_reboot ();
            } else {
                try {
                    system_interface.reboot (false);
                } catch (Error e) {
                    warning ("Unable to reboot: %s", e.message);
                }
            }
        });

        current_dialog.show_all ();
    }

    private async void update_tooltip () {
        string description;

        if (server_type == Wingpanel.IndicatorManager.ServerType.SESSION && !is_running_in_demo_mode ()) {
            if (active_user_real_name == null) {
                active_user_real_name = Environment.get_real_name ();
            }

            int n_online_users = (yield manager.get_n_active_and_online_users ()) - 1;

            if (n_online_users > 0) {
                description = dngettext (
                    GETTEXT_PACKAGE,
                    "Logged in as “%s”, %i other user logged in",
                    "Logged in as “%s”, %i other users logged in",
                    n_online_users
                );
                description = description.printf (active_user_real_name, n_online_users);
            } else {
                description = _("Logged in as “%s”").printf (active_user_real_name);
            }
        } else {
            description = _("Not logged in");
        }

        string accel_label = Granite.TOOLTIP_SECONDARY_TEXT_MARKUP.printf (_("Middle-click to prompt to shut down"));

        indicator_icon.tooltip_markup = "%s\n%s".printf (
            description,
            accel_label
        );
    }

    private bool is_running_in_demo_mode () {
        var proc_cmdline = File.new_for_path ("/proc/cmdline");
        try {
            var @is = proc_cmdline.read ();
            var dis = new DataInputStream (@is);

            var line = dis.read_line ();
            if ("boot=casper" in line || "boot=live" in line || "rd.live.image" in line) {
                return true;
            }
        } catch (Error e) {
            critical ("Couldn't detect if running in Demo Mode: %s", e.message);
        }

        return false;
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug ("Activating Session Indicator");
    var indicator = new Session.Indicator (server_type);

    return indicator;
}
