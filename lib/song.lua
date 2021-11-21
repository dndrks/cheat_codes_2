local song = {}

song.init = function()
  song_atoms = {["bank"] = {}}
  for i = 1,3 do
    song_atoms.bank[i] = {}
    song_atoms.bank[i].lane = {}
    for j = 1,1 do
      song_atoms.bank[i].lane[j] = {["arp"] = {}, ["grid"] = {}, ["euclid"] = {}, ["snapshot"] = {}}
      for k,v in pairs(song_atoms.bank[i].lane[j]) do
        song_atoms.bank[i].lane[j][k].target = 0
      end
      song_atoms.bank[i].lane[j].beats = 16
      song_atoms.bank[i].lane[j].snapshot_restore_mod_index = 0
    end
    song_atoms.bank[i].start_point = 1
    song_atoms.bank[i].end_point = 1
    song_atoms.bank[i].current = 1
    song_atoms.bank[i].runner = 0
    song_atoms.bank[i].active = true
  end
  song_atoms.clock = nil
end

song.iterate = function()
  while true do
    clock.sync(1)
    for i = 1,3 do
      if song_atoms.bank[i].active then
        local _current = song_atoms.bank[i].current
        if song_atoms.bank[i].runner == song_atoms.bank[i].lane[_current].beats then
          song_atoms.bank[i].current = util.wrap(song_atoms.bank[i].current + 1,song_atoms.bank[i].start_point,song_atoms.bank[i].end_point)
          song_atoms.bank[i].runner = 0
        end
        _current = song_atoms.bank[i].current
        song_atoms.bank[i].runner = util.wrap(song_atoms.bank[i].runner + 1,1,song_atoms.bank[i].lane[_current].beats)
        song.check_step(i)
      end
    end
  end
end

song.check_step = function(i)
  local _current = song_atoms.bank[i].current
  for k,v in pairs(song_atoms.bank[i].lane[_current]) do
    if k ~= "beats" and k ~= "snapshot_restore_mod_index" and k ~= "snapshot" and song_atoms.bank[i].runner == 1 then
      print("new step"..clock.get_beats()) -- this goes negative for Link...
      if song_atoms.bank[i].lane[_current][k].target > 0 then
        test_load(song_atoms.bank[i].lane[_current][k].target+(8*(i-1)),i)
        print(clock.get_beats())
      elseif song_atoms.bank[i].lane[_current][k].target == 0 then
      elseif song_atoms.bank[i].lane[_current][k].target == -1 then
        if type_of_pattern_loaded[i] == "grid" then
          -- grid_pat[i]:stop()
          stop_pattern(grid_pat[i])
          print("stopping grid "..clock.get_beats())
        elseif type_of_pattern_loaded[i] == "arp" then
          arp[i].pause = true
          arp[i].playing = false
        elseif type_of_pattern_loaded[i] == "euclid" then
          print("TODO: STOP EUCLID")
        end
      end
    elseif k == "snapshot" and song_atoms.bank[i].runner == 1 then
      local modifier, style = 0,"beats"
      local shot = song_atoms.bank[i].lane[_current][k].target
      if shot > 0 then
        if song_atoms.bank[i].lane[_current].snapshot_restore_mod_index > 0 then
          modifier =  bank[i].snapshot[shot].restore_times[bank[i].snapshot[shot].restore_times.mode][song_atoms.bank[i].lane[_current].snapshot_restore_mod_index]
        else
          modifier = 0
        end
        style = bank[i].snapshot[shot].restore_times.mode
        _snap.restore(i,shot,modifier,style)
      elseif shot == 0 then
      elseif shot == -1 then
      end
    end
  end
end

song.start = function()
  for i = 1,3 do
    song_atoms.bank[i].runner = 1
    song_atoms.bank[i].current = song_atoms.bank[i].start_point
  end
  song_atoms.clock = clock.run(song.iterate)
  song_atoms.running = true
  for i = 1,3 do
    song.check_step(i)
  end
end

song.stop = function()
  if song_atoms.clock ~= nil then
    clock.cancel(song_atoms.clock)
  end
  song_atoms.running = false
  for i = 1,3 do
    song_atoms.bank[i].runner = 1
    -- song_atoms.bank[i].current = song_atoms.bank[i].start_point
  end
  -- should probably kill running patterns...
end

song.add_line = function(b,loc)
  table.insert(song_atoms.bank[b].lane,loc+1,{["arp"] = {}, ["grid"] = {}, ["euclid"] = {}, ["snapshot"] = {}})
  for k,v in pairs(song_atoms.bank[b].lane[loc+1]) do
    song_atoms.bank[b].lane[loc+1][k].target = 0
  end
  song_atoms.bank[b].lane[loc+1].beats = 16
  song_atoms.bank[b].lane[loc+1].snapshot_restore_mod_index = 0
  song_atoms.bank[b].end_point = #song_atoms.bank[b].lane
end

song.duplicate_line = function(b,loc)
  table.insert(song_atoms.bank[b].lane,loc+1,{["arp"] = {}, ["grid"] = {}, ["euclid"] = {}, ["snapshot"] = {}})
  for k,v in pairs(song_atoms.bank[b].lane[loc+1]) do
    song_atoms.bank[b].lane[loc+1][k].target = song_atoms.bank[b].lane[loc][k].target
  end
  song_atoms.bank[b].lane[loc+1].beats = song_atoms.bank[b].lane[loc].beats
  song_atoms.bank[b].lane[loc+1].snapshot_restore_mod_index = song_atoms.bank[b].lane[loc].snapshot_restore_mod_index
  song_atoms.bank[b].end_point = #song_atoms.bank[b].lane
end

song.remove_line = function(b,loc)
  if #song_atoms.bank[b].lane ~= 1 then
    table.remove(song_atoms.bank[b].lane,loc)
    song_atoms.bank[b].end_point = util.clamp(song_atoms.bank[b].end_point-1,1,128)
    if page.flow.song_line[page.flow.bank_sel] > song_atoms.bank[b].end_point then
      page.flow.song_line[page.flow.bank_sel] = song_atoms.bank[b].end_point
    end
    if song_atoms.bank[b].current > song_atoms.bank[b].end_point then
      song_atoms.bank[b].runner = 0
      song_atoms.bank[b].current = song_atoms.bank[b].start_point
    end
  end
end

return song