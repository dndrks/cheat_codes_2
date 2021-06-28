local arps_menu = {}

local _arps = arps_menu
local _arps_;

local snake_styles;

function _arps.init()
  page.arps = {}
  page.arps.focus = "seq" -- "params" or "seq"
  page.arps.sel = 1
  page.arps.alt = false
  page.arps.param = 1
  page.arps.seq_focus = "pattern"
  page.arps.seq_position = {1,1,1}
  page.arps.seq_page = {1,1,1}
  page.arps.alt_view_sel = 1
  page.arps.alt_fill_sel = 1
  page.arps.fill = {}
  page.arps.fill.start_point = {1,1,1}
  page.arps.fill.end_point = {16,16,16}
  page.arps.fill.snake = 1
  _arps_ = page.arps

  snake_styles =
  {
      "horiz"
    , "h.snake"
    , "vert"
    , "v.snake"
    , "top-in"
    , "bottom-in"
    , "zig-zag"
    , "wrap"
    , "random"
  }
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
  screen.level(_arps_.sel == _arps_.sel and 15 or 3)
  screen.move(75+(_arps_.sel*15),13)
  screen.text("_")
  screen.level(_arps_.focus == "seq" and 8 or 0)
  local e_pos = _arps_.seq_position[_arps_.sel]
  screen.rect(2+(_arps.index_to_grid_pos(e_pos,8)[1]-1)*12,6+(10*_arps.index_to_grid_pos(e_pos,8)[2]),7,7)
  screen.fill()
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
    screen.move(5+(_arps.index_to_grid_pos(i,8)[1]-1)*12,12+(10*_arps.index_to_grid_pos(i,8)[2]))
    if page.arps.alt and _arps_.focus == "params" then
      local first;
      local second = arp[_arps_.sel].notes[i] ~= nil and arp[_arps_.sel].notes[i] or "-"
      local third;
      if _arps_.fill.start_point[_arps_.sel] == i then
        first = "["
      else
        first = ""
      end
      if _arps_.fill.end_point[_arps_.sel] == i then
        third = "]"
      else
        third = ""
      end
      screen.text_center(first..second..third)
    else
      screen.text_center(arp[_arps_.sel].notes[i] ~= nil and arp[_arps_.sel].notes[i] or "-")
    end
  end
  screen.move(0,62)
  screen.level(3)
  screen.text("p. ".._arps_.seq_page[_arps_.sel])
  if not page.arps.alt then
    if not key2_hold then
      
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
      (_arps_.param == 1 and 15 or 3)
      or 3)
      local banks = {"a","b","c"}
      local pad = tostring(banks[_arps_.sel]..bank[_arps_.sel].id)
      -- screen.text_right((_arps_.alt[_arps_.sel] and (pad..": ") or "")..deci_to_frac[tostring(util.round(focus_arp.time, 0.0001))])
      screen.text_right((_arps_.alt and (pad..": ") or "")..deci_to_frac[tostring(util.round(arp[_arps_.sel].time, 0.0001))])
      screen.move(125,32)
      screen.level(_arps_.focus == "params" and
      (_arps_.param == 2 and 15 or 3)
      or 3)
      screen.text_right(focus_arp.mode)
      screen.move(125,42)
      screen.level(_arps_.focus == "params" and
      (_arps_.param == 3 and 15 or 3)
      or 3)
      screen.text_right("s: "..focus_arp.start_point)
      screen.move(125,52)
      screen.level(_arps_.focus == "params" and
      (_arps_.param == 4 and 15 or 3)
      or 3)
      screen.text_right("e: "..(focus_arp.end_point > 0 and focus_arp.end_point or "1"))
      screen.move(125,62)
      screen.level(_arps_.focus == "params" and
      (_arps_.param == 5 and 15 or 3)
      or 3)
      screen.text_right("swing: "..focus_arp.swing.."%")

    elseif key2_hold then
      screen.move(100,22)
      screen.level(15)
      screen.text("K3:")
      screen.font_size(15)
      local letters = {{"P","L","A","Y"},{"S","T","O","P"},{"N","O","N","E"}}
      for i = 1,4 do
        screen.move(114,16+(i*10))
        screen.text(tab.count(arp[_arps_.sel].notes) > 0 and (arp[_arps_.sel].playing and letters[2][i] or letters[1][i]) or letters[3][i])
      end
      screen.font_size(8)
    end
  elseif page.arps.alt and _arps_.focus == "seq" then
    if not key2_hold then
      screen.level(10)
      screen.rect(98,15,128,9)
      screen.fill()
      screen.level(0)
      screen.move(113,22)
      screen.text_center("TRIG")
      screen.level(page.arps.alt_view_sel == 1 and 15 or 3)
      screen.move(99,32)
      screen.text("P: "..arp[_arps_.sel].prob[_arps_.seq_position[_arps_.sel]].."%")
      screen.level(page.arps.alt_view_sel == 2 and 15 or 3)
      screen.move(99,42)
      screen.text("C: "..arp[_arps_.sel].conditional.A[_arps_.seq_position[_arps_.sel]]..
      ":"..
      arp[_arps_.sel].conditional.B[_arps_.seq_position[_arps_.sel]])
    end
  elseif page.arps.alt and _arps_.focus == "params" then
    if not key2_hold then
      screen.level(10)
      screen.rect(98,15,128,9)
      screen.fill()
      screen.level(0)
      screen.move(113,22)
      screen.text_center("FILL")
      screen.level(page.arps.alt_fill_sel == 1 and 15 or 3)
      screen.move(99,32)
      screen.text("s: ".._arps_.fill.start_point[_arps_.sel])
      screen.level(page.arps.alt_fill_sel == 2 and 15 or 3)
      screen.move(99,42)
      screen.text("e: ".._arps_.fill.end_point[_arps_.sel])
      screen.level(page.arps.alt_fill_sel == 3 and 15 or 3)
      screen.move(99,52)
      screen.text("style:")
      screen.move(128,62)
      screen.text_right(snake_styles[_arps_.fill.snake])
    end
  end
end

function _arps.process_key(n,z)
  if n == 1 then
    key1_hold = z == 1 and true or false
    page.arps.alt = z == 1
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
  elseif n == 3 and z == 1 and not key1_hold and not key2_hold then
    _arps_.focus = _arps_.focus == "params" and "seq" or "params"
  elseif n == 3 and z == 1 and key2_hold and not key1_hold then
    if (params:string("arp_".._arps_.sel.."_hold_style") == "sequencer" and not arp[_arps_.sel].playing)
    or (params:string("arp_".._arps_.sel.."_hold_style") ~= "sequencer" and not arp[_arps_.sel].playing and tab.count(arp[_arps_.sel].notes) > 0)
    then
      arps.toggle("start",_arps_.sel)
    elseif arp[_arps_.sel].playing then
      arps.toggle("stop",_arps_.sel)
    end
  elseif n == 3 and z == 1 and not key2_hold and key1_hold then
    if _arps_.focus == "params" then
      arps.fill(_arps_.sel,_arps_.fill.start_point[_arps_.sel],_arps_.fill.end_point[_arps_.sel],page.arps.fill.snake)
    end
  end
  screen_dirty = true
  grid_dirty = true
end

function _arps.process_encoder(n,d)
  if n == 1 then
    _arps_.sel = util.clamp(_arps_.sel+d,1,3)
  end
  if _arps_.focus == "params" and not page.arps.alt then
    if n == 2 then
      _arps_.param = util.clamp(_arps_.param + d,1,5)
    elseif n == 3 then
      local id = _arps_.sel
      local focus_arp = arp[_arps_.sel]
      if _arps_.param == 1 then
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
      elseif _arps_.param == 2 then
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
      elseif _arps_.param == 3 then
        focus_arp.start_point = util.clamp(focus_arp.start_point+d,1,focus_arp.end_point)
        _arps_.fill.start_point[_arps_.sel] = focus_arp.start_point
      elseif _arps_.param == 4 then
        focus_arp.end_point = util.clamp(focus_arp.end_point+d,focus_arp.start_point,128)
        _arps_.fill.end_point[_arps_.sel] = focus_arp.end_point
      elseif _arps_.param == 5 then
        arp[_arps_.sel].swing = util.clamp(arp[_arps_.sel].swing+d,50,99)
      end
    end
  elseif _arps_.focus == "params" and page.arps.alt then
    if n == 2 then
      _arps_.alt_fill_sel = util.clamp(_arps_.alt_fill_sel+d,1,3)
    elseif n == 3 then
      if _arps_.alt_fill_sel == 1 then
        _arps_.fill.start_point[_arps_.sel] = util.clamp(_arps_.fill.start_point[_arps_.sel]+d,1,_arps_.fill.end_point[_arps_.sel])
      elseif _arps_.alt_fill_sel == 2 then
        _arps_.fill.end_point[_arps_.sel] = util.clamp(_arps_.fill.end_point[_arps_.sel]+d,_arps_.fill.start_point[_arps_.sel],128)
      elseif _arps_.alt_fill_sel == 3 then
       _arps_.fill.snake = util.clamp(_arps_.fill.snake+d,1,#snake_styles)
      end
    end
  elseif _arps_.focus == "seq" then
    if n == 2 then
      if not page.arps.alt then
        _arps_.seq_position[_arps_.sel] = util.clamp(_arps_.seq_position[_arps_.sel]+d,1,128)
        _arps_.seq_page[_arps_.sel] = math.ceil(_arps_.seq_position[_arps_.sel]/32)
      else
        _arps_.alt_view_sel = util.clamp(_arps_.alt_view_sel+d,1,2)
      end
    elseif n == 3 then
      if not page.arps.alt then
        local current = arp[_arps_.sel].notes[_arps_.seq_position[_arps_.sel]]
        if current == nil then current = 0 end
        current = util.clamp(current+d,0,16)
        if current == 0 then current = nil end
        arp[_arps_.sel].notes[_arps_.seq_position[_arps_.sel]] = current
        _arps.check_for_first_touch()
      else
        local current = _arps_.seq_position[_arps_.sel]
        if _arps_.alt_view_sel == 1 then
          arp[_arps_.sel].prob[current] = util.clamp(arp[_arps_.sel].prob[current]+d,0,100)
        elseif _arps_.alt_view_sel == 2 then
          _arps.cycle_conditional(_arps_.sel,current,d)
        end
      end
    end
  end
  grid_dirty = true
end

function _arps.cycle_conditional(target,step,d)
  if d > 0 then
    local current_B = arp[target].conditional.B[step]
    current_B = current_B+d
    if current_B > 8 then
      arp[target].conditional.A[step] = util.clamp(arp[target].conditional.A[step]+1,1,8)
      arp[target].conditional.B[step] = arp[target].conditional.A[step] ~= 8 and 1 or 8
    else
      arp[target].conditional.B[step] = current_B
    end
  elseif d < 0 then
    local current_B = arp[target].conditional.B[step]
    current_B = current_B+d
    if current_B < 1 then
      arp[target].conditional.A[step] = util.clamp(arp[target].conditional.A[step]-1,1,8)
      arp[target].conditional.B[step] = arp[target].conditional.A[step] ~= 1 and 8 or 1
    else
      arp[target].conditional.B[step] = current_B
    end
  end
end

function _arps.check_for_first_touch()
  if tab.count(arp[_arps_.sel].notes) == 1
  and not arp[_arps_.sel].playing
  and not arp[_arps_.sel].pause
  and not arp[_arps_.sel].enabled
  then
    arps.enable(_arps_.sel,true)
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

function _arps.fill(style)
  if style ~= "random" then
    for i = arp[_arps_.sel].start_point,arp[_arps_.sel].end_point do
      arp[_arps_.sel].notes[i] = snakes[style][util.wrap(i,1,16)]
    end
  else
    for i = arp[_arps_.sel].start_point,arp[_arps_.sel].end_point do
      arp[_arps_.sel].notes[i] = math.random(1,16)
    end
  end
  if not arp[_arps_.sel].playing
  and not arp[_arps_.sel].pause
  and not arp[_arps_.sel].enabled
  then
    arps.enable(_arps_.sel,true)
    arp[_arps_.sel].pause = true
    arp[_arps_.sel].hold = true
    grid_dirty = true
  end
  screen_dirty = true
end

return arps_menu