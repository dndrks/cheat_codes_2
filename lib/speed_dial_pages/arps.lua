local sd_arp = {}

sd_arp.keys_held = {}
sd_arp.pad_focus = 0

function sd_arp.draw_grid()
  local edition = params:get("LED_style")
  local _c = speed_dial.translate
  local _arps_ = page.arps
  for i = 1,3 do
    g:led(_c(i+5,1)[1],_c(i+5,1)[2],page.arps.sel == i and 15 or 8)
  end
  -- for i = 1,8 do
  --   for j = 2,5 do
  --     g:led(_c(i,j)[1],_c(i,j)[2],4)
  --   end
  -- end
  local min_max = {{1,32},{33,64},{65,96},{97,128}}
  local lvl = 5
  for i = min_max[_arps_.seq_page[_arps_.sel]][1], min_max[_arps_.seq_page[_arps_.sel]][2] do
    local x_val = _arps.index_to_grid_pos(i,8)[1]
    local y_val = wrap(_arps.index_to_grid_pos(i,8)[2],1,4)+1
    g:led(_c(x_val,y_val)[1],_c(x_val,y_val)[2],arp[_arps_.sel].notes[i] ~= nil and 12 or (i >= arp[_arps_.sel].start_point and i <= arp[_arps_.sel].end_point and 4 or 2))
  end
  local edit_pos = _arps_.seq_position[_arps_.sel]
  if edit_pos >= min_max[_arps_.seq_page[_arps_.sel]][1] and edit_pos <= min_max[_arps_.seq_page[_arps_.sel]][2] then
    local x_val =  _arps.index_to_grid_pos(edit_pos,8)[1]
    local y_val = wrap(_arps.index_to_grid_pos(edit_pos,8)[2],1,4)+1
    g:led(_c(x_val,y_val)[1],_c(x_val,y_val)[2],8)
  end
  local current_step = arp[_arps_.sel].step
  if current_step >= min_max[_arps_.seq_page[_arps_.sel]][1] and current_step <= min_max[_arps_.seq_page[_arps_.sel]][2] and arp[_arps_.sel].playing then
    local x_val =  _arps.index_to_grid_pos(current_step,8)[1]
    local y_val = wrap(_arps.index_to_grid_pos(current_step,8)[2],1,4)+1
    g:led(_c(x_val,y_val)[1],_c(x_val,y_val)[2],0)
  end
  for i = 1,4 do
    g:led(_c(i,6)[1],_c(i,6)[2],_arps_.seq_page[_arps_.sel] == i and 12 or 4)
  end
  for i = 1,4 do
    for j = 9,12 do
      g:led(_c(i,j)[1],_c(i,j)[2],led_maps["square_off"][edition])
    end
  end
  if sd_arp.pad_focus ~= 0 then
    local pad_x = _arps.index_to_grid_pos(sd_arp.pad_focus,4)[1]
    local pad_y = _arps.index_to_grid_pos(sd_arp.pad_focus,4)[2]+8
    g:led(_c(pad_x,pad_y)[1], _c(pad_x,pad_y)[2], 15)
  end
  if #sd_arp.keys_held > 0 and arp[_arps_.sel].notes[edit_pos] ~= nil then
    local show_selected = arp[_arps_.sel].notes[edit_pos]
    local x_val =  _arps.index_to_grid_pos(show_selected,4)[1]
    local y_val = _arps.index_to_grid_pos(show_selected,4)[2]+8
    g:led(_c(x_val,y_val)[1],_c(x_val,y_val)[2],8)
  end
end

function sd_arp.parse_press(x,y,z)
  local _c = speed_dial.coordinate
  local _arps_ = page.arps
  local nx = _c(x,y)[1]
  local ny = _c(x,y)[2]
  if ny >=2 and ny <=5 then
    local current_batch = _arps_.seq_page[_arps_.sel]
    if z == 1 then
      _arps_.seq_position[_arps_.sel] = nx+(8*(ny-2))+(32*(current_batch-1))
      table.insert(sd_arp.keys_held,nx+(8*(ny-2))+(32*(current_batch-1)))
    elseif z == 0 then
      local removed = tab.key(sd_arp.keys_held,nx+(8*(ny-2))+(32*(current_batch-1)))
      table.remove(sd_arp.keys_held,removed)
    end
  elseif ny == 6 and nx >= 1 and nx <= 4 and z == 1 then
    _arps_.seq_page[_arps_.sel] = nx
  elseif ny == 1 and nx >=6 and nx<=8 and z == 1 then
    _arps_.sel = nx-5
  elseif ny >= 9 and ny <= 12 and nx >= 1 and nx <= 4 then
    if z == 1 then
      sd_arp.pad_focus = nx+((ny-9)*4)
      if #sd_arp.keys_held > 0 then
        for i = 1,#sd_arp.keys_held do
          arp[_arps_.sel].notes[sd_arp.keys_held[i]] = sd_arp.pad_focus
        end
      end
    else
      sd_arp.pad_focus = 0
    end
  end
end

return sd_arp