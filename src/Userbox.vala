public class UserBox : Grid {
	public string status;
    public string username;
    public string fullname;
    
    private Gtk.Label fullname_label;
    private Gtk.Label status_label;
    
    public Gdk.Pixbuf pixbuf;
    
    public Gtk.Image image;

    public UserBox (string user, string fullname) {
		status = "Logged In";
				
		var picture_frame = new Gtk.AspectFrame (null, 0,0,1,true);
		fullname_label = new Gtk.Label (@"<b>$fullname</b>");
		status_label = new Gtk.Label (status); 
		var status_box = new Gtk.VBox (false, 4);
		pixbuf = new Gdk.Pixbuf.from_file (@"/var/lib/AccountsService/icons/$user");		
		image = new Gtk.Image.from_pixbuf (pixbuf.scale_simple (48,48, Gdk.InterpType.BILINEAR));
		
		fullname_label.set_use_markup (true);
		fullname_label.get_style_context ().add_class ("h2");
		fullname_label.xalign = 0;
		
		status_label.get_style_context ().add_class ("h3");
		status_label.xalign = 0;
				
		picture_frame.add (image);
		picture_frame.set_border_width (0);
			
		this.attach (picture_frame, 0, 0, 3, 3);
		this.attach (fullname_label, 3, 0, 2, 1);
		this.attach (fullname_label, 3, 1, 2, 1);
		
		this.set_margin_top (1);	
		this.set_margin_left (6);
		picture_frame.set_margin_right (6);
		picture_frame.set_margin_top (6);
		picture_frame.set_shadow_type (ShadowType.ETCHED_OUT);
	}
	
	public void set_username (string username) {
	
	}
	
	public string get_username () {
	    return "";
	}
	
	public void set_fullname (string fullname) {
	
	}
	
	public string get_fullname () {
	    return "";
	}
	
}
