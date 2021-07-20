local clip_actions = {}

local ca = clip_actions

function ca.init()
  SOS = {}
end

function ca.clip_table()
  clip[1].min = 1
  clip[1].max = clip[1].min + clip[1].sample_length
  --clip[2].min = clip[1].max
  clip[2].min = 33
  clip[2].max = clip[2].min + clip[2].sample_length
  --clip[3].min = clip[2].max
  clip[3].min = 65
  clip[3].max = clip[3].min + clip[3].sample_length
end

-- length mods

function ca.scale_loop_points(pad,old_min,old_max,new_min,new_max)
  --local pad = bank[b][p]
  local duration = pad.end_point - pad.start_point
  pad.start_point = util.linlin(old_min,old_max,new_min,new_max,pad.start_point)
  --pad.end_point = util.linlin(old_min,old_max,new_min,new_max,pad.end_point)
  if pad.start_point + duration > new_max then
    pad.end_point = new_max
  else
    pad.end_point = pad.start_point + duration
  end
end

function ca.change_mode(target,old_mode)
  local live_min = live[target.clip].min
  local live_max = live[target.clip].max
  local clip_min = clip[target.clip].min
  local clip_max = clip[target.clip].max
  local duration = target.end_point - target.start_point
  if old_mode == 1 then
    target.start_point = util.linlin(live_min,live_max,clip_min,clip_max,target.start_point)
  elseif old_mode == 2 then
    target.start_point = util.linlin(clip_min,clip_max,live_min,live_max,target.start_point)
  end
  if target.start_point + duration > (old_mode == 1 and clip[target.clip].max or live[target.clip].max) then
    target.end_point = (old_mode == 1 and clip[target.clip].max or live[target.clip].max)
  else
    target.end_point = target.start_point + duration
  end
end

function ca.jump_clip(bank_id,pad_id,new_clip)
  local pad = bank[bank_id][pad_id]
  local current_difference = (pad.end_point - pad.start_point)
  if pad.mode == 2 then
    local old_clip = pad.clip
    pad.clip = new_clip
    pad.start_point = util.linlin(clip[old_clip].min,clip[old_clip].max,clip[pad.clip].min,clip[pad.clip].max,pad.start_point)
    if pad.start_point + current_difference > clip[pad.clip].max then
      pad.end_point = clip[pad.clip].max
    else
      pad.end_point = pad.start_point + current_difference
    end
  else
    local old_clip = pad.clip
    pad.clip = new_clip
    pad.start_point = util.linlin(live[old_clip].min,live[old_clip].max,live[pad.clip].min,live[pad.clip].max,pad.start_point)
    if pad.start_point + current_difference > live[pad.clip].max then
      pad.end_point = live[pad.clip].max
    else
      pad.end_point = pad.start_point + current_difference
    end
  end
end

function ca.buff_freeze()
  softcut.recpre_slew_time(1,0.05)
  softcut.level_slew_time(1,0.05)
  softcut.fade_time(1,0.01)
  rec[rec.focus].state = (rec[rec.focus].state + 1)%2
  softcut.rec_level(1,rec[rec.focus].state)
  if rec[rec.focus].state == 1 then
    softcut.pre_level(1,params:get("live_rec_feedback_"..rec.focus))
  else
    softcut.pre_level(1,1)
  end
end

function ca.buff_flush()
  softcut.buffer_clear_region_channel(1,rec[rec.focus].start_point, rec[rec.focus].end_point-rec[rec.focus].start_point)
  rec[rec.focus].state = 0
  rec[rec.focus].clear = 1
  softcut.rec_level(1,0)
  if key1_hold then
    update_waveform(1,rec[rec.focus].start_point, rec[rec.focus].end_point,128)
  else
    -- local points = {{1,33},{34,66},{67,99}}
    local points = {{1,33},{33,65},{65,97}}
    update_waveform(1,points[rec.focus][1],points[rec.focus][2],128)
  end
  grid_dirty = true
end

function ca.buff_pause()
  rec[rec.focus].pause = not rec[rec.focus].pause
  softcut.rate(1,rec[rec.focus].pause and 0 or 1) -- TODO make this dynamic to include rec rate offsets
end

function ca.threshold_rec_handler()
  if rec[rec.focus].queued then
    amp_in[1]:stop()
    amp_in[2]:stop()
    rec[rec.focus].queued = false
  elseif not rec[rec.focus].queued and rec[rec.focus].state == 0 then
    amp_in[1]:start()
    amp_in[2]:start()
    rec[rec.focus].queued = true
    for i = 1,3 do
      if i~=rec.focus and rec[i].state == 1 then
        softcut.rec_level(1,0)
        softcut.pre_level(1,params:get("live_rec_feedback_"..i))
      end
    end
  elseif not rec[rec.focus].queued and rec[rec.focus].state == 1 then
    rec[rec.focus].end_point = poll_position_new[1]
    update_waveform(1,key1_hold and rec[rec.focus].start_point or live[rec.focus].min,key1_hold and rec[rec.focus].end_point or live[rec.focus].max,128)
  end
end

function ca.toggle_buffer(i,untrue_alt)

  grid_dirty = true
  
  local old_clip = rec.focus

  for j = 1,3 do
    if j ~= i then
      rec[j].state = 0
    end
  end

  rec.focus = i

  if rec[rec.focus].loop == 0 and params:string("one_shot_clock_div") == "threshold" and rec[rec.focus].queued then
    softcut.level_slew_time(1,0)
    softcut.fade_time(1,0)
    one_shot_clock()
  else
    softcut.level_slew_time(1,0.05)
    softcut.fade_time(1,0.01)
    if rec[rec.focus].loop == 0 and not grid_alt then
      if rec[rec.focus].state == 0 then
        run_one_shot_rec_clock() -- this runs only if not recording
      elseif rec[rec.focus].state == 1 and rec_state_watcher.is_running then -- can have both conditions, right?
        cancel_one_shot_rec_clock()
      end
    elseif rec[rec.focus].loop == 0 and (grid_alt and untrue_alt ~= nil) then
      -- ca.buff_flush()
    elseif rec[rec.focus].loop == 1 and not grid_alt then
      if one_shot_rec_clock ~= nil and rec_state_watcher.is_running then
        cancel_one_shot_rec_clock()
      end
      softcut.loop_start(1,rec[rec.focus].start_point)
      softcut.loop_end(1,rec[rec.focus].end_point-0.01)
    end
  end
  
  rec.play_segment = rec.focus
  softcut.loop(1,rec[rec.focus].loop)
  if rec.stopped == true then
    rec.stopped = false
    if rec[rec.focus].loop == 1 then
      softcut.position(1,rec[rec.focus].start_point)
    end
  end
  if rec[rec.focus].loop == 1 then
    if old_clip ~= rec.focus then rec[rec.focus].state = 0 end
    ca.buff_freeze()
    if rec[rec.focus].clear == 1 then
      rec[rec.focus].clear = 0
    end
  end
  -- end
  grid_dirty = true
  update_waveform(1,key1_hold and rec[rec.focus].start_point or live[rec.focus].min,key1_hold and rec[rec.focus].end_point or live[rec.focus].max,128)
end

function ca.SOS_voice_overwrite(target,state)
  --expects source: bank[x][y], state: boolean
  if state then
    local feedback = params:get("SOS_feedback_"..target.bank_id)
    local l_in = params:get("SOS_L_in_"..target.bank_id)
    local r_in = params:get("SOS_R_in_"..target.bank_id)
    softcut.pre_level(target.bank_id+1,feedback)
    softcut.rec_level(target.bank_id+1,1)
    softcut.level_input_cut(1,target.bank_id+1,l_in)
    softcut.level_input_cut(2,target.bank_id+1,r_in)
    softcut.rec(target.bank_id+1,1)
  else
    softcut.pre_level(target.bank_id+1,1)
    softcut.rec_level(target.bank_id+1,0)
  end
end

function ca.SOS_save_clip(i)
  local dirname = _path.dust.."audio/ccy_saved_SOS_clips/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local dirname = _path.dust.."audio/ccy_saved_SOS_clips/"..os.date("%y%m%d").."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local name = "ccy_"..os.date("%X-SOS_clip")..i..".wav"
  softcut.buffer_write_mono(_path.dust.."/audio/ccy_saved_SOS_clips/"..os.date("%y%m%d").."/"..name,clip[i].min,clip[i].max-clip[i].min,2)
end

function ca.SOS_toggle(i)
  local current_state = params:get("SOS_enabled_"..i)
  params:set("SOS_enabled_"..i, current_state == 1 and 0 or 1)
  ca.SOS_voice_overwrite(bank[i][bank[i].id],params:get("SOS_enabled_"..i) == 1 and true or false)
  force_waveform_redraw()
end

function ca.SOS_erase(i)
  local target = bank[i][bank[i].id].mode
  local fade = params:get("SOS_erase_fade_"..i)
  local preserve = 1 - params:get("SOS_erase_strength_"..i)
  softcut.buffer_clear_region_channel(target,bank[i][bank[i].id].start_point, (bank[i][bank[i].id].end_point-bank[i][bank[i].id].start_point)+0.01,fade,preserve)
  if key1_hold and menu == 2 then
    update_waveform(target,bank[i][bank[i].id].start_point, bank[i][bank[i].id].end_point,128)
  else
    local points;
    local cl = bank[i][bank[i].id].clip
    if target == 1 then
      points = {live[cl].min,live[cl].max}
    else
      points = {clip[cl].min,clip[cl].max}
    end
    update_waveform(target,points[1],points[2],128)
  end
  grid_dirty = true
end

function ca.sample_callback(path,i)
  if path ~= "cancel" and path ~= "" then
    ca.load_sample(path,i)
  end
  _norns.key(1,1)
  _norns.key(1,0)
  key1_hold = false
end

function ca.load_sample(file,sample)
  local old_min = clip[sample].min
  local old_max = clip[sample].max
  if file ~= "-" then
    local ch, len, rate = audio.file_info(file)
    if rate ~= 48000 then print("sample rate needs to be 48khz!") end
    if len/48000 < 32 then
      clip[sample].sample_length = len/48000
    else
      clip[sample].sample_length = 32
    end
    clip[sample].original_length = len/48000
    clip[sample].original_bpm = _dough.derive_bpm(clip[sample])
    clip[sample].original_samplerate = rate/1000
    local im_ch = ch == 2 and clip[sample].channel or 1
    softcut.buffer_clear_region_channel(2,1+(32*(sample-1)),32)
    softcut.buffer_read_mono(file, 0, 1+(32*(sample-1)),clip[sample].sample_length + 0.05, im_ch, 2)
    ca.clip_table()
    for p = 1,16 do
      for b = 1,3 do
        if bank[b][p].mode == 2 and bank[b][p].clip == sample and pre_cc2_sample[b] == false then
          ca.scale_loop_points(bank[b][p], old_min, old_max, clip[sample].min, clip[sample].max)
        end
      end
    end
  end
  for i = 1,3 do
    pre_cc2_sample[i] = false
  end
  update_waveform(2,clip[sample].min,clip[sample].max,128)
  clip[sample].waveform_samples = waveform_samples
  if params:get("clip "..sample.." sample") ~= file then
    params:set("clip "..sample.." sample", file, 1)
  end
end

function ca.load_sample_into_live_window(file,sample,startpoint,endpoint)
  local old_min = startpoint
  local old_max = endpoint
  if file ~= "-" then
    local ch, len, rate = audio.file_info(file)
    if rate ~= 48000 then print("sample rate needs to be 48khz!") end
    local im_ch = 1
    softcut.buffer_clear_region_channel(1,startpoint,endpoint-startpoint)
    softcut.buffer_read_mono(file, 0, startpoint,endpoint-startpoint, im_ch, 1)
  end
  update_waveform(1,live[sample].min,live[sample].max,128)
  rec[sample].waveform_samples = waveform_samples
end

function ca.auto_plop(file,sample,startpoint,endpoint)
  -- local old_min = rec[sample].start_point
  -- local old_max = live[sample].end_point
  local old_min = startpoint
  local old_max = endpoint
  if file ~= "-" then
    local ch, len, rate = audio.file_info(file)
    if rate ~= 48000 then print("sample rate needs to be 48khz!") end
    -- if len/48000 < 32 then
    --   clip[sample].sample_length = len/48000
    -- else
    --   clip[sample].sample_length = 32
    -- end
    -- clip[sample].original_length = len/48000
    -- clip[sample].original_bpm = _dough.derive_bpm(clip[sample])
    -- clip[sample].original_samplerate = rate/1000
    -- local im_ch = ch == 2 and clip[sample].channel or 1
    local im_ch = 1
    softcut.buffer_clear_region_channel(1,startpoint,endpoint-startpoint)
    softcut.buffer_read_mono(file, 0, startpoint,endpoint-startpoint, im_ch, 1)
    -- ca.clip_table()
    -- for p = 1,16 do
    --   for b = 1,3 do
    --     if bank[b][p].mode == 2 and bank[b][p].clip == sample and pre_cc2_sample[b] == false then
    --       ca.scale_loop_points(bank[b][p], old_min, old_max, clip[sample].min, clip[sample].max)
    --     end
    --   end
    -- end
  end
  -- for i = 1,3 do
  --   pre_cc2_sample[i] = false
  -- end
  update_waveform(1,live[sample].min,live[sample].max,128)
  rec[sample].waveform_samples = waveform_samples
  -- if params:get("clip "..sample.." sample") ~= file then
  --   params:set("clip "..sample.." sample", file, 1)
  -- end
end

function ca.save_sample(i)
  local dirname = _path.dust.."audio/ccy_saved_samples/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local name = "ccy_"..os.date("%y%m%d_%X-buff")..i..".wav"
  local save_pos = i - 1
  softcut.buffer_write_mono(_path.dust.."/audio/ccy_saved_samples/"..name,1+(32*save_pos),8,1)
end

function ca.collect_samples(i,collection) -- this works!!!
  local dirname = _path.dust.."audio/ccy_live-audio/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local dirname = _path.dust.."audio/ccy_live-audio/"..collection.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local name = "ccy_"..collection.."-"..i..".wav"
  local save_pos = i - 1
  softcut.buffer_write_mono(_path.dust.."audio/ccy_live-audio/"..collection.."/"..name,1+(32*save_pos),32,1)
end

function ca.reload_collected_samples(file,sample)
  if rec[rec.focus].state == 1 then
    ca.buff_freeze()
  end
  if file ~= "-" then
    print(file)
    softcut.buffer_read_mono(file, 0, 1+(32 * (sample-1)), 32, 1, 1)
    print("reloaded previous session's audio")
  end
end

function ca.folder_callback(file,dest)
  
  local split_at = string.match(file, "^.*()/")
  local folder = string.sub(file, 1, split_at)
  file = string.sub(file, split_at + 1)
  
  ca.collage(folder,dest,1)
  
  _norns.key(1,1)
  _norns.key(1,0)
  key1_hold = false
end

function ca.collage(folder,dest,style)
  local wavs = util.scandir(folder)
  local clean_wavs = {}
  local sample_id = 0
  for index, data in ipairs(wavs) do
    if string.match(data, ".wav") then
      table.insert(clean_wavs, data)
      sample_id = sample_id + 1
    end
  end
  print(sample_id)
  tab.print(clean_wavs)

  -- ok what are the desireable behaviors??
  -- STYLE 1, load whole folder sequentially

  if style == 1 then
    for i = 1,(sample_id <=16 and sample_id or 16) do
      local samp = folder .. clean_wavs[i]
      softcut.buffer_clear_region_channel(2,1+(32*(dest-1))+((i-1)*2)+variable_fade_time,2)
      softcut.buffer_read_mono(samp, 0, 1+(32*(dest-1))+((i-1)*2)+variable_fade_time,2, 1, 2)
      print(samp,i,1+(32*(dest-1))+((i-1)*2))
    end
  end
  clip[dest].sample_length = 32
  ca.clip_table()
  clip[dest].original_length = 32
  clip[dest].original_bpm = 120
  clip[dest].original_samplerate = 48
  
  update_waveform(2,clip[dest].min,clip[dest].max,128)

  -- local total_length = 32
  -- for i = sample_id,1,-1 do
  --   local samp = _path.audio .. folder .. clean_wavs[i]
  -- -- local ch, len = audio.file_info(samp)
  -- local start_source;
  -- -- get 2 seconds per pad
  -- if len/48000 >=2 then
  --   local start_source = math.random(0,math.floor(len/48000))
  -- else
  --   local start_source = 0
  -- end
  -- for i = 0,32,2 do
  --   softcut.buffer_clear_region_channel(2,1+(32*(dest-1))+i,2)
  --   softcut.buffer_read_mono(samp, 0, 1+(32*(dest-1)),2, math.random(1,2), 2)
  -- end
  -- for i = 0,total_length do
    -- local snip_dur = 
  -- local random_snip = math.random()
  --   if len/48000 < 32 then
  -- return (samp)
end



return clip_actions