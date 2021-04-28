class Reducer
  def initialize(file_name)
    @productions = File.open(file_name).read.split("\n")
  end

  def getSteps(input)
    target_p = input.to_i
    parsed_p = @productions[target_p].split(" ")
    # puts "input #{input[0]} goes to target #{parsed_p}"
    # puts "length #{parsed_p.length - 1}"
    return [(parsed_p.length - 1)*2, [parsed_p[0]]]
  end
end
