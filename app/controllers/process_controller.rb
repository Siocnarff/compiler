require 'yaml'
require 'lexer/lexer.rb'
require 'parser/parser.rb'

class ProcessController < ApplicationController
	def eat
		@table = Array.new
		@tree = Array.new
	 	@output = Array.new
		file = Upload.find(params[:id]).body
		def getInOfIndividual(line_num, lines)
		  lines.each do |line|
		    if line[:line].eql?(line_num)
		      return line[:in]
		    end
		  end
			return []
		end

		def getInOf(successors, lines)
		  ins = []
		  successors.each do |successor|
		    ins += getInOfIndividual(successor, lines)
		  end
		  return ins
		end

		# trims out comments, but keeps comment line numbers in file, for jumping
		def trim_out_comments(file)
		  new_file = Array.new
		  file.each do |line|
		    unless line.include?("REM")
		      new_file.push(line)
		    else
		      new_file.push(line.split(" ")[0])
		    end
		  end
		  return new_file
		end


		def remove_space_before_assigns(line)
		  words = line.split(" ")
		  altered_words = Array.new
		  words.each do |word|
		    unless word.eql?("=")
		      altered_words.push(" ")
		    end
		    altered_words.push(word)
		  end
		  return altered_words.join("")
		end

		def extract_vars(line)
		  live = Array.new
		  kills = Array.new
		  partial_var = ""
		  one_c = false
		  line = remove_space_before_assigns(line)
		  (line+='!').split("").each do |c|
		    if c.ord <= 'Z'.ord and c.ord >= 'A'.ord
		      one_c = (not one_c)
		      if one_c
		        partial_var = c
		      end
		    elsif one_c
		      if c.ord <= '9'.ord and c.ord >= '0'.ord
		        partial_var += c
		      elsif partial_var.length > 1
		        if c.eql?("=") and line.include?("LET")
		          kills.push(partial_var)
		        else
		          live.push(partial_var)
		        end
		        partial_var = ""
		      else
		        one_c = false
		      end
		    end
		  end
		  return {"gen": live.uniq, "kill": kills.uniq}
		end


		def extract_successors(line)
		  words = line.split(" ")
		  successors = Array.new
		  if words[1].eql?("IF")
		    successors.push(words.last)
		  elsif words[1].eql?("GOTO")
		    return successors.push(words.last)
		  end
		  unless words[1].eql?("RETURN") or words[1].eql?("END")
		    successors.push((words[0].to_i + 1).to_s)
		  end
		  return successors
		end


		def isVar(candiate)
		  array_candiate = candiate.split("").reverse
		  front = array_candiate.pop()
		  if front.ord <= 'Z'.ord and front.ord >= 'A'.ord
		    array_candiate.each do |c|
		      if c.ord > '9'.ord or c.ord < '0'.ord
		        return false
		      end
		    end
		    return true
		  end
		  return false
		end


		def extract_equal_pairs(line, kills, equal_pairs)
		  pairs = []
		  equal_pairs.each do |p|
		    unless (not kills.nil?) and (kills.include?(p[:left]) or kills.include?(p[:right]))
		      pairs.push(p)
		    end
		  end
		  line = line.split("=").join(" = ")
		  components = line.split(" ")
		  counter = 0

		  unless components.length < 6
		    return pairs
		  end

		  components.each do |comp|
		    if comp.eql?"="
		      left = (components[counter - 1])
		      right = (components[counter + 1])
		      if isVar(left) and isVar(right)
		        pairs.push({"left": left, "right": right})
		      end
		    end
		    counter += 1
		  end
		  return pairs
		end


		def all_i_am_equal_to(me, pairs)
		  all = []
		  pairs.each do |p|
		    if p[:left].eql?(me)
		      all.push(p[:right])
		    elsif p[:right].eql?(me)
		      all.push(p[:left])
		    end
		  end
		  return all
		end


		def interfaces(info_object, info_lines)
		  interfaces = []
		  kill = info_object[:k_g][:kill].length
		  if info_object[:k_g][:kill].length > 0
		    me = info_object[:k_g][:kill][0]
		    may_not_interface_with = all_i_am_equal_to(me, info_object[:equal_pairs])
		    may_not_interface_with.push(me)

		    info_lines.each do |line|
		        if line[:k_g][:kill].include?(me)
		          interfaces += (line[:out] - (may_not_interface_with + all_i_am_equal_to(me, info_object[:local_equal_pairs])))
		        end
		    end

		    if interfaces.length > 0
		      return {"line": info_object[:line], "var": me, "interfaces": interfaces.uniq}
		    end
		  end
		  return nil
		end


		lines = trim_out_comments(file.split("\n"))

		info = []

		equal_pairs = []
		lines.each do |line|
		  kills_and_liveness = extract_vars(line)
		  successors = extract_successors(line)
		  equal_pairs = extract_equal_pairs(line, kills_and_liveness[:kill], equal_pairs)
		  info.push({
		    "line": line.split(" ")[0],
		    "successors": successors,
		    "equal_pairs": equal_pairs,
		    "local_equal_pairs": extract_equal_pairs(line, nil, []),
		    "k_g": kills_and_liveness,
		    "in": [],
		    "out": []
		  })
		  puts({"line": line.split(" ")[0],
		  "successors": successors,
		  "equal_pairs": equal_pairs,
		  "k_g": kills_and_liveness})
		end

		change = true
		while change
		  change = false
		  info.each do |line|
		    prev_size = line[:in].length
		    line[:in] += line[:k_g][:gen]
		    line[:in] += (line[:out] - line[:k_g][:kill])
		    line[:in] = line[:in].uniq
		    if line[:in].length != prev_size
		      change = true
		    end
		  end
		  info.each do |line|
		    prev_size = line[:out].length
		    line[:out] += getInOf(line[:successors], info)
		    line[:out] = line[:out].uniq
		    if line[:out].length != prev_size
		      change = true
		    end
		  end
		end

		info.each do |line|
			interface = interfaces(line, info)
			if not interface.nil?
				@output.push(interface)
			end
		end
	end
	# 	file_data = Upload.find(params[:id]).body
	# 	lexresp = lex_do(file_data)
	# 	@output = Array.new
	# 	@tree = Array.new
	# 	@tree.push(Array.new)
	# 	@table = Array.new
	# 	@output.push("lexing...")
	# 	if not lexresp[0] # if lexing was not successful
	# 		@output.push("LEXING ERROR!")
	# 		@output += lexresp[1]
	# 		return
	# 	end
	#
	# 	@output.push("parsing...")
	# 	begin
	# 		parse_info = parse(lexresp[2]) # send token list for check if in language
	# 		if not parse_info[0]
	# 			@output.push("SYNTAX ERROR!")
	# 			#@output += parse_info[2]
	# 			return
	# 		end
	# 	rescue => e
	# 		@output.push("SYNTAX ERROR!")
	# 		@output.push(e)
	# 		return
	# 	end
	# 	begin
	# 		treeManager = parse_info[1]
	# 		@output.push("building doubly linked AST...")
	# 		@output.push("renaming variables...")
	# 		treeManager.buildTree
	# 		@output.push("renaming procs...")
	# 		treeManager.rename_procs
	# 		@output.push("checking procs / pruning dead procs...")
	# 		treeManager.prune_dead_procs
	# 		@output.push("checking for-loop variable usage...")
	# 		treeManager.check_for_loop_vars
	# 		@output.push("running type inference checks...")
	# 		treeManager.typeCheck
	# 		@output.push("pruning away dead code...")
	# 		treeManager.pruneBasedOnType
	# 		warnings = treeManager.getAllWarnings
	# 		@output.push("doing value flow analysis...")
	# 		treeManager.traceValueFlow
	# 		# @tree = treeManager.drawTree
	# 		@output.push("generating BASIC code...")
	# 		@output.push("======================= you can run the generated code at: http://www.quitebasic.com/ =======================")
	# 		file = treeManager.generateCode
	# 		@output += file
	# 		if warnings.length > 0
	# 			@output.push("---------------------------------------------------------------------------------------------------------------")
	# 			@output += warnings
	# 		end
	# 	rescue => e
	# 		@output.push("\t!! DARN IT !!")
	# 		@output.push(e)
	# 		return
	# 	end
	# 	# @output.push("---------------------------------------------------------------------------------------------------------------")
	# 	# @output.push("printing pruned AST...")
	# 	# @output.push("===============================================================================================================")
	# 	# # @output.push(
	# 	# # 	"Notes on tree notation:" +
	# 	# # 	"\n\n\ttype of node is shown as a single character above each node" +
	# 	# # 	"\n\tfor Procc and Var nodes we use [] as follows: [<InternalName>, <UserDefinedName>] for ease of marking" +
	# 	# # 	"\n\n\t{} contains node id\n\t() contains pointers to children\n\t[] holds the variable terminals owned by the node"+
	# 	# # 	"\n\tSolid lines are used to indicate different levels in the tree"
	# 	# # )
	# 	# # @output.push("---------------------------------------------------------------------------------------------------------------")
	# 	# @table = Array.new
	# 	# parse_info[1].getTokens.each do |line|
	# 	# 	unless line.is_deleted?
	# 	# 		@table.push(line.printTable)
	# 	# 	end
	# 	# end
	# end
end
