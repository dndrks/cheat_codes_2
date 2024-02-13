local number_of_patterns = 3

-- pattern recording

local pat = {}

local function initialize_parameters(i)
	params:add_separator("grid pattern " .. i)
	pat.record_duration[i] = 0
	params:add_number(
		"record_duration_pattern_" .. i,
		"record duration",
		0,
		128,
		pat.record_duration[i],
		function(param)
			return (param:get() == 0 and "free" or param:get() .. " beats")
		end
	)
	params:set_action("record_duration_pattern_" .. i, function(x)
		pat.record_duration[i] = x
	end)

	pat.hold_rec[i] = true
	params:add_option(
		"hold_rec_pattern_" .. i,
		"hold rec for first event?",
		{ "no", "yes" },
		pat.hold_rec[i] and 2 or 1
	)
	params:set_action("hold_rec_pattern_" .. i, function(x)
		pat.hold_rec[i] = x == 2
	end)

	pat.rec_sync_value[i] = nil
	params:add_option("rec_sync_value_pattern_" .. i, "sync record start", { "free", "next beat", "next bar" }, 1)
	params:set_action("rec_sync_value_pattern_" .. i, function(x)
		if x == 1 then
			pat.rec_sync_value[i] = nil
		elseif x == 2 then
			pat.rec_sync_value[i] = 1
		elseif x == 3 then
			pat.rec_sync_value[i] = 4
		end
	end)

	params:add_option("play_sync_value_pattern_" .. i, "sync play start", { "free", "next beat", "next bar" }, 1)
	params:set_action("play_sync_value_pattern_" .. i, function(x)
		if x == 1 then
			pat.play_sync_value[i] = nil
		elseif x == 2 then
			pat.play_sync_value[i] = 1
		elseif x == 3 then
			pat.play_sync_value[i] = 4
		end
	end)

	params:add_option("play_after_rec_" .. i, "play after recording?", { "no", "yes" }, 1)
	params:set_action("play_after_rec_" .. i, function(x)
		pat.play_after_rec[i] = x == 2
		grid_dirty = true
	end)

	params:add_option("loop_pattern_" .. i, "loop playback?", { "no", "yes" }, 1)
	params:set_action("loop_pattern_" .. i, function(x)
		g_pattern[i]:set_loop(x - 1)
		grid_dirty = true
	end)

	params:add_trigger("erase_rec_pattern_" .. i, "erase recording?")
	params:set_action("erase_rec_pattern_" .. i, function(x)
		g_pattern[i]:clear()
		grid_dirty = true
	end)

	params:add_trigger("double_rec_pattern_" .. i, "double recording")
	params:set_action("double_rec_pattern_" .. i, function(x)
		g_pattern[i]:double()
	end)

	params:add_option("pattern_" .. i .. "_mod_restore", "capture zilchmos", { "no", "yes" }, 1)

	pat.overdubbing[i] = false
	pat.playback_queued[i] = false
end

function pat.init()
  pat.toggles = {overdub = false, loop = false, duplicate = false, copy = false, link = false}
  pat.playback_queued = {}
  pat.overdubbing = {}
  pat.play_sync_value = {}
  pat.record_duration = {}
  pat.hold_rec = {}
  pat.queued_recording = {}
  pat.play_after_rec = {}
  pat.check_for_play_after_rec = {}
  pat.rec_sync_value = {}
  g_pattern = {}

  pat.pattern_clipboard = { event = {}, endpoint = {}, count = 0 }
  pat.pattern_clipboard = 0
  pat.pattern_links = {}
  pat.pattern_link_clocks = {}

  params:add_group('grid patterns', (10 * number_of_patterns) + 11)

  params:add_separator('grid_pattern_global_control', 'global')

  params:add_number("record_duration_global", "record duration", 0, 128, 0, function(param)
    return (param:get() == 0 and "free" or param:get() .. " beats")
  end)

  params:add_option("hold_rec_global", "hold rec for first event?", { "no", "yes" }, 2)

  params:add_option("rec_sync_value_global", "sync record start", { "free", "next beat", "next bar" }, 1)

  params:add_option("play_sync_value_global", "sync play start", { "free", "next beat", "next bar" }, 1)

  params:add_option("play_after_rec_global", "play after recording?", { "no", "yes" }, 1)

  params:add_option("loop_global", "loop playback?", { "no", "yes" }, 1)

  params:add_binary("erase_rec_global", "erase recording?", "toggle")

  params:add_binary("double_rec_global", "double recording", "toggle")

  params:add_option("global_snapshot_mod_restore", "capture snapshot mods", { "no", "yes" }, 1)

  params:add_binary("send_global_snapshot", "send to all (K3)", "trigger")
  params:set_action("send_global_snapshot", function(x)
    local prm = params:get("record_duration_global")
    for i = 1, number_of_patterns do
      params:set("record_duration_pattern_" .. i, prm)
    end
    local prm = params:get("hold_rec_global")
    for i = 1, number_of_patterns do
      params:set("hold_rec_pattern_" .. i, prm)
    end
    local prm = params:get("rec_sync_value_global")
    for i = 1, number_of_patterns do
      params:set("rec_sync_value_pattern_" .. i, prm)
    end
    local prm = params:get("play_sync_value_global")
    for i = 1, number_of_patterns do
      params:set("play_sync_value_pattern_" .. i, prm)
    end
    local prm = params:get("play_after_rec_global")
    for i = 1, number_of_patterns do
      params:set("play_after_rec_" .. i, prm)
    end
    local prm = params:get("loop_global")
    for i = 1, number_of_patterns do
      params:set("loop_pattern_" .. i, prm)
    end
    local prm = params:get("erase_rec_global")
    for i = 1, number_of_patterns do
      params:set("erase_rec_pattern_" .. i, prm)
    end
    local prm = params:get("double_rec_global")
    for i = 1, number_of_patterns do
      params:set("double_rec_pattern_" .. i, prm)
    end
    local prm = params:get("global_snapshot_mod_restore")
    for i = 1, number_of_patterns do
      params:set("pattern_" .. i .. "_mod_restore", prm)
    end
  end)

  for i = 1, number_of_patterns do
    g_pattern[i] = _r.new()
    g_pattern[i].random_pitch_range = 5
    g_pattern[i].process = pattern_execute
    g_pattern[i].start_point = 1
    
    g_pattern[i].start_callback = function() -- user-script callback
      print("playback started", i, clock.get_beats())
			g_pattern[i].current_step = 0
      pat.playback_queued[i] = false
      if pat.queued_recording[i] then
        pat.check_for_play_after_rec[i] = true
      end
      pat.queued_recording[i] = false
      grid_dirty = true
    end

    -- g_pattern[i].step_callback = function()
    --   print(g_pattern[i].step)
    -- end

    g_pattern[i].end_of_rec_callback = function() -- user-script callback
      print("recording finished", i, clock.get_beats())
      grid_dirty = true
			g_pattern[i].meaningful_steps = {}
      local step_count = 0
      local sorted = tab.sort(g_pattern[i].event)
      for steps = 1,#sorted do
        local id = sorted[steps]
        for k,v in pairs(g_pattern[i].event[id]) do
          if v.event == "pad down" then
            g_pattern[i].meaningful_steps[#g_pattern[i].meaningful_steps+1] = id
          end
        end
      end
    end

    g_pattern[i].end_of_loop_callback = function() -- user-script callback
      print("loop ended", i, clock.get_beats())
      grid_dirty = true
    end

    g_pattern[i].end_callback = function() -- user-script callback
      print('end end callback')
      if g_pattern[i].loop == 0 then
        pat.overdubbing[i] = false
      end
      if pat.check_for_play_after_rec[i] == true then
        if pat.play_after_rec[i] == true then
          if pat.play_sync_value[i] ~= nil then
            pat.playback_queued[i] = true
            g_pattern[i]:start(pat.play_sync_value[i])
          else
            g_pattern[i]:start()
          end
        end
        pat.check_for_play_after_rec[i] = false
      end
      grid_dirty = true
      -- clear stuff?
    end

    initialize_parameters(i) -- init params
  end
  grid_dirty = true
end

local function enable_toggle(target)
  local turn_off = false
  if pat.toggles[target] then
    turn_off = true
  end
  for k,v in pairs(pat.toggles) do
    pat.toggles[k] = false
  end
  if not turn_off then
    pat.toggles[target] = true
  end
  if pat.toggles.copy == false then
    pat.pattern_clipboard.event = {}
    pat.pattern_clipboard.time = {}
    pat.pattern_clipboard.count = 0
  end
end

function pat.pattern_key(id)
  print("pattern stuff",id)

	local _p = g_pattern[id]
  if not grid_alt then
    if _p.rec == 0 and _p.queued_rec == nil and _p.count == 0 then
      _p:set_rec(pat.hold_rec[id] and 2 or 1, pat.record_duration[id] > 0 and pat.record_duration[id] or nil, pat.rec_sync_value[id])
      pat.queued_recording[id] = true
    elseif _p.count > 0 and _p.play == 0 then
      if pat.play_sync_value[id] ~= nil then
        pat.playback_queued[id] = true
        _p:start(pat.play_sync_value[id])
      else
        _p:start()
      end
    elseif _p.play == 1 then
			if _p.rec == 1 then
				_p:set_rec(0)
			end
      _p:stop()
    else
      _p:set_rec(0)
    end
  else
    _p:clear()
  end
  
  grid_dirty = true
  
end

function pat.toggle_key(x)
  if x == 13 then
    enable_toggle('overdub')
  elseif x == 14 then
    enable_toggle('loop')
  elseif x == 15 then
    enable_toggle('duplicate')
  elseif x == 16 then
    enable_toggle('copy')
  -- elseif x == 16 then
  --   enable_toggle('link')
  --   pat.pattern_clipboard = 0
  end
  grid_dirty = true
end

function pattern_execute(data)

  if data.event == "pad down" then
    g_pattern[data.i].current_step = g_pattern[data.i].current_step + 1
		grid_actions.pad_down(data.i, data.id, true, true)
    print(g_pattern[data.i].current_step)
  elseif data.event == "pad up" then
		grid_actions.pad_up(data.i, data.id, true)
  end

  if data.event == "flip_to_fkprm" then
    _fkprm.flip_to_fkprm(data.id)
  elseif data.event == "flip_from_fkprm" then
    _fkprm.flip_from_fkprm(data.id)
  elseif data.event == "snapshot_restore" then
    local mod_idx = 0
    if params:string("pattern_" .. data.id .. "_mod_restore") == "yes" then
      mod_idx = data.mod_index
    end
    _snapshots.route_funnel(data.x, data.y, mod_idx)
    snapshots[data.x].focus = data.y
  elseif data.event == "snapshot_crossfade_value" then
    snapshots[data.id].crossfade_position = data.pos
    params:set('snapshot_crossfade_value_'..data.id, data.val)
  elseif data.event == "sc.change_selected_rate" then
    _sc.change_selected_rate(data.id, data.rate)
  elseif data.event == "sc.glitch" then
    _sc.glitch(data.z == 1)
  elseif data.event == "sc.change_reverse" then
    _sc.change_reverse(data.id)
  end
  grid_dirty = true
end

return pat