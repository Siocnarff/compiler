class SymbolTable
  def initialize
    @table_entries = Array.new
    @current_scope_depth = 0
    @scope = Array.new
    @scope.push(
      ScopeInfo.new(
        id = 0,
        start_pos = 0
      )
    )
    # varibles used to genereate global unique ids
    @var_name_id_source = -1
    @proc_name_id_source = -1
    @scope_id_source = 0
  end

  def open_new_scope
    @scope.push(
      ScopeInfo.new(
        id = @scope_id_source += 1,
        start_pos = @table_entries.length
      )
    )
  end

  def close_scope
    @table_entries = @table_entries[0,@scope.pop.start_pos]
  end

  def getOrGenerateVarName(name, is_counter_init = false)
    return getOrGenerateInternalName(
      name,
      is_var = true,
      is_counter_init,
      is_proc_init = false
    )
  end

  def getOrGenerateProcName(name, is_proc_init = false)
    return getOrGenerateInternalName(
      name,
      is_var = false,
      is_counter_init = false,
      is_proc_init
    )
  end

  def proc_def_exists(name)
    @table_entries.each do |entry|
      if entry.is_proc_init and entry.user_defined_name.eql?
        return true
      end
    end
    return false
  end


private
  def getOrGenerateInternalName(name, is_var, is_counter_init, is_proc_init)
    scope_string = self.generateScopeString
    @table_entries.reverse.each do |entry|
      if entry.user_defined_name.eql? name
        if entry.is_var?
          raise "error: \"#{name}\" already defines a variable, "+
          "cannot also define a procedure" unless is_var
        else
          raise "error: \"#{name}\" already defines a procedure, " +
          "cannot also define a variable" if is_var
        end
        unless is_counter_init
          entry.set_is_proc_init(is_proc_init)
          return entry.internal_name
        end
      end
    end
    @table_entries.push(
      TableEntry.new(
        name = name,
        internal_name = generateInternalName(name, is_var),
        is_var = is_var,
        is_proc_init = is_proc_init,
        scope_string = scope_string
      )
    )
    @table_entries.last.internal_name
  end

  def generateScopeString
    scope_string = ""
    @scope.each do |s|
      scope_string += "#{s.id}."
    end
    scope_string.chop
  end

  def generateInternalName(name, is_var)
    unless is_var
      return name
    end
    "v#{@var_name_id_source += 1}"
  end
end

class ScopeInfo
  def initialize(id, start_pos)
    @id = id
    @start_pos = start_pos
  end

  def id
    @id
  end

  def start_pos
    @start_pos
  end
end

class TableEntry
  def initialize(name, internal_name, is_var, is_proc_init, scope_string)
    @user_defined_name = name
    @internal_name = internal_name
    @is_var = is_var
    @is_proc_init = is_proc_init
    @scope = scope_string
  end

  def internal_name
    @internal_name
  end

  def user_defined_name
    @user_defined_name
  end

  def is_var?
    @is_var
  end

  def scope
    @scope
  end

  def is_proc_init
    return @is_proc_init
  end


  def set_is_proc_init(is_init)
    @is_proc_init = is_init
  end
end
