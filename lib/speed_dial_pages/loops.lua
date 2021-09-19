local sd_loop = {}

sd_loop.keys_held = {}
sd_loop.pad_focus = 0
sd_loop.dough_mod = {}
for i = 1,3 do
  sd_loop.dough_mod[i] = {["sub"] = false, ["add"] = false}
  sd_loop.dough_mod[i].clock = nil
end

function sd_loop.draw_grid()
  local edition = params:get("LED_style")
  local _c = speed_dial.translate
  local _loops_ = page.loops
  for i = 1,6 do
    g:led(_c(i+2,1)[1],_c(i+2,1)[2],page.loops.sel == i and 15 or 8)
  end
  if _loops_.sel < 4 then
    sd_loop.draw_grid_banks()
  elseif _loops_.sel == 4 then
    sd_loop.draw_grid_Live()
  end
end

function sd_loop.draw_grid_banks()
  local edition = params:get("LED_style")
  local _c = speed_dial.translate
  local _loops_ = page.loops
  local pad = _loops_.meta_pad[_loops_.sel]
  local rates ={-0.125,-0.25,-0.5,-1,-2,-4,0,0.125,0.25,0.5,1,2,4}
  local current_rate = tab.key(rates,bank[_loops_.sel][pad].rate)
  if current_rate ~= nil then
    for i = 1,6 do
      g:led(_c(i+1,2)[1],_c(i+1,2)[2],current_rate == i+7 and 15 or 4)
    end
    for i = 1,6 do
      g:led(_c(i+1,3)[1],_c(i+1,3)[2],current_rate == i and 15 or 4)
    end
  end
  local pad_x = _arps.index_to_grid_pos(pad,4)[1]
  local pad_y = _arps.index_to_grid_pos(pad,4)[2]+8
  g:led(_c(pad_x,pad_y)[1], _c(pad_x,pad_y)[2], 15)
  
  local SOS_level = params:get("SOS_enabled_".._loops_.sel)
  local SOS_L_in = params:string("SOS_L_in_".._loops_.sel)
  local SOS_R_in = params:string("SOS_R_in_".._loops_.sel)
  g:led(_c(1,13)[1], _c(1,13)[2], SOS_level == 1 and 15 or 4)
  if SOS_level == 1 then
    g:led(_c(1,14)[1], _c(1,14)[2], SOS_level == 1 and (SOS_L_in == "on" and 15 or 4) or 0)
    g:led(_c(2,14)[1], _c(2,14)[2], SOS_level == 1 and (SOS_R_in == "on" and 15 or 4) or 0)
  end

  local dough_mode = params:get("doughstretch_mode_".._loops_.sel)
  for i = 1,5 do
    local dough_level = dough_mode == i and 15 or 4
    g:led(_c(i+3,5)[1], _c(i+3,5)[2], dough_level)
  end

  for i = 1,2 do
    for j = 1,3 do
      if dough_mode ~= 1 then
        local mod_level = sd_loop.dough_mod[j][i==1 and "sub" or "add"] and 15 or 4
        g:led(_c(i+6,j+5)[1], _c(i+6,j+5)[2], mod_level)
      end
    end
  end

  speed_dial.perf_draw(_loops_.sel)

end

function sd_loop.draw_grid_Live()
  local edition = params:get("LED_style")
  local _c = speed_dial.translate
  local _loops_ = page.loops
  local _rec = rec.focus
  for i = 1,3 do
    g:led(_c(i,3)[1], _c(i,3)[2], _rec == i and 15 or 4)
  end
  g:led(_c(8,3)[1], _c(8,3)[2], rec[_rec].state == 1 and 15 or 4)
end

function sd_loop.parse_press(x,y,z)
  local _c = speed_dial.coordinate
  local _loops_ = page.loops
  local nx = _c(x,y)[1]
  local ny = _c(x,y)[2]
  if ny == 1 and nx >= 3 and z == 1 then
    _loops_.sel = nx-2
  end
  -- if ny >= 9 and ny <= 12 and nx >= 1 and nx <= 4 then
  --   if z == 1 then
  --     _loops_.meta_pad[_loops_.sel] = nx+((ny-9)*4)
  --     if grid_alt then
  --       selected[_loops_.sel].x = (ny-8)+(5*(_loops_.sel-1))
  --       selected[_loops_.sel].y = (9-nx)
  --       selected[_loops_.sel].id = _loops_.meta_pad[_loops_.sel]
  --       cheat(_loops_.sel,_loops_.meta_pad[_loops_.sel])
  --     end
  --   end
  -- end
  if _loops_.sel < 4 then
    sd_loop.parse_press_banks(x,y,z)
    speed_dial.perf_press(page.loops.sel,x,y,z)
  elseif _loops_.sel == 4 then
    sd_loop.parse_press_Live(x,y,z)
  end
end

function sd_loop.parse_press_banks(x,y,z)
  local _c = speed_dial.coordinate
  local _loops_ = page.loops
  local nx = _c(x,y)[1]
  local ny = _c(x,y)[2]
  if ny == 1 and nx >= 3 and z == 1 then
    _loops_.sel = nx-2
  end
  local pad = _loops_.meta_pad[_loops_.sel]
  local rates = { [2] = {0.125,0.25,0.5,1,2,4}, [3] = {-0.125,-0.25,-0.5,-1,-2,-4} }
  if (ny == 2 or ny == 3) and (nx >= 2 and nx <= 7) and z == 1 then
    local target_rate = rates[ny][nx-1]
    bank[_loops_.sel][pad].rate = target_rate
    if grid_alt then
      for i = 1,16 do
        if i ~= pad then
          bank[_loops_.sel][i].rate = target_rate
        end
      end
    end
    if bank[_loops_.sel].id == pad then
      rightangleslice.sc.rate(bank[_loops_.sel][pad],_loops_.sel)
    end
  end
  if nx == 1 and ny == 13 and z == 1 then
    if not grid_alt then
      _ca.SOS_toggle(_loops_.sel)
    else
      _ca.SOS_erase(_loops_.sel)
    end
  end
  if (nx == 1 or nx == 2) and ny == 14 and z == 1 and params:get("SOS_enabled_".._loops_.sel) == 1 then
    local SOS_strings = {"SOS_L_in_".._loops_.sel,"SOS_R_in_".._loops_.sel}
    params:set(SOS_strings[nx], params:get(SOS_strings[nx]) == 1 and 2 or 1)
  end
  if (nx >= 4 and nx <= 8) and ny == 5 and z == 1 then
    params:set("doughstretch_mode_".._loops_.sel,nx-3)
  end
  if (nx == 7 or nx == 8) and (ny >= 6 and ny <= 8) and params:get("doughstretch_mode_".._loops_.sel) ~= 1 then
    sd_loop.dough_mod[ny-5][nx == 7 and "sub" or "add"] = z == 1 and true or false
    local targets = {"doughstretch_step_","doughstretch_duration_","doughstretch_fade_"}
    if z == 1 then
      params:delta(targets[ny-5].._loops_.sel,nx == 7 and -1*(grid_alt and 5 or 1) or 1*(grid_alt and 5 or 1))
      if sd_loop.dough_mod[ny-5].clock == nil then
        sd_loop.dough_mod[ny-5].clock = clock.run(function()
          while true do
            clock.sleep(0.15)
            params:delta(targets[ny-5].._loops_.sel,nx == 7 and -1*(grid_alt and 5 or 1) or 1*(grid_alt and 5 or 1))
          end
        end)
      end
    elseif z == 0 then
      if sd_loop.dough_mod[ny-5].clock ~= nil then
        clock.cancel(sd_loop.dough_mod[ny-5].clock)
        sd_loop.dough_mod[ny-5].clock = nil
      end
    end
  end
end

function sd_loop.parse_press_Live(x,y,z)
  local _c = speed_dial.coordinate
  local _loops_ = page.loops
  local nx = _c(x,y)[1]
  local ny = _c(x,y)[2]
  if ny == 1 and nx >= 3 and z == 1 then
    _loops_.sel = nx-2
  end
end

return sd_loop