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
  if euclid.track[target].s[euclid.track[target].pos] then
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
      clock_div = 1/2
    }
    -- clock.run(euclid.step,i)
  end

  euclid.clock =
  { clock.run(euclid.step,1)
  , clock.run(euclid.step,2)
  , clock.run(euclid.step,3)
  }

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

function euclid.reset_pattern(target)
  euclid.reset[target] = true
  clock.cancel(euclid.clock[target])
  euclid.track[target].pos = 0
  euclid.reset[target] = false
  euclid.clock[target] = clock.run(euclid.step,target)
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
  local dirname = _path.data.."cheat_codes2/rytm/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  
  local dirname = _path.data.."cheat_codes2/rytm/collection-"..collection.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  for i = 1,3 do
    tab.save(euclid.track[i],_path.data .. "cheat_codes2/rytm/collection-"..collection.."/"..i..".data")
  end
end

function euclid.restore_collection()
  for i = 1,3 do
    euclid.track[i].auto_rotation = euclid.track[i].auto_rotation == nil and 0 or euclid.track[i].auto_rotation
    euclid.track[i].auto_pad_offset = euclid.track[i].auto_pad_offset == nil and 0 or euclid.track[i].auto_pad_offset
    euclid.reset_pattern(i)
  end
end

return euclid