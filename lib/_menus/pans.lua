local pans_menu = {}

local _p = pans_menu
local focused_pad = {nil,nil,nil}
local _p_ = nil

local last_slew = {nil,nil,nil}

function _p.init()
  page.pans = {}
  page.pans.regions = {"panning","LFO","SHP","DPTH","RATE"}
  page.pans.selected_region = "panning"
  page.pans.sel = 1
  page.pans.bank = 1
  _p_ = page.pans
  -- _p.lfo_init()
end

function _p.nav_banks(d)
  -- page.pans.bank = 
end

function _p.draw_menu()
  for i = 1,3 do
    if bank[i].focus_hold == true then
      focused_pad[i] = bank[i].focus_pad
    else
      focused_pad[i] = bank[i].id
    end
  end
    -- screen.level(3)
    -- screen.move(10+((i-1)*53),25)
    -- local pan_options = {"L", "C", "R"}
    -- screen.text(pan_options[i])
    -- local pan_to_screen = util.linlin(-1,1,10,112,bank[i][focused_pad].pan)
    -- screen.move(pan_to_screen,35+(10*(i-1)))
    -- local pan_to_screen_options = {"a", "b", "c"}
    -- screen.level(15)
    -- if key1_hold or grid_alt then
    --   screen.text("("..pan_to_screen_options[i]..")")
    -- else
    --   screen.text(pan_to_screen_options[i]..""..focused_pad)
    -- end
  _p.draw_side()
  _p.draw_header()
  if not key1_hold then
    _p.draw_panning()
    _p.draw_lfo()
  end
end

function _p.draw_header()
  screen.level(15)
  screen.move(0,10)
  screen.line(128,10)
  screen.stroke()
  -- screen.rect(0,0,129,8)
  -- screen.fill()
  screen.move(3,6)
  screen.level(15)
  screen.text("pans")
end

function _p.draw_side()
  local modifier;
  local pan_to_screen_options = {"a"..focused_pad[1], "b"..focused_pad[2], "c"..focused_pad[3],"#"}
  for i = 1, #pan_to_screen_options do
    screen.level(i == _p_.bank and 15 or 3)
    screen.move(10,20+((i-1)*13))
    screen.text_center(pan_to_screen_options[i])
  end
  _p.draw_boundaries()
end

function _p.draw_panning()
  screen.level(_p_.selected_region == "panning" and 15 or 3)
  local pan_options = {"L", "C", "R"}
  local x_positions = {26,74,122}
  for i = 1,3 do
    screen.move(x_positions[i],20)
    screen.text_center(pan_options[i])
  end
  local pan_to_screen = util.linlin(-1,1,26,122,bank[_p_.bank][focused_pad[_p_.bank]].pan)
  screen.move(pan_to_screen,32)
  screen.text_center("|")
  for i = 0,20 do
    screen.move(util.linlin(0,20,26,122,i),30)
    screen.text_center(".")
  end
  if focused_pad[_p_.bank] == bank[_p_.bank].id then
    local lfo_to_screen = util.linlin(-1,1,26,122,bank[_p_.bank].pan_lfo.slope)
    screen.move(lfo_to_screen,28)
    screen.text_center("*")
  end
end

function _p.draw_lfo()
  screen.level(15)
  --four sections, 20 to 128: 21.6 each
  local x_positions = {47,75,101}
  for i = 1,3 do
    screen.move(x_positions[i],40)
    screen.line(x_positions[i],64)
    screen.stroke()
  end
  x_positions = {33,60,88,114}
  local text_to_display =
  {
    bank[_p_.bank][focused_pad[_p_.bank]].pan_lfo.active == true and "on" or "off",
    bank[_p_.bank][focused_pad[_p_.bank]].pan_lfo.waveform,
    bank[_p_.bank][focused_pad[_p_.bank]].pan_lfo.depth,
    -- _p.freq_to_string(_p_.bank),
    _lfos.freq_to_string(_p_.bank,"pan_lfo")
  }
  for i = 1,4 do
    screen.level(_p_.selected_region == _p_.regions[i+1] and 15 or 3)
    screen.move(x_positions[i],48)
    screen.text_center(_p_.regions[i+1])
    screen.move(x_positions[i],58)
    screen.text_center(text_to_display[i])
  end
end

function _p.draw_boundaries()
  screen.level(15)
  screen.move(20,10)
  screen.line(20,64)
  screen.stroke()
  screen.move(1,10)
  screen.line(1,64)
  screen.stroke()
  screen.move(20,40)
  screen.line(128,40)
  screen.stroke()
  screen.move(128,10)
  screen.line(128,64)
  screen.stroke()
  screen.move(0,64)
  screen.line(128,64)
  screen.stroke()
end

function _p.process_change(n,d)
  local b = bank[_p_.bank]
  local f = focused_pad[_p_.bank]
  if n == 1 then
    _p_.bank = util.clamp(_p_.bank + d,1,3)
  elseif n == 2 then
    local current_area = tab.key(_p_.regions,_p_.selected_region)
    current_area = util.clamp(current_area+d,1,#_p_.regions)
    _p_.selected_region = _p_.regions[current_area]
  elseif n == 3 then
    if _p_.selected_region == "panning" then
      b[f].pan = util.round(util.clamp(b[f].pan+d/10,-1,1),0.01)
      softcut.pan(_p_.bank+1, b[b.id].pan)
      bank[_p_.bank].pan_lfo.offset = b[b.id].pan
      if b.id == f then
        if not bank[_p_.bank].pan_lfo.active then
          bank[_p_.bank].pan_lfo.slope = b[b.id].pan
        end
      end
    else
      _lfos.process_encoder(n,d,"pan_lfo",_p_.selected_region)
    end
  end
end

return pans_menu