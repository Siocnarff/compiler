require 'parser/mapreader.rb'
require 'parser/reducer.rb'
require 'tree/tree.rb'

def parse(token_list)
  token_list.push(["$", "$"])
  tokenGenerator = TokenGenerator.new
  mapReader = MapReader.new("#{Rails.root}/public/parserfiles/data.txt")
  reducer = Reducer.new("#{Rails.root}/public/parserfiles/productions.txt")
  parsetrace = Array.new
  stack = Array.new
  backlog = Array.new
  inbacklog = false
  success = false
  no_change = true
  error_message = "no errors"
  stack.push(0)
  i = 0
  while true
    # for the state we are currently in
    inbacklog = false
    # parsetrace.push(addToTrace(stack))
    # puts addToTrace(stack)
    productions = mapReader.getProductions()
    if backlog.length > 0
      inbacklog = true
      next_state = mapReader.nextState(backlog.last())
    else
      next_state = mapReader.nextState(token_list[i])
    end
    # puts "STATE #{next_state}"
    if next_state.eql? "CHECK NEXT"
      if token_list[i + 1][1].eql?"proc"
        productions = ["6"]
        next_state = "REDUCE"
      else
        mapReader.go(11)
        next_state = 11
      end
    elsif next_state.eql? "DONE"
      if not i < token_list.length - 1
        success = true
      end
      break
    end
    # puts "STATE After #{next_state}"

    if not next_state.eql? "REDUCE"
      no_change = false
      if inbacklog
        stack.push(backlog.pop)
      else
        stack.push(token_list[i])
      end
      stack.push(next_state)
      if not inbacklog
        i = i + 1
      end
    elsif not productions.length == 0
      no_change = false
      if productions[1].eql? token_list[i][1]
        production_number = productions[2]
        # specific token has different production
      else
        production_number = productions[0]
      end
      reduceSteps = reducer.getSteps(production_number)
      rhs = Array.new
      odd = false
      reduceSteps[0].times {
        popped = stack.pop
        if odd
          rhs.push(popped)
        end
        odd = not(odd)
        # puts "poping #{pop}"
        if popped.eql? "REDUCE"
          break
        end
      }
      mapReader.go(stack.last().to_i) # reset DFA
      # we have just popped the righthand of our production from the stack
      # send NT to backlog to be procecced next round
      backlog.push(
        tokenGenerator.generate(production_number.to_i, reduceSteps[1], rhs)
      ) # push tree to backlog
    else
      if no_change
        error_message = "tokens left to read #{token_list.length - i} #{token_list.length} #{i}"
        break
      end
      no_change = true
    end
  end
  return [success, tokenGenerator.getTokens, tokenGenerator.buildTree, error_message]
end

def addToTrace(stack)
  stacktrace = ""
  stack.each do |item|
    if not item.is_a?(Integer)
      if not item.is_a?(Token)
        if item[1].nil?
          stacktrace = "#{stacktrace} #{item[0]}"
        else
          stacktrace = "#{stacktrace} #{item[1]}"
        end
      else
        stacktrace = "#{stacktrace} #{item[0]}"
      end
    end
  end
  return stacktrace
end
