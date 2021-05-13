local p_gate = {}

function p_gate.init()
  pattern_gate = {}
  for i = 1,3 do
    pattern_gate[i] = {[1]={},[2]={}}
    for j = 1,2 do
      pattern_gate[i][j].active = false
      pattern_gate[i][j].prob = 0
    end
  end
end

return p_gate