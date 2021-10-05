local arc_actions = {}
aa = arc_actions

aa.sc = {}

--------------------------------

function aa.init(n,d)

  local this_bank;
  local which_enc;

  if params:string("arc_size") == 4 then
    which_enc = n
    this_bank = bank[arc_control[n]]
  elseif params:string("arc_size") == 2 then
    if n == 2 then
      which_enc = 4
    else
      which_enc = bank_64
    end
    this_bank = bank[bank_64]
  end

  if which_enc ~= 4 then
   if this_bank.focus_hold == false then
      which_pad = this_bank.id
    else
      which_pad = this_bank.focus_pad
    end
    local this_pad = this_bank[which_pad]
    local p_action = aa.actions[arc_param[which_enc]][1]
    local sc_action = aa.actions[arc_param[which_enc]][2]
    if not this_bank.alt_lock and not grid_alt then
      if arc_param[which_enc] ~= 4 then
        p_action(this_pad,d)
      else
        aa.map(p_action, this_bank, arc_param[which_enc] == 4 and d/1000 or d, which_enc)
      end
    elseif this_bank.alt_lock or grid_alt then
      if arc_param[which_enc] ~= 4 then
        aa.map(p_action,this_bank,d)
      else
        p_action(this_pad, arc_param[which_enc] == 4 and d/1000 or d, which_enc)
      end
    end
    if this_bank.focus_hold == false or this_bank.focus_pad == this_bank.id then
      sc_action(which_enc, this_pad)
    end
    if n < 4 then
      aa.record(which_enc)
    end
  else
    aa.change_param_focus(d)
  end
  if menu ~= 1 then screen_dirty = true end
end

function aa.new_pattern_watch(enc)
  local a_p; -- this will index the arc encoder recorders
  if arc_param[enc] == 1 or arc_param[enc] == 2 or arc_param[enc] == 3 then
    a_p = 1
  else
    a_p = arc_param[enc] - 2
  end
  arc_p[enc] = {}
  arc_p[enc][a_p] = {}
  arc_p[enc][a_p].i1 = enc
  arc_p[enc][a_p].i2 = a_p
  arc_p[enc][a_p].param = arc_param[enc]
  local id = arc_control[enc] -- could also just be enc, but this allows arc/bank mapping to be redefined
  if bank[id].focus_hold == false then
    arc_p[enc][a_p].pad = bank[id].id
  else
    arc_p[enc][a_p].pad = bank[id].focus_pad
  end
  arc_p[enc][a_p].start_point = bank[id][arc_p[enc][a_p].pad].start_point - (8*(bank[id][arc_p[enc][a_p].pad].clip-1))
  arc_p[enc][a_p].end_point = bank[id][arc_p[enc][a_p].pad].end_point - (8*(bank[id][arc_p[enc][a_p].pad].clip-1))
  arc_p[enc][a_p].prev_tilt = slew_counter[id].prev_tilt
  arc_p[enc][a_p].tilt = bank[id][bank[id].id].tilt
  --new new!
  arc_p[enc][a_p].pan = bank[id][bank[id].id].pan
  arc_p[enc][a_p].level = bank[id][bank[id].id].level
  arc_p[enc][a_p].global_level = bank[id].global_level
  --/new new!
  arc_pat[enc][a_p]:watch(arc_p[enc][a_p])
end

function aa.map(fn, bank, delta, enc)
  for i = 1,16 do
    fn(bank[i],delta,enc)
  end
end

function aa.change_param_focus(d)
  local start = util.round(arc_meta_focus)
  arc_meta_focus = util.clamp(arc_meta_focus+d/33,1,6)
  if start ~= util.round(arc_meta_focus) then
    for i = 1,3 do
      arc_param[i] = util.round(arc_meta_focus)
    end
    grid_dirty = true
  end
end

function aa.record(enc)
  aa.new_pattern_watch(enc)
end

function aa.move_window(target, delta)
  local force = math.abs(delta) >= 5 and true or false
  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local current_difference = (target.end_point - target.start_point)
  local s_p = target.mode == 1 and live[target.clip].min or clip[target.clip].min
  local reasonable_max = target.mode == 1 and live[target.clip].max or clip[target.clip].max

  if params:get("loop_enc_resolution_"..target.bank_id) > 2 then
    arc_accum[target.bank_id] = arc_accum[target.bank_id] + delta

    if math.abs(arc_accum[target.bank_id]) >= 25 then
      local resolution = loop_enc_resolution[target.bank_id]
      local rs = {1,2,4}
      local rate_mod = rs[params:get("live_buff_rate")]
      arc_accum[target.bank_id] = 0
      encoder_actions.move_play_window(target,(1/(resolution * rate_mod)) * (delta > 0 and 1 or -1))
    end
  else
    local adjusted_delta = force and (duration > 15 and (delta/25) or (delta/100)) or (delta/300)
    if target.start_point + current_difference <= reasonable_max then
      target.start_point = util.clamp(target.start_point + adjusted_delta, s_p, reasonable_max)
      target.end_point = target.start_point + current_difference
    else
      target.end_point = reasonable_max
      target.start_point = target.end_point - current_difference
    end
    if target.end_point > reasonable_max then
      target.end_point = reasonable_max
      target.start_point = target.end_point - current_difference
    end
    if menu == 2 and page.loops_view[target.bank_id] == 4 and key1_hold then
      update_waveform(2,target.start_point,target.end_point,128)
    end
  end
end

arc_accum = {0,0,0}

function aa.move_start(target, delta)

  local force = math.abs(delta) >= 5 and true or false

  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local s_p = target.mode == 1 and live[target.clip].min or clip[target.clip].min

  if params:get("loop_enc_resolution_"..target.bank_id) > 2 then
    arc_accum[target.bank_id] = arc_accum[target.bank_id] + delta

    if math.abs(arc_accum[target.bank_id]) >= 25 then
      local resolution = loop_enc_resolution[target.bank_id]
      local rs = {1,2,4}
      local rate_mod = rs[params:get("live_buff_rate")]
      arc_accum[target.bank_id] = 0
      encoder_actions.move_start(target,(1/(resolution * rate_mod)) * (delta > 0 and 1 or -1))
    end
  else
    local adjusted_delta = force and (delta/100) or (delta/300)
    if adjusted_delta >= 0 and target.start_point < (target.end_point - 0.055) then
      target.start_point = util.clamp(target.start_point+adjusted_delta,s_p,s_p+duration)
    elseif adjusted_delta < 0 then
      target.start_point = util.clamp(target.start_point+adjusted_delta,s_p,s_p+duration)
    end
  end
  if menu == 2 and page.loops_view[target.bank_id] == 4 and key1_hold then
    update_waveform(2,target.start_point,target.end_point,128)
  end
end

function aa.move_end(target, delta)

  local force = math.abs(delta) >= 5 and true or false

  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local s_p = target.mode == 1 and live[target.clip].min or clip[target.clip].min

  if params:get("loop_enc_resolution_"..target.bank_id) > 2 then
    arc_accum[target.bank_id] = arc_accum[target.bank_id] + delta

    if math.abs(arc_accum[target.bank_id]) >= 25 then
      local resolution = loop_enc_resolution[target.bank_id]
      local rs = {1,2,4}
      local rate_mod = rs[params:get("live_buff_rate")]
      arc_accum[target.bank_id] = 0
      encoder_actions.move_end(target,(1/(resolution * rate_mod)) * (delta > 0 and 1 or -1))
    end
  else
    local adjusted_delta = force and (delta/100) or (delta/300)
    if adjusted_delta <= 0 and target.start_point < (target.end_point - 0.055) then
      target.end_point = util.clamp(target.end_point+adjusted_delta,s_p,s_p+duration)
    elseif adjusted_delta > 0 then
      target.end_point = util.clamp(target.end_point+adjusted_delta,s_p,s_p+duration)
    end
    if menu == 2 and page.loops_view[target.bank_id] == 4 and key1_hold then
      update_waveform(2,target.start_point,target.end_point,128)
    end
  end

end

function aa.change_tilt(target, delta, enc)
  local a_c = enc
  if slew_counter[a_c] ~= nil then
    slew_counter[a_c].prev_tilt = target.tilt
  end
  target.tilt = util.explin(1,3,-1,1,target.tilt+2)
  target.tilt = util.clamp(target.tilt+(delta),-1,1)
  target.tilt = util.linexp(-1,1,1,3,target.tilt)-2
  if delta < 0 then
    if util.round(target.tilt*100) < 0 and util.round(target.tilt*100) > -9 then
      target.tilt = -0.10
    elseif util.round(target.tilt*100) > 0 and util.round(target.tilt*100) < 3 then
      target.tilt = 0.0
    end
  end
end

function aa.change_pan(target, delta)
  target.pan = util.clamp(target.pan + delta/300,-1,1)
end

function aa.change_level(target, delta)
  if bank[target.bank_id].alt_lock or grid_alt then
    if target.pad_id == 1 then
      bank[target.bank_id].global_level = util.clamp(bank[target.bank_id].global_level + delta/1000,0,2)
    end
  else
    target.level = util.clamp(target.level + delta/1000,0,2)
  end
end

function aa.sc.move_window(enc, target)
  softcut.loop_start(enc+1,target.start_point)
  softcut.loop_end(enc+1,target.end_point)
end

function aa.sc.move_start(enc, target)
  softcut.loop_start(enc+1,target.start_point)
end

function aa.sc.move_end(enc, target)
  softcut.loop_end(enc+1,target.end_point)
end

function aa.sc.change_tilt(enc, target)
  slew_filter(enc,slew_counter[enc].prev_tilt,target.tilt,target.q,target.q,15)
end

function aa.sc.change_pan(enc, target)
  softcut.pan(enc+1,target.pan)
end

function aa.sc.change_level(enc, target)
  if bank[enc][bank[enc].id].envelope_mode == 2 or not bank[enc][bank[enc].id].enveloped then
    softcut.level(enc+1,target.level*bank[enc].global_level)
  end
end

aa.actions =
  { [1] = { aa.move_window    , aa.sc.move_window }
  , [2] = { aa.move_start     , aa.sc.move_start }
  , [3] = { aa.move_end       , aa.sc.move_end }
  , [4] = { aa.change_tilt    , aa.sc.change_tilt }
  , [5] = { aa.change_level   , aa.sc.change_level  }
  , [6] = { aa.change_pan     , aa.sc.change_pan  }
  }

return arc_actions