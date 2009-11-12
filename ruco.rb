#!/usr/bin/env ruby

require 'gtk2'
require 'settings'

class App
	def initialize()
		# The binding context for the eval comes from this.
		@proc = Proc.new {}
		@mode = 'single'
		@opt = Settings.new
		@last_command_id = 10000
		
		self.build_gui()
	end
	
	def build_gui()
		@window = Gtk::Window.new
		@window.set_default_size(650, 400)
		
		@vpane = Gtk::VPaned.new
		
		# Output area
		@txt_output = Gtk::TextView.new
		@sw_output = Gtk::ScrolledWindow.new
		@sw_output.add(@txt_output)
		@sw_output.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		@vpane.add1(@sw_output)
		
		# Command Entry Area
		@txt_command = Gtk::TextView.new
		@sw_command = Gtk::ScrolledWindow.new
		@sw_command.add(@txt_command)
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

		
		# Capture the shortcuts typed into the command area.
		@txt_command.signal_connect("key_press_event") { |widget,e| self.handleShorcuts(widget, e) }
		
		# A hack to exit at Escape.
		@vpane.signal_connect( "cancel-position" ) { @window.destroy }
		
		
		# Switch from one mode to another when the panes are resized.
		@vpane.signal_connect("cycle_handle_focus") { |widget, e|
			puts "Hi"
		}

		Gtk.main
	end
	
	################################################ Events ######################################
	def handleShorcuts(widget, e)
		case e.keyval
			# Enter
			when Gdk::Keyval::GDK_Return, Gdk::Keyval::GDK_KP_Enter
				# Shift+Enter
				# Toggle mode between 'single' and 'multi'
				if e.state.shift_mask?
					self.toggleMode()
					@txt_command.signal_emit_stop("key_press_event")
					true
				end
			
				# Enter/Ctrl+Enter
				# If we are in single mode, execute on enter - or execute on Ctrl+Enter
				if @mode == 'single' or e.state.control_mask?
					result = self.execute()
					
					# If we are on single line mode, execution will clear the command.
					if result and @mode == 'single' then
						@txt_command.buffer.text = ""
					end
					widget.signal_emit_stop("key_press_event")
				end
			
			
			# Up / Ctrl+Up
			when Gdk::Keyval::GDK_Up
				# Up key works if its in single mode - if its in multi mode, you have to press Ctrl+up
				self.prevCommand() if @mode == 'single' or e.state.control_mask?
			
			# Down / Ctrl+Up
			when Gdk::Keyval::GDK_Down
				self.nextCommand() if @mode == 'single' or e.state.control_mask?
		end
		false
	end

	############################################### Code Functions ##############################
	def execute()
		code = self.getCode()
		
		@last_command_id = @opt.insertCommand(code)
		
		self.print("[" + @last_command_id.to_s + "] ", false)
		# Make sure that the script don't die even if there is an error in the user code.
		begin
			output = eval code, @proc.binding
		rescue Exception => exc
			self.print("Error: " + $!)
			false
		else
			self.print(output.to_s)
		end
	end
	
	############################################## GUI Controls ####################################
	def getCode()
		start_buffer, end_buffer = @txt_command.buffer.bounds
		return @txt_command.buffer.get_text(start_buffer, end_buffer)
	end
	
	def print(text, insert_new_line_at_end=true)
		text = text + "\n" if(insert_new_line_at_end)
		start_buffer, end_buffer = @txt_output.buffer.bounds
		@txt_output.buffer.insert(end_buffer, text)
	end
	
	# Switch command entry mode to the specified mode. If none is specified, toggle the mode.
	def toggleMode(mode_name='toggle')
		# Single line mode
		if mode_name == 'single'
			@vpane.position = 370
			@mode = 'single'
		
		# Multiline mode
		elsif mode_name == 'multi'
			@vpane.position = 300
			@mode = 'multi'
		
		# Toggle Mode
		else
			if @mode == 'single'
				self.toggleMode('multi')
			else
				self.toggleMode('single')
			end
		end
	end
	
	# Sets the given text as the text in the command area.
	def setCommand(command)
		@txt_command.buffer.text = command
	end
	
	# Gets the last executed command and set it as the active command.
	def prevCommand
		command_id, command = @opt.getPreviousCommand @last_command_id
		self.setCommand(command)
		@last_command_id = command_id
	end
	
	# Gets the next command in history and set it as the active one.
	def nextCommand
		command_id, command = @opt.getNextCommand @last_command_id
		self.setCommand(command)
		@last_command_id = command_id if command_id > 0
	end
	
	
	############################################# User Callable ####################################
	# These functions are accessable from the Console.
	def clear()
		@txt_output.buffer.text=""
	end
	
	def exit()
		Gtk.main_quit
	end
	
end

App.new


############################################################################3
# :TODO:
# Error must be in red color.
# Another class that holds all the functions available in the shell.
# 	Helper Functions
# 		file_get_contents
# Menu bar.
# Save history to file.
# Load commands from file.
# Recent Files.
# Aliases
