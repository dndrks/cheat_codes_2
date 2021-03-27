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
  _p.lfo_init()
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
  local lfo_to_screen = util.linlin(-1,1,26,122,pan_lfo[_p_.bank].slope)
  screen.move(lfo_to_screen,28)
  screen.text_center("*")
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
    pan_lfo[_p_.bank].active == true and "on" or "off",
    pan_lfo[_p_.bank].waveform,
    pan_lfo[_p_.bank].depth,
    _p.freq_to_string(_p_.bank),
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
      pan_lfo[_p_.bank].offset = b[b.id].pan
      if b.id == f then
        if not pan_lfo[_p_.bank].active then
          pan_lfo[_p_.bank].slope = b[b.id].pan
        end
      end
    elseif _p_.selected_region == "LFO" then
      if last_slew[_p_.bank] == nil then
        last_slew[_p_.bank] = params:get("pan slew ".._p_.bank)
        params:set("pan slew ".._p_.bank,0.1)
      end
      b[f].pan_lfo.active = d > 0 and true or false
      if b.id == f then
        pan_lfo[_p_.bank].active = b[f].pan_lfo.active
        if not pan_lfo[_p_.bank].active then
          softcut.pan(_p_.bank+1,b[f].pan)
          pan_lfo[_p_.bank].counter = 1
          pan_lfo[_p_.bank].slope = b[f].pan
          params:set("pan slew ".._p_.bank,last_slew[_p_.bank])
          last_slew[_p_.bank] = nil
        end
      end
    elseif _p_.selected_region == "SHP" then
      local current_index = tab.key(pan_lfotypes,b[f].pan_lfo.waveform)
      current_index = util.clamp(current_index + d,1,#pan_lfotypes)
      b[f].pan_lfo.waveform = pan_lfotypes[current_index]
      if b.id == f then
        pan_lfo[_p_.bank].waveform = b[f].pan_lfo.waveform
      end
    elseif _p_.selected_region == "DPTH" then
      b[f].pan_lfo.depth = util.clamp(b[f].pan_lfo.depth + d,1,200)
      if b.id == f then
        pan_lfo[_p_.bank].depth = b[f].pan_lfo.depth
      end
    elseif _p_.selected_region == "RATE" then
      -- local current_index = tab.key(pan_lforates.values,(1/pan_lfo[_p_.bank].freq)/(clock.get_beat_sec()*4))
      b[f].pan_lfo.rate_index = util.clamp(b[f].pan_lfo.rate_index + d,1,#pan_lforates.values)
      b[f].pan_lfo.freq = 1/((clock.get_beat_sec()*4) * pan_lforates.values[b[f].pan_lfo.rate_index])
      if b.id == f then
        pan_lfo[_p_.bank].freq = b[f].pan_lfo.freq
      end
    end
  end
end

function _p.process_lfo(i)
  softcut.pan(i+1, pan_lfo[i].slope)
  if menu == 4 and i == _p_.bank then
    screen_dirty = true
  end
end

function _p.process_cheat(b,p)
  pan_lfo[b].active = bank[b][p].pan_lfo.active
  pan_lfo[b].counter = 1
  pan_lfo[b].slope = 0
  pan_lfo[b].offset = bank[b][p].pan
  pan_lfo[b].depth = bank[b][p].pan_lfo.depth
  pan_lfo[b].freq = bank[b][p].pan_lfo.freq
  pan_lfo[b].waveform = bank[b][p].pan_lfo.waveform
  softcut.pan(_p_.bank+1,bank[b][p].pan)
end

local function make_sine(n)
  return 1 * math.sin(((tau / 100) * (pan_lfo[n].counter)) - (tau / (pan_lfo[n].freq)))
end


local function make_square(n)
  return make_sine(n) >= 0 and 1 or -1
end


local function make_sh(n)
  local polarity = make_square(n)
  if pan_lfo[n].prev_polarity ~= polarity then
    pan_lfo[n].prev_polarity = polarity
    return math.random() * (math.random(0, 1) == 0 and 1 or -1)
  else
    return pan_lfo[n].prev
  end
end


function _p.lfo_init()
  pan_lfotypes = {
    "sine",
    "sqr",
    "s+h"
  }
  -- these are funky..i need to be able to iterate...
  pan_lforates = {["names"] = {}, ["values"] = {}}
  pan_lforates.names = {
    "1/16",
    "1/12",
    "1/8",
    "1/6",
    "3/16",
    "1/4",
    "5/16",
    "1/3",
    "3/8",
    "1/2",
    "3/4",
    "1",
    "1.5",
    "2",
    "3",
    "4",
    "6",
    "8",
    "16",
    "32"
  }
  pan_lforates.values = {
    1/16,
    1/12,
    1/8,
    1/6,
    3/16,
    1/4,
    5/16,
    1/3,
    3/8,
    1/2,
    3/4,
    1,
    1.5,
    2,
    3,
    4,
    6,
    8,
    16,
    32
  }
  pan_lfo = {}
  for i = 1, 3 do
    pan_lfo[i] = {
      freq = 1/((clock.get_beat_sec()*4) * pan_lforates.values[14]),
      counter = 1,
      waveform = pan_lfotypes[1],
      slope = 0,
      depth = 100,
      offset = 0,
      active = false
    }
  end
  lfo_metro = metro.init()
  lfo_metro.time = 0.01
  lfo_metro.count = -1
  lfo_metro.event = function()
    for i = 1,3 do
      if pan_lfo ~= nil and pan_lfo[i].active then
        local slope
        if pan_lfo[i].waveform == "sine" then
          slope = make_sine(i)
        elseif pan_lfo[i].waveform == "sqr" then
          slope = make_square(i)
        elseif pan_lfo[i].waveform == "s+h" then
          slope = make_sh(i)
        end
        pan_lfo[i].prev = slope
        pan_lfo[i].slope = math.max(-1.0, math.min(1.0, slope)) * (pan_lfo[i].depth * 0.01) + pan_lfo[i].offset
        pan_lfo[i].counter = pan_lfo[i].counter + pan_lfo[i].freq
        _p.process_lfo(i)
      end
    end
  end
  lfo_metro:start()
  -- local lfo_metro = clock.run(function()
  --   while true do
  --     clock.sleep(0.01)
  --     for i = 1,3 do
  --       if pan_lfo[i].active then
  --         local slope
  --         if pan_lfo[i].waveform == "sine" then
  --           slope = make_sine(i)
  --         elseif pan_lfo[i].waveform == "sqr" then
  --           slope = make_square(i)
  --         elseif pan_lfo[i].waveform == "s+h" then
  --           slope = make_sh(i)
  --         end
  --         pan_lfo[i].prev = slope
  --         pan_lfo[i].slope = math.max(-1.0, math.min(1.0, slope)) * (pan_lfo[i].depth * 0.01) + pan_lfo[i].offset
  --         pan_lfo[i].counter = pan_lfo[i].counter + pan_lfo[i].freq
  --         _p.process_lfo(i)
  --       end
  --     end
  --   end
  -- end)
  
end

function _p.bpm_to_lfo(target,new_val)
  pan_lfo[target].freq = 1/((clock.get_beat_sec()*4) * pan_lforates.values[new_val])
end

--pan_lfo[target].freq = 1/((clock.get_beat_sec()*4) * bars)
-- bars = (1/pan_lfo[target].freq)/clock.get_beat_sec())/4

function _p.freq_to_string(target)
  -- local inverted = tab.invert(pan_lforates)
  -- return inverted[(1/pan_lfo[target].freq)/(clock.get_beat_sec()*4)]
  -- return _p.find(pan_lforates,(1/pan_lfo[target].freq)/(clock.get_beat_sec()*4))
  return pan_lforates.names[bank[target][bank[target].id].pan_lfo.rate_index]
end

function _p.adjust_lfo_rate(target)
  for i = 1,16 do
    bank[target][i].pan_lfo.freq = 1/((clock.get_beat_sec()*4) * pan_lforates.values[bank[target][i].pan_lfo.rate_index])
    if i == bank[target].focus_pad then
      pan_lfo[target].freq = bank[target][i].pan_lfo.freq
    end
  end
end


function _p.find(tbl, val)
  for k, v in pairs(tbl) do
      if v == val then return k end
  end
  return nil
end

return pans_menu