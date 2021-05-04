class SymbolTable
  def initialize
    @var_name_id_source = 0
    @scope_id_source = 0
    @table_entries = Array.new
    @current_scope_depth = 0
    @scope = Array.new(
      ScopeInfo.new(
        id = 0,
        start_pos = 0
      )
    )
  end

  def open_new_scope
    @current_scope.push(
      ScopeInfo.new(
        id = @scope_id_source += 1,
        start_pos = @table_entries.length
      )
    )
  end

  def close_scope
    @table_entries = @table_entries[0, @scope.pop.start_pos]
  end

  def fetchOrFabricateInternalName(name, is_procedure)
    @table_entries.each do |entry|
      if entry.name.eql? name
        if entry.is_var?
          raise "error: #{name} already defines a variable" if is_procedure
        else
          raise "error: #{name} already defines a procedure" unless is_procedure
        end
        return entry.internal_name
      end
    end
    @table_entries.push(
      TableEntry.new(
        name = name,
        internal_name = generateInternalName(name, is_procedure)
      )
    )
    @table_entries.last
  end

private
  def generateInternalName(name, is_procedure)
    if is_procedure
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
  def initialize(name, internal_name, is_for_counter = false, var = true)
    @user_defined_name = name
    @internal_name = internal_name
    @is_for_counter = is_for_counter
    @var = var
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
end
