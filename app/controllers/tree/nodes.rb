class Token
  @@count = 0
  def initialize(lhs, rhs)
    @id = @@count
    @@count += 1
    special_tokens = ["String", "UserDefinedName"]
    @name = self.class.inspect
    @nt = Array.new
    @t = Array.new
    rhs.each do | token |
      if token.is_a?(Token)
        @nt.push(token)
      elsif special_tokens.include?(token[0])
        @t.push(token)
      end
    end
    @nt.push(lhs[0])
    @nt.reverse!
  end

  def [](x)
    return @nt[x]
  end

  def add(x)
    @nt.insert(1, x)
    return self
  end

  def replace(index, item)
    @nt.delete_at(index)
    @nt.insert(index, item)
    return self
  end

  def id
    return @id
  end

  def pointersToChildren
    ids = Array.new
    @nt[1,@nt.length-1].each do |nt|
      if nt.is_a?(Token)
        ids.push(nt.id)
      end
    end
  end

  def print
    miniNT = ""
    @nt[1,@nt.length-1].each do |nt|
      if nt.is_a?(Token)
        miniNT += nt.printMini
      else
        miniNT += nt[0]
      end
    end
    return "
    #{@id}, #{@name}, #{@nt[0]},
    NT: #{miniNT}
    T: #{@t.inspect}
    =================================\n
    "
  end

  def printMini
    return " me (id:#{@id}, name:#{@name})"
  end
end

class Prog < Token
end

class Code < Token
end

class ProcDefs < Token
end

class Procc < Token
end

class Instr < Token
end

class Var < Token #NOT instr, only if part of assign
  def getUserDefinedName
    return @nt[1][1]
  end
end

class Halt < Instr
end

class IOInput < Instr
end

class IOOutput < Instr
end

class Call < Instr
end
#UserDefinedName

class Assign < Instr
end
# VAR, String, NUMEXPR

class CondLoop < Token
end

class WhileLoop < CondLoop #instr
end

class ForLoop < CondLoop #instr
end

class CondBranch < Token
end

class IfThenElse < CondBranch #instr
end

class IfThen < CondBranch #instr
end

class Numexpr < Token
end
# VAR, Integer, CALC

class Calc < Token
end

class AddCalc < Calc
end

class SubCalc < Calc
end

class MultCalc < Calc
end

class Bool < Token
end

class BoolEq < Bool
end
# VAR, BOOL, NUMEXPR

class BoolLessThan < Bool
end

class BoolGreaterThan < Bool
end

class BoolNegation < Bool
end

class BoolAnd < Bool
end

class BoolOr < Bool
end
