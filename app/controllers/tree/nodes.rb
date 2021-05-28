class Token
  def initialize(lhs, rhs, id)
    @parent = nil
    @deleted = false
    @scopeID = 0
    @scope = "0"
    @id = id
    special_tokens = ["String", "UserDefinedName", "Integer"]
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

  def get_parent
    @parent
  end

  def add_parent(parent)
    @parent = parent
  end

  def setProcScope(proc_scope)
    @proc_scope = proc_scope
  end

  def getProcScope
    @proc_scope
  end

  def does_not_contain_assignment(var_name)
    if self.is_a?(Assign) and self.nts[0].terminals[0].eql? (var_name)
      raise "for loop is modifying counter variable!"
    else
      self.nts.each do |nt|
        nt.does_not_contain_assignment(var_name)
      end
    end
  end

  def remove_child_with_id(id)
    if @nt.nil?
      return false
    end
    filterd_children = Array.new
    self.nts.each do |child|
      if child.id != id
        filterd_children.push(child)
      end
    end
    if filterd_children.length == self.nts.length
      return false
    end
    @nt = @nt[0,1] + filterd_children
    return true
  end

  def has_no_children
    @nt.length < 2
  end

  def mark_as_deleted
    @deleted = true
  end

  def is_deleted?
    @deleted
  end

  def terminals
    terminals = Array.new
    @t.each do |t|
      terminals.push(t[1])
    end
    return terminals
  end

  def terminal_types
    types = Array.new
    @t.each do |t|
      types.push(t[0])
    end
    return types
  end

  def set_terminal(index, item)
    @t.delete_at(index)
    @t.insert(index, item)
  end

  def scope
    return @scope
  end

  def setScope(s)
    @scope = s
  end

  def scopeID
    @scopeId
  end

  def setScopeID(id)
    @scopeId = id
  end

  def nts
    return @nt[1,@nt.length-1]
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
    return ids
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

  def printTable
    return "#{@id} #{@name}\nterminal children:#{@t.inspect}\nscope: #{@scope}"
  end

  def printTree
    c_ids = ""
    pointersToChildren.each do |child|
      c_ids += " #{child}"
    end

    a = "  | {#{@id}} #{@name}"
    b = "  | (#{c_ids} )"
    c = "  | #{self.terminals.inspect}"
    if a.length >= b.length and a.length >= c.length
      counter = a.length - b.length
      b += " "*counter
      counter = a.length - c.length
      c += " "*counter
    elsif b.length >= a.length and b.length >= c.length
      counter = b.length - a.length
      a += " "*counter
      counter = b.length - c.length
      c += " "*counter
    else
      counter = c.length - a.length
      a += " "*counter
      counter = c.length - b.length
      b += " "*counter
    end
    return " #{@scope}\n" + a + " |  \n" + b + " |  \n" + c + " |"
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
  def raise_issue_if_vars_invalid
    c = self.nts
    var_name = c[0].terminals[0];
    unless c[1].terminals[0].eql?(var_name) and c[3].terminals[0].eql?(var_name) and c[4].terminals[0].eql?(var_name)
      raise "for loop counting variable incorrectly defined, should have the same name"
    end
    # call on code block
    c[5].does_not_contain_assignment(var_name)
  end
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
