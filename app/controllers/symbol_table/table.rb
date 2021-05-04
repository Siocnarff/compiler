class SymbolTable
  def initialize
    @table_entries = Array.new
    @current_scope_depth = 0
    @scope = Array.new(
      ScopeInfo.new(
        id = 0,
        start_pos = 0
      )
    )
    # varibles used to genereate global unique ids
    @var_name_id_source = 0
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
    @table_entries = @table_entries[0, @scope.pop.start_pos]
  end

  def getOrGenerateInternalName(name, is_var, is_for_counter)
    scope_string = self.generateScopeString
    @table_entries.each do |entry|
      if entry.name.eql? name and not entry.scope.eql? scope_string
        if entry.is_var?
          raise "error: #{name} already defines a variable" unless is_var
        else
          raise "error: #{name} already defines a procedure" if is_var
        end
        return entry.internal_name
      end
    end
    @table_entries.push(
      TableEntry.new(
        name = name,
        internal_name = generateInternalName(name, is_var, is_for_counter),
        is_for_counter = is_for_counter,
        is_var = is_var,
        scope_string = scope_string
      )
    )
    @table_entries.last
  end


private

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
  def initialize(name, internal_name, is_for_counter, is_var, scope_string)
    @scope_string
    @user_defined_name = name
    @internal_name = internal_name
    @is_for_counter = is_for_counter
    @var = var
    @scope = scope_string
  end

  def internal_name
    @internal_name
  end

  def user_defined_name
    @user_defined_name
  end

  def is_for_counter
    @is_for_counter
  end

  def is_var?
    @var
  end

  def scope
    @scope
  end
end
