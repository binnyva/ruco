#!/usr/bin/env ruby

require 'gtk2'

class App
	def initialize()
		# The binding context for the eval comes from this.
		@proc = Proc.new {}
		@mode = 'single'
		
		self.build_gui()
	end
	
	def build_gui()
		@window = Gtk::Window.new
		@window.set_default_size(650, 400)
		
		@vpane = Gtk::VPaned.new
		@txt_output = Gtk::TextView.new
		@sw_output = Gtk::ScrolledWindow.new
		@sw_output.add_with_viewport(@txt_output)
		@sw_output.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		@vpane.add1(@sw_output)
		
		@txt_command = Gtk::TextView.new
		@sw_command = Gtk::ScrolledWindow.new
		@sw_command.add_with_viewport(@txt_command)
		@sw_command.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		@vpane.add2(@sw_command)
		@vpane.position=375
		
		@window.add(@vpane)
		@window.show_all
		@txt_command.grab_focus #Initial focus will be for the command text box.
		
		######################### Set the signals/Events ####################################
		@window.signal_connect("delete_event") {
			false
		}
		@window.signal_connect("destroy") {
			Gtk.main_quit
		}

		
		# Capture the Enter/Ctrl+Enter thats typed into the command area.
		@txt_command.signal_connect("key_press_event") { |widget, e|
			if (e.keyval == Gdk::Keyval::GDK_Return or e.keyval == Gdk::Keyval::GDK_KP_Enter)
			
				# If Shift+Enter is pressed, switch mode from 'single' to 'multi'
				if e.state.shift_mask?
					if @mode == 'single'
						@vpane.position = 300
						@mode = 'multi'
					else
						@vpane.position = 370
						@mode = 'single'
					end
					#@txt_command.signal_emit_stop("key_press_event")
					true
				end
				
				# If we are in single mode, execute on enter - or execute on Ctrl+Enter
				if @mode == 'single' or e.state.control_mask?
					result = self.execute()
					
					# If we are on single line mode, execution will clear the command.
					if result and @mode == 'single' then
						@txt_command.buffer.text = ""
					end
					widget.signal_emit_stop("key_press_event")
				end
			end
			false
		}
		
		# A hack to exit at Escape.
		@vpane.signal_connect( "cancel-position" ) { @window.destroy }
		
		
		# Switch from one mode to another when the panes are resized.
		@vpane.signal_connect("cycle_handle_focus") { |widget, e|
			puts "Hi"
		}

		Gtk.main
	end

	def execute()
		code = self.get_code()
		
		# Make sure that the script don't die even if there is an error in the user code.
		begin
			output = eval code, @proc.binding
		rescue Exception => exc
			self.output("Error: " + $!)
			false
		else
			self.output(output.to_s)
		end
	end
	
	def get_code()
		start_buffer, end_buffer = @txt_command.buffer.bounds
		return @txt_command.buffer.get_text(start_buffer, end_buffer)
	end
	
	def output(text)
		start_buffer, end_buffer = @txt_output.buffer.bounds
		@txt_output.buffer.insert(end_buffer, text + "\n")
	end
	
	public
	# These functions are accessable from the Console.
	def clear()
		@txt_output.buffer.text=""
	end
	def exit()
		Gtk.main_quit
	end
	
end

$app = App.new
