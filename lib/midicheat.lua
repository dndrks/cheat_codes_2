local midicheat = {}

local mc = midicheat

function mc.init()
  active_midi_notes = {{},{},{}}
  for i = 1,3 do
    mc.redraw(bank[i][bank[i].id])
  end
  for i = 1,16 do
    if midi_dev[i].name == "Midi Fighter Twister" or midi_dev[i].name == "Faderfox EC4" then
      mc.mft_redraw(bank[1][bank[1].id],"all")
    end
  end
  mc.initialize_UI()
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
  params:set("filter tilt "..tonumber(string.format("%.0f",target.bank_id)),target.tilt,"true")
end

function mc.mft_redraw(target,parameter)
  -- TODO: these need to redraw on the right target.bank_id CCs...
  -- TODO: when the bank is changed on MFT, redraw these
  if params:string("midi_enc_control_enabled") == "yes" and params:string("midi_enc_echo_enabled") == "yes" and (midi_dev[params:get("midi_enc_control_device")].name == "Midi Fighter Twister" or midi_dev[params:get("midi_enc_control_device")].name == "Faderfox EC4") then
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
    vports[i] = midi.vports[i].name ~= "none" and (tostring(i)..": "..util.trim_string_to_width(midi.vports[i].name,70)) or tostring(i)..": [device]"
  end
end

function mc.pad_to_note_params()
  params:add_group("pad to note setup",56)
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
  params:add_option("global_pad_to_midi_note_root_octave", "octave", {"-5","-4","-3","-2","-1","middle","+1","+2","+3","+4","+5"},6)
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

  params:add_option("global_pad_to_wsyn_note_enabled","w/syn output?",{"no","yes"},1)
  params:set_action("global_pad_to_wsyn_note_enabled",function()
    wsyn_init()
    print("initializing wsyn")
    if all_loaded then
      persistent_state_save()
      wsyn_init()
      print("initializing wsyn")
    end
  end)
  
  for i = 1,3 do
    params:add_separator("bank "..banks[i])
    params:add_option(i.."_pad_to_midi_note_enabled", "bank "..banks[i].." MIDI output?", {"no","yes"},1)
    params:set_action(i.."_pad_to_midi_note_enabled", function() if all_loaded then persistent_state_save() mc.all_midi_notes_off(i) end end)
    params:add_option(i.."_pad_to_midi_note_destination", "MIDI dest",vports,2)
    params:set_action(i.."_pad_to_midi_note_destination", function() if all_loaded then persistent_state_save() mc.all_midi_notes_off(i) end end)
    params:add_number(i.."_pad_to_midi_note_channel", "MIDI channel",1,16,1)
    params:set_action(i.."_pad_to_midi_note_channel", function(x) if all_loaded then
        mc.all_midi_notes_off(i)
        mc.set_parameter_all("midi_notes_channels",i,1,16,x)
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
    params:add_option(i.."_pad_to_midi_note_root_octave", "octave", {"-5","-4","-3","-2","-1","middle","+1","+2","+3","+4","+5"},6)
    params:set_action(i.."_pad_to_midi_note_root_octave",function()
      mc.build_scale(i)
      if all_loaded then persistent_state_save() end
    end)
    params:add_number(i.."_pad_to_midi_note_velocity", "velocity",0,127,127)

    params:add_option(i.."_pad_to_jf_note_enabled", "Just Friends channel",{"none","IDENTITY","2N","3N","4N","5N","6N","all","any"},9)
    params:set_action(i.."_pad_to_jf_note_enabled",function()
      if all_loaded then persistent_state_save() end
    end)
    params:add_number(i.."_pad_to_jf_note_velocity", "Just Friends velocity",1,10,5)
    params:set_action(i.."_pad_to_jf_note_velocity",function()
      if all_loaded then persistent_state_save() end
    end)
    params:add_option(i.."_pad_to_wsyn_note_enabled", "w/syn voice",{"none","1","2","3","4","any"},6)
    params:set_action(i.."_pad_to_wsyn_note_enabled",function()
      if all_loaded then persistent_state_save() end
    end)
    params:add_number(i.."_pad_to_wsyn_note_velocity", "w/syn velocity",0,127,60)
    params:add_option(i.."_pad_to_crow_v-8", "crow v/8 output",{"none","1","2","3","4"},1)
    params:set_action(i.."_pad_to_crow_v-8",
    function(x)
      if all_loaded then
        persistent_state_save()
      end
    end
    )
    params:add_option(i.."_pad_to_crow_pulse", "crow pulse output",{"none","1","2","3","4"},1)
    params:set_action(i.."_pad_to_crow_pulse",
    function(x)
      if all_loaded then
        persistent_state_save()
      end
    end
    )
    params:add_option(i.."_pad_to_jf_pulse", "Just Friends pulse ch.",{"none","ID","2N","3N","4N","5N","6N","all"},1)
    params:set_action(i.."_pad_to_jf_pulse",
    function(x)
      if all_loaded then
        persistent_state_save()
      end
    end
    )
    mc.build_scale(i)
    -- if mxcc ~= nil then
    --   mxcc_available = mxcc:list_instruments()
    -- else
    --   mxcc_available = {}
    -- end
    -- table.insert(mxcc_available,1,"none")
    -- params:add_option(i.."_pad_to_mxcc_note_enabled", "Mx voice",mxcc_available,1)
  end

  params:add_group("w/syn controls",10)
  params:add {
    type = "option",
    id = "wsyn_ar_mode",
    name = "AR mode",
    options = {"off", "on"},
    default = 2,
    action = function(val) 
      crow.ii.wsyn.ar_mode(val - 1) 
    end
  }
  params:add {
    type = "control",
    id = "w/curve",
    name = "Curve",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) 
      crow.ii.wsyn.curve(val)
    end
  }
  params:add {
    type = "control",
    id = "w/ramp",
    name = "Ramp",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) 
      crow.ii.wsyn.ramp(val)
    end
  }
  params:add {
    type = "control",
    id = "w/fm index",
    name = "FM index",
    controlspec = controlspec.new(0, 5, "lin", 0, 0, "v"),
    action = function(val) 
      crow.ii.wsyn.fm_index(val)
    end
  }
  params:add {
    type = "control",
    id = "w/fm env",
    name = "FM env",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) 
      crow.ii.wsyn.fm_env(val)
    end
  }
  params:add {
    type = "control",
    id = "w/fm num",
    name = "FM ratio numerator",
    controlspec = controlspec.new(1, 20, "lin", 1, 2),
    action = function(val) 
      crow.ii.wsyn.fm_ratio(val, params:get("w/fm den"))
    end
  }
  params:add {
    type = "control",
    id = "w/fm den",
    name = "FM ratio denominator",
    controlspec = controlspec.new(1, 20, "lin", 1, 1),
    action = function(val) 
      crow.ii.wsyn.fm_ratio(params:get("w/fm num"), val)
    end
  }
  params:add {
    type = "control",
    id = "w/lpg time",
    name = "LPG time",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) 
      crow.ii.wsyn.lpg_time(val)
    end
  }
  params:add {
    type = "control",
    id = "w/lpg symm",
    name = "LPG symmetry",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) 
      crow.ii.wsyn.lpg_symmetry(val)
    end
  }
  params:add{
    type = "trigger",
    id = "wsyn_randomize",
    name = "Randomize",
    allow_pmap = false,
    action = function()
      params:set("w/curve", math.random(-50, 50)/10)
      params:set("w/ramp", math.random(-50, 50)/10)
      params:set("w/fm index", math.random(0, 50)/10)
      params:set("w/fm env", math.random(-50, 50)/10)
      params:set("w/fm num", math.random(1, 20))
      params:set("w/fm den", math.random(1, 20))
      params:set("w/lpg time", math.random(-50, 50)/10)
      params:set("w/lpg symm", math.random(-50, 50)/10)
    end
  }

  function wsyn_init()
    crow.ii.wsyn.ar_mode(params:get("wsyn_ar_mode") - 1)
    crow.ii.wsyn.curve(params:get("w/curve"))
    crow.ii.wsyn.ramp(params:get("w/ramp"))
    crow.ii.wsyn.fm_index(params:get("w/fm index"))
    crow.ii.wsyn.fm_env(params:get("w/fm env"))
    crow.ii.wsyn.fm_ratio(params:get("w/fm num"), params:get("w/fm den"))
    crow.ii.wsyn.lpg_time(params:get("w/lpg time"))
    crow.ii.wsyn.lpg_symmetry(params:get("w/lpg symm"))
  end

end

function mc.build_scale(target)
  mc_notes[target] = MU.generate_scale_of_length(params:get(target.."_pad_to_midi_note_root")+(12*(params:get(target.."_pad_to_midi_note_root_octave")-1)), params:get(target.."_pad_to_midi_note_scale"), 16)
  local num_to_add = 16 - #mc_notes[target]
  for i = 1, num_to_add do
    table.insert(mc_notes[target], mc_notes[target][16 - num_to_add])
  end
  mc.inherit_notes(target)
end

local midi_off = {nil,nil,nil}

function mc.inherit_notes(target)
  if all_loaded then
    for i = 1,16 do
      mc.midi_notes[target].entries[i] = mc_notes[target][i]
    end
  end
end

-- function what()
--   for i=1,10 do
--     if i == 3 then
--       goto different
--     end
--     print("do this for "..i)
--   end
--   ::different::
--   print("this is 3")
-- end

local mx_dests ={
  "steinway model b"
, "cello"
, "alto sax choir"
}

function mc.midi_note_from_pad(b,p)
  if bank[b][p].crow_pad_execute == 1 then
    if params:string(b.."_pad_to_midi_note_enabled") == "yes" then
      if mc.get_midi("midi_notes",b,p) ~= "-" and mc.get_midi("midi_notes_velocities",b,p) ~= "-" and mc.get_midi("midi_notes_channels",b,p) ~= "-" then
        mc.all_midi_notes_off(b)
        -- local note_num = mc_notes[b][p]
        local note_num = mc.get_midi("midi_notes",b,p)
        -- local vel = params:get(b.."_pad_to_midi_note_velocity")
        local vel = mc.get_midi("midi_notes_velocities",b,p)
        local ch = params:get(b.."_pad_to_midi_note_channel")
        local dest = params:get(b.."_pad_to_midi_note_destination")
        midi_dev[dest]:note_on(note_num,vel,ch)
        table.insert(active_midi_notes[b], note_num)
        if midi_off[b] ~= nil then clock.cancel(midi_off[b]) end
        midi_off[b] = clock.run(mc.midi_note_from_pad_off,b,p)
        -- mxcc:on({name = mx_dests[b],midi=note_num,velocity=vel})
      end
    end
    if mc.get_midi("midi_ccs",b,p) ~= "-" and mc.get_midi("midi_ccs_values",b,p) ~= "-" and mc.get_midi("midi_ccs_channels",b,p) ~= "-" then
      local cc_num = mc.get_midi("midi_ccs",b,p)
      local val = mc.get_midi("midi_ccs_values",b,p)
      local ch = mc.get_midi("midi_ccs_channels",b,p)
      local dest = params:get(b.."_pad_to_midi_note_destination")
      midi_dev[dest]:cc(cc_num,val,ch)
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
    if params:string("global_pad_to_wsyn_note_enabled") == "yes" then
      if params:string(b.."_pad_to_wsyn_note_enabled") ~= "none" then
        local note_num = mc_notes[b][p] - 60
        local velocity = util.linlin(0,127,0,5,params:get(b.."_pad_to_wsyn_note_velocity"))
        if params:string(b.."_pad_to_wsyn_note_enabled") == "any" then
          crow.ii.wsyn.play_note(note_num/12,velocity)
        else
          local wsyn_chan = params:get(b.."_pad_to_wsyn_note_enabled") - 1
          crow.ii.wsyn.play_voice(wsyn_chan,note_num/12,velocity)
        end
      end
    end
    if params:string(b.."_pad_to_crow_v-8") ~= "none" then
      local note_num =  mc.get_midi("midi_notes",b,p) - 60
      local which_output = tonumber(params:string(b.."_pad_to_crow_v-8"))
      crow.output[which_output].volts = note_num/12
    end
    if params:string(b.."_pad_to_crow_pulse") ~= "none" then
      local which_output = tonumber(params:string(b.."_pad_to_crow_pulse"))
      norns.crow.send ("output["..which_output.."]( pulse() )")
    end
    if params:string(b.."_pad_to_jf_pulse") ~= "none" then
      local jf_destinations =
      {
        ["ID"] = 1
      , ["2N"] = 2
      , ["3N"] = 3
      , ["4N"] = 4
      , ["5N"] = 5
      , ["6N"] = 6
      , ["all"] = 0
      }
      -- local note_num = mc_notes[b][p] - 60
      local velocity = util.round(util.linlin(0,127,0,10,mc.get_midi("midi_notes_velocities",b,p)))
      -- local velocity = params:get(b.."_pad_to_jf_note_velocity")
      if params:string(b.."_pad_to_jf_pulse") == "any" then
        crow.ii.jf.play_note(0,velocity)
      else
        local jf_chan = jf_destinations[params:string(b.."_pad_to_jf_pulse")]
        crow.ii.jf.vtrigger(jf_chan,velocity)
      end
    end
  end
end

function mc.midi_note_from_pad_off(b,p)
  clock.sleep(bank[b][p].arp_time-(bank[b][p].arp_time/100))
  mc.all_midi_notes_off(b)
  midi_off[b] = nil
end

function mc.all_midi_notes_off(b)
  for _, a in pairs(active_midi_notes[b]) do
    midi_dev[params:get(b.."_pad_to_midi_note_destination")]:note_off(a, nil, params:get(b.."_pad_to_midi_note_channel"))
    -- mxcc:off({name = mx_dests[b],midi=a})
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
  , ["a: pause"] = {2,'12'}
  , ["b: pause"] = {2,'12'}
  , ["c: pause"] = {2,'12'}
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
  for j = (not grid_alt and bank[b].id or 1), (not grid_alt and bank[b].id or 16) do
    rightangleslice.actions[row][str][1](bank[b][j])
    if str ~= '12' then
      rightangleslice.actions[row][str][2](bank[b][j],b)
    end
  end
end

local UI_number_table = {}
local UI_note_table = {{},{},{}}
local UI_note_ch_table = {{},{},{}}
local UI_velocity_table = {{},{},{}}
local UI_cc_table = {{},{},{}}
local UI_cc_ch_table = {{},{},{}}
local UI_cc_value_table = {{},{},{}}
mc.numbers = {}
mc.midi_notes = {}
mc.midi_notes_channels = {}
mc.midi_notes_velocities = {}
mc.midi_ccs = {}
mc.midi_ccs_channels = {}
mc.midi_ccs_values = {}

local function set_limits(target,bank)
  mc[target][bank].num_above_selected = 0
  mc[target][bank].num_visible = 4
end

function mc.initialize_UI()
  for i = 1,16 do
    table.insert(UI_number_table,i..": ")
    for j = 1,3 do
      table.insert(UI_note_table[j],mc_notes[j][i])
      table.insert(UI_note_ch_table[j],params:get(j.."_pad_to_midi_note_channel"))
      table.insert(UI_velocity_table[j],params:get(j.."_pad_to_midi_note_velocity"))
      table.insert(UI_cc_table[j],"-")
      table.insert(UI_cc_ch_table[j],params:get(j.."_pad_to_midi_note_channel"))
      table.insert(UI_cc_value_table[j],127)
    end
  end
  for i = 1,3 do
    mc.numbers[i] = UI.ScrollingList.new(0,20,1,UI_number_table)
    set_limits("numbers",i)
    mc.midi_notes[i] = UI.ScrollingList.new(15,20,1,UI_note_table[i])
    set_limits("midi_notes",i)
    mc.midi_notes_velocities[i] = UI.ScrollingList.new(30,20,1,UI_velocity_table[i])
    set_limits("midi_notes_velocities",i)
    mc.midi_notes_channels[i] = UI.ScrollingList.new(50,20,1,UI_note_ch_table[i])
    set_limits("midi_notes_channels",i)
    mc.midi_notes_channels[i].active = false
    mc.midi_ccs[i] = UI.ScrollingList.new(70,20,1,UI_cc_table[i])
    set_limits("midi_ccs",i)
    mc.midi_ccs[i].active = false
    mc.midi_ccs_values[i] = UI.ScrollingList.new(85,20,1,UI_cc_value_table[i])
    set_limits("midi_ccs_values",i)
    mc.midi_ccs_values[i].active = false
    mc.midi_ccs_channels[i] = UI.ScrollingList.new(105,20,1,UI_cc_ch_table[i])
    set_limits("midi_ccs_channels",i)
    mc.midi_ccs_channels[i].active = false
  end
end

function mc.update_UI_list(target,bank,k,v)
  mc[target][bank].entries[k] = v
end

function mc.flip_from_text(target)
  if target == "-" then
    return -1
  else
    return target
  end
end
function mc.flip_to_text(target)
  if target == -1 then
    return "-"
  else
    return target
  end
end

function mc.get_midi(format,bank,pad)
  return mc[format][bank].entries[pad]
end

function mc.set_parameter_all(parameter,target,min,max,value,exclude)
  for i = min,max do
    if exclude ~= nil and i ~= exclude then
      mc[parameter][target].entries[i] = value
    end
  end
end

function mc.delta_parameter_all(parameter,target,min,max,d,exclude)
  for i = min,max do
    if exclude ~= nil and i ~= exclude then
      encoder_actions.delta_MIDI_values(mc[parameter][i],d)
    end
  end
end

function mc.reverse_pad_notes(list)
  local reversed_list = {}
  for i = 1,4 do
    reversed_list[i] = list[i+12]
  end
  for i = 5,8 do
    reversed_list[i] = list[i+4]
  end
  for i = 9,12 do
    reversed_list[i] = list[i-4]
  end
  for i = 13,16 do
    reversed_list[i] = list[i-12]
  end
  return reversed_list
end

function mc.key(n,z)
  if n == 3 and z == 1 then
    if key2_hold and not key1_hold then
      local i = page.midi_bank
      local menu_actions =
      {
        ["notes"] = {"midi_notes", mc.midi_notes[i].entries[mc.midi_notes[i].index]}
      , ["alt_notes"] = {"midi_notes_channels", mc.midi_notes_channels[i].entries[mc.midi_notes[i].index]}
      , ["ccs"] = {"midi_ccs",mc.midi_ccs[i].entries[mc.midi_ccs[i].index]}
      , ["alt_ccs"] = {"midi_ccs_channels",mc.midi_ccs_channels[i].entries[mc.midi_ccs_channels[i].index]}
      }
      local this_param = menu_actions[page.midi_focus][1]
      local this_value = menu_actions[page.midi_focus][2]
      local this_exclude = mc.midi_notes[i].index
      mc.set_parameter_all(this_param,page.midi_bank,1,16,this_value,this_exclude)
      key2_hold_and_modify = true
    elseif key2_hold and key1_hold then
      local i = page.midi_bank
      local menu_actions =
      {
        ["alt_notes"] = {"midi_notes_channels", mc.midi_notes_channels[i].entries[mc.midi_notes[i].index]}
      , ["alt_ccs"] = {"midi_ccs_channels",mc.midi_ccs_channels[i].entries[mc.midi_ccs_channels[i].index]}
      }
      local this_param = menu_actions[page.midi_focus][1]
      local this_value = menu_actions[page.midi_focus][2]
      local this_exclude = mc.midi_notes[i].index
      mc.set_parameter_all(this_param,page.midi_bank,1,16,this_value,this_exclude)
      key2_hold_and_modify = true
    elseif not key2_hold and key1_hold and page.midi_focus == "header" then
      mc.midi_notes[page.midi_bank].entries = mc.reverse_pad_notes(mc.midi_notes[page.midi_bank].entries)
      key1_hold = false
    else
      local d = {"header", "notes", "ccs"}
      local old_focus = tab.key(d,page.midi_focus)
      page.midi_focus = d[util.wrap(old_focus + 1,1,3)]
    end
  elseif n == 2 and z == 1 then
    key2_hold_counter:start()
    key2_hold_and_modify = false
  elseif n == 2 and z == 0 then
    key2_hold_counter:stop()
    if key2_hold == false then
      menu = 1
    end
    key2_hold = false
    key1_hold = false
    key2_hold_and_modify = false
  elseif n == 1 and z == 1 then
    if key2_hold then
      local i = page.midi_bank
      local menu_actions =
      {
        ["notes"] = {"midi_notes_velocities", mc.midi_notes_velocities[i].entries[mc.midi_notes[i].index]}
      , ["ccs"] = {"midi_ccs_values",mc.midi_ccs_values[i].entries[mc.midi_ccs[i].index]}
      }
      local this_param = menu_actions[page.midi_focus][1]
      local this_value = menu_actions[page.midi_focus][2]
      local this_exclude = mc.midi_notes[i].index
      mc.set_parameter_all(this_param,page.midi_bank,1,16,this_value,this_exclude)
      key2_hold_and_modify = true
      key1_hold = false
    else
      key1_hold = true
      if page.midi_focus ~= "header" then
        pre_k1_midi_page = page.midi_focus
        page.midi_focus = pre_k1_midi_page == "notes" and "alt_notes" or "alt_ccs"
      end
    end
  elseif n == 1 and z == 0 then
    key1_hold = false
    if page.midi_focus ~= "header" then
      if pre_k1_midi_page == nil then pre_k1_midi_page = page.midi_focus end
      page.midi_focus = pre_k1_midi_page
    end
  end
end

function mc.midi_config_enc(n,d)
  if n == 1 then
    if page.midi_focus == "header" then
      page.midi_bank = util.clamp(page.midi_bank + d,1,3)
    else
      local i = page.midi_bank
      mc.numbers[i]:set_index_delta(d)
      mc.midi_notes[i]:set_index_delta(d)
      mc.midi_notes_channels[i]:set_index_delta(d)
      mc.midi_notes_velocities[i]:set_index_delta(d)
      mc.midi_ccs[i]:set_index_delta(d)
      mc.midi_ccs_channels[i]:set_index_delta(d)
      mc.midi_ccs_values[i]:set_index_delta(d)
    end
  elseif n == 2 then
    local i = page.midi_bank
    if page.midi_focus == "notes" then
      encoder_actions.delta_MIDI_values(mc.midi_notes[i],d)
    elseif page.midi_focus == "ccs" then
      encoder_actions.delta_MIDI_values(mc.midi_ccs[i],d)
    elseif page.midi_focus == "alt_notes" then
      encoder_actions.delta_MIDI_values(mc.midi_notes_channels[i],d)
    elseif page.midi_focus == "alt_ccs" then
      encoder_actions.delta_MIDI_values(mc.midi_ccs_channels[i],d)
    end
  elseif n == 3 then
    local i = page.midi_bank
    if page.midi_focus == "notes" then
      encoder_actions.delta_MIDI_values(mc.midi_notes_velocities[i],d)
    elseif page.midi_focus == "ccs" then
      encoder_actions.delta_MIDI_values(mc.midi_ccs_values[i],d)
    elseif page.midi_focus == "header" and key1_hold then
      params:delta(i.."_pad_to_midi_note_scale",d)
    end
  end
end

function mc.midi_config_redraw(i)
  if all_loaded then
    
    mc.numbers[i].active = page.midi_focus ~= "header" and true or false
    mc.midi_notes[i].active = page.midi_focus == "notes" and true or false
    mc.midi_notes_channels[i].active = page.midi_focus == "alt_notes" and true or false
    mc.midi_notes_velocities[i].active = page.midi_focus == "notes" and true or false
    mc.midi_ccs[i].active = page.midi_focus == "ccs" and true or false
    mc.midi_ccs_channels[i].active = page.midi_focus == "alt_ccs" and true or false
    mc.midi_ccs_values[i].active = page.midi_focus == "ccs" and true or false
    
    -- mc.midi_config_tabs.active = page.midi_focus == "header" and true or false

    local bank_names = {"(a)","(b)","(c)"}
    local x_locations = {5,55,105}
    screen.level(page.midi_focus == "header" and 15 or 3)
    screen.rect(0, 0, 128, 7)
    screen.fill()
    screen.move(2,6)
    screen.level(0)
    screen.text("MIDI CONFIG: BANK "..bank_names[page.midi_bank])
    screen.move(126,6)
    screen.text_right(page.midi_bank.."/3")
    if key1_hold and page.midi_focus == "header" then
      screen.level(15)
      screen.move(60,20)
      screen.text_center("SCALE:")
      screen.move(60,30)
      screen.text_center(string.upper(params:string(page.midi_bank.."_pad_to_midi_note_scale")))
      screen.move(60,50)
      screen.text_center("KEY 3: REVERSE DISTRIBUTION")
    elseif key2_hold and page.midi_focus ~= "header" and not key2_hold_and_modify then
      local view_menus =
      {
        ["notes"] = {"notes",mc.midi_notes[i].entries[mc.midi_notes[i].index],"velocities",mc.midi_notes_velocities[i].entries[mc.midi_notes_velocities[i].index]}
      , ["alt_notes"] = {"note chs",mc.midi_notes_channels[i].entries[mc.midi_notes_channels[i].index]}
      , ["ccs"] = {"ccs",mc.midi_ccs[i].entries[mc.midi_ccs[i].index],"values",mc.midi_ccs_values[i].entries[mc.midi_ccs_values[i].index]}
      , ["alt_ccs"] = {"cc chs",mc.midi_ccs_channels[i].entries[mc.midi_ccs_channels[i].index]}
      }
      screen.level(15)
      screen.move(60,30)
      local this_menu = view_menus[page.midi_focus]
      screen.text_center("+K3: set all "..this_menu[1].." to "..this_menu[2])
      if #this_menu == 4 then
        screen.move(60,40)
        screen.text_center("+K1: set all "..this_menu[3].." to "..this_menu[4])
      end
    else
      screen.move(mc.numbers[i].x,mc.numbers[i].y-5)
      screen.level(page.midi_focus ~= "header" and 15 or 3)
      screen.text("#")
      mc.numbers[i]:redraw()
      screen.move(mc.midi_notes[i].x,mc.midi_notes[i].y-5)
      screen.level(page.midi_focus == "notes" and 15 or 3)
      screen.text("N")
      mc.midi_notes[i]:redraw()
      screen.move(mc.midi_notes_velocities[i].x+5,mc.midi_notes_velocities[i].y-5)
      screen.level(page.midi_focus == "notes" and 15 or 3)
      screen.text_center("V")
      mc.midi_notes_velocities[i]:redraw()
      screen.move(mc.midi_notes_channels[i].x+2,mc.midi_notes_channels[i].y-5)
      screen.level(page.midi_focus == "alt_notes" and 15 or 3)
      screen.text_center("CH")
      screen.move(mc.midi_ccs[i].x,mc.midi_ccs[i].y-5)
      screen.level(page.midi_focus == "ccs" and 15 or 3)
      screen.text("CC")
      mc.midi_ccs[i]:redraw()
      screen.move(mc.midi_ccs_values[i].x+5,mc.midi_ccs_values[i].y-5)
      screen.level(page.midi_focus == "ccs" and 15 or 3)
      screen.text_center("V")
      screen.move(mc.midi_ccs_channels[i].x+2,mc.midi_ccs_channels[i].y-5)
      screen.level(page.midi_focus == "alt_ccs" and 15 or 3)
      screen.text_center("CH")
      mc.midi_ccs_values[i]:redraw()
      mc.midi_notes_channels[i]:redraw()
      mc.midi_ccs_channels[i]:redraw()
    end
  end
end

return midicheat