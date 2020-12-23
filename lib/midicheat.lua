local midicheat = {}

local mc = midicheat

function mc.init()
  active_midi_notes = {{},{},{}}
  for i = 1,3 do
    mc.redraw(bank[i][bank[i].id])
  end
  for i = 1,4 do
    if midi_dev[i].name == "Midi Fighter Twister" then
      mc.mft_redraw(bank[1][bank[1].id],"all")
    end
  end
end

function mc.move_start(target,val) -- expects (bank[x][y],0-127)
  local lo = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  local hi = target.end_point-0.1
  local max = target.mode == 1 and live[target.clip].max or clip[target.clip].max
  local save_this = target.start_point
  target.start_point = util.round(util.clamp(util.linlin(0,127,lo,max,val),lo,hi),0.1)
  if save_this ~= target.start_point then
    softcut.loop_start(target.bank_id+1,target.start_point)
  end
  params:set("start point "..target.bank_id,val,"true")
  if menu ~= 1 then screen_dirty = true end
end

function mc.move_end(target,val) -- expects (bank[x][y],0-127)
  local lo = target.start_point+0.1
  local hi = target.mode == 1 and live[target.clip].max or clip[target.clip].max
  local min = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  local save_this = target.end_point
  target.end_point = util.round(util.clamp(util.linlin(0,127,min,hi,val),lo,hi),0.1)
  if save_this ~= target.end_point then
    softcut.loop_end(target.bank_id+1,target.end_point)
  end
  params:set("end point "..target.bank_id,val,"true")
  if menu ~= 1 then screen_dirty = true end
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
  if menu ~= 1 then screen_dirty = true end
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
  if menu ~= 1 then screen_dirty = true end
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
  if menu ~= 1 then screen_dirty = true end
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

function mc.enc_redraw(target)
  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local min = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  local max = target.mode == 1 and live[target.clip].max or clip[target.clip].max
  local start_to_cc = util.round(util.linlin(min,max,0,127,target.start_point))
  midi_dev[params:get("midi_enc_control_device")]:cc(1,start_to_cc,params:get("bank_"..target.bank_id.."_midi_enc_channel"))
  local end_to_cc = util.round(util.linlin(min,max,0,127,target.end_point))
  midi_dev[params:get("midi_enc_control_device")]:cc(2,end_to_cc,params:get("bank_"..target.bank_id.."_midi_enc_channel"))
  local tilt_to_cc = util.round(util.linlin(-1,1,0,127,target.tilt))
  midi_dev[params:get("midi_enc_control_device")]:cc(3,tilt_to_cc,params:get("bank_"..target.bank_id.."_midi_enc_channel"))
  local level_to_cc = util.round(util.linlin(0,2,0,127,target.level))
  midi_dev[params:get("midi_enc_control_device")]:cc(4,level_to_cc,params:get("bank_"..target.bank_id.."_midi_enc_channel"))
end

function mc.params_redraw(target)
  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local min = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  local max = target.mode == 1 and live[target.clip].max or clip[target.clip].max
  local start_to_cc = util.round(util.linlin(min,max,0,127,target.start_point))
  params:set("current pad "..tonumber(string.format("%.0f",target.bank_id)),target.pad_id,"true")
  params:set("start point "..tonumber(string.format("%.0f",target.bank_id)),start_to_cc,"true")
  local end_to_cc = util.round(util.linlin(min,max,0,127,target.end_point))
  params:set("end point "..tonumber(string.format("%.0f",target.bank_id)),end_to_cc,"true")
  local pad_level_to_cc = util.round(util.linlin(0,2,0,127,target.level))
  params:set("level "..tonumber(string.format("%.0f",target.bank_id)),pad_level_to_cc,"true")
  local bank_level_to_cc = util.round(util.linlin(0,2,0,127,bank[target.bank_id].global_level))
  params:set("bank level "..tonumber(string.format("%.0f",target.bank_id)),bank_level_to_cc,"true")
  params:set("pan "..tonumber(string.format("%.0f",target.bank_id)),target.pan,"true")
  local offset_to_cc = util.round(util.linlin(-1,1,0,127,(math.log(target.offset)/math.log(0.5))*-12))
end

function mc.mft_redraw(target,parameter)
  -- TODO: these need to redraw on the right target.bank_id CCs...
  -- TODO: when the bank is changed on MFT, redraw these
  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local min = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  local max = target.mode == 1 and live[target.clip].max or clip[target.clip].max
  local start_to_cc = util.round(util.linlin(min,max,0,127,target.start_point))
  local dest_cc =
  {
    [1] = {0,1,2,4,5,6,7,8,10,11}
  , [2] = {16,17,18,20,21,22,23,24,26,27}
  , [3] = {32,33,34,36,37,38,39,40,42,43}
  }
  local dests = dest_cc[target.bank_id]
  if parameter == "pad_id" then
    local pad_to_cc = util.round(util.linlin(1,16,0,127,target.pad_id))
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[1],pad_to_cc,1)
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[1],pad_to_cc,5)
  elseif parameter == "start_point" then
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[2],start_to_cc,1)
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[2],start_to_cc,5)
  elseif parameter == "end_point" then
    local end_to_cc = util.round(util.linlin(min,max,0,127,target.end_point))
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[3],end_to_cc,1)
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[3],end_to_cc,5)
  elseif parameter == "pad_level" then
    local pad_level_to_cc = util.round(util.linlin(0,2,0,127,target.level))
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[4],pad_level_to_cc,1)
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[4],pad_level_to_cc,5)
  elseif parameter == "bank_level" then
    local bank_level_to_cc = util.round(util.linlin(0,2,0,127,bank[target.bank_id].global_level))
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[5],bank_level_to_cc,1)
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[5],bank_level_to_cc,5)
  elseif parameter == "pad_offset" then
    local offset_to_cc = util.round(util.linlin(-1,1,0,127,(math.log(target.offset)/math.log(0.5))*-12))
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[6],offset_to_cc,1)
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[6],offset_to_cc,5)
  elseif parameter == "pad_rate" then
    local rate_to_cc = util.round(util.linlin(-4,4,0,127,target.rate))
    local rates_to_ccs =
    {
      [4] = 127
    , [2] = 127
    , [1] = 110
    , [0.5] = 95
    , [0.25] = 85
    , [0.125] = 71
    , [0] = 64
    , [-0.125] = 56
    , [-0.25] = 45
    , [-0.5] = 32
    , [-1] = 16
    , [-2] = 10
    , [-4] = 0
    }
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[7],rates_to_ccs[target.rate],1)
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[7],rates_to_ccs[target.rate],5)
  elseif parameter == "pan" then
    local pan_to_cc = util.round(util.linlin(-1,1,0,127,target.pan))
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[8],pan_to_cc,1)
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[8],pan_to_cc,5)
  elseif parameter == "filter_tilt" then
    local tilt_to_cc = util.round(util.linlin(-1,1,0,127,target.tilt))
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[9],tilt_to_cc,1)
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[9],tilt_to_cc,5)
  elseif parameter == "filter_q" then
    local q_to_cc = util.round(util.linlin(-0.3,2,127,0,params:get("filter "..target.bank_id.." q")))
    midi_dev[params:get("midi_enc_control_device")]:cc(dests[10],q_to_cc,1)
  elseif parameter == "all" then
    mc.mft_redraw(target,"pad_id")
    mc.mft_redraw(target,"start_point")
    mc.mft_redraw(target,"end_point")
    mc.mft_redraw(target,"pad_level")
    mc.mft_redraw(target,"bank_level")
    mc.mft_redraw(target,"pad_rate")
    mc.mft_redraw(target,"pad_offset")
    mc.mft_redraw(target,"pan")
    mc.mft_redraw(target,"filter_tilt")
    mc.mft_redraw(target,"filter_q")
  end
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
  if menu ~= 1 then screen_dirty = true end
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
    toggle_buffer(rec.focus)
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

  if menu ~= 1 then screen_dirty = true end

end

function mc.pass_midi_device_mappings()
  local midi_device_mappings = {{},{},{},{}}
  for i = 1,4 do
    for j = 1,16 do
      midi_device_mappings[i][j] = norns.pmap.rev[i][j]
    end
  end
  return midi_device_mappings
end

function mc.pass_midi_devices_present_during_mapping()
  local midi_devices_present_during_mapping = {}
  for i = 1,4 do
    midi_devices_present_during_mapping[i] = midi.vports[i].name
  end
  return midi_devices_present_during_mapping
end

function mc.deep_copy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == "table" then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
        copy[mc.deep_copy(orig_key)] = mc.deep_copy(orig_value)
    end
    setmetatable(copy, mc.deep_copy(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

function mc.match_mapping_to_device()
  local old_mapped_devices = tab.load(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/params/mapped-devices.txt")
  local switched = {false,false,false,false}
  local switched_to = {nil,nil,nil,nil}
  local abandoned = {false,false,false,false}
  for i = 1,4 do
    for j = 1,4 do
      if old_mapped_devices[i] == midi.vports[j].name then
        norns.pmap.rev[j] = mc.deep_copy(norns.pmap.rev[i])
        switched[i] = true
        switched_to[i] = j
        for k = 1,16 do
          norns.pmap.rev[i][k] = {}
        end
      end
    end
  end
  for k,v in pairs(norns.pmap.data) do
    if switched[norns.pmap.data[k].dev] then
      norns.pmap.data[k].dev = switched_to[norns.pmap.data[k].dev]
      norns.pmap.assign(k,norns.pmap.data[k].dev,norns.pmap.data[k].ch,norns.pmap.data[k].cc)
    end
  end
end

function mc.save_mappings(collection)
  tab.save(mc.pass_midi_device_mappings(),_path.data.."cheat_codes_2/collection-"..collection.."/params/mappings.txt")
  tab.save(norns.pmap.data,_path.data.."cheat_codes_2/collection-"..collection.."/params/map-data.txt")
  tab.save(mc.pass_midi_devices_present_during_mapping(),_path.data.."cheat_codes_2/collection-"..collection.."/params/mapped-devices.txt")
end

local vports = {}
local function refresh_params_vports()
  for i = 1,#midi.vports do
    vports[i] = midi.vports[i].name ~= "none" and (tostring(i)..": "..util.trim_string_to_width(midi.vports[i].name,70)) or tostring(i)..": empty"
  end
end

function mc.pad_to_note_params()
  params:add_group("pad to note setup",37)
  refresh_params_vports()
  local banks = {"a","b","c"}
  mc_notes = {{},{},{}}
  mc_scale_names = {}
  for i = 1, #MU.SCALES do
    table.insert(mc_scale_names, string.lower(MU.SCALES[i].name))
  end
  params:add_separator("global")
  params:add_option("global_pad_to_midi_note_enabled", "MIDI output?", {"no","yes"},1)
  params:set_action("global_pad_to_midi_note_enabled",
  function(x)
    if all_loaded then
      persistent_state_save()
      for i = 1,3 do
        params:set(i.."_pad_to_midi_note_enabled",x)
      end
    end
  end)
  params:add_option("global_pad_to_midi_note_destination", "MIDI dest",vports,2)
  params:set_action("global_pad_to_midi_note_destination",
  function(x)
    if all_loaded then
      persistent_state_save()
      for i = 1,3 do
        params:set(i.."_pad_to_midi_note_destination",x)
      end
    end
  end)
  params:add_number("global_pad_to_midi_note_channel", "MIDI channel",1,16,1)
  params:set_action("global_pad_to_midi_note_channel",
  function(x)
    if all_loaded then
      persistent_state_save()
      for i = 1,3 do
        params:set(i.."_pad_to_midi_note_channel",x)
      end
    end
  end)
  params:add{type='binary',name="MIDI panic",id='midi_panic',behavior='trigger',
  action=function(x)
    if all_loaded then
      if x == 1 then
        for i = 1,128 do
          for j = 1,3 do
            for z = 1,16 do
            midi_dev[params:get(j.."_pad_to_midi_note_destination")]:note_off(i, nil, z)
            end
          end
        end
      end
    end
  end}
  params:add_option("global_pad_to_midi_note_scale", "scale",mc_scale_names,5)
  params:set_action("global_pad_to_midi_note_scale",
  function(x)
    if all_loaded then
      persistent_state_save()
      for i = 1,3 do
        params:set(i.."_pad_to_midi_note_scale",x)
      end
    end
  end)
  params:add_number("global_pad_to_midi_note_root", "root note",0,11,0,function(param) return MU.note_num_to_name(param:get(), false) end)
  params:set_action("global_pad_to_midi_note_root",
  function(x)
    if all_loaded then
      persistent_state_save()
      for i = 1,3 do
        params:set(i.."_pad_to_midi_note_root",x)
      end
    end
  end)
  params:add_option("global_pad_to_midi_note_root_octave", "octave", {"-4","-3","-2","-1","middle","+1","+2","+3","+4","+5"},5)
  params:set_action("global_pad_to_midi_note_root_octave",
  function(x)
    if all_loaded then
      persistent_state_save()
      for i = 1,3 do
        params:set(i.."_pad_to_midi_note_root_octave",x)
      end
    end
  end)
  params:add_option("global_pad_to_jf_note_enabled","Just Friends output?",{"no","yes"},1)
  params:set_action("global_pad_to_jf_note_enabled",function()
    if all_loaded then persistent_state_save() end
  end)
  
  local jf_mode;

  crow.ii.jf.event = function( event, value )
    if event.name == 'mode' then
      jf_mode = value
    end
  end
  
  crow.ii.jf.get('mode')
  
  params:add_trigger("jf_toggle","toggle JF synth mode")
  params:set_action("jf_toggle",
    function(x)
      crow.ii.jf.get('mode')
      if jf_mode == 1 then
        crow.ii.jf.mode(0)
        crow.ii.jf.get('mode')
      else
        crow.ii.jf.mode(1)
        crow.ii.jf.get('mode')
      end
    end
  )
  
  for i = 1,3 do
    params:add_separator("bank "..banks[i])
    params:add_option(i.."_pad_to_midi_note_enabled", "bank "..banks[i].." MIDI output?", {"no","yes"},1)
    params:set_action(i.."_pad_to_midi_note_enabled", function() if all_loaded then persistent_state_save() mc.all_midi_notes_off(i) end end)
    params:add_option(i.."_pad_to_midi_note_destination", "MIDI dest",vports,2)
    params:set_action(i.."_pad_to_midi_note_destination", function() if all_loaded then persistent_state_save() mc.all_midi_notes_off(i) end end)
    params:add_number(i.."_pad_to_midi_note_channel", "MIDI channel",1,16,1)
    params:set_action(i.."_pad_to_midi_note_channel", function() if all_loaded then
        mc.all_midi_notes_off(i)
        persistent_state_save()
      end 
    end)
    params:add_option(i.."_pad_to_midi_note_scale", "scale",mc_scale_names,5)
    params:set_action(i.."_pad_to_midi_note_scale",function()
      mc.build_scale(i)
      if all_loaded then persistent_state_save() end
    end)
    params:add_number(i.."_pad_to_midi_note_root", "root note",0,11,0,function(param) return MU.note_num_to_name(param:get(), false) end)
    params:set_action(i.."_pad_to_midi_note_root",function()
      mc.build_scale(i)
      if all_loaded then persistent_state_save() end
    end)
    params:add_option(i.."_pad_to_midi_note_root_octave", "octave", {"-4","-3","-2","-1","middle","+1","+2","+3","+4","+5"},5)
    params:set_action(i.."_pad_to_midi_note_root_octave",function()
      mc.build_scale(i)
      if all_loaded then persistent_state_save() end
    end)
    params:add_option(i.."_pad_to_jf_note_enabled", "Just Friends channel",{"none","IDENTITY","2N","3N","4N","5N","6N","all","any"},9)
    params:set_action(i.."_pad_to_jf_note_enabled",function()
      if all_loaded then persistent_state_save() end
    end)
    params:add_number(i.."_pad_to_jf_note_velocity", "Just Friends velocity",1,10,5)
    params:set_action(i.."_pad_to_jf_note_velocity",function()
      if all_loaded then persistent_state_save() end
    end)
    mc.build_scale(i)
    -- params:add_number(i.."_pad_to_midi_note_duration", "note length",1,16,1)
  end
end

function mc.build_scale(target)
  mc_notes[target] = MU.generate_scale_of_length(params:get(target.."_pad_to_midi_note_root")+(12*params:get(target.."_pad_to_midi_note_root_octave")), params:get(target.."_pad_to_midi_note_scale"), 16)
  local num_to_add = 16 - #mc_notes[target]
  for i = 1, num_to_add do
    table.insert(mc_notes[target], mc_notes[target][16 - num_to_add])
  end
end

function mc.midi_note_from_pad(b,p)
  if params:string(b.."_pad_to_midi_note_enabled") == "yes" then
    mc.all_midi_notes_off(b)
    local note_num = mc_notes[b][p]
    midi_dev[params:get(b.."_pad_to_midi_note_destination")]:note_on(note_num,96,params:get(b.."_pad_to_midi_note_channel"))
    table.insert(active_midi_notes[b], note_num)
    clock.run(mc.midi_note_from_pad_off,b,p)
  end
  if params:string("global_pad_to_jf_note_enabled") == "yes" then
    local jf_destinations =
    {
      ["IDENTITY"] = 1
    , ["2N"] = 2
    , ["3N"] = 3
    , ["4N"] = 4
    , ["5N"] = 5
    , ["6N"] = 6
    , ["all"] = 0
    }
    if params:string(b.."_pad_to_jf_note_enabled") ~= "none" then
      local note_num = mc_notes[b][p] - 60
      local velocity = params:get(b.."_pad_to_jf_note_velocity")
      if params:string(b.."_pad_to_jf_note_enabled") == "any" then
        crow.ii.jf.play_note(note_num/12,velocity)
      else
        local jf_chan = jf_destinations[params:string(b.."_pad_to_jf_note_enabled")]
        crow.ii.jf.play_voice(jf_chan,note_num/12,velocity)
      end
    end
  end
end

function mc.midi_note_from_pad_off(b,p)
  clock.sleep(bank[b][p].arp_time-(bank[b][p].arp_time/100))
  mc.all_midi_notes_off(b)
end

function mc.all_midi_notes_off(b)
  for _, a in pairs(active_midi_notes[b]) do
    midi_dev[params:get(b.."_pad_to_midi_note_destination")]:note_off(a, nil, params:get(b.."_pad_to_midi_note_channel"))
  end
  active_midi_notes[b] = {}
end

mc.midi_mod_table =
{
  ["0.5x rate"] = false
, ["2x rate"] = false
, ["reverse rate"] = false
, ["hard pan L"] = false
, ["hard pan C"] = false
, ["hard pan R"] = false
, ["nudge pan L"] = false
, ["nudge pan R"] = false
, ["reverse pan"] = false
, ["random pan"] = false
, ["increase level"] = false
, ["decrease level"] = false
, ["pause"] = false
, ["random start"] = false
, ["random end"] = false
, ["random window"] = false
, ["a: 0.5x rate"] = false
, ["b: 0.5x rate"] = false
, ["c: 0.5x rate"] = false
, ["a: 2x rate"] = false
, ["b: 2x rate"] = false
, ["c: 2x rate"] = false
, ["a: reverse rate"] = false
, ["b: reverse rate"] = false
, ["c: reverse rate"] = false
, ["a: random pan"] = false
, ["b: random pan"] = false
, ["c: random pan"] = false
, ["a: random start"] = false
, ["b: random start"] = false
, ["c: random start"] = false
, ["a: random end"] = false
, ["b: random end"] = false
, ["c: random end"] = false
, ["a: random window"] = false
, ["b: random window"] = false
, ["c: random window"] = false
}

function mc.route_midi_mod(b,p)
  local midi_mod_actions =
  {
    ["0.5x rate"] = {4,'134'}
  , ["2x rate"] = {4,'124'}
  , ["reverse rate"] = {4,'14'}
  , ["hard pan L"] = {3,'1'}
  , ["hard pan C"] = {3,'2'}
  , ["hard pan R"] = {3,'3'}
  , ["nudge pan L"] = {3,'12'}
  , ["nudge pan R"] = {3,'23'}
  , ["reverse pan"] = {3,'13'}
  , ["random pan"] = {3,'123'}
  , ["increase level"] = {2,'2'}
  , ["decrease level"] = {2,'1'}
  , ["pause"] = {2,'12'}
  , ["random start"] = {4,'12'}
  , ["random end"] = {4,'34'}
  , ["random window"] = {4,'23'}
  , ["a: 0.5x rate"] = {4,'134'}
  , ["b: 0.5x rate"] = {4,'134'}
  , ["c: 0.5x rate"] = {4,'134'}
  , ["a: 2x rate"] = {4,'124'}
  , ["b: 2x rate"] = {4,'124'}
  , ["c: 2x rate"] = {4,'124'}
  , ["a: reverse rate"] = {4,'14'}
  , ["b: reverse rate"] = {4,'14'}
  , ["c: reverse rate"] = {4,'14'}
  , ["a: random pan"] = {3,'123'}
  , ["b: random pan"] = {3,'123'}
  , ["c: random pan"] = {3,'123'}
  , ["a: random start"] = {4,'12'}
  , ["b: random start"] = {4,'12'}
  , ["c: random start"] = {4,'12'}
  , ["a: random end"] = {4,'34'}
  , ["b: random end"] = {4,'34'}
  , ["c: random end"] = {4,'34'}
  , ["a: random window"] = {4,'23'}
  , ["b: random window"] = {4,'23'}
  , ["c: random window"] = {4,'23'}
  }
  for k,v in pairs(mc.midi_mod_table) do
    if v then
      local which = string.sub(k,1,2)
      if which ~= "a:" and which ~= "b:" and which ~= "c:" then
        mc.execute_midi_zilch(b,p,midi_mod_actions[k][1],midi_mod_actions[k][2])
      else
        local which_banks = {["a:"] = 1, ["b:"] = 2, ["c:"] = 3}
        if b == which_banks[which] then
          mc.execute_midi_zilch(b,p,midi_mod_actions[k][1],midi_mod_actions[k][2])
        end
      end
    end
  end
end

function mc.execute_midi_zilch(b,p,row,str)
  for j = (not grid.alt and bank[b].id or 1), (not grid.alt and bank[b].id or 16) do
    rightangleslice.actions[row][str][1](bank[b][j])
    if str ~= '12' then
      rightangleslice.actions[row][str][2](bank[b][j],b)
    end
  end
end

return midicheat