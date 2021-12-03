s = require 'sequins'
-- _live.mode = enabled -- this line is for cheat codes yellow only

_pads = { s{1,3,5,7,s{9,11,13,15}}, s{1,3,5,7,s{9,11,13,15}}, s{2,4,8,10,s{1,3,6,15}} }
_reps = { s{3,6,8,s{3,1,9,7}}, s{3,6,8,s{3,1,9,7}}, s{3,6,8,s{3,1,9,7}} }
_syncs = { s{1/3,1/4,1/6,1/8,1/2}, s{1/3,1/4,1/6,1/8,1/2}, s{1/3,1/4,1/6,1/8,1/2} }

pad_mutes = {false,false,false}

SP = midi.connect(12) -- replace '2' with whatever midi port your device is on

SP.event = function(data)
  local d = midi.to_msg(data)
  if d.type == "note_on" then
    print(d.note)
    if d.note == 48 and not pad_mutes[1] then
      _start(1)
    elseif d.note == 37 and not pad_mutes[2] then
      _start(2)
    elseif d.note == 41 and not pad_mutes[3] then
      _start(3)
    end
  end
end

MC8 = midi.connect(13) -- replace '2' with whatever midi port your device is on

MC8.event = function(data)
  local d = midi.to_msg(data)
  if d.type == "cc" then
    pad_mutes[d.cc+1] = d.val == 127 and true or false
  end
end

clocks = {}

function _play(target)
  local _p = _pads[target]()
  grid_actions.pad_down(target,_p)
  clock.sleep(0.05)
  grid_actions.pad_up(target,_p)
end

function _start(target)
  clocks[target] = clock.run(_play,target,_syncs[target]())  
end