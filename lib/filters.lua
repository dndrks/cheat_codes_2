local filters = {}

local speeds =
  {
    ["rapid"] = 0.001,
    ["1 bar"] = (clock.get_beat_sec()*4) / 100,
    ["2 bar"] = ((clock.get_beat_sec()*4) / 100) * 2,
    ["3 bar"] = ((clock.get_beat_sec()*4) / 100) * 3,
    ["4 bar"] = ((clock.get_beat_sec()*4) / 100) * 4,
  }

function filters.init()

  filter = {}
  for i = 1,3 do
    filter[i] = {}
    filter[i].dry = {["current_value"] = 1, ["target_value"] = 0, ["clock"] = nil, ["active"] = true}
    filter[i].lp = {["current_value"] = 0, ["target_value"] = 1, ["clock"] = nil, ["active"] = false}
    filter[i].hp = {["current_value"] = 0, ["target_value"] = 1, ["clock"] = nil, ["active"] = false}
    filter[i].bp = {["current_value"] = 0, ["target_value"] = 1, ["clock"] = nil, ["active"] = false}
  end

  local filter_types = {"dry","lp","hp","bp"}

  params:add_group("filters",57)
  for i = 1,3 do
    local banks = {"(a)", "(b)", "(c)"}
    local filter_controlspec = controlspec.FREQ
    filter_controlspec.default = 20000
    params:add_separator(banks[i].." general")
    params:add_control("filter "..i.." cutoff", "filter "..banks[i].." cutoff", filter_controlspec)
    params:set_action("filter "..i.." cutoff", function(x) softcut.post_filter_fc(i+1,x) bank[i][bank[i].id].fc = x end)
    params:add_control("filter "..i.." q", "filter "..banks[i].." q", controlspec.new(0.0005, 2.0, 'exp', 0, 2, ""))
    params:set_action("filter "..i.." q", function(x)
      softcut.post_filter_rq(i+1,x)
      for j = 1,16 do
        bank[i][j].q = x
      end
    end)
    for j = 1,#filter_types do
      params:add_separator(banks[i].." "..filter_types[j])
      params:add_binary("filter "..i.." "..filter_types[j].." active", "filter "..banks[i].." "..filter_types[j].." active","toggle",0)
      params:set_action("filter "..i.." "..filter_types[j].." active", function(x)
        if x == 1 then
          filter[i][filter_types[j]].active = true
        else
          filter[i][filter_types[j]].active = false
        end
      end)
      params:add_control("filter "..i.." "..filter_types[j].." max level", "filter "..banks[i].." "..filter_types[j].." max level", controlspec.new(0, 1, 'lin', 0, 1, ""))
      params:set_action("filter "..i.." "..filter_types[j].. " max level", function(x)
        if filter[i][filter_types[j]].active then
          softcut["post_filter_"..filter_types[j]](i+1,x)
          filter[i][filter_types[j]].current_value = x
        else
          filter[i][filter_types[j]].target_value = x
        end
      end)
      params:add_option("filter "..i.." "..filter_types[j].." fade", "filter "..banks[i].." "..filter_types[j].." fade time", {"1 bar","2 bar","3 bar","4 bar"})
    end
    params:set("filter "..i.." dry active",1)
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
  if speed == nil then
    speed = speeds["rapid"]
  else
    speed = speeds[speed]
  end
  local target_val = params:get("filter "..i.." "..type.." max level")
  if filter[i][type].clock ~= nil then
    filter[i][type].current_value = state == 1 and 0 or target_val
    filter[i][type].target_value = state == 1 and target_val or 0
    params:set("filter "..i.." "..type.." active",state)
  end
  if state == 0 then
    params:set("filter "..i.." "..type.." active",0)
    filter[i][type].clock = clock.run(
      function()
        while filter[i][type].current_value > filter[i][type].target_value do
          clock.sleep(speed)
          if filter[i][type].current_value <= 1 and filter[i][type].current_value >= filter[i][type].target_value then
            filter[i][type].current_value = util.round(filter[i][type].current_value - 0.01,0.01)
            softcut["post_filter_"..type](i+1,filter[i][type].current_value)
            if speed_dial_active and speed_dial.menu == 5 then
              grid_dirty = true
            end
          end
        end
      end
    )
  elseif state == 1 then
    params:set("filter "..i.." "..type.." active",1)
    filter[i][type].clock = clock.run(
      function()
        while filter[i][type].current_value < filter[i][type].target_value do
          clock.sleep(speed)
          if filter[i][type].current_value >= 0 and filter[i][type].current_value <= filter[i][type].target_value then
            filter[i][type].current_value = util.round(filter[i][type].current_value + 0.01,0.01)
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