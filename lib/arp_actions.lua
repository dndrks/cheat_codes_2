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
    arp[target].retrigger = true
    arp_clock[target] = clock.run(arp_actions.arpeggiate,target)
end

function arp_actions.find_index(tab,el)
    local rev = {}
    for k,v in pairs(tab) do
        rev[v]=k
    end
    return rev[el]
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
          table.remove(arp[target].notes, removed_note)
      end
      arp[target].end_point = #arp[target].notes
    end
  -- end
end

function arp_actions.add(target, position, value)
    arp[target].notes[position] = value
    arp[target].end_point = position
end

function arp_actions.toggle(state,target)
  local i = target
  if state == "start" then
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
      if arp[i].enabled then arp[i].enabled = false end
    end
  elseif state == "stop" then
    arp[i].pause = true
    arp[i].playing = false
    arp[i].step = arp[i].start_point
    arp[i].conditional.cycle = 0
  end
end

function arp_actions.arpeggiate(target)
  while true do
    -- clock.sync(bank[target][bank[target].id].arp_time)
    clock.sync(arp[target].time)
    arp_actions.tick(target)
  end
end

function arp_actions.tick(target,source)
  if transport.is_running then
    -- if #arp[target].notes > 0 then
    if tab.count(arp[target].notes) > 0 or params:string("arp_"..target.."_hold_style") == "sequencer" then
      if arp[target].pause == false then
        -- if arp[target].step == 1 then print("arp "..target, clock.get_beats()) end
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
      arp[target].notes[i] = snakes[style][util.wrap(i,1,16)]
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
    arp[target].enabled = true
    arp[target].pause = true
    arp[target].hold = true
    grid_dirty = true
  end
  screen_dirty = true
end

function arp_actions.process(target,source)
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
  arp[target].step = util.wrap(arp[target].step + 1,arp[target].start_point,arp[target].end_point)
  if arp[target].step == arp[target].start_point then
    arp[target].conditional.cycle = arp[target].conditional.cycle + 1
  end
end

function arp_actions.backward(target)
  arp[target].step = util.wrap(arp[target].step - 1,arp[target].start_point,arp[target].end_point)
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
    if arp_actions.check_prob(target,step) then
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
  -- if not arp[target].gate.active
  -- or (arp[target].gate.active and arp_actions.check_gate_prob(target))
  if not pattern_gate[target][1].active and not pattern_gate[target][2].active
  then
    bank[target].id = arp[target].notes[step]
    selected[target].x = (5*(target-1)+1)+(math.ceil(bank[target].id/4)-1)
    if (bank[target].id % 4) ~= 0 then
      selected[target].y = 9-(bank[target].id % 4)
    else
      selected[target].y = 5
    end
    if arp[target].retrigger then
      cheat(target,bank[target].id)
    else
      if arp[target].notes[step] ~= arp[target].notes[step-1] then
        cheat(target,bank[target].id)
      end
    end
      -- print(clock.get_beats()..": "..(source == nil and "" or source))
  end
end

function arp_actions.clear(target)
  if params:string("arp_"..target.."_hold_style") ~= "sequencer" then
    arp[target].playing = false
    arp[target].pause = false
    arp[target].hold = false
    arp[target].notes = {}
    arp[target].start_point = 1
    arp[target].end_point = 1
    arp[target].step = arp[target].start_point
    clock.cancel(arp_clock[target])
    arp_clock[target] = nil
    arp_clock[target] = clock.run(arp_actions.arpeggiate,target)
  elseif params:string("arp_"..target.."_hold_style") == "sequencer" then
    arp[target].notes = {}
  end
end

function arp_actions.savestate()
  local collection = params:get("collection")
  local dirname = _path.data.."cheat_codes_2/arp/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  
  local dirname = _path.data.."cheat_codes_2/arp/collection-"..collection.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  for i = 1,3 do
    tab.save(arp[i],_path.data .. "cheat_codes_2/arp/collection-"..collection.."/"..i..".data")
  end
end

function arp_actions.loadstate()
  local collection = params:get("collection")
  for i = 1,3 do
    if tab.load(_path.data .. "cheat_codes_2/arp/collection-"..collection.."/"..i..".data") ~= nil then
      arp[i] = tab.load(_path.data .. "cheat_codes_2/arp/collection-"..collection.."/"..i..".data")
    end
  end
end

function arp_actions.restore_collection()
  for i = 1,3 do
    arp[i].down = arp[i].down == nil and 0 or arp[i].down
  end
end

return arp_actions