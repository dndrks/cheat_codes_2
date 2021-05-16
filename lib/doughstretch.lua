local dough = {}

function dough.init()
  dough_stretch = {}
  for i = 1,3 do
    dough_stretch[i] = {}
    dough_stretch[i].enabled = false
    dough_stretch[i].modes = {"off","neo","nyc","chi"} -- neo: pitch constant, nyc: time stretching, chi: granular
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
  for i = 1,3 do
    params:add_option("doughstretch_mode_"..i,"doughstretch mode "..i,{"off","neo","nyc","chi"},1)
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
        softcut.fade_time(i+1,dough_stretch[i].fade_time/100)
        dough_stretch[i].pos = poll_position_new[i+1]
        params:set("doughstretch_step_"..i,12)
        params:set("doughstretch_duration_"..i,12)
      elseif x == 3 then
        softcut.fade_time(i+1,dough_stretch[i].fade_time/100)
        dough_stretch[i].pos = poll_position_new[i+1]
        params:set("doughstretch_step_"..i,100)
        dough.scale_sample_to_main(i)
      end
    end)
    params:add_number("doughstretch_step_"..i,"doughstep step "..i,1,300,12)
    params:set_action("doughstretch_step_"..i, function(x)
      dough_stretch[i].inc = x
    end)
    params:add_number("doughstretch_duration_"..i,"doughstep duration "..i,1,300,12)
    params:set_action("doughstretch_duration_"..i, function(x)
      dough_stretch[i].time = x
    end)
    params:add_number("doughstretch_fade_"..i,"doughstep fade "..i,0,300,1)
    params:set_action("doughstretch_fade_"..i, function(x)
      dough_stretch[i].fade_time = x
      softcut.fadetime(i+1,x/100)
    end)
  end
end

function dough.stretch(i)
  while true do
    -- clock.sleep((1/dough_stretch[i].time)*clock.get_beat_sec())
    clock.sync(1/dough_stretch[i].time)
    softcut.position(i+1, dough_stretch[i].pos)
    if dough_stretch[i].pos + ((1/dough_stretch[i].inc)*clock.get_beat_sec()) > (bank[i][bank[i].id].end_point - (dough_stretch[i].fade_time/100))then
      if bank[i][bank[i].id].loop then
        dough_stretch[i].pos = bank[i][bank[i].id].start_point - ((1/dough_stretch[i].inc)*clock.get_beat_sec())
      else
        dough.toggle(i) -- not ideal...
      end
    end
    dough_stretch[i].pos = dough_stretch[i].pos + ((1/dough_stretch[i].inc)*clock.get_beat_sec())
  end
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
    dough_stretch[i].fade_time = 6
    softcut.fade_time(i+1,dough_stretch[i].fade_time/100)
  end
end

return dough