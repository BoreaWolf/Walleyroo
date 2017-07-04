#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 29 Jun 2017 
# Description: GUI for Walley
#

Shoes.setup do
	gem "pg"
end

require "./Constants.rb"
require "./DB_Handler.rb"
require "date"

# Solarized colors
#	base03 	= "#002b36"
#	base02 	= "#073642"
#	base01 	= "#586e75"
#	base00 	= "#657b83"
#	base0 	= "#839496"
#	base1 	= "#93a1a1"
	base2 	= "#eee8d5"
#	base3 	= "#fdf6e3"
#	yellow 	= "#b58900"
#	orange 	= "#cb4b16"
#	red 	= "#dc322f"
#	magenta	= "#d33682"
#	violet 	= "#6c71c4"
#	blue 	= "#268bd2"
#	cyan 	= "#2aa198"
#	green 	= "#859900"

Shoes.app( title: "Walleyroo", :width => 1024, :height => 768 ) do

	def configure
		@db = DB_Handler.new( DB_USER, DB_NAME )
	
		@types_descr = update_types.transpose.rotate.transpose.to_h
		@payments_descr = update_payments.transpose.rotate.transpose.to_h
		@types_id = update_types.to_h
		@payments_id = update_payments.to_h
	
		info( "Walleyroo::configure Types:\n\t#{@types_descr}\n\t#{@types_id}" )
		info( "Walleyroo::configure Payments:\n\t#{@payments_descr}\n\t#{@payments_id}" )
	end
	
	def update_types
		update_from_db( "types" )
	end
	
	def update_payments
		update_from_db( "payments" )
	end
	
	def update_from_db( table )
		case table
		when "types"
		    @db.get_types
		when "payments"
		    @db.get_payments
		end
	end
	
	def switch( tab )
		case tab
		when "insert"
			show_insert
		when "report"
			show_report
		end
	end
	
	def save
		# Getting the data inserted
		#	puts "Date: '#{@date.text}'\n" +
		#		 "Value: '#{@value.text}'\n" +
		#		 "Payment: '#{@payment.text}' => '#{@payments_descr[ @payment.text ]}'\n" +
		#		 "Type: '#{@type.text}' => '#{@types_descr[ @type.text ]}'\n" +
		#		 "Description: '#{@descr.text}'"

		# Composing the values array for the insert query
		values = [
					@date.text == "" ? nil : @date.text,
					@value.text.to_f > 0 ? @value.text.to_f : nil,
					@descr.text,
					@payments_descr[ @payment.text ],
					@types_descr[ @type.text ]
				 ]

		info( "Walleyroo::save #{values}" )

		if !@db.insert_transaction( values ) then
			alert( "Problem with your data, try again giving all info required." )
		else
			alert( "Data inserted correctly" )
		end
	end
	
	def show_insert
		@core_stack.clear
		@core_stack.append do
			border green, strokewidth: 2
			
			flow do
				para "Transaction date: "
				@date = edit_line
				@date.text = Date.today.strftime( DATE_FORMAT )
			end
	
			flow do
				para "Value: "
				@value = edit_line
			end
	
			flow do
				para "Payment: "
				@payment = list_box items: @payments_descr.keys
			end
	
			flow do
				para "Type: "
				@type = list_box items: @types_descr.keys
			end
	
			flow do 
				para "Description: "
				@descr = edit_box
			end
	
			button "Save" do save() end
		end
	end
	
	def show_report
		@core_stack.clear
		@core_stack.append do
			flow do 
				stack( :width => "75%" ) do
					border red, strokewidth: 2
					stack do
						tagline "Report", :align => 'center'
					end

					@report_stack = stack do 
						generate_report_table_title
						@report_info = para "Nothing to show for now"
					end
				end

				@param_stack = stack( :width => "25%" ) do
					border green, strokewidth: 2

					flow do
						para "From: "
						@date_from = edit_line
						@date_from.text = Date.today.prev_month.strftime( DATE_FORMAT )
					end

					flow do
						para "To: "
						@date_to = edit_line
						@date_to.text = Date.today.strftime( DATE_FORMAT )
					end

					# Creating the checkboxes for both types and payments
					@checkbox_payments = Array.new
					@checkbox_types = Array.new
					[ 
						[ @checkbox_payments, @payments_descr, "Payment: " ],
						[ @checkbox_types, @types_descr, "Types: " ]
					].each do |box, data, text|
						stack( :margin => "5%" ) do
							para text
							data.keys.each do |d|
								flow{ @c = check; para d }
								@c.checked = true
								box.push( [ @c, d ] )
							end
						end
					end

					# Temporary way to show what is selected
					button "Show me what you got" do 
						constraints = Hash.new
						constraints[ "date" ] = [ @date_from.text, @date_to.text ]
						constraints[ "payments" ] = get_payment_id( get_selected( @checkbox_payments ) )
						constraints[ "types" ] = get_type_id( get_selected( @checkbox_types ) )

						data = @db.get_transaction( constraints )
						info( "Walleyroo::report Got #{data.length} results" )
						update_report( data )
					end

				end
			end
		end
	end

	def get_selected( checkboxes )
		checkboxes.map{ |c, name| name if c.checked? }.compact
	end

	def get_payment_id( values )
		get_values( @payments_descr, values )
	end

	def get_payment_descr( values )
		get_values( @payments_id, values )
	end

	def get_type_id( values )
		get_values( @types_descr, values )
	end

	def get_type_descr( values )
		get_values( @types_id, values )
	end

	def get_values( structure, values )
		result = Array.new
		values.each do |v|
			result << structure[ v ]
		end
		return result
	end

	def update_report( data )
		@report_stack.clear
		@report_stack.append do
			generate_report_table_title

			data.each do |id, date, value, descr, payment, type|
				@report_date.append do para date end
				@report_value.append do para "#{'%.2f' % value.to_f.round(2)} #{CURRENCY}" end
				@report_payment.append do para get_payment_descr( [ payment ] ) end
				@report_type.append do para get_type_descr( [ type ] ) end
				@report_descr.append do para descr end
			end
		end
		add_report_total( data )
	end

	def generate_report_table_title
		flow do 
			@report_date = stack( :width => "20%" ) do
				caption "Date", :align => 'center'
			end
			@report_value = stack( :width => "20%" ) do
				caption "Value", :align => 'center'
			end
			@report_payment = stack( :width => "20%" ) do
				caption "Payment", :align => 'center'
			end
			@report_type = stack( :width => "20%" ) do
				caption "Type", :align => 'center'
			end
			@report_descr = stack( :width => "20%" ) do
				caption "Description", :align => 'center'
			end
		end
	end
	
	def add_report_empty_line
		@report_date.append do para "" end
		@report_value.append do para "" end
		@report_payment.append do para "" end
		@report_type.append do para "" end
		@report_descr.append do para "" end
	end

	def add_report_total( data )
		result = data.map{ |id, date, value| value.to_f }.reduce( :+ )
		result = 0 if result.nil?
		add_report_empty_line
		@report_date.append do caption "Total: " end
		@report_value.append do caption "#{'%.2f' % result} #{CURRENCY}" end
	end

	configure
	background base2 

	@tab_buttons = flow do
		button "Insert" do switch( "insert" ) end
		button "Report" do switch( "report" ) end
	end

	@core_stack = stack( margin: 8 ) do
	end

	show_insert
end

