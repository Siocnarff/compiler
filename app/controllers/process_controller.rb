require 'yaml'
require 'lexer/lexer.rb'

class ProcessController < ApplicationController
	def eat
		file_data = Upload.find(params[:id]).body
		@lexed = lex_do(file_data)
	end
end
