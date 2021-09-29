local song = {}

song.init = function()
  song_atoms = {["bank"] = {}}
  for i = 1,3 do
    song_atoms.bank[i] = {}
    song_atoms.bank[i].lane = {}
    for j = 1,128 do
      song_atoms.bank[i].lane[j] = {["arp"] = {}, ["grid"] = {}, ["euclid"] = {}}
      for k,v in pairs(song_atoms.bank[i].lane[j]) do
        song_atoms.bank[i].lane[j][k].target = 0
      end
      song_atoms.bank[i].lane[j].beats = 16
    end
    song_atoms.bank[i].start_point = 1
    song_atoms.bank[i].end_point = 3
    song_atoms.bank[i].current = 1
    song_atoms.bank[i].runner = 0
  end
  song_atoms.clock = nil
end

song.iterate = function()
  while true do
    clock.sync(1)
    for i = 1,3 do
      local _current = song_atoms.bank[i].current
      if song_atoms.bank[i].runner == song_atoms.bank[i].lane[_current].beats then
        song_atoms.bank[i].current = util.wrap(song_atoms.bank[i].current + 1,song_atoms.bank[i].start_point,song_atoms.bank[i].end_point)
        song_atoms.bank[i].runner = 0
      end
      _current = song_atoms.bank[i].current
      song_atoms.bank[i].runner = util.wrap(song_atoms.bank[i].runner + 1,1,song_atoms.bank[i].lane[_current].beats)
      for k,v in pairs(song_atoms.bank[i].lane[_current]) do
        if k ~= "beats" and song_atoms.bank[i].runner == 1 and song_atoms.bank[i].lane[_current][k].target ~= 0 then
          -- print(i,song_atoms.bank[i].lane[_current][k].target,"load",clock.get_beats())
          local concat_dest = "handle_"..k.."_pat"
          _ps[concat_dest](i,song_atoms.bank[i].lane[_current][k].target,"load")
        else
          -- should a 0 placeholder kill the running pattern??
        end
      end
      -- if song_atoms.bank[i].runner == 1 and song_atoms.bank[i].lane[_current].arp.target ~= 0 then
      --   -- print(i,song_atoms.bank[i].lane[_current].arp.target,"load",clock.get_beats())
      --   _ps.handle_arp_pat(i,song_atoms.bank[i].lane[_current].arp.target,"load")
      -- end
    end
  end
end

song.start = function()
  for i = 1,3 do
    song_atoms.bank[i].runner = 0
    song_atoms.bank[i].current = song_atoms.bank[i].start_point
  end
  song_atoms.clock = clock.run(song.iterate)
  song_atoms.running = true
end

song.stop = function()
  if song_atoms.clock ~= nil then
    clock.cancel(song_atoms.clock)
  end
  song_atoms.running = false
  -- should probably kill running patterns...
end

return song