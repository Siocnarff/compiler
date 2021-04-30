class MapReader
  def initialize(file_name)
    @s = 1
    @matrix = Array.new
    file_lines = File.open(file_name).read.split("\n")
    file_lines.each do |line|
      @matrix.append(line.split("\t"))
    end
  end

  def go(state)
    @s = state + 1
  end

  def nextState(food)
    # puts "state: #{@s - 1}"
    # puts "food: #{food[0]}"
    if food[0].eql? "S"
      return "DONE"
    end
    c = findDestinationColumn(food)
    if c == -1
      raise "what?"
    end
    if not @s < @matrix.length
      return "exceeded array row bound"
    elsif not @matrix[@s].length > c
      raise "exceeded collumn bound"
    else
      if @matrix[@s][c].eql? ""
        return "REDUCE"
      end
      state = @matrix[@s][c].to_i
      if state == 11 and @s == 15 + 1
        return "CHECK NEXT"
      end
      go(state)
      return state
    end
  end

  def getProductions
    return @matrix[@s][1].split(",")
  end

private
  def findDestinationColumn(food)
    index = 0
    @matrix[0].each do | transition |
      if @s == 38 and food[1].eql? "0"
        return 39
      elsif @s == 48 and food[1].eql? "1"
        return 40
      elsif transition.eql? food[0] or transition.eql? food[1]
        return index
      end
      index = index + 1
    end
    return -1
  end
end
