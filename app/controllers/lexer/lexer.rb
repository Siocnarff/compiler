require 'autmaton-classes.rb'

def lex_do(file_data)
  lexed = Array.new

  dfa = DFA.new(
    YAML.load_file("#{Rails.root}/public/automata/dfa.yml")
  )

  error_location_text = ''
  count = 1
  line_count = 1
  file_data.split('').push(' ').each do |k|
    if k.ord == 13 or k.ord == 10
      line_count += 1
      error_location_text = ''
    else
      error_location_text += k
    end
    begin
      info = dfa.eat(k)
      if info
        lexed.push("#{count} #{info[0]} #{info[1]}")
        dfa.reset
        if dfa.data_in_buffer?
          dfa.eat(dfa.buffer)
        end
        count += 1
      end
    rescue Exception => e
      if k.ord == 32
        char = "space"
      elsif k.ord == 10
        char = "line feed"
      elsif k.ord == 13
        char = "carraige return"
      else
        char = k
      end
      if e.is_a?(TypeError)
        m = "#{char} is an illegal character here"
      else
        m = "#{e}"
      end
      lexed.push("")
      lexed.push("Lexical Error: #{dfa.token + k}")
      lexed.push("#{m}.")
      lexed.push("#{line_count}: #{error_location_text}")
      lexed.push("Scanning Aborted.")
      break
    end
  end
  return lexed
end
