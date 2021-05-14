local dough = {}

function dough.init()
  dough_stretch = {}
  for i = 1,3 do
    dough_stretch[i] = {}
    dough_stretch[i].enabled = false
    dough_stretch[i].inc = 1/12
    dough_stretch[i].time = 1/12
    dough_stretch[i].clock = nil
    dough_stretch[i].fade_time = 0.06
    dough_stretch[i].pos = bank[i][bank[i].id].start_point
  end
end

function dough.stretch(i)
  while true do
    clock.sleep(dough_stretch[i].time*clock.get_beat_sec())
    softcut.position(2, dough_stretch[i].pos)
    if dough_stretch[i].pos + (dough_stretch[i].inc*clock.get_beat_sec()) > bank[i][bank[i].id].end_point then
      dough_stretch[i].pos = bank[i][bank[i].id].start_point - (dough_stretch[i].inc*clock.get_beat_sec())
    end
    dough_stretch[i].pos = dough_stretch[i].pos + (dough_stretch[i].inc*clock.get_beat_sec())
  end
end

function dough.toggle(i)
  if dough_stretch[i].clock ~= nil then
    clock.cancel(dough_stretch[i].clock)
    dough_stretch[i].enabled = false
    dough_stretch[i].clock = nil
  else
    dough_stretch[i].pos = bank[i][bank[i].id].start_point
    dough_stretch[i].clock = clock.run(dough.stretch,i)
    dough_stretch[i].enabled = true
  end
end

return dough