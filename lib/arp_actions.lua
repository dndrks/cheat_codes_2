local arp_actions = {}

arp = {}

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
    -- arp[target].clock = clock.run(arp_actions.arpeggiate, target)
    clock.run(arp_actions.arpeggiate, target)
    arp[target].retrigger = true
end

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

function arp_actions.arpeggiate(target)
  while true do
    clock.sync(arp[target].time)
    if #arp[target].notes > 0 then
      if arp[target].pause == false then
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
    redraw()
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

local direction = {}

for i = 1,3 do
    direction[i] = "positive"
end

function arp_actions.pendulum(target)
    if direction[target] == "positive" then
        arp[target].step = arp[target].step + 1
        if arp[target].step > arp[target].end_point then
            arp[target].step = arp[target].end_point
        end
    elseif direction[target] == "negative" then
        arp[target].step = arp[target].step - 1
        if arp[target].step == arp[target].start_point - 1 then
            arp[target].step = arp[target].start_point
        end
    end
    if arp[target].step == arp[target].end_point and arp[target].step ~= arp[target].start_point then
        direction[target] = "negative"
    elseif arp[target].step == arp[target].start_point then
        direction[target] = "positive"
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
end

function arp_actions.savestate()
  local collection = params:get("collection")
  local dirname = _path.data.."cheat_codes2/arp/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  
  local dirname = _path.data.."cheat_codes2/arp/collection-"..collection.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  for i = 1,3 do
    tab.save(arp[i],_path.data .. "cheat_codes2/arp/collection-"..collection.."/"..i..".data")
  end
end

function arp_actions.loadstate()
  local collection = params:get("collection")
  for i = 1,3 do
    if tab.load(_path.data .. "cheat_codes2/arp/collection-"..collection.."/"..i..".data") ~= nil then
      arp[i] = tab.load(_path.data .. "cheat_codes2/arp/collection-"..collection.."/"..i..".data")
      -- arp[i].clock = nil
      -- arp[i].pause = true
      -- arp[i].playing = false
      -- if arp[i].playing then
      --   arp[i].clock = clock.run(arp_actions.arpeggiate, i)
      -- end
    end
  end
end

return arp_actions