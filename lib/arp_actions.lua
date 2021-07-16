local arp_actions = {}

arp = {}

arp_clock = {}

arp_lattice = lattice:new{
  -- auto = true,
  -- meter = 4,
  ppqn = 32
}
arp_timers = {}

local deci_to_whole =
{ ["0.125"] = 64
, ["0.1667"] = 48
, ["0.25"] = 32
, ["0.3333"] = 24
, ["0.5"] = 16
, ["0.6667"] = 12
, ["1.0"] = 8
, ["1.3333"] = 6
, ["2.0"] = 4
, ["2.6667"] = 3
, ["4.0"] = 2
}

function arp_actions.init(target)
    arp[target] = {}
    arp[target].playing = false
    arp[target].pause = false
    arp[target].hold = false
    arp[target].enabled = false
    arp[target].time = 1/4
    arp[target].step = 1
    arp[target].notes = {}
    arp[target].prob = {}
    arp[target].conditional = {}
    arp[target].conditional.cycle = 0
    arp[target].conditional.A = {}
    arp[target].conditional.B = {}
    for i = 1,128 do
      arp[target].prob[i] = 100
      arp[target].conditional.A[i] = 1
      arp[target].conditional.B[i] = 1
    end
    arp[target].gate = {}
    arp[target].gate.active = false
    arp[target].gate.prob = 0
    arp[target].swing = 50
    arp[target].mode = "fwd"
    arp[target].start_point = 1
    arp[target].end_point = 16
    arp[target].down = 0
    arp[target].loop = true
    arp_clock[target] = clock.run(arp_actions.arpeggiate,target)
end

function arp_actions.find_index(tab,el)
    local rev = {}
    for k,v in pairs(tab) do
        rev[v]=k
    end
    return rev[el]
end

function arp_actions.remove_momentary(i,j)
  grid_actions.kill_note(i,arp[i].notes[j])
  table.remove(arp[i].notes,j)
end

function arp_actions.momentary(target, value, state)
  -- if not arp[target].gate.active then
    if state == "on" then
      if params:string("arp_"..target.."_hold_style") ~= "sequencer" then
        table.insert(arp[target].notes, value)
        arp[target].end_point = #arp[target].notes
      else
        if arp[target].notes[arp[target].step] ~= nil then
          if arp[target].step == #arp[target].notes then
            table.insert(arp[target].notes, arp[target].step, value)
          else
            arp[target].notes[arp[target].step] = value
            cheat(target,value)
          end
        else
          arp[target].notes[arp[target].step] = value
          cheat(target,value)
        end
      end
    elseif state == "off" then
      local removed_note = arp_actions.find_index(arp[target].notes,value)
      if removed_note ~= nil then
        -- print("turning note off")
        arp_actions.remove_momentary(target, removed_note)
        -- grid_actions.kill_note(target,removed_note)-- ?
      end
      arp[target].end_point = #arp[target].notes
    end
  -- end
end

function arp_actions.add(target, position, value)
    arp[target].notes[position] = value
    arp[target].end_point = position
end

function arp_actions.enable(target,state)
  arp[target].enabled = state
end

function arp_actions.toggle(state,target)
  local i = target
  if state == "start" then
    arp_actions.start_playback(i)
  elseif state == "stop" then
    arp_actions.stop_playback(i)
  end
end

function arp_actions.start_playback(i)
  local arp_start =
  {
    ["fwd"] = arp[i].start_point - 1
  , ["bkwd"] = arp[i].end_point + 1
  , ["pend"] = arp[i].start_point
  , ["rnd"] = arp[i].start_point - 1
  }
  arp[i].step = arp_start[arp[i].mode]
  arp[i].pause = false
  arp[i].playing = true
  if arp[i].mode == "pend" then
    arp_direction[i] = "negative"
  end
  if not transport.is_running then
    print("should start transport...")
    transport.toggle_transport()
  end
  if params:string("arp_"..i.."_hold_style") == "sequencer" then
    if arp[i].enabled then arp_actions.enable(i,false) end
  end
  grid_dirty = true
end

function arp_actions.stop_playback(i)
  arp[i].pause = true
  arp[i].playing = false
  arp[i].step = arp[i].start_point
  arp[i].conditional.cycle = 0
  -- clock.run(function() clock.sleep(0.25) grid_dirty = true end)
  for k,v in pairs(arp[i].notes) do
    if tab.contains(held_keys[i],v) then
      -- print("<<<--->>>"..v)
      grid_actions.kill_note(i,v)
    end
  end
  grid_dirty = true
end

function arp_actions.arpeggiate(target)
  while true do
    clock.sync(arp[target].time)
    arp_actions.tick(target)
  end
end

function arp_actions.tick(target,source)
  if transport.is_running then
    if tab.count(arp[target].notes) > 0 or params:string("arp_"..target.."_hold_style") == "sequencer" then
      if arp[target].pause == false then
        if arp[target].step == arp[target].end_point and not arp[target].loop then
          arp_actions.stop_playback(target)
        else
          if arp[target].swing > 50 and arp[target].step % 2 == 1 then
            local base_time = (clock.get_beat_sec() * arp[target].time)
            local swung_time =  base_time*util.linlin(50,100,0,1,arp[target].swing)
            clock.run(function()
              clock.sleep(swung_time)
              arp_actions.process(target)
            end)
          else
            arp_actions.process(target,source)
          end
          arp[target].playing = true
          grid_dirty = true
        end
      else
        arp[target].playing = false
      end
    else
      arp[target].playing = false
    end
  end
end

function arp_actions.fill(target,s_p,e_p,style)
  local snakes = 
  { 
      [1] = { 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16 }
    , [2] = { 1,2,3,4,8,7,6,5,9,10,11,12,16,15,14,13 }
    , [3] = { 1,5,9,13,2,6,10,14,3,7,11,15,4,8,12,16 }
    , [4] = { 1,5,9,13,14,10,6,2,3,7,11,15,16,12,8,4 }
    , [5] = { 1,2,3,4,8,12,16,15,14,13,9,5,6,7,11,10 }
    , [6] = { 13,14,15,16,12,8,4,3,2,1,5,9,10,11,7,6 }
    , [7] = { 1,2,5,9,6,3,4,7,10,13,14,11,8,12,15,16 }
    , [8] = { 1,6,11,16,15,10,5,2,7,12,8,3,9,14,13,4 }
  }
  if style ~= 9 then
    for i = s_p,e_p do
      arp[target].notes[i] = snakes[style][wrap(i,1,16)]
    end
  else
    for i = s_p,e_p do
      arp[target].notes[i] = math.random(1,16)
    end
  end
  if not arp[target].playing
  and not arp[target].pause
  and not arp[target].enabled
  then
    arp_actions.enable(target,true)
    arp[target].pause = true
    arp[target].hold = true
    grid_dirty = true
  end
  screen_dirty = true
end

function arp_actions.process(target,source)
  if arp[target].step == nil then
    print("how is arp step nil???")
    arp[target].step = arp[target].start_point
  end
  if arp[target].mode == "fwd" then
    arp_actions.forward(target)
  elseif arp[target].mode == "bkwd" then
    arp_actions.backward(target)
  elseif arp[target].mode == "pend" then
    arp_actions.pendulum(target)
  elseif arp[target].mode == "rnd" then
    arp_actions.random(target)
  end
  if menu ~= 1 then screen_dirty = true end
  arp_actions.cheat(target,arp[target].step,source)
end

function arp_actions.forward(target)
  arp[target].step = wrap(arp[target].step + 1,arp[target].start_point,arp[target].end_point)
  if arp[target].step == arp[target].start_point then
    arp[target].conditional.cycle = arp[target].conditional.cycle + 1
  end
end

function arp_actions.backward(target)
  arp[target].step = wrap(arp[target].step - 1,arp[target].start_point,arp[target].end_point)
  if arp[target].step == arp[target].end_point then
    arp[target].conditional.cycle = arp[target].conditional.cycle + 1
  end
end

function arp_actions.random(target)	
  arp[target].step = math.random(arp[target].start_point,arp[target].end_point)
  if arp[target].step == arp[target].start_point or arp[target].step == arp[target].end_point then
    arp[target].conditional.cycle = arp[target].conditional.cycle + 1
  end
end

arp_direction = {}

for i = 1,3 do
  arp_direction[i] = "positive"
end

function arp_actions.pendulum(target)
    if arp_direction[target] == "positive" then
        arp[target].step = arp[target].step + 1
        if arp[target].step > arp[target].end_point then
            arp[target].step = arp[target].end_point
        end
    elseif arp_direction[target] == "negative" then
        arp[target].step = arp[target].step - 1
        if arp[target].step == arp[target].start_point - 1 then
            arp[target].step = arp[target].start_point
        end
    end
    if arp[target].step == arp[target].end_point and arp[target].step ~= arp[target].start_point then
      arp_direction[target] = "negative"
    elseif arp[target].step == arp[target].start_point then
      arp_direction[target] = "positive"
    end
end

function arp_actions.check_prob(target,step)
  if arp[target].prob[step] == 0 then
    return false
  elseif arp[target].prob[step] >= math.random(1,100) then
    return true
  else
    return false
  end
end

function arp_actions.cheat(target,step,source)
  if arp[target].notes[step] ~= nil then
    if (pattern_gate[target][1].active and p_gate.check_prob(pattern_gate[target][1])) or not pattern_gate[target][1].active then
      local should_happen = arp_actions.check_prob(target,step)
      if should_happen then
        if arp[target].conditional.cycle < arp[target].conditional.A[step] then
        elseif arp[target].conditional.cycle == arp[target].conditional.A[step] then
          arp_actions.execute_step(target,step,source)
        elseif arp[target].conditional.cycle > arp[target].conditional.A[step] then
          if arp[target].conditional.cycle <= (arp[target].conditional.A[step] + arp[target].conditional.B[step]) then
            if arp[target].conditional.cycle % (arp[target].conditional.A[step] + arp[target].conditional.B[step]) == 0 then
              arp_actions.execute_step(target,step,source)
            end
          else
            if (arp[target].conditional.cycle - arp[target].conditional.A[step]) % arp[target].conditional.B[step] == 0 then
              arp_actions.execute_step(target,step,source)
            end
          end
        end
      else
        -- print("missed it. ",target,arp[target].notes[wrap(step-1,arp[target].start_point,arp[target].end_point)])
        grid_actions.kill_note(target,arp[target].notes[wrap(step-1,arp[target].start_point,arp[target].end_point)])
        -- want to kill the previous note...
      end
    end
  end
end

function arp_actions.check_gate_prob(target)
  if  arp[target].gate.prob == 0 then
    return false
  elseif arp[target].gate.prob >= math.random(1,100) then
    return true
  else
    return false
  end
end

function arp_actions.execute_step(target,step,source)
  if (not pattern_gate[target][2].active and not pattern_gate[target][3].active)
  or (pattern_gate[target][2].active and pattern_gate[target][1].active)
  then
    local last_pad = arp[target].notes[wrap(step-1,arp[target].start_point,arp[target].end_point)]
    bank[target].id = arp[target].notes[step]
    selected[target].x = (5*(target-1)+1)+(math.ceil(bank[target].id/4)-1)
    if (bank[target].id % 4) ~= 0 then
      selected[target].y = 9-(bank[target].id % 4)
    else
      selected[target].y = 5
    end
    arp_actions.resolve_step(target,step,last_pad)
  end
end

function arp_actions.resolve_step(target,step,last_pad)
  if last_pad ~= nil then
    local next_pad = arp[target].notes[wrap(step+1,arp[target].start_point,arp[target].end_point)]
    -- print("killing "..tostring(last_pad)) -- do i care if this executes on the first run?
    grid_actions.kill_note(target,last_pad)
    grid_actions.add_held_key(target,arp[target].notes[step])
    cheat(target,bank[target].id)
    -- print("playing "..bank[target].id)
    if next_pad == nil then
      -- print("forcing "..bank[target].id.." off")
      arp_actions.timed_note_off(target,bank[target].id)
    end
  else
    -- print("WEIRIIRIRIRIRD..."..arp[target].notes[step])
    grid_actions.add_held_key(target,arp[target].notes[step])
    cheat(target,bank[target].id)
    local this_last_pad = arp[target].notes[step]
    -- print("the last one "..this_last_pad)
    arp_actions.timed_note_off(target,this_last_pad)
  end
end

function arp_actions.timed_note_off(target,pad)
  clock.run(function()
    clock.sleep(clock.get_beat_sec() * (arp[target].time-(arp[target].time/10)))
    grid_actions.kill_note(target,pad)
    -- print("killing", target, pad)
  end)
end

function arp_actions.clear(target)
  for k,v in pairs(arp[target].notes) do
    if tab.contains(held_keys[target],v) then
      -- print("////>"..v)
      grid_actions.kill_note(target,v)
    end
  end
  if params:string("arp_"..target.."_hold_style") ~= "sequencer" then
    arp[target].playing = false
    arp[target].pause = false
    arp[target].hold = false
    arp[target].notes = {}
    arp[target].start_point = 1
    arp[target].end_point = 1
    arp[target].step = arp[target].start_point
    arp[target].loop = true
    clock.cancel(arp_clock[target])
    arp_clock[target] = nil
    arp_clock[target] = clock.run(arp_actions.arpeggiate,target)
  elseif params:string("arp_"..target.."_hold_style") == "sequencer" then
    arp[target].notes = {}
  end
end

function arp_actions.savestate()
  local collection = params:get("collection")
  local dirname = _path.data.."cheat_codes_yellow/arp/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  
  local dirname = _path.data.."cheat_codes_yellow/arp/collection-"..collection.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  for i = 1,3 do
    tab.save(arp[i],_path.data .. "cheat_codes_yellow/arp/collection-"..collection.."/"..i..".data")
  end
end

function arp_actions.loadstate()
  local collection = params:get("collection")
  for i = 1,3 do
    if tab.load(_path.data .. "cheat_codes_yellow/arp/collection-"..collection.."/"..i..".data") ~= nil then
      arp[i] = tab.load(_path.data .. "cheat_codes_yellow/arp/collection-"..collection.."/"..i..".data")
    end
  end
end

function arp_actions.restore_collection()
  for i = 1,3 do
    arp[i].down = arp[i].down == nil and 0 or arp[i].down
  end
end

return arp_actions