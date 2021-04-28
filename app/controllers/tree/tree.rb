require 'tree/nodes.rb'

class TokenGenerator
  def initialize
    @tokens = Array.new
  end
  def generate(p, lhs, rhs)
    if p == 0
      rhs[0].replace(0, "S")  # simply rename PROG to S, then tree is complete
      return rhs[0]
    elsif p < 3
      @tokens.push(Prog.new(lhs, rhs))
    elsif p == 3
      @tokens.push(ProcDefs.new(lhs, rhs))
    elsif p == 4
      return rhs[0].add(rhs[1]) # pull Proc into ProcDefs
    elsif p == 5
      @tokens.push(Procc.new(lhs, rhs))
    elsif p == 6
      @tokens.push(Code.new(lhs, rhs))
    elsif p == 7
      # puts rhs[0].inspect
      # puts "\n\n"
      # puts rhs[2].inspect
      return rhs[0].add(rhs[2]) # pull Instr into Code
    elsif p == 8
      @tokens.push(Halt.new(lhs, rhs))
    elsif p < 14
      rhs.reverse!
      # reduce to INSTR without growing tree
      return rhs[0].replace(0, "INSTR")
    elsif p == 14
      @tokens.push(IOInput.new(lhs, rhs))
    elsif p == 15
      @tokens.push(IOOutput.new(lhs, rhs))
    elsif p == 16
      @tokens.push(Var.new(lhs, rhs))
    elsif p == 17
      @tokens.push(Assign.new(lhs, rhs))
    elsif p < 20
      @tokens.push(Assign.new(lhs, rhs))
    elsif p < 23
      @tokens.push(Numexpr.new(lhs, rhs))
    elsif p == 23
      @tokens.push(AddCalc.new(lhs, rhs))
    elsif p == 24
      @tokens.push(SubCalc.new(lhs, rhs))
    elsif p == 25
      @tokens.push(MultCalc.new(lhs, rhs))
    elsif p == 26
      @tokens.push(IfThen.new(lhs, rhs))
    elsif p == 27
      @tokens.push(IfThenElse.new(lhs, rhs))
    elsif p == 28
      @tokens.push(WhileLoop.new(lhs, rhs))
    elsif p == 29
      @tokens.push(ForLoop.new(lhs, rhs))
    elsif p < 33
      @tokens.push(BoolEq.new(lhs, rhs))
    elsif p == 33
      @tokens.push(BoolLessThan.new(lhs, rhs))
    elsif p == 34
      @tokens.push(BoolNegation.new(lhs, rhs))
    elsif p == 35
      @tokens.push(BoolAnd.new(lhs, rhs))
    elsif p == 36
      @tokens.push(BoolOr.new(lhs, rhs))
    elsif p == 37
      @tokens.push(BoolGreaterThan.new(lhs, rhs))
    elsif p == 38
      @tokens.push(Call.new(lhs, rhs))
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
end
