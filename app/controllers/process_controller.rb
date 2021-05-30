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
			@output.push(parse_info[2])
			return
		end
		@output.push(
			"Notes on notation:" +
			"\n\ttype of node is shown as a single character above each node" +
			"\n\tfor Procc and Var nodes we : [<InternalName>, <UserDefinedName>] for ease of marking" +
			"\n\n\t{} contains node id\n\t() contains pointers to children\n\t[] holds the variable terminals owned by the node"+
			"\n\tSolid lines are used to indicate different levels in the tree"
		)
		begin
			treeManager = parse_info[1]
			treeManager.buildTree
			treeManager.rename_procs
			treeManager.prune_dead_procs
			treeManager.check_for_loop_vars
			treeManager.typeCheck
			@tree = treeManager.drawTree
		rescue => e
			@output.push(e)
			return
		end
		@table = Array.new
		parse_info[1].getTokens.each do |line|
			unless line.is_deleted?
				@table.push(line.printTable)
			end
		end
	end
end
