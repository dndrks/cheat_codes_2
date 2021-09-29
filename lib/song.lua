local song = {}

song.init = function()
  song_atoms = {["bank"] = {}}
  for i = 1,3 do
    song_atoms.bank[i] = {}
    song_atoms.bank[i].lane = {}
    for j = 1,128 do
      song_atoms.bank[i].lane[j] = {["arp"] = {}, ["pat"] = {}, ["euc"] = {}}
      for k,v in pairs(song_atoms.bank[i].lane[j]) do
        song_atoms.bank[i].lane[j][k].target = 0
      end
      song_atoms.bank[i].lane[j].beats = 16
    end
    song_atoms.bank[i].start_point = 1
    song_atoms.bank[i].end_point = 2
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
      if song_atoms.bank[i].lane[_current].arp.target ~= 0 then
        _ps.handle_arp_pat(i,song_atoms.bank[i].lane[_current].arp.target,"load")
      end
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