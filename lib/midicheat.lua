local midicheat = {}

local mc = midicheat

function mc.init()
  for i = 1,3 do
    mc.redraw(bank[i][bank[i].id])
  end
end

function mc.move_start(target,val) -- expects (bank[x][y],0-127)
  local lo = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  local hi = target.end_point-0.1
  local max = target.mode == 1 and live[target.clip].max or clip[target.clip].max
  target.start_point = util.round(util.clamp(util.linlin(0,127,lo,max,val),lo,hi),0.1)
  softcut.loop_start(target.bank_id+1,target.start_point)
  params:set("start point "..target.bank_id,val,"true")
  redraw()
end

function mc.move_end(target,val) -- expects (bank[x][y],0-127)
  local lo = target.start_point+0.1
  local hi = target.mode == 1 and live[target.clip].max or clip[target.clip].max
  local min = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  target.end_point = util.round(util.clamp(util.linlin(0,127,min,hi,val),lo,hi),0.1)
  softcut.loop_end(target.bank_id+1,target.end_point)
  params:set("end point "..target.bank_id,val,"true")
  redraw()
end

function mc.adjust_filter(target,val) -- expects (x,0-127)
  for j = 1,16 do
    local which_bank = bank[target][j]
    if slew_counter[target] ~= nil then
      slew_counter[target].prev_tilt = which_bank.tilt
    end
    which_bank.tilt = util.linlin(0,127,-1,1,val)
  end
  local pad = bank[target][bank[target].id]
  slew_filter(target,slew_counter[target].prev_tilt,pad.tilt,pad.q,pad.q,15)
  redraw()
end

function mc.adjust_pad_level(target,val) -- expects (bank[x][y],0-127)
  target.level = util.linlin(0,127,0,2,val)
  if target.envelope_mode == 2 or not target.enveloped then
    softcut.level_slew_time(target.bank_id +1,1.0)
    softcut.level(target.bank_id +1,target.level*bank[target.bank_id].global_level)
    softcut.level_cut_cut(target.bank_id +1,5,(target.left_delay_level*target.level)*bank[target.bank_id].global_level)
    softcut.level_cut_cut(target.bank_id +1,6,(target.right_delay_level*target.level)*bank[target.bank_id].global_level)
  end
  params:set("level "..target.bank_id,val,"true")
  redraw()
end

function mc.adjust_bank_level(target,val)
  bank[target.bank_id].global_level = util.linlin(0,127,0,2,val)
  if target.envelope_mode == 2 or not target.enveloped then
    softcut.level_slew_time(target.bank_id +1,1.0)
    softcut.level(target.bank_id +1,target.level*bank[target.bank_id].global_level)
    softcut.level_cut_cut(target.bank_id +1,5,(target.left_delay_level*target.level)*bank[target.bank_id].global_level)
    softcut.level_cut_cut(target.bank_id +1,6,(target.right_delay_level*target.level)*bank[target.bank_id].global_level)
  end
  params:set("bank level "..target.bank_id,val,"true")
  redraw()
end

function mc.redraw(target) -- expects (bank[x][y])
  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local min = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  local max = target.mode == 1 and live[target.clip].max or clip[target.clip].max
  local start_to_cc = util.round(util.linlin(min,max,0,127,target.start_point))
  midi_dev[params:get("midi_control_device")]:cc(1,start_to_cc,params:get("bank_"..target.bank_id.."_midi_channel"))
  local end_to_cc = util.round(util.linlin(min,max,0,127,target.end_point))
  midi_dev[params:get("midi_control_device")]:cc(2,end_to_cc,params:get("bank_"..target.bank_id.."_midi_channel"))
  local tilt_to_cc = util.round(util.linlin(-1,1,0,127,target.tilt))
  midi_dev[params:get("midi_control_device")]:cc(3,tilt_to_cc,params:get("bank_"..target.bank_id.."_midi_channel"))
  local level_to_cc = util.round(util.linlin(0,2,0,127,target.level))
  midi_dev[params:get("midi_control_device")]:cc(4,level_to_cc,params:get("bank_"..target.bank_id.."_midi_channel"))
end

function mc.cheat(target,note) -- expects (x,0-127)
  bank[target].id = note
  if not arp[target].playing then
    selected[target].x = (5*(target-1)+1)+(math.ceil(bank[target].id/4)-1)
    if (bank[target].id % 4) ~= 0 then
      selected[target].y = 9-(bank[target].id % 4)
    else
      selected[target].y = 5
    end
    cheat(target,bank[target].id)
    if params:get("midi_echo_enabled") == 2 then
      mc.redraw(bank[target][bank[target].id])
    end
  end
  grid_dirty = true
  redraw()
end

function mc.zilch(target,note) -- expects (x,0-127)
  if note == 1 or note == 2 then
    for i = (note == 1 and bank[target].id or 1), (note == 1 and bank[target].id or 16) do
      rightangleslice.actions[4]['134'][1](bank[target][i])
      rightangleslice.actions[4]['134'][2](bank[target][i],target)
    end
  elseif note == 3 or note == 4 then
    for i = (note == 3 and bank[target].id or 1), (note == 3 and bank[target].id or 16) do
      rightangleslice.actions[4]['14'][1](bank[target][i])
      rightangleslice.actions[4]['14'][2](bank[target][i],target)
    end
  elseif note == 5 or note == 6 then
    for i = (note == 5 and bank[target].id or 1), (note == 5 and bank[target].id or 16) do
      rightangleslice.actions[4]['124'][1](bank[target][i])
      rightangleslice.actions[4]['124'][2](bank[target][i],target)
    end
  elseif note == 8 or note == 9 then
    for i = (note == 8 and bank[target].id or 1), (note == 8 and bank[target].id or 16) do
      bank[target][i].loop = not bank[target][i].loop
    end
    softcut.loop(target+1,bank[target][bank[target].id].loop == true and 1 or 0)
  elseif note == 11 then
    toggle_buffer(rec.clip)
  elseif note == 13 or note == 14 then
    for i = (note == 13 and bank[target].id or 1), (note == 13 and bank[target].id or 16) do
      rightangleslice.actions[4]['12'][1](bank[target][i])
      rightangleslice.actions[4]['12'][2](bank[target][i],target)
    end
  elseif note == 15 or note == 16 then
    for i = (note == 15 and bank[target].id or 1), (note == 15 and bank[target].id or 16) do
      rightangleslice.actions[4]['23'][1](bank[target][i])
      rightangleslice.actions[4]['23'][2](bank[target][i],target)
    end
  elseif note == 17 or note == 18 then
    for i = (note == 17 and bank[target].id or 1), (note == 17 and bank[target].id or 16) do
      rightangleslice.actions[4]['34'][1](bank[target][i])
      rightangleslice.actions[4]['34'][2](bank[target][i],target)
    end
  elseif note == 21 then
    for i = 1,16 do
      rightangleslice.actions[4]['2'][1](bank[target][i])
      rightangleslice.actions[4]['2'][2](bank[target][i],target)
    end
  elseif note == 23 then
    buff_flush()
  end

  if params:get("midi_echo_enabled") == 2 then
    mc.redraw(bank[target][bank[target].id])
  end

  redraw()

end

return midicheat