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
		@output.push("lexing...")
		if not lexresp[0] # if lexing was not successful
			@output.push("LEXING ERROR!")
			@output += lexresp[1]
			return
		end

		@output.push("parsing...")
		begin
			parse_info = parse(lexresp[2]) # send token list for check if in language
			if not parse_info[0]
				@output.push("SYNTAX ERROR!")
				#@output += parse_info[2]
				return
			end
		rescue => e
			@output.push("SYNTAX ERROR!")
			@output.push(e)
			return
		end
		begin
			treeManager = parse_info[1]
			@output.push("building doubly linked AST...")
			@output.push("renaming variables...")
			treeManager.buildTree
			@output.push("renaming procs...")
			treeManager.rename_procs
			@output.push("checking procs / pruning dead procs...")
			treeManager.prune_dead_procs
			@output.push("checking for-loop variable usage...")
			treeManager.check_for_loop_vars
			@output.push("running type inference checks...")
			treeManager.typeCheck
			@output.push("pruning away dead code...")
			treeManager.pruneBasedOnType
			warnings = treeManager.getAllWarnings
			@output.push("doing value flow analysis...")
			treeManager.traceValueFlow
			@tree = treeManager.drawTree
			if warnings.length > 0
				@output.push("---------------------------------------------------------------------------------------------------------------")
				@output += warnings
			end
		rescue => e
			@output.push("\t!! DARN IT !!")
			@output.push(e)
			return
		end
		@output.push("---------------------------------------------------------------------------------------------------------------")
		@output.push("printing pruned AST...")
		@output.push("===============================================================================================================")
		# @output.push(
		# 	"Notes on tree notation:" +
		# 	"\n\n\ttype of node is shown as a single character above each node" +
		# 	"\n\tfor Procc and Var nodes we use [] as follows: [<InternalName>, <UserDefinedName>] for ease of marking" +
		# 	"\n\n\t{} contains node id\n\t() contains pointers to children\n\t[] holds the variable terminals owned by the node"+
		# 	"\n\tSolid lines are used to indicate different levels in the tree"
		# )
		# @output.push("---------------------------------------------------------------------------------------------------------------")
		@table = Array.new
		parse_info[1].getTokens.each do |line|
			unless line.is_deleted?
				@table.push(line.printTable)
			end
		end
	end
end
