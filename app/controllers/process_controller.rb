require 'yaml'
require 'lexer/lexer.rb'
require 'parser/parser.rb'

class ProcessController < ApplicationController
	def eat
		file_data = Upload.find(params[:id]).body
		lexresp = lex_do(file_data)
		@output = Array.new
		@tree = Array.new
		@tree.push(Array.new)
		@table = Array.new
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
			@output.push(parse_info[3])
			return
		end
		@output.push(
			"notes on tree notation:" +
			"\n\t{} contains node id\n\t() contains pointers to children\n\t[] holds the variable nonterminals owned by the node"+
			"\n\tpointers and ids are the same thing, i.e. id is pointer to position in table" +
			"\n\tsolid lines are used to indicate different levels in the tree\n\tstring printed above each node is the scope of that node"
		)
		@output.push(
			"notes on pruning:"+
			"\n\tmy pruning software is ruthless, anything that is unchanging is pruned away"+
			"\n\timportant information is not lost, because a special class is genereated that implicitly stores this fixed data"+
			"\n\tfor example: a for loop can be reduced to the ForLoop class with 5 Vars and a Code node as children"+
			"\n\tbecause these are stored in the ForLoop class, we 'know where to put them amongst the constant terminals' for all future operations"
		)
		@tree = parse_info[2]
		@table = Array.new
		parse_info[1].each do |line|
			@table.push(line.printTable)
		end
	end
end
