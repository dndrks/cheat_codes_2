local filters = {}

local speeds =
  {
    ["rapid"] = 0.001,
    ["1 bar"] = (clock.get_beat_sec()*4) / 100,
    ["2 bar"] = ((clock.get_beat_sec()*4) / 100) * 2,
    ["3 bar"] = ((clock.get_beat_sec()*4) / 100) * 3,
    ["4 bar"] = ((clock.get_beat_sec()*4) / 100) * 4,
  }

local filter_types = {"dry","lp","hp","bp"}

function filters.init()

  filter = {}
  for i = 1,3 do
    filter[i] = {}
    filter[i].dry = {["current_value"] = 1, ["target_value"] = 0, ["clock"] = nil, ["active"] = true}
    filter[i].lp = {["current_value"] = 0, ["target_value"] = 1, ["clock"] = nil, ["active"] = false}
    filter[i].hp = {["current_value"] = 0, ["target_value"] = 1, ["clock"] = nil, ["active"] = false}
    filter[i].bp = {["current_value"] = 0, ["target_value"] = 1, ["clock"] = nil, ["active"] = false}
    filter[i].freq = {
      ["current_value"] = 1000,
      ["min"] = 1000,
      ["max"] = 7000,
      ["attack"] = 10,
      ["release"] = 10,
      ["clock"] = nil,
      ["attack_clock"] = nil,
      ["release_clock"] = nil,
      ["clock_stage"] = "done",
      ["latch"] = false, -- toggles the freq_press
      ["sample_hold"] = false -- toggles...
    }
  end

  params:add_group("filters",78)
  for i = 1,3 do
    local banks = {"(a)", "(b)", "(c)"}
    local filter_controlspec = controlspec.FREQ
    filter_controlspec.default = 1000
    params:add_separator(banks[i].." general")
    params:add_control("filter cutoff "..i, "filter "..banks[i].." cutoff", filter_controlspec)
    params:set_action("filter cutoff "..i, function(x)
      softcut.post_filter_fc(i+1,x)
      bank[i][bank[i].id].fc = x
      filter[i].freq.current_value = x
    end)
    params:add_control("filter q "..i, "filter "..banks[i].." q", controlspec.new(0.0005, 2.0, 'exp', 0, 2, ""))
    params:set_action("filter q "..i, function(x)
      softcut.post_filter_rq(i+1,x)
      for j = 1,16 do
        bank[i][j].q = x
      end
    end)
    params:add_binary("filter dynamic freq "..i, "filter "..banks[i].." dynamic freq","momentary",0)
    params:set_action("filter dynamic freq "..i,
      function(x)
        local state;
        if x == 1 then
          state = true
        else
          state = false
        end
        filters.freq_press(i,state)
      end
    )
    local filter_min_controlspec = controlspec.FREQ
    filter_min_controlspec.default = 1000
    params:add_control("filter dynamic freq min "..i, "filter "..banks[i].." dyn min", filter_min_controlspec)
    params:set_action("filter dynamic freq min "..i,
      function(x)
        filter[i].freq.min = x
      end
    )
    local filter_max_controlspec = controlspec.FREQ
    filter_max_controlspec.default = 7000
    params:add_control("filter dynamic freq max "..i, "filter "..banks[i].." dyn max", filter_max_controlspec)
    params:set_action("filter dynamic freq max "..i,
      function(x)
        filter[i].freq.max = x
      end
    )
    params:add_option("filter dynamic freq attack "..i, "filter "..banks[i].." dyn rise",lfo_rates.names,15)
    params:set_action("filter dynamic freq attack "..i, function(x)
      filter[i].freq.attack = (clock.get_beat_sec()*4) * lfo_rates.values[x]
    end)
    params:add_option("filter dynamic freq release "..i, "filter "..banks[i].." dyn fall",lfo_rates.names,15)
    params:set_action("filter dynamic freq release "..i, function(x)
      filter[i].freq.release = (clock.get_beat_sec()*4) * lfo_rates.values[x]
    end)
    local macro_min = controlspec.FREQ
    macro_min.default = 20
    params:add_control("filter macro min "..i, "filter "..banks[i].." macro min", macro_min)
    local macro_max = controlspec.FREQ
    macro_max.default = 20000
    params:add_control("filter macro max "..i, "filter "..banks[i].." macro max", macro_max)
    params:hide("filter macro min "..i)
    params:hide("filter macro max "..i)
    for j = 1,#filter_types do
      params:add_separator(banks[i].." "..filter_types[j])
      params:add_binary("filter "..filter_types[j].." fast flip "..i, "filter "..banks[i].." "..filter_types[j].." fast flip","trigger")
      params:set_action("filter "..filter_types[j].." fast flip "..i, function(x)
        filters.filt_flip(i,filter_types[j],"rapid",filter[i][filter_types[j]].active and 0 or 1)
      end)
      params:add_control("filter "..filter_types[j].." max level "..i, "filter "..banks[i].." "..filter_types[j].." max level", controlspec.new(0, 1, 'lin', 0, 1, ""))
      params:set_action("filter "..filter_types[j].." max level "..i, function(x)
        if filter[i][filter_types[j]].active then
          softcut["post_filter_"..filter_types[j]](i+1,x)
          filter[i][filter_types[j]].current_value = x
        else
          filter[i][filter_types[j]].target_value = x
        end
      end)
      params:add_option("filter "..filter_types[j].." fade "..i, "filter "..banks[i].." "..filter_types[j].." fade time", {"1 bar","2 bar","3 bar","4 bar"})
    end
    -- params:set("filter dry active "..i,1)
  end

  -- test_count = 1
end

function filters.filt_level_adjust(i,type,target_val)
  if filter[i][type].clock ~= nil then
    clock.cancel(filter[i][type].clock)
    filter[i][type].clock = nil
  end
  if filter[i][type].current_value > target_val then
    filter[i][type].clock = clock.run(
      function()
        while filter[i][type].current_value > target_val do
          clock.sleep(0.001)
          if filter[i][type].current_value <= 1 and filter[i][type].current_value >= target_val then
            filter[i][type].current_value = util.round(filter[i][type].current_value - 0.01,0.01)
            if filter[i][type].active then
              softcut["post_filter_"..type](i+1,filter[i][type].current_value)
            end
            if speed_dial_active and speed_dial.menu == 5 then
              grid_dirty = true
            end
          end
        end
      end
    )
  elseif filter[i][type].current_value < target_val then
    filter[i][type].clock = clock.run(
      function()
        while filter[i][type].current_value < target_val do
          clock.sleep(0.001)
          if filter[i][type].current_value >= 0 and filter[i][type].current_value <= target_val then
            filter[i][type].current_value = util.round(filter[i][type].current_value + 0.01,0.01)
            if filter[i][type].active then
              softcut["post_filter_"..type](i+1,filter[i][type].current_value)
            end
            if speed_dial_active and speed_dial.menu == 5 then
              grid_dirty = true
            end
          end
        end
      end
    )
  end
end

function filters.filt_flip(i,type,speed,state)
  local delta = (speed == "rapid" or speed == nil) and 0.015 or 0.01
  if speed == nil then
    speed = speeds["rapid"]
  else
    speed = speeds[speed]
  end
  local target_val = params:get("filter "..type.." max level "..i)
  if filter[i][type].clock ~= nil then
    filter[i][type].current_value = state == 1 and 0 or target_val
    filter[i][type].target_value = state == 1 and target_val or 0
    -- params:set("filter "..type.." active "..i,state)
    filter[i][type].active = state == 1 and true or false
  end
  if state == 0 then
    -- params:set("filter "..type.." active "..i,0)
    filter[i][type].active = false
    filter[i][type].clock = clock.run(
      function()
        while filter[i][type].current_value > filter[i][type].target_value do
          clock.sleep(speed)
          if filter[i][type].current_value <= 1 and filter[i][type].current_value >= filter[i][type].target_value then
            filter[i][type].current_value = util.round(filter[i][type].current_value - delta,delta)
            softcut["post_filter_"..type](i+1,filter[i][type].current_value)
            if speed_dial_active and speed_dial.menu == 5 then
              grid_dirty = true
            end
          end
        end
      end
    )
  elseif state == 1 then
    -- params:set("filter "..type.." active "..i,1)
    filter[i][type].active = true
    filter[i][type].clock = clock.run(
      function()
        while filter[i][type].current_value < filter[i][type].target_value do
          clock.sleep(speed)
          if filter[i][type].current_value >= 0 and filter[i][type].current_value <= filter[i][type].target_value then
            filter[i][type].current_value = util.round(filter[i][type].current_value + delta,delta)
            softcut["post_filter_"..type](i+1,filter[i][type].current_value)
            if speed_dial_active and speed_dial.menu == 5 then
              grid_dirty = true
            end
          end
        end
      end
    )
  end
end

local function compare_freq_values(i,min,max,style)
  if style == "attack" then
    if max > min then
      return util.round(filter[i].freq.current_value) < util.round(max)
    else
      return util.round(filter[i].freq.current_value) > util.round(max)
    end
    -- if filter[i].freq.max > filter[i].freq.min then
    --   return util.round(filter[i].freq.current_value) < util.round(filter[i].freq.max)
    -- else
    --   return util.round(filter[i].freq.current_value) > util.round(filter[i].freq.max)
    -- end
  elseif style == "release" then
    if filter[i].freq.max > filter[i].freq.min then
      return util.round(filter[i].freq.current_value) > util.round(filter[i].freq.min)
    else
      return util.round(filter[i].freq.current_value) < util.round(filter[i].freq.min)
    end
  end
end

local function iterate_freq_values(i,min,max,delta,style)
  if style == "attack" then
    if filter[i].freq.max > filter[i].freq.min then
      if filter[i].freq.current_value <= filter[i].freq.max then
        filter[i].freq.current_value = util.round(filter[i].freq.current_value + (delta/100),1)
      end
    else
      if filter[i].freq.current_value >= filter[i].freq.max then
        filter[i].freq.current_value = util.round(filter[i].freq.current_value - (delta/100),1)
      end
    end
  elseif style == "release" then
    if filter[i].freq.max > filter[i].freq.min then
      if filter[i].freq.current_value >= filter[i].freq.min then
        filter[i].freq.current_value = util.round(filter[i].freq.current_value - (delta/100),1)
      end
    else
      if filter[i].freq.current_value <= filter[i].freq.min then
        filter[i].freq.current_value = util.round(filter[i].freq.current_value + (delta/100),1)
      end
    end
  end
  if filter[i].freq.max > filter[i].freq.min then
    local new_val = util.linexp(min, max, min, max, filter[i].freq.current_value)
    params:set("filter cutoff "..i,new_val,true)
    softcut.post_filter_fc(i+1,new_val)
    -- print("max>min",filter[i].freq.current_value, new_val)
  else
    local new_val = util.linexp(max, min, max, min, filter[i].freq.current_value)
    params:set("filter cutoff "..i,new_val,true)
    softcut.post_filter_fc(i+1,new_val) -- won't work for min > max tho...
    -- print("min > max",max,filter[i].freq.current_value,new_val)
  end
  if speed_dial_active and speed_dial.menu == 5 then
    grid_dirty = true
  end
  if menu == 5 then
    screen_dirty = true
  end
end

function filters.freq_press(i,state)
  local direction, delta;
  if state then -- pressed
    if filter[i].freq.release_clock~= nil then
      clock.cancel(filter[i].freq.release_clock)
    end
    if not filter[i].freq.sample_hold then -- only if that toggle isn't on should any of these events happen...
      local min_val,max_val;
      if (filter[i].freq.min > filter[i].freq.max) and (filter[i].freq.current_value > filter[i].freq.max) then
        min_val = filter[i].freq.current_value
      elseif (filter[i].freq.min < filter[i].freq.max) and (filter[i].freq.current_value < filter[i].freq.min) then
        min_val = filter[i].freq.current_value
      elseif (filter[i].freq.min < filter[i].freq.max) and (filter[i].freq.current_value > filter[i].freq.min) then
        min_val = filter[i].freq.current_value
      else
        min_val = filter[i].freq.min
      end
      if (filter[i].freq.min > filter[i].freq.max) and (filter[i].freq.current_value < filter[i].freq.max) then
        max_val = filter[i].freq.current_value
      elseif (filter[i].freq.max > filter[i].freq.min) and (filter[i].freq.current_value > filter[i].freq.max) then
        max_val = filter[i].freq.current_value
      else
        max_val = filter[i].freq.max
      end
      filter[i].freq.attack_clock = clock.run(
        function()
          delta = math.abs(filter[i].freq.max - min_val)
          local comparator;
          -- while compare_freq_values(i,filter[i].freq.min,filter[i].freq.max,"attack") do
          while compare_freq_values(i,min_val,max_val,"attack") do
            clock.sleep(filter[i].freq.attack/100)
            iterate_freq_values(i,min_val,max_val,delta,"attack")
          end
        end
      )
    end
  else -- released
    if filter[i].freq.attack_clock~= nil then
      clock.cancel(filter[i].freq.attack_clock)
    end
    if not filter[i].freq.sample_hold then -- cuz this only matters during release...it's a 'hold'
      local max_val;
      if (filter[i].freq.max > filter[i].freq.min) and (filter[i].freq.current_value > filter[i].freq.max) then
        max_val = filter[i].freq.current_value
      elseif (filter[i].freq.max < filter[i].freq.min) and (filter[i].freq.current_value < filter[i].freq.max) then
        max_val = filter[i].freq.current_value
      else
        max_val = filter[i].freq.max
      end
      filter[i].freq.release_clock = clock.run(
        function()
          -- delta = math.abs(filter[i].freq.max - filter[i].freq.min)
          delta = math.abs(max_val - filter[i].freq.min)
          while compare_freq_values(i,filter[i].freq.min,filter[i].freq.max,"release") do
            clock.sleep(filter[i].freq.release/100)
            iterate_freq_values(i,filter[i].freq.min,max_val,delta,"release")
          end
        end
      )
    end
  end
end

function filters.toggle_hold_freq(i,state)
  filter[i].freq.sample_hold = state
  if filter[i].freq.attack_clock~= nil then
    clock.cancel(filter[i].freq.attack_clock)
  end
  if filter[i].freq.release_clock~= nil then
    clock.cancel(filter[i].freq.release_clock)
  end
end

function filters.latch_freq_press(i,state)
  filter[i].freq.latch = state
end

function filters.restore_collection(collection)
  for i = 1,3 do
    filter[i] = tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/filters/filter"..i..".data")
    softcut.post_filter_fc(i+1,filter[i].freq.current_value)
    for j = 1,#filter_types do
      if filter[i][filter_types[j]].active then
        softcut["post_filter_"..filter_types[j]](i+1,filter[i][filter_types[j]].current_value)
      else
        softcut["post_filter_"..filter_types[j]](i+1,0)
      end
    end
  end
end

return filters

-- function try_something()
--   if testing_clock ~= nil then
--     clock.cancel(testing_clock)
--     testing_clock = nil
--   end
--   testing_clock = clock.run(
--     function()
--       while test_count > 0 do
--         clock.sleep(0.001)
--         print(test_count)
--         if test_count >= 0 then
--           test_count = util.round(test_count - 0.01,0.01)
--         elseif test_count < 0 then
--           clock.cancel(testing_clock)
--           testing_clock = nil
--           test_count = 1
--         end
--       end
--     end
--   )
-- end