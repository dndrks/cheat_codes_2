local sd_filter = {}

sd_filter.keys_held = {}
sd_filter.pad_focus = 0
sd_filter.dough_mod = {}
for i = 1,3 do
  sd_filter.dough_mod[i] = {["sub"] = false, ["add"] = false}
  sd_filter.dough_mod[i].clock = nil
end
sd_filter.inv_mod = false

local filter_types = {"dry","lp","hp","bp"}

function sd_filter.draw_grid()
  local edition = params:get("LED_style")
  local _c = speed_dial.translate
  local _filters_ = page.filters
  for i = 1,3 do
    g:led(_c(i+5,1)[1],_c(i+5,1)[2],page.filters.bank == i and 15 or 8)
  end
  if _filters_.bank < 4 then
    sd_filter.draw_grid_banks()
    sd_filter.draw_filters()
  end
end

function sd_filter.draw_filters()
  local edition = params:get("LED_style")
  local _c = speed_dial.translate
  local _filters_ = page.filters
  local b = _filters_.bank
  -- local pad = _filters_.meta_pad[_filters_.bank]
  local led_s = {"filter_engaged","filter_disengaged"}
  for i = 1,4 do
    local leds = filter[b][filter_types[i]].active and led_s[1] or led_s[2]
    g:led(_c(1,i+2)[1],_c(1,i+2)[2],led_maps[leds][edition])
    local level_to_led = util.round(util.linlin(0,1,1,6,filter[b][filter_types[i]].current_value))
    local off_bright = filter[b][filter_types[i]].active and "filter_level_on" or "filter_level_on_disengaged"
    for j = 1,6 do
      g:led(_c(j+2,i+2)[1], _c(j+2,i+2)[2],led_maps["filter_level_off"][edition])
    end
    for j = 1,level_to_led do
      g:led(_c(j+2,i+2)[1], _c(j+2,i+2)[2],led_maps[off_bright][edition])
    end
  end
  g:led(_c(1,15)[1],_c(1,15)[2],sd_filter.inv_mod and 15 or 4)
end


function sd_filter.draw_grid_banks()
  local edition = params:get("LED_style")
  local _c = speed_dial.translate
  local _filters_ = page.filters
  local pad = _filters_.meta_pad[_filters_.bank]
  speed_dial.perf_draw(_filters_.bank)
end

function sd_filter.parse_press(x,y,z)
  local _c = speed_dial.coordinate
  local _filters_ = page.filters
  local nx = _c(x,y)[1]
  local ny = _c(x,y)[2]
  if ny == 1 and nx >= 6 and z == 1 then
    _filters_.bank = nx-5
  end
  speed_dial.perf_press(_filters_.bank,x,y,z)
  if _filters_.bank < 4 then
    sd_filter.parse_press_banks(x,y,z)
    sd_filter.parse_press_filters(x,y,z)
  end
end

function sd_filter.parse_press_filters(x,y,z)
  local _c = speed_dial.coordinate
  local _filters_ = page.filters
  local b = _filters_.bank
  local nx = _c(x,y)[1]
  local ny = _c(x,y)[2]
  if nx == 1 and ny == 15 then
    sd_filter.inv_mod = z == 1 and true or false
  end
  if (nx >= 3 and nx <= 8) and (ny >= 3 and ny <= 6) and z == 1 then

  end
  if nx == 1 and (ny >= 3 and ny <= 6) and z == 1 then
    local pre_flip = filter[b][filter_types[ny-2]].active
    filters.filt_flip(b,filter_types[ny-2],"rapid",filter[b][filter_types[ny-2]].active and 0 or 1)
    if not sd_filter.inv_mod and grid_alt then
      for i = 1,3 do
        if i ~= b then
          filters.filt_flip(i,filter_types[ny-2],"rapid",pre_flip and 0 or 1)
        end
      end
    elseif sd_filter.inv_mod and not grid_alt then
      for i = 1,3 do
        if i ~= b then
          filters.filt_flip(i,filter_types[ny-2],"rapid",filter[i][filter_types[ny-2]].active and 0 or 1)
        end
      end
    end
  elseif nx == 2 and (ny >= 3 and ny <= 6) and z == 1 then
    local pre_flip = filter[b][filter_types[ny-2]].active
    local s = params:string("filter "..b.." "..filter_types[ny-2].." fade")
    filters.filt_flip(b,filter_types[ny-2],s,filter[b][filter_types[ny-2]].active and 0 or 1)
    if not sd_filter.inv_mod and grid_alt then
      for i = 1,3 do
        if i ~= b then
          local s = params:string("filter "..i.." "..filter_types[ny-2].." fade")
          filters.filt_flip(i,filter_types[ny-2],s,pre_flip and 0 or 1)
        end
      end
    elseif sd_filter.inv_mod and not grid_alt then
      for i = 1,3 do
        if i ~= b then
          local s = params:string("filter "..i.." "..filter_types[ny-2].." fade")
          filters.filt_flip(i,filter_types[ny-2],s,filter[i][filter_types[ny-2]].active and 0 or 1)
        end
      end
    end
  end
end

function sd_filter.parse_press_banks(x,y,z)
  local _c = speed_dial.coordinate
  local _filters_ = page.filters
  local nx = _c(x,y)[1]
  local ny = _c(x,y)[2]
  local pad = _filters_.meta_pad[_filters_.bank]
  if nx == 1 and (ny >=3 and ny <= 6) and z == 1 then

  end
end

return sd_filter