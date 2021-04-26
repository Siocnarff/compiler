class Transition
  def initialize(on, to)
    @on = on
    @to = to
  end
  def eat(k)
    if @on.include?(k)
      return @to
    end
    return false
  end
end

class State
  def initialize(id, label = "", error = "")
    @transitions = Array.new
    @id = id
    @is_accepting = label != ""
    @label = label
    @error = error
  end
  def add_transition(t)
    @transitions.push(t)
  end
  def transitions
    return @transitions
  end
  def eat(k)
    @transitions.each do |t|
      go_to = t.eat(k)
      if go_to
        return go_to
      end
    end
    raise @error
  end
  def is_accepting?
    return @is_accepting
  end
  def get_class_label
    return @label
  end
  def get_id
    return @id
  end
  def get_error
    return @error
  end
end

class DFA
  def initialize(dfa)
    @buffer = ''
    @token = ''
    @current_state = 1
    @states = Array.new
    dfa['states'].each do |s|
      alpha_ex_go_to = 0
      do_alpha_numa_ex = false
      s_id = s.keys[0]
      s_data = s.values[0]
      state = State.new(s_id, s_data["label"], s_data["error"])
      letters = Array.new
      if not s_data["transitions"].nil?
        s_data["transitions"].each do |t|
          if t[0].is_a?(Array)
            letters += t[0]
            state.add_transition(Transition.new(t[0], t[1]))
          elsif t[0] == 'alpha_numa_ex'
            do_alpha_numa_ex = true
            alpha_ex_go_to = t[1]
          else
            letters += dfa[t[0]]
            state.add_transition(Transition.new(dfa[t[0]], t[1]))
          end
        end
        if do_alpha_numa_ex
          state.add_transition(
            Transition.new(
              (dfa['alpha'] | dfa['dnull']) - letters, alpha_ex_go_to
            )
          )
        end
      end
      @states[state.get_id] = state
    end
  end
  def reset
    @token = ''
    @current_state = 1
  end
  def eat(k)
    @buffer = ''
    current = @states[@current_state]
    if k.ord != 10 and k.ord != 13 and k.ord != 32
      @buffer = k
    elsif @current_state == 1
      return false
    end
    begin
      @current_state = current.eat(k)
    rescue
      if current.is_accepting?
        return [current.get_class_label, @token]
      else
        raise current.get_error
      end
    end
    @token += k
    return false
  end
  def token
    return @token
  end
  def data_in_buffer?
    return @buffer != ''
  end
  def buffer
    return @buffer
  end
end
