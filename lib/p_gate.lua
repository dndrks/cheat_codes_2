local p_gate = {}

function p_gate.init()
  pattern_gate = {}
  for i = 1,3 do
    pattern_gate[i] = {}
    pattern_gate[i].active = false
    pattern_gate[i].prob = 0
  end
end

return p_gate