local pattern_saver = {}

local ps = pattern_saver

local all_foci = {"arp","grid","euclid"}

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
        pattern_data[i][k][l].loop = true
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
      pattern_data[i].grid[slot].dirty = true
    elseif command == "load" then -- should this start the pattern??
      mc.all_midi_notes_off(i)
      target = grid_pat[i]
      stop_pattern(target)
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
    if command == "load" then
      target.step = 0
      target.loop = pattern_data[i].grid[slot].loop and 1 or 0
      start_pattern(target)
    end
  else
    pattern_data[i].grid[slot].raw = {}
    pattern_data[i].grid[slot].dirty = false
    pattern_data[i].grid.save_slot = nil
    pattern_data[i].grid.load_slot = 0
  end
  grid_dirty = true
end

function ps.handle_arp_pat(i,slot,command)
  local target, source;
  if command ~= "delete" then
    if command == "save" then
      pattern_data[i].arp[slot].raw = deep_copy(arp[i])
      pattern_data[i].arp[slot].raw.step = 0
      pattern_data[i].arp.save_slot = slot
      pattern_data[i].arp.load_slot = slot
      pattern_data[i].arp[slot].dirty = true
    elseif command == "load" then
      for k,v in pairs(arp[i].notes) do
        if tab.contains(held_keys[i],v) then
          -- print("<<<--->>>"..v)
          grid_actions.kill_note(i,v)
        end
      end
      arp[i] = deep_copy(pattern_data[i].arp[slot].raw)
      pattern_data[i].arp.load_slot = slot
      if not arp[i].playing then
        arps.toggle("start",i)
      end
    end
  else
    pattern_data[i].arp[slot].raw = {}
    pattern_data[i].arp[slot].dirty = false
    pattern_data[i].arp.save_slot = nil
    pattern_data[i].arp.load_slot = 0
  end
  grid_dirty = true
end

function ps.handle_euclid_pat(i,slot,command)
  if command == "save" then
    pattern_data[i].euclid[slot].raw = deep_copy(rytm.track[i])
    pattern_data[i].euclid.save_slot = slot
    pattern_data[i].euclid.load_slot = slot
    pattern_data[i].euclid[slot].dirty = true
  elseif command == "load" then
    local pre_load = {rytm.track[i].pos,rytm.track[i].runner}
    rytm.track[i] = deep_copy(pattern_data[i].euclid[slot].raw)
    pattern_data[i].euclid.load_slot = slot
    rytm.track[i].pos = pre_load[1]
    rytm.track[i].runner = pre_load[2]
  elseif command == "delete" then
    pattern_data[i].euclid[slot].raw = {}
    pattern_data[i].euclid[slot].dirty = false
    pattern_data[i].euclid.save_slot = nil
    pattern_data[i].euclid.load_slot = 0
  end
  grid_dirty = true
end

function ps.toggle_loop(i,target,slot)
  pattern_data[i][target][slot].loop = not pattern_data[i][target][slot].loop
  if target == "grid" then
    grid_pat[i].loop = pattern_data[i][target][slot].loop and 1 or 0
  end
end

function ps.disk_save_patterns(coll)
  local dirname = _path.data.."cheat_codes_yellow/collection-"..coll.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local dirname = _path.data.."cheat_codes_yellow/collection-"..coll.."/patterns/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  for i = 1,24 do
    local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..coll.."/patterns/"..i..".data", "w+")
    if file then
      os.remove(_path.data .. "cheat_codes_yellow/collection-"..coll.."/patterns/"..i..".data")
      io.close(file)
    end
  end

  for i = 1,3 do
    if meta_grid_pattern ~= nil and meta_grid_pattern[i] ~= nil then
      for k,v in pairs(meta_grid_pattern[i]) do
        if #meta_grid_pattern[i][k] == 0 then
          tab.save(meta_grid_pattern[i][k],_path.data .. "cheat_codes_yellow/collection-"..coll.."/patterns/"..k..".data")
        else
          local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..coll.."/patterns/"..k..".data", "w+")
          io.output(file)
          meta_grid_pattern[i][k][1] = "stored pad pattern: collection "..coll.." + slot "..k
          for key,val in ipairs(meta_grid_pattern[i][k]) do
            io.write(val.."\n")
          end
          io.close(file)
        end
      end
      -- need to delete unused patterns
    end
  end
end

function ps.draw_grid()
  local _c = speed_dial.translate
  local windows = {{1,3},{6,8},{11,13}}
  for i = 1,3 do
    for j = windows[i][1],windows[i][2] do
      for k = 1,8 do
        local focus = all_foci[j-(5*(i-1))]
        local level = pattern_data[i][focus][k].dirty == true and 8 or 4
        g:led(_c(k,j)[1],_c(k,j)[2],level)
        if k == pattern_data[i][focus].load_slot then
          g:led(_c(k,j)[1],_c(k,j)[2],15)
        end
      end
    end
    for j = 5,15,5 do
      g:led(_c(i,j)[1],_c(i,j)[2],pattern_gate[j/5][i].active and 15 or 0)
    end
  end
  for i = 5,15,5 do
    g:led(_c(4,i)[1],_c(4,i)[2],bank[i/5].alt_lock and 15 or 0)
    -- g:led(_c(5,i)[1],_c(5,i)[2],arp[i/5].loop and 4 or 0)
    -- g:led(_c(6,i)[1],_c(6,i)[2],grid_pat[i/5].loop and 4 or 0)
    -- g:led(_c(7,i)[1],_c(7,i)[2],rytm.track[i/5].loop and 4 or 0)
    -- g:led(_c(7,i)[1],_c(7,i)[2],arc_pat[i/5].loop and 4 or 0)
  end
end

function ps.parse_press(x,y,z)
  local _c = speed_dial.coordinate
  local nx = _c(x,y)[1]
  local ny = _c(x,y)[2]

  local save_bank;
  local focus;
  local pgb = ny/5

  if ny == 5 or ny == 10 or ny == 15 then
    if nx <=3 then
      if (bank[pgb].alt_lock and z == 1) or not bank[pgb].alt_lock then
        pattern_gate[pgb][nx].active = not pattern_gate[pgb][nx].active
      end
    elseif nx == 4 then
      if not grid_alt then
        bank[pgb].alt_lock = z == 1 and true or false
      else
        if z == 1 then
          bank[pgb].alt_lock = not bank[pgb].alt_lock
        end
      end
    end
  end

  if ny <= 3 then
    save_bank = 1
    focus = all_foci[ny]
  elseif ny >=6 and ny<=8 then
    save_bank = 2
    focus = all_foci[ny-5]
  elseif ny >=11 and ny <=13 then
    save_bank = 3
    focus = all_foci[ny-10]
  end

  if ny <=3 or (ny >=6 and ny<=8) or (ny >=11 and ny <=13) then
    if z == 1 then
      if not grid_alt then
        if not pattern_data[save_bank][focus][nx].dirty then
          pattern_data[save_bank][focus].save_clock = clock.run(
            function()
              clock.sleep(0.25)
              if focus == "arp" then
                if tab.count(arp[save_bank].notes) > 0 then
                  ps.handle_arp_pat(save_bank,nx,"save")
                end
              elseif focus == "grid" then
                if #grid_pat[save_bank].event > 0 then
                  ps.handle_grid_pat(save_bank,nx,"save")
                end
              elseif focus == "euclid" then
                ps.handle_euclid_pat(save_bank,nx,"save")
              end
              pattern_data[save_bank][focus].save_clock = nil
            end
          )
        else
          if focus == "arp" then
            ps.handle_arp_pat(save_bank,nx,"load")
          elseif focus == "grid" then
            ps.handle_grid_pat(save_bank,nx,"load")
          elseif focus == "euclid" then
            ps.handle_euclid_pat(save_bank,nx,"load")
          end
        end
      else
        if pattern_data[save_bank][focus][nx].dirty then
          local concat = "handle_"..focus.."_pat"
          ps[concat](save_bank,nx,"delete")
        end
      end
    elseif z == 0 then
      if pattern_data[save_bank][focus].save_clock ~= nil then
        clock.cancel(pattern_data[save_bank][focus].save_clock)
        pattern_data[save_bank][focus].save_clock = nil
      end
    end
  end

  if nx == 1 and ny == 16 then
    grid_alt = z == 1 and true or false
  end

end

-- TODO
-- - add load + delete gestures
-- - confirm holding many works

return pattern_saver