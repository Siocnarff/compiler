require 'yaml'

class ProcessController < ApplicationController
	def lex
		@lexed = Array.new
	  	@file_data = Upload.find(params[:id]).body

	  	puts @file_data
	  	dfa = DFA.new(
			YAML.load_file("#{Rails.root}/public/automata/dfa.yml")
		)

		error_location_text = ''
		count = 1
		line_count = 1
		@file_data.split('').push(' ').each do |k|
			if k.ord == 13 or k.ord == 10
				line_count += 1
				error_location_text = ''
			else 
				error_location_text += k
			end
			begin
				info = dfa.eat(k)
				if info
					@lexed.push("#{count} #{info[0]} #{info[1]}")
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
				@lexed.push("")
				@lexed.push("Lexical Error: #{dfa.token + k}")
				@lexed.push("#{m}.")
				@lexed.push("#{line_count}: #{error_location_text}")
				@lexed.push("Scanning Aborted.")
				break
			end
		end
	end
	private
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
end


