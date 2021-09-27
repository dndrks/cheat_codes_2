local snap = {}

snap.init = function()
  for i = 1,3 do
    bank[i].snapshot = {{},{},{},{},{},{},{},{}}
    bank[i].snapshot_fnl_active = false
    for j = 1,8 do
      bank[i].snapshot[j] = {["pad"]= {}}
      for k = 1,16 do
        bank[i].snapshot[j].pad[k] = {}
      end
    end
  end
end

snap.capture = function(b,slot)
  local shot = bank[b].snapshot[slot]
  local src = bank[b]
  for i = 1,16 do
    shot.pad[i].rate = src[i].rate
    shot.pad[i].fifth = src[i].fifth
    shot.pad[i].start_point = src[i].start_point
    shot.pad[i].end_point = src[i].end_point
    shot.pad[i].loop = src[i].loop
    shot.pad[i].mode = src[i].mode
    shot.pad[i].clip = src[i].clip
    shot.pad[i].level = src[i].level
    shot.pad[i].pan = src[i].pan
  end
end

snap.restore = function(b,slot,sec)
  local shot = bank[b].snapshot[slot]
  local src = bank[b]
  local original_srcs = {}
  for i = 1,16 do
    original_srcs[i] = {}
    original_srcs[i].rate = src[i].rate
    original_srcs[i].fifth = src[i].fifth
    original_srcs[i].start_point = src[i].start_point
    original_srcs[i].end_point = src[i].end_point
    original_srcs[i].loop = src[i].loop
    original_srcs[i].mode = src[i].mode
    original_srcs[i].clip = src[i].clip
    original_srcs[i].level = src[i].level
    original_srcs[i].pan = src[i].pan
  end
  if not bank[b].snapshot.fnl_active and (sec ~= nil and sec > 0.1) then
    bank[b].snapshot.fnl_active = true
    bank[b].snapshot.fnl = _live.fnl(
      function(r_val)
        bank[b].snapshot.current_value = r_val
        for i = 1,16 do
          src[i].start_point = util.linlin(0,1,original_srcs[i].start_point,shot.pad[i].start_point,r_val)
          src[i].end_point = util.linlin(0,1,original_srcs[i].end_point,shot.pad[i].end_point,r_val)
          if i == src.id then
            softcut.loop_start(b+1,src[i].start_point)
            softcut.loop_end(b+1,src[i].end_point)
          end
        end
        if bank[b].snapshot.current_value ~= nil and util.round(bank[b].snapshot.current_value,0.001) == 1 then
          print("snapshot funnel done")
          bank[b].snapshot.fnl_active = false
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
    print("snapshot funnel done")
    bank[b].snapshot.fnl_active = false
  else
    print("already running!!!")
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

return snap