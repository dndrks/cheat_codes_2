local sd_loop = {}

sd_loop.keys_held = {}
sd_loop.pad_focus = 0

function sd_loop.draw_grid()
  local edition = params:get("LED_style")
  local _c = speed_dial.translate
  local _loops_ = page.loops
  for i = 1,6 do
    g:led(_c(i+2,1)[1],_c(i+2,1)[2],page.loops.sel == i and 15 or 8)
  end
  if _loops_.sel < 4 then
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
    for i = 1,4 do
      for j = 8,11 do
        g:led(_c(i,j)[1],_c(i,j)[2],led_maps["square_off"][edition])
      end
    end
    local pad_x = _arps.index_to_grid_pos(pad,4)[1]
    local pad_y = _arps.index_to_grid_pos(pad,4)[2]+7
    g:led(_c(pad_x,pad_y)[1], _c(pad_x,pad_y)[2], 15)
  end
  -- local min_max = {{1,32},{33,64},{65,96},{97,128}}
  -- local lvl = 5
  -- for i = min_max[_loops_.seq_page[_loops_.sel]][1], min_max[_loops_.seq_page[_loops_.sel]][2] do
  --   local x_val = _arps.index_to_grid_pos(i,8)[1]
  --   local y_val = util.wrap(_arps.index_to_grid_pos(i,8)[2],1,4)+1
  --   g:led(_c(x_val,y_val)[1],_c(x_val,y_val)[2],arp[_loops_.sel].notes[i] ~= nil and 12 or (i >= arp[_loops_.sel].start_point and i <= arp[_loops_.sel].end_point and 4 or 2))
  -- end
  -- local edit_pos = _loops_.seq_position[_loops_.sel]
  -- if edit_pos >= min_max[_loops_.seq_page[_loops_.sel]][1] and edit_pos <= min_max[_loops_.seq_page[_loops_.sel]][2] then
  --   local x_val =  _arps.index_to_grid_pos(edit_pos,8)[1]
  --   local y_val = util.wrap(_arps.index_to_grid_pos(edit_pos,8)[2],1,4)+1
  --   g:led(_c(x_val,y_val)[1],_c(x_val,y_val)[2],8)
  -- end
  -- local current_step = arp[_loops_.sel].step
  -- if current_step >= min_max[_loops_.seq_page[_loops_.sel]][1] and current_step <= min_max[_loops_.seq_page[_loops_.sel]][2] and arp[_loops_.sel].playing then
  --   local x_val =  _arps.index_to_grid_pos(current_step,8)[1]
  --   local y_val = util.wrap(_arps.index_to_grid_pos(current_step,8)[2],1,4)+1
  --   g:led(_c(x_val,y_val)[1],_c(x_val,y_val)[2],0)
  -- end
  -- for i = 1,4 do
  --   g:led(_c(i,6)[1],_c(i,6)[2],_loops_.seq_page[_loops_.sel] == i and 12 or 4)
  -- end
  -- for i = 1,4 do
  --   for j = 8,11 do
  --     g:led(_c(i,j)[1],_c(i,j)[2],led_maps["square_off"][edition])
  --   end
  -- end
  -- if sd_loop.pad_focus ~= 0 then
  --   local pad_x = _arps.index_to_grid_pos(sd_loop.pad_focus,4)[1]
  --   local pad_y = _arps.index_to_grid_pos(sd_loop.pad_focus,4)[2]+7
  --   g:led(_c(pad_x,pad_y)[1], _c(pad_x,pad_y)[2], 15)
  -- end
  -- if #sd_loop.keys_held > 0 and arp[_loops_.sel].notes[edit_pos] ~= nil then
  --   local show_selected = arp[_loops_.sel].notes[edit_pos]
  --   local x_val =  _arps.index_to_grid_pos(show_selected,4)[1]
  --   local y_val = _arps.index_to_grid_pos(show_selected,4)[2]+7
  --   g:led(_c(x_val,y_val)[1],_c(x_val,y_val)[2],8)
  -- end
end

function sd_loop.parse_press(x,y,z)
  local _c = speed_dial.coordinate
  local _loops_ = page.loops
  local nx = _c(x,y)[1]
  local ny = _c(x,y)[2]
  if ny == 1 and nx >= 3 and z == 1 then
    _loops_.sel = nx-2
  end
  if ny >= 8 and ny <= 11 and nx >= 1 and nx <= 4 then
    if z == 1 then
      _loops_.meta_pad[_loops_.sel] = nx+((ny-8)*4)
    end
  end
  if _loops_.sel < 4 then
    local pad = _loops_.meta_pad[_loops_.sel]
    local rates = { [2] = {0.125,0.25,0.5,1,2,4}, [3] = {-0.125,-0.25,-0.5,-1,-2,-4} }
    if (ny == 2 or ny == 3) and (nx >= 2 and nx <= 7) and z == 1 then
      local target_rate = rates[ny][nx-1]
      bank[_loops_.sel][pad].rate = target_rate
      if bank[_loops_.sel].id == pad then
        rightangleslice.sc.rate(bank[_loops_.sel][pad],_loops_.sel)
      end
    end
  end
end

return sd_loop