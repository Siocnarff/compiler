require './table.rb'

st = SymbolTable.new
puts st.getOrGenerateVarName("a")
puts st.getOrGenerateVarName("b")
puts st.getOrGenerateVarName("c")
puts st.getOrGenerateVarName("a")
st.open_new_scope
puts st.getOrGenerateVarName("b")
puts st.getOrGenerateVarName("b", is_counter_init = true)
st.open_new_scope
puts st.getOrGenerateVarName("b", is_counter_init = true)
st.open_new_scope
puts "B Should Still Have Same Internal Name"
puts st.getOrGenerateVarName("b")
st.close_scope
puts st.getOrGenerateVarName("b")
st.close_scope
puts st.getOrGenerateProcName("myProc")
puts st.getOrGenerateVarName("c")
puts st.getOrGenerateVarName("e")
