require './table.rb'

st = SymbolTable.new
puts st.getOrGenerateInternalName("a", is_var = false, is_for_counter = false).inspect
puts st.getOrGenerateInternalName("b", is_var = true, is_for_counter = false).inspect
puts st.getOrGenerateInternalName("c", is_var = true, is_for_counter = false).inspect
puts st.getOrGenerateInternalName("a", is_var = true, is_for_counter = false).inspect
puts st.getOrGenerateInternalName("b", is_var = true, is_for_counter = false).inspect
puts st.getOrGenerateInternalName("c", is_var = true, is_for_counter = false).inspect
puts st.getOrGenerateInternalName("e", is_var = true, is_for_counter = false).inspect
