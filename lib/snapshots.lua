local snap = {}

local restorable_params = {"rate","offset","fifth","start_point","end_point","loop","mode","clip","level","pan","tilt"}

snap.init = function()
  for i = 1,3 do
    bank[i].snapshot = {{},{},{},{},{},{},{},{}}
    bank[i].snapshot_fnl_active = false
    bank[i].snapshot_saver_active = false
    bank[i].snapshot_saver_clock = nil
    for j = 1,8 do
      bank[i].snapshot[j] = {["pad"]= {},["saved"] = false}
      for k = 1,16 do
        bank[i].snapshot[j].pad[k] = {}
        bank[i].snapshot[j].pad[k].rate_restore = true
        bank[i].snapshot[j].pad[k].offset_restore = true
        bank[i].snapshot[j].pad[k].fifth_restore = true
        bank[i].snapshot[j].pad[k].start_point_restore = true
        bank[i].snapshot[j].pad[k].end_point_restore = true
        bank[i].snapshot[j].pad[k].loop_restore = true
        bank[i].snapshot[j].pad[k].mode_restore = true
        bank[i].snapshot[j].pad[k].clip_restore = true
        bank[i].snapshot[j].pad[k].level_restore = true
        bank[i].snapshot[j].pad[k].pan_restore = true
        bank[i].snapshot[j].pad[k].tilt_restore = true
      end
    end
  end
end

snap.capture = function(b,slot)
  local shot = bank[b].snapshot[slot]
  local src = bank[b]
  for i = 1,16 do
    shot.pad[i].rate = src[i].rate
    shot.pad[i].offset = src[i].offset
    shot.pad[i].fifth = src[i].fifth
    shot.pad[i].start_point = src[i].start_point
    shot.pad[i].end_point = src[i].end_point
    shot.pad[i].loop = src[i].loop
    shot.pad[i].mode = src[i].mode
    shot.pad[i].clip = src[i].clip
    shot.pad[i].level = src[i].level
    shot.pad[i].pan = src[i].pan
    shot.pad[i].tilt = params:get("filter tilt "..b)
  end
  shot.saved = true
end

snap.clear = function(b,slot)
  local shot = bank[b].snapshot[slot]
  for k = 1,16 do
    shot.pad[k] = {}
    shot.pad[k].rate_restore = true
    shot.pad[k].offset_restore = true
    shot.pad[k].fifth_restore = true
    shot.pad[k].start_point_restore = true
    shot.pad[k].end_point_restore = true
    shot.pad[k].loop_restore = true
    shot.pad[k].mode_restore = true
    shot.pad[k].clip_restore = true
    shot.pad[k].level_restore = true
    shot.pad[k].pan_restore = true
    shot.pad[k].tilt_restore = true
  end
  shot.saved = false
end

snap.save_to_slot = function(b,slot)
  clock.sleep(0.25)
  bank[b].snapshot_saver_active = true
  if bank[b].snapshot_saver_active then
    if not grid_alt then
      print("saved snap",b,slot)
      snap.capture(b,slot)
    else
      snap.clear(b,slot)
    end
    grid_dirty = true
  end
  bank[b].snapshot_saver_active = false
end

snap.check_restore = function(b,slot,prm)
  
end

snap.restore = function(b,slot,sec)
  print("restoring snap",b,slot)
  local shot = bank[b].snapshot[slot]
  local src = bank[b]
  local original_srcs = {}
  for i = 1,16 do
    original_srcs[i] = {}
    for j = 1,#restorable_params do
      -- print(src[i][restorable_params[j]])
      original_srcs[i][restorable_params[j]] = src[i][restorable_params[j]]
    end
    -- original_srcs[i].rate = src[i].rate
    -- original_srcs[i].fifth = src[i].fifth
    -- original_srcs[i].start_point = src[i].start_point
    -- original_srcs[i].end_point = src[i].end_point
    -- original_srcs[i].loop = src[i].loop
    -- original_srcs[i].mode = src[i].mode
    -- original_srcs[i].clip = src[i].clip
    -- original_srcs[i].level = src[i].level
    -- original_srcs[i].pan = src[i].pan
    -- original_srcs[i].tilt = src[i].tilt
  end
  if not bank[b].snapshot.fnl_active and (sec ~= nil and sec > 0.1) then
    bank[b].snapshot.fnl_active = true
    bank[b].snapshot.fnl = snap.fnl(
      function(r_val)
        bank[b].snapshot.current_value = r_val
        for i = 1,16 do
          src[i].start_point = util.linlin(0,1,original_srcs[i].start_point,shot.pad[i].start_point,r_val)
          src[i].end_point = util.linlin(0,1,original_srcs[i].end_point,shot.pad[i].end_point,r_val)
          params:set("filter tilt "..b,util.linlin(0,1,original_srcs[i].tilt,shot.pad[i].tilt,r_val))
          if i == src.id then
            softcut.loop_start(b+1,src[i].start_point)
            softcut.loop_end(b+1,src[i].end_point)
          end
        end
        if bank[b].snapshot.current_value ~= nil and util.round(bank[b].snapshot.current_value,0.001) == 1 then
          snap.snapshot_funnel_done_action(b,slot)
        end
      end,
      0,
      {{1,sec}}
    )
  elseif not bank[b].snapshot.fnl_active and (sec == nil or sec == 0) then
    for i = 1,16 do
      src[i].start_point = shot.pad[i].start_point
      src[i].end_point = shot.pad[i].end_point
      if i == src.id then
        softcut.loop_start(b+1,src[i].start_point)
        softcut.loop_end(b+1,src[i].end_point)
      end
    end
    -- bank[b].snapshot.fnl_active = false
    snap.snapshot_funnel_done_action(b,slot)
  else
    print("already running!!!") -- this ends up restoring from current in duration... 
    clock.cancel(bank[b].snapshot.fnl)
    bank[b].snapshot.fnl_active = false
    _snap.restore(b,slot,sec)
  end
    -- for i = 1,16 do
    --   src[i].rate = shot.pad[i].rate
    --   src[i].fifth = shot.pad[i].fifth
    --   src[i].start_point = shot.pad[i].start_point
    --   src[i].end_point = shot.pad[i].end_point
    --   src[i].loop = shot.pad[i].loop
    --   src[i].mode = shot.pad[i].mode
    --   src[i].clip = shot.pad[i].clip
    --   src[i].level = shot.pad[i].level
    --   src[i].pan = shot.pad[i].pan
    -- end
end

snap.snapshot_funnel_done_action = function(b,slot,args)
  print("snapshot funnel done")
  local shot = bank[b].snapshot[slot]
  local src = bank[b]
  bank[b].snapshot.fnl_active = false
  for i = 1,16 do
    src[i].rate = shot.pad[i].rate
    src[i].offset = shot.pad[i].offset
    if i == src.id then
      softcut.rate(b+1,src[i].rate*src[i].offset)
    end
  end
end

-- we do need to keep the clips inside of the limits of the clip...

snap.crossfade = function(b,scene_a,scene_b,val)
  local min_fade = bank[b].snapshot[scene_a].pad
  local max_fade = bank[b].snapshot[scene_b].pad
  local dest = bank[b]
  for i = 1,16 do
    -- new_val[i].rate = util.linlin(0,127,min_fade[i].rate,max_fade[i].rate,val)
    -- new_val[i].fifth = util.linlin(0,127,min_fade[i].fifth,max_fade[i].fifth,val)
    dest[i].start_point = util.linlin(0,127,min_fade[i].start_point,max_fade[i].start_point,val)
    dest[i].end_point = util.linlin(0,127,min_fade[i].end_point,max_fade[i].end_point,val)
    -- new_val[i].loop = src[i].loop
    -- new_val[i].mode = src[i].mode
    -- new_val[i].clip = src[i].clip
    -- new_val[i].level = src[i].level
    dest[i].pan = util.linlin(0,127,min_fade[i].pan,max_fade[i].pan,val)
    dest[i].tilt = util.linlin(0,127,min_fade[i].tilt,max_fade[i].tilt,val)
    if i == dest.id then
      softcut.loop_start(b+1,dest[i].start_point)
      softcut.loop_end(b+1,dest[i].end_point)
      params:set("filter tilt "..b,dest[i].tilt)
    end
  end
end

snap.fnl_crossfade = function(b,scene_a,scene_b,sec)
  local filter_current = params:get("filter tilt "..b)
  bank[b].snapshot.crossfade_fnl = snap.fnl(
    function(r_val)
      snap.crossfade(b,scene_a,scene_b,r_val)
    end,
    0,
    {{127,sec}}
  )
  -- TODO should still work this out:
  -- snap.fnl(
  --   function(r_val)
  --     params:set("filter tilt "..b,r_val)
  --   end,
  --   filter_current,
  --   {{bank[b].snapshot[scene_b].pad[bank[b].id].tilt,0.3}}
  -- )
end

snap.fnl = function(fn, origin, dest_ms, fps)
  return clock.run(function()
    fps = fps or 15 -- default
    local spf = 1 / fps -- seconds per frame
    fn(origin)
    for _,v in ipairs(dest_ms) do
      local count = math.floor(v[2] * fps) -- number of iterations
      local stepsize = (v[1]-origin) / count -- how much to increment by each iteration
      while count > 0 do
        clock.sleep(spf)
        origin = origin + stepsize -- move toward destination
        count = count - 1 -- count iteration
        fn(origin)
      end
    end
  end)
end

return snap