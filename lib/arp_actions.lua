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
    arp[target].mode = "fwd"
    arp[target].start_point = 1
    arp[target].end_point = 1
    arp[target].down = 0
    arp[target].retrigger = true
    arp_clock[target] = clock.run(arp_actions.arpeggiate,target)

    -- arp_timers[target] = {}
    -- arp_timers[target].divisions = {2,3,4,6,8,12,16,24,32,48,64}
    -- for _,division in ipairs(arp_timers[target].divisions) do
    --   arp_timers[target][division]={}
    --   arp_timers[target][division].lattice=arp_lattice:new_pattern{
    --     action=function(t)
    --       arp_actions.iterate(target,division,t)
    --     end,
    --   division=1/(division/2)}
    -- end
    -- arp[target].active_division = 8

end

-- function arp_actions.iterate(target,div,step)
--   -- if div == arp[target].active_division then
--   if div == deci_to_whole[tostring(util.round(bank[target][bank[target].id].arp_time, 0.0001))] then
--     if target == 1 then print(target,bank[target].id,clock.get_beats()) end
--     arp_actions.alt_arpeggiate(target)
--   end
-- end

-- function arp_actions.toggle_arp(target,enable)
--   if enable then
--     clock.run(function()
--       arp[target].lattice.phase = 0
--       clock.sync(arp[target].time)
--       arp[target].lattice:start()
--     end)
--   else
--     arp[target].lattice:stop()
--   end
-- end

function arp_actions.find_index(tab,el)
    local rev = {}
    for k,v in pairs(tab) do
        rev[v]=k
    end
    return rev[el]
end

function arp_actions.momentary(target, value, state)
    if state == "on" then
        table.insert(arp[target].notes, value)
    elseif state == "off" then
        local removed_note = arp_actions.find_index(arp[target].notes,value)
        if removed_note ~= nil then
            table.remove(arp[target].notes, removed_note)
        end
    end
    arp[target].end_point = #arp[target].notes
end

function arp_actions.add(target, value)
    if arp[target].hold then
        table.insert(arp[target].notes, value)
        arp[target].end_point = #arp[target].notes
    end
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
  elseif state == "stop" then
    arp[i].pause = true
    arp[i].playing = false
  end
end

-- function arp_actions.alt_arpeggiate(target)
--   if transport.is_running then
--     if #arp[target].notes > 0 then
--       if arp[target].pause == false then
--         -- if arp[target].step == 1 then print("arp "..target, clock.get_beats()) end
--         if menu ~= 1 then screen_dirty = true end
--         if arp[target].mode == "fwd" then
--           arp_actions.forward(target)
--         elseif arp[target].mode == "bkwd" then
--           arp_actions.backward(target)
--         elseif arp[target].mode == "pend" then
--           arp_actions.pendulum(target)
--         elseif arp[target].mode == "rnd" then
--           arp_actions.random(target)
--         end
--         arp[target].playing = true
--         arp_actions.cheat(target,arp[target].step)
--         grid_dirty = true
--       else
--         arp[target].playing = false
--       end
--     else
--       arp[target].playing = false
--     end
--   end
-- end

function arp_actions.arpeggiate(target)
  while true do
    clock.sync(bank[target][bank[target].id].arp_time)
    if transport.is_running then
      if #arp[target].notes > 0 then
        if arp[target].pause == false then
          -- if arp[target].step == 1 then print("arp "..target, clock.get_beats()) end
          if menu ~= 1 then screen_dirty = true end
          if arp[target].mode == "fwd" then
            arp_actions.forward(target)
          elseif arp[target].mode == "bkwd" then
            arp_actions.backward(target)
          elseif arp[target].mode == "pend" then
            arp_actions.pendulum(target)
          elseif arp[target].mode == "rnd" then
            arp_actions.random(target)
          end
          arp[target].playing = true
          arp_actions.cheat(target,arp[target].step)
          grid_dirty = true
        else
          arp[target].playing = false
        end
      else
        arp[target].playing = false
      end
    end
  end
end

function arp_actions.forward(target)
    arp[target].step = arp[target].step + 1
    if arp[target].step > arp[target].end_point then
        arp[target].step = arp[target].start_point
    end
end

function arp_actions.backward(target)
    arp[target].step = arp[target].step - 1
    if arp[target].step == 0 then
        arp[target].step = arp[target].end_point
    end
end

function arp_actions.random(target)	
  arp[target].step = math.random(arp[target].end_point)	
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

function arp_actions.cheat(target,step)
    if arp[target].notes[step] ~= nil then
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
    end
end

function arp_actions.clear(target)
    arp[target].playing = false
    arp[target].pause = false
    arp[target].hold = false
    arp[target].step = 1
    arp[target].notes = {}
    arp[target].start_point = 1
    arp[target].end_point = 1
    clock.cancel(arp_clock[target])
    arp_clock[target] = nil
    arp_clock[target] = clock.run(arp_actions.arpeggiate,target)
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