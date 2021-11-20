s = require 'sequins'
-- _live.mode = enabled -- this line is for cheat codes yellow only

_pads = { s{1,3,5,7,s{9,11,13,15}}, s{1,3,5,7,s{9,11,13,15}}, s{2,4,8,10,s{1,3,6,15}} }
_reps = { s{3,6,8,s{3,1,9,7}}, s{3,6,8,s{3,1,9,7}}, s{3,6,8,s{3,1,9,7}} }
_syncs = { s{1/3,1/4,1/6,1/8,1/2}, s{1/3,1/4,1/6,1/8,1/2}, s{1/3,1/4,1/6,1/8,1/2} }
_md = { s{0,1,2,3,4}, s{3,4,5}, s{6,7,8,9}, s{6,7,8,9,10,11,12,13,14,15} }

pad_mutes = {false,false,false}

_MD = midi.connect(9)

BP = midi.connect(8) -- replace '2' with whatever midi port your device is on

BP.event = function(data)
  local d = midi.to_msg(data)
  if d.type == "note_on" then
    print(d.note)
    if d.note == 44 then
      out_to_md(1)
      if not pad_mutes[1] then
        _start(1)
      end
    elseif d.note == 48 then
      out_to_md(2)
      if not pad_mutes[2] then
        _start(2)
      end
    elseif d.note == 37 then
      out_to_md(3)
      if not pad_mutes[3] then
        _start(3)
      end
    elseif d.note == 41 then
      out_to_md(4)
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

function out_to_md(target)
  _MD:note_on(_md[target]())
end