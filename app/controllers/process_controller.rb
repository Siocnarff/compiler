require 'yaml'
require 'lexer/lexer.rb'
require 'parser/parser.rb'

class ProcessController < ApplicationController
	def eat
		file_data = Upload.find(params[:id]).body
		lexresp = lex_do(file_data)
		@output = Array.new
		if not lexresp[0] # if lexing was not successful
			@output += ["LEXING FAILED"]
			@output += lexresp[1]
			return
		else
			@output += ["LEXED INPUT SUCCESSFULLY"]
		end

		parse_info = parse(lexresp[2]) # send token list for check if in language

		if parse_info[0]
			@output.push("PARSING SUCCESSFULL")
		else
			@output.push("SYNTAX ERROR")
		end
		
		parse_info[1].each do |line|
			@output.push(line.print)
		end
	end
end
