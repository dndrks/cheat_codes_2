local arc_actions = {}
aa = arc_actions

aa.sc = {}

--------------------------------

function aa.init(n,d)

  local this_bank = bank[arc_control[n]]
  if n ~= 4 then
    if this_bank.focus_hold == false then
      which_pad = this_bank.id
    else
      which_pad = this_bank.focus_pad
    end
    local this_pad = this_bank[which_pad]
    local p_action = aa.actions[arc_param[n]][1]
    local sc_action = aa.actions[arc_param[n]][2]
    if not this_bank.alt_lock and grid.alt == 0 then
      if arc_param[n] ~= 4 then
        p_action(this_pad,d)
      else
        aa.map(p_action, this_bank, d/1000, n)
      end
    elseif this_bank.alt_lock or grid.alt == 1 then
      if arc_param[n] ~= 4 then
        aa.map(p_action,this_bank,d)
      else
        p_action(this_pad,d/1000, n)
      end
    end
    if this_bank.focus_hold == false or this_bank.focus_pad == this_bank.id then
      sc_action(n, this_pad)
    end
    if n < 4 then
      aa.record(n)
    end
  else
    -- local side = (arc.alt == nil or arc.alt == 0) and "L" or "R"
    -- aa.delay_rate(d,side)
    -- aa.record_delay(side)
    aa.change_param_focus(d)
  end
  redraw()
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

-- function aa.delay_rate(d,side)
--   local chan = side == "L" and 1 or 2
--   delay[chan].arc_rate_tracker = util.clamp(delay[chan].arc_rate_tracker + d/10,1,13)
--   delay[chan].arc_rate = math.floor(delay[chan].arc_rate_tracker)
--   params:set("delay "..side..": rate",math.floor(delay[chan].arc_rate_tracker))
-- end

function aa.record(enc)
  aa.new_pattern_watch(enc)
end

-- function aa.record_delay(side)
--   arc_p[side] = {}
--   arc_p[side].i = side
--   if grid.alt == 0 then
--     arc_p[side].delay_focus = "L"
--     arc_p[side].left_delay_value = params:get("delay L: rate")
--   else
--     arc_p[side].delay_focus = "R"
--     arc_p[side].right_delay_value = params:get("delay R: rate")
--   end
-- end

function aa.move_window(target, delta)
  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local current_difference = (target.end_point - target.start_point)
  local current_clip = duration*(target.clip-1)
  if target.start_point + current_difference <= (duration+1)+current_clip then
    target.start_point = util.clamp(target.start_point + delta/300, 1+current_clip, (duration+1)+current_clip)
    target.end_point = target.start_point + current_difference
  else
    target.end_point = ((duration+1)+current_clip)
    target.start_point = target.end_point - current_difference
  end
end

function aa.move_start(target, delta)
  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local current_clip = duration*(target.clip-1)
  target.start_point = util.clamp(target.start_point + delta/300, (1+current_clip), target.end_point-0.01)
end

function aa.move_end(target, delta)
  local duration = target.mode == 1 and 8 or clip[target.clip].sample_length
  local current_clip = duration*(target.clip-1)
  target.end_point = util.clamp(target.end_point + delta/300, target.start_point+0.01, ((duration+1)+current_clip))
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
  if not bank[target.bank_id].alt_lock and grid.alt == 0 then
    target.level = util.clamp(target.level + delta/1000,0,2)
  else
    if target.pad_id == 1 then
      bank[target.bank_id].global_level = util.clamp(bank[target.bank_id].global_level + delta/1000,0,2)
    end
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
  softcut.level(enc+1,target.level*bank[enc].global_level)
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