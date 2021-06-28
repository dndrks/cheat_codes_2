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

function p_gate.flip(i,j)
  if (j == 2 or j == 3) and not pattern_gate[i][1].active then
    for k,v in pairs(arp[i].notes) do
      if tab.contains(held_keys[i],v) then
        grid_actions.kill_note(i,v)
      end
    end
  elseif (j == 1 or j == 3) and not pattern_gate[i][2].active then
    for k = 1,#grid_pat[i].event do
      if tab.contains(held_keys[i],grid_pat[i].event[k].id) then
        print(">>>"..grid_pat[i].event[k].id, clock.get_beats())
        grid_actions.kill_note(i,grid_pat[i].event[k].id)
      end
    end
    if pattern_gate[i][1] and pattern_gate[i][2] and arp[i].enabled and not arp[i].hold then
      arp[i].down = 0
    end
  end
  pattern_gate[i][j].active = not pattern_gate[i][j].active
end

function p_gate.check_conflicts(i,source)
  local source = tab.key({"arp","grid","euclid"},source)
  for j = 1,3 do
    if j ~= source then
      if not pattern_gate[i][j].active then
        if j == 1 then
          for k,v in pairs(arp[i].notes) do
            if tab.contains(held_keys[i],v) then
              grid_actions.kill_note(i,v)
            end
          end
        elseif j == 2 then
          for k = 1,#grid_pat[i].event do
            if tab.contains(held_keys[i],grid_pat[i].event[k].id) then
              print(">>>"..grid_pat[i].event[k].id, clock.get_beats())
              grid_actions.kill_note(i,grid_pat[i].event[k].id)
            end
          end
          if pattern_gate[i][1] and pattern_gate[i][2] and arp[i].enabled and not arp[i].hold then
            arp[i].down = 0
          end
        end
      end
    end
  end
end

return p_gate