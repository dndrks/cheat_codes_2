local euclid = {}

local er = require 'er'

function euclid.reer(i)
  if euclid.track[i].k == 0 then
    for n=1,32 do euclid.track[i].s[n] = false end
  else
    euclid.track[i].s = euclid.rotate_pattern(er.gen(euclid.track[i].k,euclid.track[i].n), euclid.track[i].rotation)
  end
end

function euclid.trig(target)
  if euclid.track[target].s[euclid.track[target].pos] and not euclid.track[target].mute then
    if euclid.track[target].mode == "single" then
      cheat(target,euclid.rotate_pads(bank[target].id + euclid.track[target].pad_offset))
    elseif euclid.track[target].mode == "span" then
      bank[target].id = euclid.rotate_pads(euclid.track[target].pos + euclid.track[target].pad_offset)
      selected[target].x = (5*(target-1)+1)+(math.ceil(bank[target].id/4)-1)
      if (bank[target].id % 4) ~= 0 then
        selected[target].y = 9-(bank[target].id % 4)
      else
        selected[target].y = 5
      end
      cheat(target,euclid.rotate_pads(euclid.track[target].pos + euclid.track[target].pad_offset))
    end
    grid_dirty = true
    if menu ~= 1 then screen_dirty = true end
  end
end

function euclid.init()

  -- euclid.reset = false
  euclid.alt = false
  euclid.running = false
  euclid.track_edit = 1
  euclid.current_pattern = 0
  euclid.clock_div = {1/2,1/2,1/2}
  euclid.screen_focus = "left"

  euclid.track = {}
  for i = 1,3 do
    euclid.track[i] = {
      k = 0,
      n = 8,
      pos = 1,
      s = {},
      rotation = 0,
      auto_rotation = 0,
      focus = 1,
      pad_offset = 0,
      auto_pad_offset = 0,
      mode = "single",
      clock_div = 1/2,
      runner = 0,
      mute = false
    }
  end

  -- euclid.clock = clock.run(euclid.super_clock)
  euclid.clock = nil

  euclid.reset = { false, false, false}

  euclid.pattern = {}
  for i = 1,112 do
      euclid.pattern[i] = {
        data = 0,
        k = {},
        n = {}
      }
    for x=1,3 do
      euclid.pattern[i].k[x] = 0
      euclid.pattern[i].n[x] = 0
    end
  end

  for i=1,3 do euclid.reer(i) end

end

function euclid.super_clock()
  while true do
    for i = 1,3 do
      euclid.iter(i)
    end
    clock.sync(1/32)
  end
end

function euclid.add_params()
  params:add_group("euclid",3*10)
  local banks = {"[a]","[b]","[c]"}
  for i = 1,3 do
    params:add_separator("bank "..banks[i])
    params:add_number("euclid_pulses_"..i,"pulses",0,16,0)
    params:set_action("euclid_pulses_"..i,function(x)
      if all_loaded then
        if x > rytm.track[i].n then
          params:set("euclid_pulses_"..i,rytm.track[i].n)
        end
        rytm.track[i].k = params:get("euclid_pulses_"..i)
        rytm.reer(i)
      end
    end)
    params:add_number("euclid_duration_"..i,"duration",1,16,8)
    params:set_action("euclid_duration_"..i,function(x)
      if all_loaded then
        if x < rytm.track[i].k then
          params:set("euclid_pulses_"..i,x)
        end
        rytm.track[i].n = x
        rytm.reer(i)
      end
    end)
    params:add_number("euclid_rotation_"..i,"rotation",0,16,0)
    params:set_action("euclid_rotation_"..i,function(x)
      if all_loaded then
        rytm.track[i].rotation = x
        rytm.track[i].s = rytm.rotate_pattern(rytm.track[i].s, rytm.track[i].rotation)
        rytm.reer(i)
      end
    end)
    params:add_number("euclid_pad_offset_"..i,"offset",-15,15,0)
    params:set_action("euclid_pad_offset_"..i,function(x)
      if all_loaded then
        rytm.track[i].pad_offset = x
        rytm.reer(i)
      end
    end)
    params:add_option("euclid_mode_"..i,"mode",{"single","span"},1)
    params:set_action("euclid_mode_"..i,function(x)
      if all_loaded then
        rytm.track[i].mode = params:string("euclid_mode_"..i)
        rytm.reer(i)
      end
    end)
    params:add_option("euclid_clock_div_"..i,"clock rate",{"1/16","1/8","1/4","1/2","1"},2)
    params:set_action("euclid_clock_div_"..i,function(x)
      if all_loaded then
        local translate_times = {0.25,0.5,1,2,4}
        rytm.track[i].clock_div = translate_times[x]
        rytm.reer(i)
      end
    end)
    params:add_number("euclid_auto_rotation_"..i,"auto rotation step",0,16,0)
    params:set_action("euclid_auto_rotation_"..i,function(x)
      if all_loaded then
        rytm.track[i].auto_rotation = x
        rytm.reer(i)
      end
    end)
    params:add_number("euclid_auto_offset_"..i,"auto offset step",-15,15,0)
    params:set_action("euclid_auto_offset_"..i,function(x)
      if all_loaded then
        rytm.track[i].auto_pad_offset = x
        rytm.reer(i)
      end
    end)
    params:add_binary("euclid_mute_"..i,"mute","toggle")
    params:set_action("euclid_mute_"..i, function(x)
      if all_loaded then
        euclid.toggle_mute(i)
      end
    end)
  end
end

function euclid.iter(target)
  euclid.track[target].runner = euclid.track[target].runner + 1
  if euclid.track[target].runner > 32 * euclid.track[target].clock_div then
    euclid.track[target].runner = euclid.track[target].runner - (32 * euclid.track[target].clock_div)
    euclid.track[target].pos = (euclid.track[target].pos % euclid.track[target].n) + 1
    euclid.trig(target)
    if euclid.track[target].pos == euclid.track[target].n and euclid.track[target].auto_rotation ~= 0 then
      local new_rotation = (euclid.track[target].rotation + euclid.track[target].auto_rotation)%16
      euclid.track[target].rotation = new_rotation
      euclid.track[target].s = euclid.rotate_pattern(euclid.track[target].s, euclid.track[target].rotation)
    end
    if euclid.track[target].pos == euclid.track[target].n and euclid.track[target].auto_pad_offset ~= 0 then
      local sign = (euclid.track[target].pad_offset + euclid.track[target].auto_pad_offset) < 0 and -16 or 16
      euclid.track[target].pad_offset = (euclid.track[target].pad_offset + euclid.track[target].auto_pad_offset) % sign
    end
    if menu == 8 then screen_dirty = true end
  end
end

function euclid.reset_pattern(target)
  if euclid.restarting == false or euclid.restarting == nil then
    clock.run(function()
      euclid.restarting = true
      clock.sync(4)
      euclid.trig(target)
      euclid.reset[target] = true
      euclid.track[target].runner = 0
      euclid.track[target].pos = 1
      euclid.reset[target] = false
      screen.dirty = true
      euclid.restarting = false
    end)
  end
end

function euclid.reset_all_patterns()
  if euclid.all_restarting == false or euclid.all_restarting == nil then
    clock.run(function()
      euclid.all_restarting = true
      clock.sync(4)
      if euclid.clock ~= nil then
        clock.cancel(euclid.clock)
      end
      for target = 1,3 do
        euclid.trig(target)
        euclid.reset[target] = true
        euclid.track[target].runner = 0
        euclid.track[target].pos = 1
        euclid.reset[target] = false
      end
      euclid.clock = clock.run(euclid.super_clock)
      screen.dirty = true
      euclid.all_restarting = false
    end)
  end
end

function euclid.toggle(state)
  if state == "start" then
    euclid.all_restarting = true
    if euclid.clock ~= nil then
      clock.cancel(euclid.clock)
    end
    for target = 1,3 do
      euclid.reset[target] = true
      euclid.track[target].runner = 0
      euclid.track[target].pos = 1
      euclid.reset[target] = false
      euclid.trig(target)
    end
    euclid.clock = clock.run(euclid.super_clock)
    screen.dirty = true
    euclid.all_restarting = false
  elseif state == "stop" then
    if euclid.clock ~= nil then
      clock.cancel(euclid.clock)
    end
    -- euclid.trig(target)
  end
  screen.dirty = true
end

function euclid.step(target)
  while true do
    clock.sync(euclid.track[target].clock_div)
    euclid.track[target].pos = (euclid.track[target].pos % euclid.track[target].n) + 1
    euclid.trig(target)
    if euclid.track[target].pos == euclid.track[target].n and euclid.track[target].auto_rotation ~= 0 then
      local new_rotation = (euclid.track[target].rotation + euclid.track[target].auto_rotation)%16
      euclid.track[target].rotation = new_rotation
      euclid.track[target].s = euclid.rotate_pattern(euclid.track[target].s, euclid.track[target].rotation)
    end
    if euclid.track[target].pos == euclid.track[target].n and euclid.track[target].auto_pad_offset ~= 0 then
      local sign = (euclid.track[target].pad_offset + euclid.track[target].auto_pad_offset) < 0 and -16 or 16
      euclid.track[target].pad_offset = (euclid.track[target].pad_offset + euclid.track[target].auto_pad_offset) % sign
    end
    if menu ~= 1 then screen_dirty = true end
  end
end

function euclid.rotate_pattern(t, rot, n, r)
  -- rotate_pattern comes to us via okyeron and stackexchange, which appeared originally in justmat's foulplay
  n, r = n or #t, {}
  rot = rot % n
  for i = 1, rot do
    r[i] = t[n - rot + i]
  end
  for i = rot + 1, n do
    r[i] = t[i - rot]
  end
  return r
end

function euclid.rotate_pads(i)
  if i < 1 then
    i = (16 - (1 - i) % (15))+1;
  end
  return 1 + (i - 1) % 16
end

function euclid.savestate()
  local collection = params:get("collection")
  local dirname = _path.data.."cheat_codes_2/rytm/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  
  local dirname = _path.data.."cheat_codes_2/rytm/collection-"..collection.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  for i = 1,3 do
    tab.save(euclid.track[i],_path.data .. "cheat_codes_2/rytm/collection-"..collection.."/"..i..".data")
  end
end

function euclid.restore_collection()
  for i = 1,3 do
    euclid.track[i].auto_rotation = euclid.track[i].auto_rotation == nil and 0 or euclid.track[i].auto_rotation
    euclid.track[i].auto_pad_offset = euclid.track[i].auto_pad_offset == nil and 0 or euclid.track[i].auto_pad_offset
    if euclid.track[i].mute == nil then
      euclid.track[i].mute = false
    end
    params:set("euclid_pulses_"..i,euclid.track[i].k)
    params:set("euclid_duration_"..i,euclid.track[i].n)
    params:set("euclid_rotation_"..i,euclid.track[i].rotation)
    params:set("euclid_pad_offset_"..i,euclid.track[i].pad_offset)
    params:set("euclid_mode_"..i,euclid.track[i].mode == "single" and 1 or 2)
    local translate_times = {0.25,0.5,1,2,4}
    local restore_clock_div = tab.key(translate_times,euclid.track[i].clock_div)
    params:set("euclid_clock_div_"..i,restore_clock_div)
    params:set("euclid_auto_rotation_"..i,euclid.track[i].auto_rotation)
    params:set("euclid_auto_offset_"..i,euclid.track[i].auto_pad_offset)
    if euclid.track[i].mute then
      params:set("euclid_mute_"..i,1)
    else
      params:set("euclid_mute_"..i,0)
    end
  end
end

function euclid.toggle_mute(i)
  euclid.track[i].mute = not euclid.track[i].mute
end

return euclid