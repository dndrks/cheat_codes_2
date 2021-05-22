local dough = {}

function dough.init()
  dough_stretch = {}
  for i = 1,3 do
    dough_stretch[i] = {}
    dough_stretch[i].enabled = false
    dough_stretch[i].modes = {"off","neo","nyc","chi","pgh"} -- neo: pitch constant, nyc: time stretching, chi: granular
    dough_stretch[i].mode = "off"
    dough_stretch[i].inc = 12
    dough_stretch[i].time = 12
    dough_stretch[i].clock = nil
    dough_stretch[i].fade_time = 6
    dough_stretch[i].pos = poll_position_new[i+1]
    -- if bank~= nil then
    --   dough_stretch[i].pos = bank[i][bank[i].id].start_point
    -- else
    --   dough_stretch[i].pos = nil
    -- end
  end
end

function dough.init_params()
  dough.init()
  params:add_separator("doughstretch")
  local bank_names = {"[a]","[b]","[c]"}
  for i = 1,3 do
    params:add_option("doughstretch_mode_"..i,"doughstretch mode "..bank_names[i],{"off","neo","nyc","chi","pgh"},1)
    params:set_action("doughstretch_mode_"..i,function(x)
      if x == 1 then
        if dough_stretch[i].clock ~= nil then
          clock.cancel(dough_stretch[i].clock)
          dough_stretch[i].enabled = false
          dough_stretch[i].clock = nil
          softcut.fade_time(i+1,variable_fade_time)
        end
      elseif x > 1 then
        if dough_stretch[i].clock == nil then
          dough_stretch[i].clock = clock.run(dough.stretch,i)
          dough_stretch[i].enabled = true
        end
      end
      if x == 2 then
        dough_stretch[i].pos = poll_position_new[i+1]
        local p_t =
        {
          {"doughstretch_step_",12},
          {"doughstretch_duration_",12},
          {"doughstretch_fade_",1}
        }
        for j = 1,#p_t do
          params:set(p_t[j][1]..i,p_t[j][2])
          local id = params.lookup[p_t[j][1]..i]
          if all_loaded then
            params.params[id]:bang()
          end
        end
      elseif x == 3 then
        dough_stretch[i].pos = poll_position_new[i+1]
        local p_t =
        {
          {"doughstretch_step_",100},
          -- {"doughstretch_duration_",12},
          {"doughstretch_fade_",6}
        }
        for j = 1,#p_t do
          params:set(p_t[j][1]..i,p_t[j][2])
          local id = params.lookup[p_t[j][1]..i]
          if all_loaded then
            params.params[id]:bang()
          end
        end
        dough.scale_sample_to_main(i)
      elseif x == 4 then
        dough_stretch[i].pos = poll_position_new[i+1]
        local p_t =
        {
          {"doughstretch_step_",100},
          {"doughstretch_duration_",8},
          {"doughstretch_fade_",30}
        }
        for j = 1,#p_t do
          params:set(p_t[j][1]..i,p_t[j][2])
          local id = params.lookup[p_t[j][1]..i]
          if all_loaded then
            params.params[id]:bang()
          end
        end
      elseif x == 5 then
        dough_stretch[i].pos = poll_position_new[i+1]
        local p_t =
        {
          {"doughstretch_step_",math.random(3,60)},
          {"doughstretch_duration_",math.random(6,105)},
          {"doughstretch_fade_",math.random(40,300)}
        }
        for j = 1,#p_t do
          params:set(p_t[j][1]..i,p_t[j][2])
          local id = params.lookup[p_t[j][1]..i]
          if all_loaded then
            params.params[id]:bang()
          end
        end
      end
    end)
    params:add_number("doughstretch_step_"..i,"    step time",1,300,12)
    params:set_action("doughstretch_step_"..i, function(x)
      dough_stretch[i].inc = x
    end)
    params:add_number("doughstretch_duration_"..i,"    duration",1,300,12)
    params:set_action("doughstretch_duration_"..i, function(x)
      dough_stretch[i].time = x
    end)
    params:add_number("doughstretch_fade_"..i,"    fade",0,300,1)
    params:set_action("doughstretch_fade_"..i, function(x)
      dough_stretch[i].fade_time = x
      softcut.fade_time(i+1,x/100)
    end)
  end
end

function dough.stretch(i)
  while true do
    -- clock.sleep((1/dough_stretch[i].time)*clock.get_beat_sec())
    clock.sync(1/dough_stretch[i].time)
    if dough_stretch[i].enabled then
      softcut.position(i+1, dough_stretch[i].pos)
      if dough_stretch[i].pos + ((1/dough_stretch[i].inc)*clock.get_beat_sec()) > (bank[i][bank[i].id].end_point - (dough_stretch[i].fade_time/100))then
        if bank[i][bank[i].id].loop then
          dough_stretch[i].pos = bank[i][bank[i].id].start_point - ((1/dough_stretch[i].inc)*clock.get_beat_sec())
        else
          dough_stretch[i].enabled = false
          -- dough.toggle(i) -- not ideal...
        end
      end
      if params:get("doughstretch_mode_"..i) == 5 then
        local next_pos = math.random(0,1)
        next_pos = next_pos == 0 and -1 or 1
        dough_stretch[i].pos = util.clamp(
          dough_stretch[i].pos + ((next_pos/dough_stretch[i].inc)*clock.get_beat_sec()),
          bank[i][bank[i].id].start_point,
          bank[i][bank[i].id].end_point)
        dough.pgh_set("doughstretch_fade_",i)
        dough.pgh_set("doughstretch_step_",i)
        dough.pgh_set("doughstretch_duration_",i)
      else
        dough_stretch[i].pos = dough_stretch[i].pos + ((1/dough_stretch[i].inc)*clock.get_beat_sec())
      end
    end
  end
end

function dough.pgh_set(param,i)
  local bounds =
  {
    ["doughstretch_fade_"] = {["min"]=1,["max"]=200},
    ["doughstretch_step_"] = {["min"]=3,["max"]=60},
    ["doughstretch_duration_"] = {["min"]=3,["max"]=105}
  }
  local current = params:get(param..i)
  local next_move = math.random(0,1)
  next_move = next_move == 0 and -1 or 1
  local next_step = util.wrap(current+next_move,bounds[param].min,bounds[param].max)
  params:set(param..i,next_step)
end

function dough.toggle(i) -- this shouldn't call/cancel clock, it should gate it...
  if dough_stretch[i].clock ~= nil then
    clock.cancel(dough_stretch[i].clock)
    dough_stretch[i].enabled = false
    dough_stretch[i].clock = nil
    softcut.fade_time(i+1,variable_fade_time)
  else
    softcut.fade_time(i+1,dough_stretch[i].fade_time/100)
    dough_stretch[i].pos = bank[i][bank[i].id].start_point
    dough_stretch[i].clock = clock.run(dough.stretch,i)
    dough_stretch[i].enabled = true
  end
end

function dough.change(i,param,d)
  dough_stretch[i][param] = util.clamp(dough_stretch[i][param]+d,1,100)
  if param == "fade_time" then
    softcut.fade_time(i+1,util.clamp(dough_stretch[i][param]+d/100,0.01,32))
  end
end

function dough.derive_bpm(source)
  local dur = 0
  local pattern_id;
  dur = source.original_length
  if dur > 0 then
    local quarter = dur/4
    local derived_bpm = 60/quarter
    while derived_bpm < 70 do
      derived_bpm = derived_bpm * 2
      if derived_bpm > 160 then break end
    end
    while derived_bpm > 160 do
      derived_bpm = derived_bpm/2
      if derived_bpm <= 70 then break end
    end
    return util.round(derived_bpm,0.01)
  end
end

function dough.scale_sample_to_main(i)
  -- print("stretching to time...")
  if bank[i][bank[i].id].mode == 2 and bank[i][bank[i].id].clip == i then
    local sample_tempo = dough.derive_bpm(clip[i])
    local proj_tempo = clock.get_tempo()
    local scale = util.round(sample_tempo/proj_tempo * 100,0.01)
    dough_stretch[i].time = 100
    dough_stretch[i].inc = scale
    dough_stretch[i].fade_time = params:get("doughstretch_fade_"..i)
    softcut.fade_time(i+1,dough_stretch[i].fade_time/100)
  end
end

function dough.cheat(i)
  local pad = bank[i][bank[i].id]
  if not dough_stretch[i].enabled then
    softcut.fade_time(i+1,variable_fade_time)
    if pad.rate > 0 then
      -- softcut.position(b+1,pad.start_point+0.05)
      softcut.position(i+1,pad.start_point+variable_fade_time)
    elseif pad.rate < 0 then
        -- softcut.position(b+1,pad.end_point-variable_fade_time-0.05)
      softcut.position(i+1,pad.end_point-variable_fade_time-0.01)
    end
  else
    if pad.rate > 0 then
      dough_stretch[i].pos = util.wrap(pad.start_point+dough_stretch[i].fade_time,pad.start_point,pad.end_point)
    elseif pad.rate < 0 then
      dough_stretch[i].pos = util.wrap(pad.end_point-dough_stretch[i].fade_time-0.01,pad.start_point,pad.end_point)
    end
  end
end

return dough