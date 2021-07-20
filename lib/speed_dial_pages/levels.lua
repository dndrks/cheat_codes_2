local sd_level = {}

sd_level.keys_held = {}
sd_level.pad_focus = 0
sd_level.dough_mod = {}
for i = 1,3 do
  sd_level.dough_mod[i] = {["sub"] = false, ["add"] = false}
  sd_level.dough_mod[i].clock = nil
end

function sd_level.draw_grid()
  local edition = params:get("LED_style")
  local _c = speed_dial.translate
  local _levels_ = page.levels
  local pad = _levels_.meta_pad[_levels_.bank]
  for i = 1,3 do
    g:led(_c(i+5,1)[1],_c(i+5,1)[2],_levels_.bank == i and 15 or 8)
  end
  for i = 1,4 do
    for j = 9,12 do
      g:led(_c(i,j)[1],_c(i,j)[2],led_maps["square_off"][edition])
    end
  end
  local pad_x = _arps.index_to_grid_pos(pad,4)[1]
  local pad_y = _arps.index_to_grid_pos(pad,4)[2]+8
  g:led(_c(pad_x,pad_y)[1], _c(pad_x,pad_y)[2], 15)
  for i = 11,3,-1 do
    for j = 7,8 do
      g:led(_c(j,i)[1], _c(j,i)[2], 4)
    end
  end
  local level_to_led = util.round(util.linlin(0,1,1,7,bank[_levels_.bank][pad].level))
  for i = 1,level_to_led do
    g:led(_c(7,12-i)[1], _c(7,12-i)[2], 8)
  end
  if bank[_levels_.bank][pad].level > 1.2 then
    level_to_led = util.round(bank[_levels_.bank][pad].level)
    for i = 1,level_to_led do
      g:led(_c(7,5-i)[1], _c(7,5-i)[2], 8)
    end
  end
  level_to_led = util.round(util.linlin(0,1,1,7,bank[_levels_.bank].global_level))
  for i = 1,level_to_led do
    g:led(_c(8,12-i)[1], _c(8,12-i)[2], 8)
  end
  if bank[_levels_.bank].global_level > 1.2 then
    level_to_led = util.round(bank[_levels_.bank].global_level)
    for i = 1,level_to_led do
      g:led(_c(8,5-i)[1], _c(8,5-i)[2], 8)
    end
  end
end

function sd_level.parse_press(x,y,z)
  local _c = speed_dial.coordinate
  local _levels_ = page.levels
  local nx = _c(x,y)[1]
  local ny = _c(x,y)[2]
  if ny == 1 and nx >= 3 and z == 1 then
    _levels_.bank = nx-2
  end
  if ny >= 9 and ny <= 12 and nx >= 1 and nx <= 4 then
    if z == 1 then
      _levels_.meta_pad[_levels_.bank] = nx+((ny-9)*4)
      if grid_alt then
        selected[_levels_.bank].x = (ny-8)+(5*(_levels_.bank-1))
        selected[_levels_.bank].y = (9-nx)
        selected[_levels_.bank].id = _levels_.meta_pad[_levels_.bank]
        cheat(_levels_.bank,_levels_.meta_pad[_levels_.bank])
      end
    end
  end
  if _levels_.bank < 4 then
    sd_level.parse_press_banks(x,y,z)
  elseif _levels_.bank == 4 then
    sd_level.parse_press_Live(x,y,z)
  end
end

function sd_level.parse_press_banks(x,y,z)
  local _c = speed_dial.coordinate
  local _levels_ = page.levels
  local nx = _c(x,y)[1]
  local ny = _c(x,y)[2]
  if ny == 1 and nx >= 3 and z == 1 then
    _levels_.bank = nx-2
  end
  local pad = _levels_.meta_pad[_levels_.bank]
  local rates = { [2] = {0.125,0.25,0.5,1,2,4}, [3] = {-0.125,-0.25,-0.5,-1,-2,-4} }
  if (ny == 2 or ny == 3) and (nx >= 2 and nx <= 7) and z == 1 then
    local target_rate = rates[ny][nx-1]
    bank[_levels_.bank][pad].rate = target_rate
    if grid_alt then
      for i = 1,16 do
        if i ~= pad then
          bank[_levels_.bank][i].rate = target_rate
        end
      end
    end
    if bank[_levels_.bank].id == pad then
      rightangleslice.sc.rate(bank[_levels_.bank][pad],_levels_.bank)
    end
  end
  if (nx == 1 or nx == 2 or nx == 3) and ny == 13 and z == 1 then
    if not grid_alt then
      _ca.SOS_toggle(nx)
    else
      _ca.SOS_erase(nx)
    end
  end
  if (nx >= 4 and nx <= 8) and ny == 5 and z == 1 then
    params:set("doughstretch_mode_".._levels_.bank,nx-3)
  end
  if (nx == 7 or nx == 8) and (ny >= 6 and ny <= 8) and params:get("doughstretch_mode_".._levels_.bank) ~= 1 then
    sd_level.dough_mod[ny-5][nx == 7 and "sub" or "add"] = z == 1 and true or false
    local targets = {"doughstretch_step_","doughstretch_duration_","doughstretch_fade_"}
    if z == 1 then
      params:delta(targets[ny-5].._levels_.bank,nx == 7 and -1*(grid_alt and 5 or 1) or 1*(grid_alt and 5 or 1))
      if sd_level.dough_mod[ny-5].clock == nil then
        sd_level.dough_mod[ny-5].clock = clock.run(function()
          while true do
            clock.sleep(0.15)
            params:delta(targets[ny-5].._levels_.bank,nx == 7 and -1*(grid_alt and 5 or 1) or 1*(grid_alt and 5 or 1))
          end
        end)
      end
    elseif z == 0 then
      if sd_level.dough_mod[ny-5].clock ~= nil then
        clock.cancel(sd_level.dough_mod[ny-5].clock)
        sd_level.dough_mod[ny-5].clock = nil
      end
    end
  end
end

function sd_level.parse_press_Live(x,y,z)
  local _c = speed_dial.coordinate
  local _levels_ = page.levels
  local nx = _c(x,y)[1]
  local ny = _c(x,y)[2]
  if ny == 1 and nx >= 3 and z == 1 then
    _levels_.bank = nx-2
  end
end

return sd_level