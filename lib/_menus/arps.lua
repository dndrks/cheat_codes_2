local arps_menu = {}

local _arps = arps_menu

function _arps.init()
  page.arps = {}
  page.arps.focus = "params" -- "params" or "seq"
  page.arps.sel = 1
  page.arps.alt = {false,false,false}
  page.arps.param = {1,1,1}
  page.arps.param_group ={1,1,1}
  page.arps.seq_focus = "pattern"
  page.arps.seq_position = {1,1,1}
  _arps_ = page.arps
end

function _arps.draw_menu()
  local focus_arp = arp[_arps_.sel]
  screen.move(0,10)
  screen.level(3)
  screen.text("arp")
  local header = {"a","b","c"}
  for i = 1,3 do
    screen.level(_arps_.sel == i and 15 or 3)
    screen.move(75+(i*15),10)
    screen.text(header[i])
  end
  screen.level(_arps_.sel == _arps_.sel and 15 or 3)
  screen.move(75+(_arps_.sel*15),13)
  screen.text("_")
  if _arps_.focus == "params" then
    screen.move(100,10)
    screen.move(0,60)
    screen.font_size(15)
    screen.level(15)
    screen.text((focus_arp.hold and focus_arp.playing) and "hold" or ((focus_arp.hold and not focus_arp.playing) and "pause" or ""))
    
    screen.font_size(40)
    screen.move(50,50)
    screen.text(#focus_arp.notes > 0 and focus_arp.notes[focus_arp.step] or "...")

    screen.font_size(8)
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
    screen.move(125,20)
    screen.level(_arps_.param[_arps_.sel] == 1 and 15 or 3)
    local banks = {"a","b","c"}
    local pad = tostring(banks[_arps_.sel]..bank[_arps_.sel].id)
    -- screen.text_right((_arps_.alt[_arps_.sel] and (pad..": ") or "")..deci_to_frac[tostring(util.round(focus_arp.time, 0.0001))])
    screen.text_right((_arps_.alt[_arps_.sel] and (pad..": ") or "")..deci_to_frac[tostring(util.round(bank[_arps_.sel][bank[_arps_.sel].id].arp_time, 0.0001))])
    screen.move(125,30)
    screen.level(_arps_.param[_arps_.sel] == 2 and 15 or 3)
    screen.text_right(focus_arp.mode)
    screen.move(125,40)
    screen.level(_arps_.param[_arps_.sel] == 3 and 15 or 3)
    screen.text_right("s: "..focus_arp.start_point)
    screen.move(125,50)
    screen.level(_arps_.param[_arps_.sel] == 4 and 15 or 3)
    screen.text_right("e: "..(focus_arp.end_point > 0 and focus_arp.end_point or "1"))
    screen.move(125,60)
    screen.level(_arps_.param[_arps_.sel] == 5 and 15 or 3)
    screen.text_right("retrig: "..(tostring(focus_arp.retrigger) == "true" and "y" or "n"))
  elseif _arps_.focus == "seq" then
    for i = 1,32 do
      screen.level(_arps_.seq_position[_arps_.sel] == i and 15
      or (arp[_arps_.sel].step == i and 8 or 3))
      screen.move(40+(_arps.index_to_grid_pos(i,8)[1]-1)*12,15+(10*_arps.index_to_grid_pos(i,8)[2]))
      screen.text_center(arp[_arps_.sel].notes[i] ~= nil and arp[_arps_.sel].notes[i] or "-")
    end
  end
end

function _arps.process_encoder(n,d)
  if _arps_.focus == "params" then
    if n == 1 then
      _arps_.sel = util.clamp(_arps_.sel+d,1,3)
    elseif n == 2 then
      _arps_.param[_arps_.sel] = util.clamp(_arps_.param[_arps_.sel] + d,1,5)
    elseif n == 3 then
      local focus_arp = arp[_arps_.sel]
      local id = _arps_.sel
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
        local rounded = util.round(focus_arp.time,0.0001)
        local working = deci_to_int[tostring(rounded)]
        working = util.clamp(working+d,1,11)
        local int_to_deci = {0.125,1/6,0.25,1/3,0.5,2/3,1,4/3,2,8/3,4}
        if _arps_.alt[_arps_.sel] then
          bank[_arps_.sel][bank[_arps_.sel].id].arp_time = int_to_deci[working]
          focus_arp.time = bank[_arps_.sel][bank[_arps_.sel].id].arp_time
        else
          focus_arp.time = int_to_deci[working]
          for i = 1,16 do
            bank[_arps_.sel][i].arp_time = focus_arp.time
          end
        end
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
        if #focus_arp.notes > 0 then
          focus_arp.end_point = util.clamp(focus_arp.end_point+d,focus_arp.start_point,#focus_arp.notes)
        end
      elseif _arps_.param[id] == 5 then
        local working = arp[_arps_.sel].retrigger and 0 or 1
        working = util.clamp(working+d,0,1)
        arp[_arps_.sel].retrigger = (working == 0 and true or false)
      end
    end
  elseif _arps_.focus == "seq" then
    if n == 1 then
      _arps_.sel = util.clamp(_arps_.sel+d,1,3)
    elseif n == 2 then
      if _arps_.seq_focus == "pattern" then
        _arps_.seq_position[_arps_.sel] = util.clamp(_arps_.seq_position[_arps_.sel]+d,1,32)
      end
    elseif n == 3 then
      if _arps_.seq_focus == "pattern" then
        local current = arp[_arps_.sel].notes[_arps_.seq_position[_arps_.sel]]
        if current == nil then current = 0 end
        current = util.clamp(current+d,0,16)
        if current == 0 then current = nil end
        arp[_arps_.sel].notes[_arps_.seq_position[_arps_.sel]] = current
      end
    end
  end
end

function _arps.index_to_grid_pos(val,columns)
  local x = math.fmod(val-1,columns)+1
  local y = math.modf((val-1)/columns)+1
  return {x,y}
end

return arps_menu