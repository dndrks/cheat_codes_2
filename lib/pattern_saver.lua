local pattern_saver = {}

local ps = pattern_saver

function ps.init()
  pattern_data = {}
  for i = 1,3 do
    pattern_data[i] = { ["grid"] = {}, ["arp"] = {}, ["euclid"] = {} }
    for j = 1,8 do
      pattern_data[i].grid[j] = {}
      pattern_data[i].arp[j] = {}
      pattern_data[i].euclid[j] = {}
    end
    for k,v in pairs(pattern_data[i]) do
      for l,d in pairs(pattern_data[i][k]) do
        pattern_data[i][k][l].raw = {}
        pattern_data[i][k][l].dirty = false
      end
      pattern_data[i][k].save_clock = nil
      pattern_data[i][k].saver_active = false
      pattern_data[i][k].save_slot = nil
      pattern_data[i][k].load_slot = 0
      pattern_data[i][k].delete_clock = nil
      pattern_data[i][k].delete_clock = nil
    end
  end
end

function ps.save(i,source,slot)
  pattern_data[i][source].saver_active = true
  clock.sleep(1)
    if not grid_alt then
      if source == "grid" then
        if grid_pat[i].count > 0 and grid_pat[i].rec == 0 then
          ps.handle_grid_pat(i,slot,"save")
        elseif source == "arp" then
          if tab.count(arp[i].notes) > 0 then
            ps.handle_arp_pat(i,slot,"save")
          end
        elseif source == "euclid" then
          ps.handle_euclid_pat(i,slot,"save")
        else
          print("no pattern data to save")
        end
        pattern_data[i][source].save_clock = nil
        grid_dirty = true
      end
    else
      print("should delete")
      if pattern_saver[i][source].saved[slot] == 1 then
        delete_pattern(i,pattern_saver[i].save_slot+8*(i-1))
        pattern_saver[i].saved[pattern_saver[i].save_slot] = 0
        pattern_saver[i].load_slot = 0
      else
        print("no pattern data to delete")
      end
    end
  -- end
  pattern_data[i][source].saver_active = true
end

function ps.handle_grid_pat(i,slot,command)
  local target, source;
  if command ~= "delete" then
    if command == "save" then
      target = pattern_data[i].grid[slot].raw
      source = grid_pat[i]
      target.metro_props_time = source.metro.props.time
      pattern_data[i].grid.save_slot = slot
      pattern_data[i].grid.load_slot = slot
    elseif command == "load" then
      target = grid_pat[i]
      source = pattern_data[i].grid[slot].raw
      target.metro.props.time = source.metro_props_time
      pattern_data[i].grid.load_slot = slot
    end
    target.count = source.count
    target.time = deep_copy(source.time)
    target.event = deep_copy(source.event)
    target.prev_time = source.prev_time
    target.playmode = source.playmode
    target.start_point = source.start_point
    target.end_point = source.end_point
    target.mode = source.mode
    target.rec_clock_time = source.rec_clock_time
  else
    pattern_data[i].grid[slot].raw = {}
    pattern_data[i].grid[slot].dirty = false
  end
  grid_dirty = true
end

function ps.handle_arp_pat(i,slot,command)
  local target, source;
  if command ~= "delete" then
    if command == "save" then
      pattern_data[i].arp[slot].raw = deep_copy(arp[i])
      pattern_data[i].arp.save_slot = slot
      pattern_data[i].arp.load_slot = slot
    elseif command == "load" then
      arp[i] = deep_copy(pattern_data[i].arp[slot].raw)
      pattern_data[i].arp.load_slot = slot
    end
  else
    pattern_data[i].arp[slot].raw = {}
    pattern_data[i].arp[slot].dirty = false
  end
  grid_dirty = true
end

function ps.handle_euclid_pat(i,slot,command)
  if command == "save" then
    pattern_data[i].euclid[slot].raw = deep_copy(rytm.track[i])
    pattern_data[i].euclid.save_slot = slot
    pattern_data[i].euclid.load_slot = slot
  elseif command == "load" then
    rytm.track[i] = deep_copy(pattern_data[i].euclid[slot].raw)
    pattern_data[i].euclid.load_slot = slot
  elseif command == "delete" then
    pattern_data[i].euclid[slot].raw = {}
    pattern_data[i].euclid[slot].dirty = false
    pattern_data[i].euclid.load_slot = 0
  end
end

return pattern_saver