local arps_menu = {}

local _arps = arps_menu
local _arps_;

function _arps.init()
  page.arps = {}
  page.arps.focus = "seq" -- "params" or "seq"
  page.arps.sel = 1
  page.arps.alt = {false,false,false}
  page.arps.param = {1,1,1}
  page.arps.param_group ={1,1,1}
  page.arps.seq_focus = "pattern"
  page.arps.seq_position = {1,1,1}
  page.arps.seq_page = {1,1,1}
  _arps_ = page.arps
end

function _arps.draw_menu()
  local focus_arp = arp[_arps_.sel]
  screen.move(0,10)
  screen.level(3)
  screen.text("arps")
  local header = {"a","b","c"}
  for i = 1,3 do
    screen.level(_arps_.sel == i and 15 or 3)
    screen.move(75+(i*15),10)
    screen.text(header[i])
  end
  screen.level(_arps_.focus == "seq" and 8 or 0)
  local e_pos = _arps_.seq_position[_arps_.sel]
  screen.rect(2+(_arps.index_to_grid_pos(e_pos,8)[1]-1)*12,6+(10*_arps.index_to_grid_pos(e_pos,8)[2]),7,7)
  screen.fill()
  screen.level(_arps_.sel == _arps_.sel and 15 or 3)
  screen.move(75+(_arps_.sel*15),13)
  screen.text("_")
  local min_max = {{1,32},{33,64},{65,96},{97,128}}
  local lvl = 5
  for i = min_max[_arps_.seq_page[_arps_.sel]][1], min_max[_arps_.seq_page[_arps_.sel]][2] do
    if _arps_.seq_position[_arps_.sel] == i then
      if arp[_arps_.sel].step == i and arp[_arps_.sel].playing then
        lvl = _arps_.focus == "seq" and 5 or 4
      else
        lvl = _arps_.focus == "seq" and 0 or 2
      end
    else
      if i <= arp[_arps_.sel].end_point and i >= arp[_arps_.sel].start_point then
        if arp[_arps_.sel].step == i then
          lvl = _arps_.focus == "seq" and 15 or 4
        else
          lvl = _arps_.focus == "seq" and 5 or 2
        end
      else
        lvl = 1
      end
    end
    screen.level(lvl)
    -- and (_arps_.seq_position[_arps_.sel] == i and (arp[_arps_.sel].step == i and 0 or 15)
    --   or (arp[_arps_.sel].step == i and (_arps_.seq_position[_arps_.sel] == i and 0 or 5)
    --     or ((i <= arp[_arps_.sel].end_point and i >= arp[_arps_.sel].start_point) and 3 or 1)))
    -- or (arp[_arps_.sel].step == i and 4
    --   or ((i <= arp[_arps_.sel].end_point and i >= arp[_arps_.sel].start_point) and 2 or 1)))
    screen.move(5+(_arps.index_to_grid_pos(i,8)[1]-1)*12,12+(10*_arps.index_to_grid_pos(i,8)[2]))
    screen.text_center(arp[_arps_.sel].notes[i] ~= nil and arp[_arps_.sel].notes[i] or "-")
  end
  screen.move(5,62)
  screen.level(3)
  if math.ceil(arp[_arps_.sel].end_point/32) > 1 then
    screen.text_center(_arps_.seq_page[_arps_.sel]..":"..math.ceil(arp[_arps_.sel].end_point/32))
  end

  local deci_to_frac =
  { ["0.125"] = "1/32"
  , ["0.1667"] = "1/16t"
  , ["0.25"] = "1/16"
  , ["0.3333"] = "1/8t"
  , ["0.5"] = "1/8"
  , ["0.6667"] = "1/4t"
  , ["1.0"] = "1/4"
  , ["1.3333"] = "1/2t"
  , ["2.0"] = "1/2"
  , ["2.6667"] = "1t"
  , ["4.0"] = "1"
  }
  screen.move(125,22)
  screen.level(_arps_.focus == "params" and
  (_arps_.param[_arps_.sel] == 1 and 15 or 3)
  or 3)
  local banks = {"a","b","c"}
  local pad = tostring(banks[_arps_.sel]..bank[_arps_.sel].id)
  -- screen.text_right((_arps_.alt[_arps_.sel] and (pad..": ") or "")..deci_to_frac[tostring(util.round(focus_arp.time, 0.0001))])
  screen.text_right((_arps_.alt[_arps_.sel] and (pad..": ") or "")..deci_to_frac[tostring(util.round(arp[_arps_.sel].time, 0.0001))])
  screen.move(125,32)
  screen.level(_arps_.focus == "params" and
  (_arps_.param[_arps_.sel] == 2 and 15 or 3)
  or 3)
  screen.text_right(focus_arp.mode)
  screen.move(125,42)
  screen.level(_arps_.focus == "params" and
  (_arps_.param[_arps_.sel] == 3 and 15 or 3)
  or 3)
  screen.text_right("s: "..focus_arp.start_point)
  screen.move(125,52)
  screen.level(_arps_.focus == "params" and
  (_arps_.param[_arps_.sel] == 4 and 15 or 3)
  or 3)
  screen.text_right("e: "..(focus_arp.end_point > 0 and focus_arp.end_point or "1"))
  screen.move(125,62)
  screen.level(_arps_.focus == "params" and
  (_arps_.param[_arps_.sel] == 5 and 15 or 3)
  or 3)
  screen.text_right("retrig: "..(tostring(focus_arp.retrigger) == "true" and "y" or "n"))
end

function _arps.process_key(n,z)
  if n == 1 then
    key1_hold = z == 1 and true or false
    if z == 1 then
    end
  elseif n == 2 and z == 1 and not key1_hold then
    key2_hold_counter:start()
    key2_hold_and_modify = false
  elseif n == 2 and z == 0 and not key1_hold then
    if key2_hold == false and not key1_hold then
      key2_hold_counter:stop()
      menu = 1
    elseif key2_hold_and_modify then
      key2_hold = false
      key2_hold_and_modify = false
    elseif not key2_hold_and_modify then
      key2_hold = false
      key2_hold_and_modify = false
    end
  elseif n == 3 and z == 1 and not key1_hold then
    _arps_.focus = _arps_.focus == "params" and "seq" or "params"
    -- if page.arps.focus == "params" then
      -- local id = page.arps.sel
      -- if not arp[id].hold then
      --   if not arp[id].enabled then
      --     arp[id].enabled = true
      --   end
      --   if #arp[id].notes > 0 then
      --     arp[id].hold = true
      --   else
      --     arp[id].enabled = false
      --   end
      -- else
      --   if #arp[id].notes > 0 then
      --     if arp[id].playing == true then
      --       arp[id].hold = not arp[id].hold
      --       if not arp[id].hold then
      --         arps.clear(id)
      --       end
      --       arp[id].enabled = false
      --     end
      --   end
      -- end
    -- end
  end
  screen_dirty = true
  grid_dirty = true
end

function _arps.process_encoder(n,d)
  if n == 1 then
    _arps_.sel = util.clamp(_arps_.sel+d,1,3)
  end
  if _arps_.focus == "params" then
    if n == 2 then
      _arps_.param[_arps_.sel] = util.clamp(_arps_.param[_arps_.sel] + d,1,5)
    elseif n == 3 then
      local id = _arps_.sel
      local focus_arp = arp[_arps_.sel]
      if _arps_.param[id] == 1 then
        local deci_to_int =
        { ["0.125"] = 1 --1/32
        , ["0.1667"] = 2 --1/16T
        , ["0.25"] = 3 -- 1/16
        , ["0.3333"] = 4 -- 1/8T
        , ["0.5"] = 5 -- 1/8
        , ["0.6667"] = 6 -- 1/4T
        , ["1.0"] = 7 -- 1/4
        , ["1.3333"] = 8 -- 1/2T
        , ["2.0"] = 9 -- 1/2
        , ["2.6667"] = 10  -- 1T
        , ["4.0"] = 11 -- 1
        }
        local rounded = util.round(arp[id].time,0.0001)
        local working = deci_to_int[tostring(rounded)]
        working = util.clamp(working+d,1,11)
        local int_to_deci = {0.125,1/6,0.25,1/3,0.5,2/3,1,4/3,2,8/3,4}
        arp[id].time = int_to_deci[working]
      elseif _arps_.param[id] == 2 then
        local dir_to_int =
        { ["fwd"] = 1
        , ["bkwd"] = 2
        , ["pend"] = 3
        , ["rnd"] = 4
        }
        local dir = dir_to_int[focus_arp.mode]
        dir = util.clamp(dir+d,1,4)
        local int_to_dir = {"fwd","bkwd","pend","rnd"}
        focus_arp.mode = int_to_dir[dir]
      elseif _arps_.param[id] == 3 then
        focus_arp.start_point = util.clamp(focus_arp.start_point+d,1,focus_arp.end_point)
      elseif _arps_.param[id] == 4 then
        focus_arp.end_point = util.clamp(focus_arp.end_point+d,focus_arp.start_point,128)
      elseif _arps_.param[id] == 5 then
        local working = arp[_arps_.sel].retrigger and 0 or 1
        working = util.clamp(working+d,0,1)
        arp[_arps_.sel].retrigger = (working == 0 and true or false)
      end
    end
  elseif _arps_.focus == "seq" then
    if n == 2 then
      if _arps_.seq_focus == "pattern" then
        _arps_.seq_position[_arps_.sel] = util.clamp(_arps_.seq_position[_arps_.sel]+d,1,128)
        _arps_.seq_page[_arps_.sel] = math.ceil(_arps_.seq_position[_arps_.sel]/32)
      end
    elseif n == 3 then
      if _arps_.seq_focus == "pattern" then
        local current = arp[_arps_.sel].notes[_arps_.seq_position[_arps_.sel]]
        if current == nil then current = 0 end
        current = util.clamp(current+d,0,16)
        if current == 0 then current = nil end
        arp[_arps_.sel].notes[_arps_.seq_position[_arps_.sel]] = current
        _arps.check_for_first_touch()
      end
    end
  end
end

function _arps.check_for_first_touch()
  if tab.count(arp[_arps_.sel].notes) == 1
  and not arp[_arps_.sel].playing
  and not arp[_arps_.sel].pause
  and not arp[_arps_.sel].enabled
  then
    arp[_arps_.sel].enabled = true
    arp[_arps_.sel].pause = true
    arp[_arps_.sel].hold = true
    grid_dirty = true
  end
end

function _arps.index_to_grid_pos(val,columns)
  local x = math.fmod(val-1,columns)+1
  local y = math.modf((val-1)/columns)+1
  return {x,y-(4*(_arps_.seq_page[_arps_.sel]-1))}
end

local snakes = 
{ 
    [1] = { 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16 }
  , [2] = { 1,2,3,4,8,7,6,5,9,10,11,12,16,15,14,13 }
  , [3] = { 1,5,9,13,2,6,10,14,3,7,11,15,4,8,12,16 }
  , [4] = { 1,5,9,13,14,10,6,2,3,7,11,15,16,12,8,4 }
  , [5] = { 1,2,3,4,8,12,16,15,14,13,9,5,6,7,11,10 }
  , [6] = { 13,14,15,16,12,8,4,3,2,1,5,9,10,11,7,6 }
  , [7] = { 1,2,5,9,6,3,4,7,10,13,14,11,8,12,15,16 }
  , [8] = { 1,6,11,16,15,10,5,2,7,12,8,3,9,14,13,4 }
}

local snake_styles =
{
    "horizontal"
  , "h.snake"
  , "vertical"
  , "v.snake"
  , "top-in"
  , "bottom-in"
  , "zig-zag"
  , "wrap"
}

function _arps.fill(style)
  for i = arp[_arps_.sel].start_point,arp[_arps_.sel].end_point do
    arp[_arps_.sel].notes[i] = snakes[style][util.wrap(i,1,16)]
  end
  screen_dirty = true
end

return arps_menu