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

public class Session.Widgets.SoftLabel : Gtk.Grid {
	private Gtk.Label normal;
	private Gtk.Label medium;
	private Gtk.Label light;
	private Gtk.Label soft;
	private Gtk.Label dots;

	private int max_length;

	private string label;
	private string termination = "…";

	public SoftLabel (string label_, int max_length_) {
		max_length = max_length_;
		label = label_;

		normal = new Gtk.Label ("");
		medium = new Gtk.Label ("");
		light  = new Gtk.Label ("");
		dots   = new Gtk.Label ("");

		medium.set_opacity (0.70);
		light.set_opacity (0.35);
		dots.set_opacity (0.15);

		this.set_orientation (Gtk.Orientation.HORIZONTAL);

		this.add (normal);
		this.add (medium);
		this.add (light);
		this.add (dots);

		cut_label ();
		this.show_all ();
	}

	private void cut_label () {
		int chars = label.char_count ();

		medium.set_label ("");
		light.set_label ("");
		dots.set_label ("");

		if (chars > max_length) {
			normal.set_label (label[0: max_length - 2]);
			medium.set_label (label[max_length - 2: max_length - 1]);
			light.set_label  (label[max_length - 1: max_length]);
			dots.set_label (termination);
		} else
			normal.set_label (label);
	}

	public void set_max_length (int max_length_) {
		max_length = max_length_;
		cut_label ();
	}

	public int get_max_length () {
		return max_length;
	}

	public void set_label (string label_) {
		label = label_;
		cut_label ();
	}

	public string get_label () {
		return label;
	}

	public void set_termination (string label_) {
		termination = label_;
		cut_label ();
	}
}
