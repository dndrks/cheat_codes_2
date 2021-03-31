local lfos = {}

local focused_pad = {nil,nil,nil}
local last_slew = {nil,nil,nil}
local the_one = {1,1,1}

function lfos.init()

  lfo_types =
  {
    "sine",
    "sqr",
    "s+h"
  }
  lfo_rates = {["names"] = {}, ["values"] = {}}
  lfo_rates.names = {
    "1/32",
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
  lfo_rates.values = {
    1/32,
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

  lfo_destinations =
  {
    "pan_lfo"
  }

  lfo_metro = metro.init()
  lfo_metro.time = 0.01
  lfo_metro.count = -1
  lfo_metro.event = function()
    for i = 1,3 do
      lfos.iterate(i,"pan_lfo")
      lfos.iterate(i,"level_lfo")
      lfos.iterate(i,"filter_lfo")
    end
  end
  lfo_metro:start()
end

local function make_sine(n,parameter)
  return 1 * math.sin(((tau / 100) * (bank[n][parameter].counter)) - (tau / (bank[n][parameter].freq)))
end


local function make_square(n,parameter)
  return make_sine(n,parameter) >= 0 and 1 or -1
end


local function make_sh(n,parameter)
  local polarity = make_square(n,parameter)
  if bank[n][parameter].prev_polarity ~= polarity then
    bank[n][parameter].prev_polarity = polarity
    return math.random() * (math.random(0, 1) == 0 and 1 or -1)
  else
    return bank[n][parameter].prev
  end
end

n_s = "inQuart"

local function make_complex(n,parameter)
  -- print(easingFunctions["inQuart"](make_sine(n,parameter),0,1,1), easeinquart((make_sine(n,parameter))))
  return {easingFunctions[n_s](util.linlin(-1,1,0,1,make_sine(n,parameter)),0,1,1),easeinbounce((make_sine(n,parameter)))} -- these match...
  -- return util.linlin(0,2,-1,1,easeoutinquad(util.linlin(-1,1,0,2,make_sine(n,parameter))))
  -- easingFunctions[m[i].curve](val/self.in_max,self.in_min,self.in_max,1)
end

function easeinbounce(t)
  t = 1-t
  local n1=7.5625
  local d1=2.75

  if (t<1/d1) then
    return 1-n1*t*t;
  elseif(t<2/d1) then
    t = t-1.5/d1
    return 1-n1*t*t-.75;
  elseif(t<2.5/d1) then
    t = t-2.25/d1
    return 1-n1*t*t-.9375;
  else
    t = t-2.625/d1
    return 1-n1*t*t-.984375;
  end
end

function easeoutinquad(t)
  if t<.5 then
    t = t-.5
    return .5-t*t*2
  else
    t = t-.5
    return .5+t*t*2
  end
end


function easeinquart(t)
  return t*t*t*t
end


function lfos.find_the_zero(id,parameter)
  local thing = 1
  while util.round(1 * math.sin(((tau / 100) * (thing)) - (tau / (bank[id][parameter].freq))),0.01) ~= 0 do
    thing = thing + 0.01
  end
  return thing
end

function lfos.find_the_one(id,parameter)
  local thing = 1
  while util.round(1 * math.sin(((tau / 100) * (thing)) - (tau / (bank[id][parameter].freq))),0.1) ~= 1 do
    thing = thing + 0.1
  end
  return thing
end

function lfos.find_the_mid(id,parameter,num) -- can't go over 1...
  if num > 1 then num = 1 print("setting to 1") end
  local thing = 1
  while util.round(1 * math.sin(((tau / 100) * (thing)) - (tau / (bank[id][parameter].freq))),0.01) ~= util.round(num,0.01) do
    thing = thing + 0.01
  end
  return thing
end


function lfos.find_the_current(id,parameter)
  local thing = 1
  while util.round(1 * math.sin(((tau / 100) * (thing)) - (tau / (bank[id][parameter].freq))),0.01) ~= bank[id][parameter].slope do
    thing = thing + 0.01
  end
  return thing
end

function lfos.iterate(id,parameter)
  -- want to basically pass the lfo metro ticker to the different lfos
  -- need to watch for oversaturattion -- does there need to be 10ms processing?
  -- at least stuff like pans shouldn't be sent to softcut every 10ms...
  if bank ~= nil and bank[id][parameter].active then
    local slope
    if bank[id][parameter].waveform == "sine" then
      slope = make_sine(id,parameter)
    elseif bank[id][parameter].waveform == "sqr" then
      slope = make_square(id,parameter)
    elseif bank[id][parameter].waveform == "s+h" then
      slope = make_sh(id,parameter)
    elseif bank[id][parameter].waveform == "complex" then
      slope = make_complex(id,parameter)[1]
      print(slope,make_complex(id,parameter)[2])
    end
    if not bank[id][parameter].loop then
      if util.round(1 * math.sin(((tau / 100) * (bank[id][parameter].counter)) - (tau / (bank[id][parameter].freq))),0.1) <=  0 then
        bank[id][parameter].active = false
        goto continue
      end
    end
    bank[id][parameter].prev = slope
    bank[id][parameter].slope = math.max(-1.0, math.min(1.0, slope)) * (bank[id][parameter].depth * 0.01) + bank[id][parameter].offset
    bank[id][parameter].counter = bank[id][parameter].counter + bank[id][parameter].freq
    lfos.process(id,parameter)
    ::continue::
    if not bank[id][parameter].active then
      print("it's here...")
      lfos.zero_out(id,parameter)
      screen_dirty = true
    end
  end
end

function lfos.zero_out(id,parameter)
  if parameter == "pan_lfo" then
    bank[id][parameter].slope = bank[id][bank[id].id].pan
    softcut.pan(id+1,bank[id][bank[id].id].pan)
  elseif parameter == "level_lfo" then
    bank[id][parameter].slope = 0
    softcut.level(id+1,0)
  end
end

function lfos.process(id,parameter)
  if parameter == "pan_lfo" then
    softcut.pan(id+1, bank[id][parameter].slope)
    if menu == 4 and id == page.pans.bank then
      screen_dirty = true
    end
  elseif parameter == "level_lfo" then
    local highest_to_lowest = util.linlin(0,1,0,bank[id][bank[id].id].level,bank[id][parameter].slope) -- this is so super important!
    softcut.level(id+1,highest_to_lowest)
    -- if menu == 3 and id == page.levels.bank then
    --   screen_dirty = true
    -- end
  elseif parameter == "filter_lfo" then
    softcut.post_filter_fc(id+1,util.linlin(-1,1,8000,12000,bank[id][parameter].slope))
  end
end

function lfos.process_cheat(b,p,parameter)
  if parameter == "pan_lfo" then
    bank[b][parameter].active =  bank[b][p][parameter].active
    -- bank[b][parameter].counter = lfos.find_the_one(b,parameter)
    -- bank[b][parameter].counter = 1
    bank[b][parameter].depth =  bank[b][p][parameter].depth
    bank[b][parameter].freq =  bank[b][p][parameter].freq
    bank[b][parameter].waveform =  bank[b][p][parameter].waveform
    bank[b][parameter].slope = bank[b][p].pan
    bank[b][parameter].offset = bank[b][p].pan
    softcut.pan(b+1,bank[b][p].pan)
  elseif parameter == "level_lfo" then
    lfos.turn_on_level(b)
  end
end

function lfos.process_encoder(n,d,target,parameter)
  local _p_ = page.pans
  if bank[_p_.bank].focus_hold == true then
    focused_pad[_p_.bank] = bank[_p_.bank].focus_pad
  else
    focused_pad[_p_.bank] = bank[_p_.bank].id
  end
  if target == "pan_lfo" then
    local b = bank[_p_.bank]
    local f = focused_pad[_p_.bank]
    if parameter == "LFO" then
      if last_slew[_p_.bank] == nil then
        last_slew[_p_.bank] = params:get("pan slew ".._p_.bank)
        params:set("pan slew ".._p_.bank,0.1)
      end
      b[f].pan_lfo.active = d > 0 and true or false
      if b.id == f then
        b.pan_lfo.active = b[f].pan_lfo.active
        b.pan_lfo.counter = lfos.find_the_one(_p_.bank,target) -- TODO ERROR WHEN PATTERN IS GOING??
        b.pan_lfo.slope = b[f].pan
        if not b.pan_lfo.active then
          softcut.pan(_p_.bank+1,b[f].pan)
          b.pan_lfo.counter = 1 -- TODO ERROR WHEN PATTERN IS GOING??
          b.pan_lfo.slope = b[f].pan
          params:set("pan slew ".._p_.bank,last_slew[_p_.bank])
          last_slew[_p_.bank] = nil
        end
      end
    elseif parameter == "SHP" then
      local current_index = tab.key(lfo_types,b[f].pan_lfo.waveform)
      current_index = util.clamp(current_index + d,1,#lfo_types)
      b[f].pan_lfo.waveform = lfo_types[current_index]
      if b.id == f then
        b.pan_lfo.waveform = b[f].pan_lfo.waveform
      end
    elseif parameter == "DPTH" then
      b[f].pan_lfo.depth = util.clamp(b[f].pan_lfo.depth + d,1,200)
      if b.id == f then
        b.pan_lfo.depth = b[f].pan_lfo.depth
      end
    elseif parameter == "RATE" then
      b[f].pan_lfo.rate_index = util.clamp(b[f].pan_lfo.rate_index + d,1,#lfo_rates.values)
      b[f].pan_lfo.freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[b[f].pan_lfo.rate_index])
      if b.id == f then
        b.pan_lfo.freq = b[f].pan_lfo.freq
      end
    end
  end
end

function lfos.turn_on_level(i)
  -- if all_loaded and the_one[i] == 1 then
  --   the_one[i] = _lfos.find_the_one(i,"level_lfo")
  -- end
  softcut.level_slew_time(i+1,0.01)
  softcut.level(i+1,0)
  local b = bank[i]
  if b.focus_hold == true then
    focused_pad[i] = b.focus_pad
  else
    focused_pad[i] = b.id
  end
  local f = focused_pad[i]
  b.level_lfo.active = true
  b.level_lfo.counter = lfos.find_the_one(i,"level_lfo") -- FIXME don't calculate this every fuckin time.
  -- b.level_lfo.counter = the_one[i]
  print(b.level_lfo.counter)
  b.level_lfo.slope = b[f].level
  if not b.level_lfo.active then
    -- softcut.level(_p_.bank+1,b[f].pan)
    b.level_lfo.counter = 1 -- TODO ERROR WHEN PATTERN IS GOING??
    b.level_lfo.slope = b[f].level
    -- params:set("pan slew ".._p_.bank,last_slew[_p_.bank])
    last_slew[_p_.bank] = nil
  end
end

function lfos.adjust_to_clock(target)
  for h = 1,#lfo_destinations do
    for i = 1,16 do
      bank[target][i][lfo_destinations[h]].freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[bank[target][i][lfo_destinations[h]].rate_index])
      if i == bank[target].focus_pad then
        bank[target][lfo_destinations[h]].freq = bank[target][i][lfo_destinations[h]].freq
      end
    end
  end
end

function lfos.freq_to_string(target,parameter)
  local _p_ = page.pans
  if bank[_p_.bank].focus_hold == true then
    focused_pad[_p_.bank] = bank[_p_.bank].focus_pad
  else
    focused_pad[_p_.bank] = bank[_p_.bank].id
  end
  return lfo_rates.names[bank[target][focused_pad[_p_.bank]][parameter].rate_index]
end

-- function _p.bpm_to_lfo(target,new_val)
--   pan_lfo[target].freq = 1/((clock.get_beat_sec()*4) * pan_lforates.values[new_val])
-- end

-- function _p.find(tbl, val)
--   for k, v in pairs(tbl) do
--       if v == val then return k end
--   end
--   return nil
-- end


return lfos