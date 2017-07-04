#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Tue 27 Jun 2017 
# Description: Testing the DB connection
#

require './Constants.rb'
require './DB_Handler.rb'
require 'pg'

# Library version
puts "Version of libpg: #{PG.library_version}"

# Postgres server version
begin
	connection = PG.connect :dbname => DB_NAME,
							:user => DB_USER
	puts "Connecting to '#{DB_NAME}' as '#{DB_USER}'"
	puts "Postgres server version: #{connection.server_version}"
rescue PG::Error => e
	puts "Connection error: '#{e.message}'"
ensure
	connection.close if connection
end

db = DB_Handler.new( DB_USER, DB_NAME )

db.insert_transaction( "" )
puts "#{db.select( "payment" )}"
puts "#{db.select( "type" )}"
puts "#{db.select( "transaction" )}"
puts "#{db.get_types}"
puts "#{db.get_payments}"

db.close

