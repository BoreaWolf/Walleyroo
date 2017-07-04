#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Tue 27 Jun 2017 
# Description: Class for managing the database
#

require "pg"

class DB_Handler

	def initialize( user, db )
		open_db( user, db )
		create_database
	end

	# Closing the connection to the database
	def close
		close_db
	end
	
	# Creating the tables if not in the database yet
	def create_database
		# Checking if the tables exist
		ans = @db.exec "SELECT * FROM information_schema.tables
						WHERE table_schema='public' AND table_name='type'"
		
		# If no answer is received I will create the tables for the database
		if ans.ntuples == 0 then
	
			@db.exec "CREATE TABLE Type
					  (
					  	id serial PRIMARY KEY,
					  	description varchar(100)
					  );"

			# Some predefined values
			@db.exec "INSERT INTO Type (description) 
					  VALUES ('Groceries'), ('Rent'), ('Bills'), ('Steam'), ('House');"
	
			@db.exec "CREATE TABLE Payment
					  (
					  	id serial PRIMARY KEY,
					  	description varchar(100)
					  );"

			@db.exec "INSERT INTO Payment (description)
					  VALUES ('Cash'), ('Debit Card'), ('Credit Card')"
	
			@db.exec "CREATE TABLE Transaction
					  (
					  	id serial PRIMARY KEY,
					  	date date NOT NULL,
					  	value numeric NOT NULL,
					  	description varchar(100),
					  	payment_id integer REFERENCES Payment,
					  	type_id integer REFERENCES Type
					  );"

			#	warn "DB_Handler::create_database Tables created"
		end
	end
	
	def insert_transaction( values )
		# Checking if all the values required are given
		if values.compact.length != values.length then
			return false
		else
			values = values.map{ |x| if x.is_a? Numeric then x else "'#{x}'" end }.join( "," )
			ins_query = "INSERT INTO transaction (date, value, description, payment_id, type_id) VALUES (#{values})"
			@db.exec ins_query
			#	warn "DB_Handler::insert_transaction #{ins_query}"
			return true
		end
	end

	def insert_type( value )
		insert_primitive( "type", value )
	end

	def insert_payment( value )
		insert_primitive( "payment", value )
	end

	def select( table, fields = "*", constraints = "" )
		query = "SELECT #{fields} FROM #{table}"
		if constraints != "" then
			query_cons = Array.new
			# Composing the query
			if !constraints[ "date" ].empty? then
				query_cons << "(date >= '#{constraints["date"][0]}' AND date <= '#{constraints["date"][1]}')"
			end

			[ "types", "payments" ].each do |i|
				if !constraints[ i ].empty? then
					query_cons << "(" + 
									constraints[ i ]
									.map{ |x| "#{i[0...-1]}_id = #{x}" }
									.join( " OR " ) +
									")"
				end
			end

			query += " WHERE " + query_cons.join( " AND " )
			query += " ORDER BY date DESC"
			#	warn "DB_Handler::select #{query}"
			# Query completed
		end
		# Executing the query
		@db.exec( query ).values
	end

	def get_transaction( constraints )
		select( "transaction", "*", constraints )
	end
	
	def get_types
		select( "type" )
	end

	def get_payments
		select( "payment" )
	end

	private

	def open_db( user, db )
		begin
			@db = PG.connect :dbname => db, :user => user
		rescue PG::Error => err
			warn "DB_Handler::open_db Connection error: '#{err.message}'"
		end
	end
	
	def close_db
		@db.close if @db
		#	warn "DB_Handler::close_db closed"
	end

	def insert_primitive( table, value )
		@db.exec "INSERT INTO #{table} (description) VALUES ('#{value}')"
	end
end
	
