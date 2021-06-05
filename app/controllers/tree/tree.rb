require 'tree/nodes.rb'
require 'symbol_table/table.rb'

class TokenStorage
  def initialize
    @tkns = Array.new
  end

  def array
    filtered_tokens = Array.new
    @tkns.each do |token|
      unless token.is_deleted?
        filtered_tokens.push(token)
      end
    end
    return filtered_tokens
  end

  def push(token)
    @tkns.push(token)
  end

  def last
    @tkns.last
  end

  def delete(id)
    @tkns[id].mark_as_deleted
  end

  def get(id)
    target = @tkns[id]
    if target.is_deleted?
      raise "#{target.terminals} is deleted!"
    end
    @tkns[id]
  end
end

class TokenGenerator
  def initialize
    @lgr = Logger.new("#{Rails.root}/log/test.log")
    @tree = Array.new
    @symbol_table = SymbolTable.new
    @procScopeSource = 0
    @scopeSource = 0
    @idSource = -1
    @tokens = TokenStorage.new
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
    return @tokens.last
  end


  def traceValueFlow
    @tokens.last.trace_flow(nil, "SAFE")
  end

  def getAllWarnings
    warnings = Array.new
    @tokens.array.each do |token|
      if token.has_warning?
        warnings.push("\t" + token.warning)
      end
    end
    return warnings
  end

  def typeCheck
    @tokens.last.calculate_type # kick of chain reaction that calculates all types
    @tokens.array.each do |token|
      if token.peek_type.eql?("e")
        raise "type error!\n#{token.get_error_message}"
      end
    end
  end

  def pruneBasedOnType
    root = @tokens.last
    root.mark_d_or_prune_based_on_type # kick off chain reaction of marking and some just-in-time pruning
    if root.peek_type.eql?("d")
      raise "entire AST is dead code!"
    end
    remove_marked_as_d(root)
  end

  def remove_marked_as_d(node)
    if node.peek_type.eql?("d")
      remove(node.id)
    else
      node.nts.each do |child|
        remove_marked_as_d(child)
      end
    end
  end

  def getTokens
    i = 0
    tokens = Array.new
    @tokens.array.each do | token |
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
    @tokens.array.reverse.each do |proc|
      if proc.is_a?(Procc) and proc.terminal_types[0].eql?("UDIN")
        proc_name = proc.terminals[0]
        has_mates = false
        new_name = "p#{id_source + 1}"
        @tokens.array.each do |call|

          if call.is_a?(Call)
            if call.terminals[0].eql?(proc_name)
              procFamilyLine = proc.getProcScope.split(".")
              callFamilyLine = call.getProcScope.split(".")
              distance = procFamilyLine.length - callFamilyLine.length

              may_rename = false

              if distance >= 0 and distance <= 1
                if has_ancestor(procFamilyLine, callFamilyLine)
                  may_rename = true
                  call.set_terminal(0, ["InternalName", new_name])
                  if distance != 0
                    proc.tag_has_outside_call
                  end
                else
                  call.tag_in_wrong_tree
                end
              end

              if may_rename
                has_mates = true
                call.set_terminal(0, ["InternalName", new_name])
              end

            end
          end
        end
        if has_mates
          proc.set_terminal(0, ["InternalName", new_name])
          id_source += 1
        end
      end
    end
  end

  def has_ancestor(procFT, callFT)
    if procFT.length != callFT.length
      procFT.pop
    end
    procFT.pop.eql?(callFT.last)
  end

  def prune_dead_procs
    @tokens.array.each do |t|
      token_not_renamed = t.terminal_types[0].eql?("UDIN")
      if t.is_a?(Call) and token_not_renamed
        if t.in_wrong_tree?
          raise "raise 'proc #{t.terminals[0]}' does not stand in any ancestor relationship with the location it is called from!"
        else
          raise "'proc #{t.terminals[0]}' has not been defined within proc scope distance of one, so cannot be called here!"
        end
      ## come back to : elsif t.is_a?(Procc) and (token_not_renamed or t.has_no_outside_call?)
      elsif t.is_a?(Procc) and (token_not_renamed or t.has_no_outside_call?)
        remove(t.id)
      end
    end
  end

  def remove(id)
    if @tokens.nil?
      raise "all tokens deleted!"
    end
    if @tokens.get(id).nil?
      return
    end
    @tokens.get(id).nts.each do |nt|
      unless nt.nil?
        remove(nt.id)
      end
    end
    @tokens.delete(id)
    remove_from_parent(id)
  end

  def remove_from_parent(id)
    @tokens.array.each do |t|
      if (t.remove_child_with_id(id))
        if t.has_no_children
          remove(t.id)
        end
      end
    end
  end

  def check_for_loop_vars
    @tokens.array.each do |t|
      if t.is_a?(ForLoop)
        t.raise_issue_if_vars_invalid
      end
    end
  end

  def buildTree
    @symbol_table = SymbolTable.new
    buildTreeRecursive(@tokens.last, i = 0, scope_str = "0", proc_scope = "0")
    doubleLinkTree(@tokens.last)
  end

  def doubleLinkTree(node)
    node.nts.each do |child|
      child.add_parent(node)
      doubleLinkTree(child)
    end
  end

  def drawTree
    @tree = Array.new
    drawTreeRecursive(@tokens.last, @tree, 0, "0")
    return @tree
  end

  def drawTreeRecursive(node, tree, counter, scope)
    if node.nil?
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
      proc_scope = "#{proc_scope}.#{@procScopeSource += 1}"
    end
    node.setProcScope(proc_scope)
    node.setScope(scope)

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
      node.nts[0].set_token_link(@symbol_table.get_last_token)
      node.nts[1, node.nts.length - 2].each do |child|
        n = child.terminals[0]
        child.set_terminal(0, ["InternalName", @symbol_table.getOrGenerateVarName(n)])
        child.set_token_link(@symbol_table.get_last_token)
      end
    else
      # replace any var with
      node.nts.each do |child|
        if child.is_a?(Var)
          n = child.terminals[0]
          child.set_terminal(0, ["InternalName", @symbol_table.getOrGenerateVarName(n)])
          child.set_token_link(@symbol_table.get_last_token)
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
