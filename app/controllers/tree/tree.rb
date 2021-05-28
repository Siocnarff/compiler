require 'tree/nodes.rb'
require 'symbol_table/table.rb'

class TokenGenerator
  def initialize
    @tree = Array.new
    @symbol_table = SymbolTable.new
    @scopeSource = 0
    @idSource = -1
    @tokens = Array.new
  end
  def generate(p, lhs, rhs)
    if p == 0
      rhs[0].replace(0, "S")  # simply rename PROG to S, then tree is complete
      return rhs[0]
    elsif p < 3
      @tokens.push(Prog.new(lhs, rhs, @idSource += 1))
    elsif p == 3
      @tokens.push(ProcDefs.new(lhs, rhs, @idSource += 1))
    elsif p == 4
      return rhs[0].add(rhs[1]) # pull Proc into ProcDefs
    elsif p == 5
      @tokens.push(Procc.new(lhs, rhs, @idSource += 1))
    elsif p == 6
      @tokens.push(Code.new(lhs, rhs, @idSource += 1))
    elsif p == 7
      # puts rhs[0].inspect
      # puts "\n\n"
      # puts rhs[2].inspect
      return rhs[0].add(rhs[2]) # pull Instr into Code
    elsif p == 8
      @tokens.push(Halt.new(lhs, rhs, @idSource += 1))
    elsif p < 14
      rhs.reverse!
      # reduce to INSTR without growing tree
      return rhs[0].replace(0, "INSTR")
    elsif p == 14
      @tokens.push(IOInput.new(lhs, rhs, @idSource += 1))
    elsif p == 15
      @tokens.push(IOOutput.new(lhs, rhs, @idSource += 1))
    elsif p == 16
      @tokens.push(Var.new(lhs, rhs, @idSource += 1))
    elsif p == 17
      @tokens.push(Assign.new(lhs, rhs, @idSource += 1))
    elsif p < 20
      @tokens.push(Assign.new(lhs, rhs, @idSource += 1))
    elsif p < 23
      @tokens.push(Numexpr.new(lhs, rhs, @idSource += 1))
    elsif p == 23
      @tokens.push(AddCalc.new(lhs, rhs, @idSource += 1))
    elsif p == 24
      @tokens.push(SubCalc.new(lhs, rhs, @idSource += 1))
    elsif p == 25
      @tokens.push(MultCalc.new(lhs, rhs, @idSource += 1))
    elsif p == 26
      @tokens.push(IfThen.new(lhs, rhs, @idSource += 1))
    elsif p == 27
      @tokens.push(IfThenElse.new(lhs, rhs, @idSource += 1))
    elsif p == 28
      @tokens.push(WhileLoop.new(lhs, rhs, @idSource += 1))
    elsif p == 29
      @tokens.push(ForLoop.new(lhs, rhs, @idSource += 1))
    elsif p < 33
      @tokens.push(BoolEq.new(lhs, rhs, @idSource += 1))
    elsif p == 33
      @tokens.push(BoolLessThan.new(lhs, rhs, @idSource += 1))
    elsif p == 34
      @tokens.push(BoolNegation.new(lhs, rhs, @idSource += 1))
    elsif p == 35
      @tokens.push(BoolAnd.new(lhs, rhs, @idSource += 1))
    elsif p == 36
      @tokens.push(BoolOr.new(lhs, rhs, @idSource += 1))
    elsif p == 37
      @tokens.push(BoolGreaterThan.new(lhs, rhs, @idSource += 1))
    elsif p == 38
      @tokens.push(Call.new(lhs, rhs, @idSource += 1))
    end
    return @tokens.last()
  end

  def getTokens
    i = 0
    tokens = Array.new
    @tokens.each do | token |
      tokens.push(token)
      i = i + 1;
    end
    return tokens
  end

  def getTree
    return @tree
  end

  def rename_procs
    id_source = -1
    lgr = Logger.new("#{Rails.root}/log/test.log")
    lgr.info("\n================================================================\n")
    @tokens.reverse.each do |n|
      if n.is_a?(Procc)
        has_mates = false
        new_name = "p#{id_source + 1}"
        @tokens.each do |ni|
          if ni.is_a?(Call) and n.terminal_types[0].eql?("UDIN")
            if ni.terminals[0].eql?(n.terminals[0])
              distance = n.getProcScope - ni.getProcScope
              if distance == 0 and not ni.get_parent.eql?(n)
                raise "call #{ni.terminals[0]} not in same tree as the proc def it is referring to!"
              end
              if distance >= 0 and distance < 2
                has_mates = true
                ni.set_terminal(0, ["InternalName", new_name])
              end
            end
          end
        end
        if has_mates
          n.set_terminal(0, ["InternalName", new_name])
          id_source += 1
        end
      end
    end
  end

  def prune_dead_procs
    @tokens.each do |t|
      n = t.terminal_types[0]
      if n.eql?("UDIN")
        if t.is_a?(Call)
          raise "process #{t.terminals[0]} has not been defined within proc scope distance of one, so cannot be called!"
        elsif t.is_a?(Procc)
          remove(t.id)
        end
      end
    end
  end

  def remove(id)
    if @tokens.nil?
      raise "all tokens deleted!"
    end
    if @tokens[id].nil?
      return
    end
    @tokens[id].mark_as_deleted
    @tokens[id].nts.each do |nt|
      unless nt.nil?
        remove(nt.id)
      end
    end
    remove_from_parent(id)
  end

  def remove_from_parent(id)
    @tokens.each do |t|
      if (t.remove_child_with_id(id))
        if t.has_no_children
          remove(t.id)
        end
      end
    end
  end

  def check_for_loop_vars
    @tokens.each do |t|
      unless t.is_deleted?
        if t.is_a?(ForLoop)
          t.raise_issue_if_vars_invalid
        end
      end
    end
  end

  def buildTree
    @symbol_table = SymbolTable.new
    buildTreeRecursive(@tokens.last, i = 0, scope_str = "0", proc_scope = 0)
  end

  def drawTree
    @tree = Array.new
    drawTreeRecursive(@tokens.last, @tree, 0, "0")
    return @tree
  end

  def drawTreeRecursive(node, tree, counter, scope)
    if node.nil? or node.is_deleted?
      return
    end
    if tree.length <= counter
      tree.push(Array.new)
    end
    tree[counter].push(node.printTree)
    if node.nts.nil?
      return
    end
    node.nts.each do |child|
      drawTreeRecursive(child, tree, counter + 1, scope)
    end
  end

  def buildTreeRecursive(node, counter, scope, proc_scope)
    if node.nil?
      return
    end
    if node.is_a?(ForLoop) or node.is_a?(Procc)
      @symbol_table.open_new_scope
      scope = "#{scope}.#{@scopeSource += 1}"
    end

    if node.is_a?(Procc)
      proc_scope += 1
    end
    node.setProcScope(proc_scope)
    node.setScope(scope)
    node.setScopeID(scope.split(".").last.to_i)

    # P4 CODE:
    # replace for loop named var with internal var
    if node.is_a?(ForLoop)
      name_of_dec = node.nts[0].terminals[0]
      node.nts[0].set_terminal(
        0,
        [
          "InternalName",
          @symbol_table.getOrGenerateVarName(name_of_dec, is_counter_init = true)
        ]
      )
      node.nts[1, node.nts.length - 2].each do |child|
        n = child.terminals[0]
        child.set_terminal(0, ["InternalName", @symbol_table.getOrGenerateVarName(n)])
      end
    else
      # replace any var with
      node.nts.each do |child|
        if child.is_a?(Var)
          n = child.terminals[0]
          child.set_terminal(0, ["InternalName", @symbol_table.getOrGenerateVarName(n)])
        elsif child.is_a?(Call)
          n = child.terminals[0]
          child.set_terminal(0, ["UDIN", @symbol_table.getOrGenerateProcName(n)])
        end
      end
    end
    # replace proc name with internal var name
    if node.is_a?(Procc)
      n = node.terminals[0]
      unless @symbol_table.proc_def_exists(n)
        node.set_terminal(0, ["UDIN", @symbol_table.getOrGenerateProcName(n)])
      else
        raise "Proc with name #{n} already defined in this scope or a parent scope!"
      end
    end

    # end P4 Code

    if node.nts.nil?
      return
    end
    node.nts.each do |child|
      buildTreeRecursive(child, counter + 1, scope, proc_scope)
    end
    if node.is_a?(ForLoop) or node.is_a?(Procc)
      @symbol_table.close_scope
    end
  end
end
