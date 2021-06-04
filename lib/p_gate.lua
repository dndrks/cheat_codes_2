local p_gate = {}

function p_gate.init()
  pattern_gate = {}
  for i = 1,3 do
    pattern_gate[i] = {[1]={},[2]={},[3]={}}
    for j = 1,3 do
      pattern_gate[i][j].active = false
      pattern_gate[i][j].prob = 100
    end
  end
end

function p_gate.check_prob(stream)
  if stream.prob == 0 then
    return false
  elseif stream.prob >= math.random(1,100) then
    return true
  else
    return false
  end
end

return p_gate