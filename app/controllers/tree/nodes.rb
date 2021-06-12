class Token
  def initialize(lhs, rhs, id)
    @@needsToRepeat = false
    @@set = false
    @@safety_key_source = 0
    @lgr = Logger.new("#{Rails.root}/log/test2.log")
    @warning = ""
    @error_message = ""
    @type = "u"
    @flow = ""
    @parent = nil
    @deleted = false
    @proc_scope = "0"
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

  def read_flow(safety_key)
    @flow
  end

  def trace_flow(callback, safety_key)
    self.nts.each do |child|
      child.trace_flow(callback, safety_key)
    end
  end

  def print_flow
    if @flow.length > 0
      return " f: '#{@flow}'"
    else
      return ""
    end
  end

  def has_warning?
    not @warning.eql?("")
  end

  def warning
    @warning
  end

  def peek_type
    @type
  end

  def calculate_type
    if all_children_are?("c")
        @type = "c"
    end
    @type
  end

  def all_children_are?(type)
    children = self.nts
    are_type = true # if no children then vacuously true
    children.each do |child|
      are_type = (are_type and child.calculate_type.eql?(type))
    end
    return are_type
  end

  def get_error_message
    @error_message
  end

  def mark_d_or_prune_based_on_type
    @lgr.info(@id)
    # "child functions" have to call super first to ensure
    # that the "d" cases are propageted upwards correctly
    children = self.nts
    children.each do |child|
      child.mark_d_or_prune_based_on_type
    end
    # now each child will be "d" if it ever will be
    all_dead = (children.length == 1)
    children.each do |child|
      all_dead = (all_dead and child.peek_type.eql?("d"))
    end
    # if all children are "d" I should also be dead
    if all_dead
      @type = "d"
    end
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

  def replace_child(id, replacment)
    unless @nt.nil?
      updated_children = Array.new
      self.nts.each do |child|
        if child.id != id
          updated_children.push(child)
        else
          updated_children.push(replacment)
        end
      end
      @nt = @nt[0,1] + updated_children
    end
  end

  def has_no_children
    @nt.length < 2
  end

  def mark_as_deleted
    @deleted = true
  end

  def mark_self_and_children_deleted
    children = self.nts
    children.each do |child|
      child.mark_self_and_children_deleted
    end
    self.mark_as_deleted
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
    unless @t[index][0].eql?("UserDefinedName")
      @t.delete_at(index)
    end
    @t.insert(index, item)
  end

  def scope
    return @scope
  end

  def setScope(s)
    @scope = s
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
    return "#{@id} #{@name}\nterminal children:#{@t.inspect}\nscope: #{@scope}\ntype: #{self.peek_type}"
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
    return "#{peek_type()} #{print_flow()}\n #{@scope}\n" + a + " |  \n" + b + " |  \n" + c + " |"
  end
end

class Prog < Token
  def trace_flow(callback, safety_key)
    code = self.nts[0]
    code.trace_flow(callback = self, safety_key)
  end

  def trace_flow_in_proc(name, callback, safety_key)
    unless self.nts.length < 2
      self.nts[1].trace_flow_in_proc(name, callback, safety_key)
    end
  end
end

class Code < Token
end

class ProcDefs < Token
  def trace_flow_in_proc(name, callback, safety_key)
    self.nts.each do |procdef|
      if procdef.terminals[0].eql?(name)
        procdef.trace_flow(callback, safety_key)
      end
    end
  end
end

class Procc < Token
  def initialize(lhs, rhs, id)
    super
    @has_outside_call = false
  end

  def tag_has_outside_call
    @has_outside_call = true
  end

  def has_no_outside_call?
    not @has_outside_call
  end
end

class Instr < Token
end

class Var < Token  #NOT instr, only if part of assign
  def initialize(lhs, rhs, id)
    super
    @has_init = false
    @symbol_table_token_link = nil
  end

  def getUserDefinedName
    return @nt[1][1]
  end

  def print_flow
    " f: '#{@symbol_table_token_link.read_flow}'"
  end

  def set_flow(value, safety_key)
    if @@needsToRepeat
      if not @symbol_table_token_link.read_flow.eql?("+")
        @symbol_table_token_link.set_set_count(0)
      end
      if value.eql?("+")
        if @@set and not @symbol_table_token_link.get_set_count == 3
          if @symbol_table_token_link.get_set_count == 1
            @symbol_table_token_link.set_set_count(2)
          end
        elsif not @symbol_table_token_link.get_set_count == 3
          @symbol_table_token_link.set_set_count(1)
        end
      end
    end
    @symbol_table_token_link.set_safety_key(safety_key)
    @symbol_table_token_link.set_flow(value)
  end

  def is_safe(key)
    if @symbol_table_token_link.get_set_count < 2
      raise "var #{self.terminals[1]} not defined in both branches of 'if then else'"
    end
    target_key = read_safety()
    if target_key.length <= key.length
      @lgr.info(key.first(target_key.length))
      @lgr.info(target_key)
      @lgr.info("===========")
      return key.first(target_key.length).eql?(target_key)
    end
    return false
  end

  def read_flow(safety_key)
    if is_safe(safety_key)
      @symbol_table_token_link.read_flow
    else
      raise "for your safety var #{self.terminals[1]} must be initialized OUTSIDE blocks of code that might not execute!"
    end
  end

  def read_safety
    @symbol_table_token_link.read_safety
  end

  def set_token_link(token_link)
    @has_init = true
    @symbol_table_token_link = token_link
  end

  def peek_type
    @symbol_table_token_link.get_type
  end

  def calculate_type
    type_string = @symbol_table_token_link.get_type
    if type_string.eql?("u")
      self.set_type("o")
    end
    return type_string
  end

  def set_type(type)
    @symbol_table_token_link.set_type(type)
  end
end

class Halt < Instr
end

class IOInput < Instr
  def trace_flow(callback, safety_key)
    var = self.nts[0]
    var.set_flow("+", safety_key)
  end

  def calculate_type
    var = self.nts[0]
    if var.calculate_type.eql?("s")
      @error_message = "io inputs have to be saved in var of type number! '#{var.terminals[1]}' is not of type number!"
      @type = "e"
    else
      var.set_type("n")
      @type = "c"
    end
    @type
  end
end

class IOOutput < Instr
  def trace_flow(callback, safety_key)
    var = self.nts[0]
    if var.read_flow(safety_key).eql?("-")
      raise "error: #{var.terminals[1]} has no gauranteed value at output point!"
    end
  end

  def calculate_type
    var = self.nts[0]
    unless var.calculate_type.eql?("n") or var.calculate_type.eql?("s")
      var.set_type("o")
    end
    @type = "c"
    @type
  end
end

class Call < Instr
  def initialize(lhs, rhs, id)
    super
    @in_wrong_tree_error = false
  end

  def trace_flow(callback, safety_key)
    proc_name = self.terminals[0]
    callback.trace_flow_in_proc(proc_name, callback, safety_key)
  end

  def tag_in_wrong_tree
    @in_wrong_tree_error = true
  end

  def in_wrong_tree?
    @in_wrong_tree_error
  end
end
#UserDefinedName

class Assign < Instr
  def trace_flow(callback, safety_key)
    var = self.nts[0]
    unless self.nts.length == 1
      if self.nts[1].is_a?(Var)
        target_var = self.nts[1]
        if target_var.read_flow(safety_key).eql?("-")
          raise "#{var.terminals[1]} cannot be assigned to #{target_var.terminals[1]} as this var has no value yet!"
        end
      elsif self.nts[1].is_a?(Numexpr)
        numexpr = self.nts[1]
        unless numexpr.all_vars_have_values(callback, safety_key)
          raise "#{var.terminals[1]} cannot be assigned a value here, since not all vars in numexpr have values yet!"
        end
      end
    end
    var.set_flow("+", safety_key)
  end

  def calculate_type
    var = self.nts[0]
    if self.nts.length == 1
      self.type_var_string(var)
    elsif self.nts[1].is_a?(Var)
      self.type_var_var(var, self.nts[1])
    elsif self.nts[1].is_a?(Numexpr)
      self.type_var_numexpr(var, self.nts[1])
    end
    @type
  end

  def type_var_string(var)
    if var.calculate_type.eql?("n")
      @error_message = "'#{var.terminals[1]}' is of type number and you may not assign a string to it!"
      @type = "e"
    else
      var.set_type("s")
      @type = "c"
    end
  end

  def type_var_var(left, right)
    if left.calculate_type.eql?("n") and right.calculate_type.eql?("s")
      @error_message= "'#{var.terminals[1]}' is of type number and you may not assign string variable '#{left.terminals[1]}' to it!"
      @type = "e"
      return
    elsif right.calculate_type.eql?("n") and left.calculate_type.eql?("s")
      @error_message= "'#{var.terminals[1]}' is of type number and may not be assigned to string variable '#{left.terminals[1]}'!"
      @type = "e"
      return
    elsif left.calculate_type.eql?("n") and not right.calculate_type.eql?("s")
      right.set_type("n")
    elsif right.calculate_type.eql?("n") and not left.calculate_type.eql?("s")
      left.set_type("n")
    elsif left.calculate_type.eql?("s") and not right.calculate_type.eql?("n")
      right.set_type("s")
    elsif right.calculate_type.eql?("s") and not left.calculate_type.eql?("n")
      left.set_type("s")
    else
      left.set_type("o")
      right.set_type("o")
    end
    @type = "c"
  end

  def type_var_numexpr(var, numexpr)
    if var.calculate_type.eql?("s")
      @error_message = "may not assign a number to string var #{var.terminals[1]}"
      @type = "e"
    else
      var.set_type("n")
      if numexpr.calculate_type.eql?("n")
        @type = "c"
      end
    end
  end
end
# VAR, String, NUMEXPR

class CondLoop < Token
end

class WhileLoop < CondLoop #instr
  def trace_flow(callback, safety_key)
    super(callback, "#{safety_key}.#{@@safety_key_source += 1}")
  end

  def calculate_type
    bool = self.nts[0]
    code = self.nts[1]
    bool_valid = (bool.calculate_type.eql?("b") or bool.calculate_type.eql?("f"))
    code_valid = code.calculate_type.eql?("c")
    if bool.is_a?(BoolNegation) and bool.child_is_f
      @warning = "Warning! Infinite Loop!"
    end
    if bool_valid and code_valid
      @type = "c"
    end
    @type
  end

  def mark_d_or_prune_based_on_type
    super
    bool = self.nts[0]
    if bool.peek_type.eql?("f")
      @type = "d"
    end
  end
end

class ForLoop < CondLoop #instr
  def trace_flow(callback, safety_key)
    self.nts[0].set_flow("+", safety_key)
    if self.nts[2].read_flow(safety_key).eql?("-")
      raise "var #{self.nts[2].terminals[1]} being compared against in for loop has no value yet!"
    end
    vars = self.nts
    code = vars.pop
    vars.each do |child|
      child.trace_flow(callback, safety_key)
    end
    code.trace_flow(callback, "#{safety_key}.#{@@safety_key_source += 1}")
  end

  def raise_issue_if_vars_invalid
    c = self.nts
    var_name = c[0].terminals[0];
    unless c[1].terminals[0].eql?(var_name) and c[3].terminals[0].eql?(var_name) and c[4].terminals[0].eql?(var_name)
      raise "for-loop counting variable incorrectly defined, should have the same name"
    end
    # call on code block
    c[5].does_not_contain_assignment(var_name)
  end

  def calculate_type
    vars = self.nts
    code = vars.pop()
    if code.calculate_type.eql?("c")
      @type = "c"
      vars.each do |var|
        var.set_type("n")
      end
    end
    vars.each do |var|
      if var.calculate_type.eql?("s")
        @error_message = "for-loop control variables may not be of type string! '#{var.terminals[1]}' violates this rule!"
        @type = "e"
      end
    end
    @type
  end

  def mark_d_or_prune_based_on_type
    super
    vars = self.nts
    if vars[1].terminals[0].eql?(vars[2].terminals[0])
      @type = "d"
    end
  end
end

class CondBranch < Token
  def mark_d_or_prune_based_on_type
    super
    bool = self.nts[0]
    code = self.nts[1]
    if bool.is_a?(BoolNegation) and bool.child_is_f
      # replace myself with my child
      self.get_parent.replace_child(@id, code)
      self.mark_self_and_children_deleted
    end
  end
end

class IfThenElse < CondBranch #instr
  def trace_flow(callback, safety_key)
    bool = self.nts[0]
    codeA = self.nts[1]
    codeB = self.nts[2]
    bool.trace_flow(callback, safety_key)
    @@needsToRepeat = true
    codeA.trace_flow(callback, safety_key)
    @@set = true
    codeB.trace_flow(callback, safety_key)
    @@needsToRepeat = false
    @@set = false
  end

  def calculate_type
    bool = self.nts[0]
    then_code = self.nts[1]
    else_code = self.nts[2]
    bool_valid = (bool.calculate_type.eql?("b") or bool.calculate_type.eql?("f"))
    code_valid = (then_code.calculate_type.eql?("c") and else_code.calculate_type.eql?("c"))
    if bool_valid and code_valid
      @type = "c"
    end
    @type
  end

  def mark_d_or_prune_based_on_type
    super
    bool = self.nts[0]
    else_code = self.nts[2]
    if bool.peek_type.eql?("f")
      # replace myself with my child
      self.get_parent.replace_child(@id, else_code)
      self.mark_self_and_children_deleted
    end
  end
end

class IfThen < CondBranch #instr
  def trace_flow(callback, safety_key)
    super(callback, "#{@@safety_key_source += 1}")
  end

  def calculate_type
    bool = self.nts[0]
    code = self.nts[1]
    bool_valid = (bool.calculate_type.eql?("f") or bool.calculate_type.eql?("b"))
    code_valid = code.calculate_type.eql?("c")
    if bool_valid and code_valid
      @lgr.info("TRUE")
      @type = "c"
    end
    @type
  end

  def mark_d_or_prune_based_on_type
    super
    bool = self.nts[0]
    if bool.peek_type.eql?("f")
      @type = "d"
      @lgr.info(@type)
    end
  end
end

class Numexpr < Token
  def initialize(lhs, rhs, id)
    super
    @flow = "-"
  end

  def trace_flow(callback, safety_key)
    super
    unless self.all_vars_have_values(callback, safety_key)
      raise "not all vars have values!"
    end
  end

  def all_vars_have_values(callback, safety_key)
    unless self.nts.length == 0
      target = self.nts[0]
      if target.is_a?(Var) and target.read_flow(safety_key).eql?("-")
        return false
      elsif target.is_a?(Calc)
        target.trace_flow(callback, safety_key)
        if target.read_flow(safety_key).eql?("-")
          return false
        end
      end
    end
    @flow = "+"
    true
  end

  def calculate_type
    if self.nts.length == 0
      self.type_integer
    elsif self.nts[0].is_a?(Var)
      self.type_var(self.nts[0])
    elsif self.nts[0].is_a?(Calc)
      self.type_calc(self.nts[0])
    end
    @type
  end

  def only_a_var?
    self.nts.length == 1 and self.nts[0].is_a?(Var)
  end

  def get_child
    self.nts[0]
  end

  def type_integer
    @type = "n"
  end

  def type_var(var)
    if var.calculate_type.eql?("s")
      @error_message = "numexpr may not have var of type string! '#{var.terminals[1]}' breaks this rule!"
      @type = "e"
    else
      var.set_type("n")
      @type = "n"
    end
  end

  def type_calc(calc)
    if calc.calculate_type.eql?("n")
      @type = "n"
    end
  end
end
# VAR, Integer, CALC

class Calc < Token
  def trace_flow(callback, safety_key)
    super
    left = self.nts[0]
    right = self.nts[1]
    if right.read_flow(safety_key).eql?("+") and left.read_flow(safety_key).eql?("+")
      @flow = "+"
    end
  end

  def calculate_type
    left  = self.nts[0]
    right = self.nts[1]
    if left.calculate_type.eql?("n") and right.calculate_type.eql?("n")
      @type = "n"
    end
    @type
  end
end

class AddCalc < Calc
end

class SubCalc < Calc
end

class MultCalc < Calc
end

class Bool < Token
  def trace_flow(callback, safety_key)
    super
    @flow = "+"
  end
end

class BoolEq < Bool
  # VAR, BOOL, NUMEXPR
  def calculate_type
    self.attempt_reduce_to_var_var
    left = self.nts[0]
    right = self.nts[1]
    if left.is_a?(Var)
      self.type_var_var(left, right)
    elsif left.is_a?(Bool)
      self.type_bool_bool(left, right)
    elsif left.is_a?(Numexpr)
      self.type_numexpr_numexpr(left, right)
    end
    @type
  end

  def attempt_reduce_to_var_var
    left = self.nts[0]
    right = self.nts[1]
    if left.is_a?(Numexpr) and right.is_a?(Numexpr)
      if left.only_a_var? and right.only_a_var?
        self.replace_child(left.id, left.get_child)
        self.replace_child(right.id, right.get_child)
        left.mark_as_deleted
        right.mark_as_deleted
      end
    end
  end

  def type_var_var(left, right)
    if left.calculate_type.eql?("n") and right.calculate_type.eql?("s")
      @type = "f"
      return
    elsif right.calculate_type.eql?("n") and left.calculate_type.eql?("s")
      @type = "f"
      return
    elsif left.calculate_type.eql?("n") and not right.calculate_type.eql?("s")
      right.set_type("n")
    elsif right.calculate_type.eql?("n") and not left.calculate_type.eql?("s")
      left.set_type("n")
    elsif left.calculate_type.eql?("s") and not right.calculate_type.eql?("n")
      right.set_type("s")
    elsif right.calculate_type.eql?("s") and not left.calculate_type.eql?("n")
      left.set_type("s")
    else
      left.set_type("o")
      right.set_type("o")
    end
    @type = "b"
  end

  def type_bool_bool(left, right)
    left_bool = (left.calculate_type.eql?("b") or left.calculate_type.eql?("f"))
    right_bool = (right.calculate_type.eql?("b") or right.calculate_type.eql?("f"))
    if left_bool and right_bool
      @type = "b"
    end
  end

  def type_numexpr_numexpr(left, right)
    if left.calculate_type.eql?("n") and right.calculate_type.eql?("n")
      @type = "b"
    end
  end
end

class BoolLessThan < Bool
  def calculate_type
    var_left = self.nts[0]
    var_right = self.nts[1]
    if var_left.calculate_type.eql?("s") or var_right.calculate_type.eql?("s")
      @type_error = "less than comparison may not operate on strings!"
      @type = "e"
    else
      var_left.set_type("n")
      var_right.set_type("n")
      @type = "b"
    end
    @type
  end
end

class BoolGreaterThan < Bool
  def calculate_type
    var_left = self.nts[0]
    var_right = self.nts[1]
    if var_left.calculate_type.eql?("s") or var_right.calculate_type.eql?("s")
      @type_error = "greater than comparison may not operate on strings!"
      @type = "e"
    else
      var_left.set_type("n")
      var_right.set_type("n")
      @type = "b"
    end
    @type
  end
end

class BoolNegation < Bool
  def calculate_type
    bool = self.nts[0]
    if bool.calculate_type.eql?("b") or bool.calculate_type.eql?("f")
      @type = "b"
    end
    @type
  end

  def child_is_f
    bool = self.nts[0]
    bool.peek_type.eql?("f")
  end
end

class BoolAnd < Bool
  def calculate_type
    left = self.nts[0]
    right = self.nts[1]
    if left.calculate_type.eql?("f") and right.calculate_type.eql?("b")
      @type = "f"
    elsif left.calculate_type.eql?("b") and right.calculate_type.eql?("f")
      @type = "f"
    elsif left.calculate_type.eql?("f") and right.calculate_type.eql?("f")
      @type = "f"
    elsif left.calculate_type.eql?("b") and right.calculate_type.eql?("b")
      @type = "b"
    end
    @type
  end
end

class BoolOr < Bool
  def calculate_type
    left = self.nts[0]
    right = self.nts[1]
    left_bool = (left.calculate_type.eql?("b") or left.calculate_type.eql?("f"))
    right_bool = (right.calculate_type.eql?("b") or right.calculate_type.eql?("f"))
    if left_bool and right_bool
      @type = "b"
    end
    @type
  end
end
