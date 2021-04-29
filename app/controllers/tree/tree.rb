require 'tree/nodes.rb'

class TokenGenerator
  def initialize
    @tree = Array.new
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

  def buildTree
    root = @tokens.last
    @tree = Array.new
    buildTreeRecursive(root, @tree, 0, "0")
    return @tree
  end

  def buildTreeRecursive(node, tree, counter, scope)
    if tree.length <= counter
      tree.push(Array.new)
    end
    if node.is_a?(ForLoop) or node.is_a?(Procc)
      scope = "#{scope}.#{@scopeSource += 1}"
    end
    node.setScope(scope)
    tree[counter].push(node.printTree)
    if node.nts.nil?
      return
    end
    node.nts.each do |child|
      buildTreeRecursive(child, tree, counter + 1, scope)
    end
  end
end
