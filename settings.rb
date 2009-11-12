#!/usr/bin/env ruby

require 'sqlite3'

class Settings
	def initialize()
		@db_file = "/home/binnyva/.ruco/ruco.db"
		@sql = SQLite3::Database.new(@db_file)
		@sql.results_as_hash = true

	end
	
	def insertCommand(command)
		@sql.execute("INSERT INTO Command(command, added_on) VALUES(?, DATETIME('now'))", command)
		return @sql.last_insert_row_id
	end
	
	def getPreviousCommand(command_id)
		return 0, "" if command_id <= 0
		
		row = @sql.execute "SELECT id,command FROM Command WHERE id<? ORDER BY id DESC LIMIT 0,1", command_id
		
		return row[0]['id'].to_i, row[0]['command'] unless row.empty?
		return 0, ""
	end
	
	def getNextCommand(command_id)
		row = @sql.execute "SELECT id,command FROM Command WHERE id>? ORDER BY id LIMIT 0,1", command_id
		
		return row[0]['id'].to_i, row[0]['command'] unless row.empty?
		return 0, ""
	end
end

