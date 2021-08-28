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
    for i = 1,8 do
      lfos.iterate(i,"macro_lfo")
    end
    for i = 1,2 do
      lfos.iterate(i,"delay_filter_lfo")
    end
  end
  lfo_metro:start()
end

local function make_sine(construct)
  -- print(((tau / 100) * (construct.counter)) - (tau / (construct.freq)))
  return math.sin(((tau / 100) * (construct.counter)) - (tau / (construct.freq)))
end

local function derive_sine(construct)

end


local function make_square(construct)
  return make_sine(construct) >= 0 and 1 or -1
end


local function make_sh(construct)
  local polarity = make_square(construct)
  if construct.prev_polarity ~= polarity then
    construct.prev_polarity = polarity
    return math.random() * (math.random(0, 1) == 0 and 1 or -1)
  else
    return construct.prev
  end
end

n_s = "inQuart"

local function make_complex(construct)
  -- print(easingFunctions["inQuart"](make_sine(n,parameter),0,1,1), easeinquart((make_sine(n,parameter))))
  return {easingFunctions[n_s](util.linlin(-1,1,0,1,make_sine(construct)),0,1,1),easeinbounce((make_sine(construct)))} -- these match...
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
  local current_value;
  if parameter == "pan_lfo" then
    current_value = bank[id][bank[id].id].pan
  end
  return (math.asin(current_value) + (tau/bank[id][parameter].freq))/(tau/100)
end

function lfos.respect_the_current(id,parameter)
  local current_value = bank[id][parameter].slope
  return (math.asin(current_value) + (tau/bank[id][parameter].freq))/(tau/100)
end

function lfos.iterate(id,parameter)
  -- want to basically pass the lfo metro ticker to the different lfos
  -- need to watch for oversaturattion -- does there need to be 10ms processing?
  -- at least stuff like pans shouldn't be sent to softcut every 10ms...
  if parameter ~= "macro_lfo" and parameter ~= "delay_filter_lfo" then
    if bank ~= nil and bank[id]~= nil and bank[id][parameter]~= nil and bank[id][parameter].active ~= nil then
      if bank[id][parameter].active then
        lfos.parse("banks",id,parameter)
      end
    end
  elseif parameter == "macro_lfo" then
    if macro[id].lfo.active then
      lfos.parse("macros",id,parameter)
    end
  elseif parameter == "delay_filter_lfo" then
    if delay ~= nil and delay[id].filter_lfo.active then
      lfos.parse("delays",id,parameter)
    end
  end
end

function lfos.parse(style,id,parameter)
  local construct;
  if style == "banks" then
    construct = bank[id][parameter]
  elseif style == "macros" then
    construct = macro[id].lfo
  elseif style == "delays" then
    construct = delay[id].filter_lfo
  end
  local slope;
  construct.prev_slope = construct.slope
  if construct.waveform == "sine" then
    slope = make_sine(construct)
  elseif construct.waveform == "sqr" then
    slope = make_square(construct)
  elseif construct.waveform == "s+h" then
    slope = make_sh(construct)
  elseif construct.waveform == "complex" then
    slope = make_complex(construct)[1]
    print(slope,make_complex(construct)[2])
  end
  if not construct.loop then
    if util.round(1 * math.sin(((tau / 100) * (construct.counter)) - (tau / (construct.freq))),0.1) <=  0 then
      construct.active = false
      goto continue
    end
  end
  construct.prev = slope
  construct.slope = math.max(-1.0, math.min(1.0, slope)) * (construct.depth * 0.01) + construct.offset
  construct.counter = construct.counter + construct.freq
  lfos.process(id,parameter)
  ::continue::
  if not construct.active then
    print("it's here...")
    lfos.zero_out(id,parameter)
    screen_dirty = true
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
    if util.round(bank[id][parameter].prev_slope,0.05) ~= util.round(bank[id][parameter].slope,0.05) then
      softcut.pan(id+1, bank[id][parameter].slope)
      if menu == 4 and id == page.pans.bank then
        screen_dirty = true
      end
    end
  elseif parameter == "level_lfo" then
    local highest_to_lowest = util.linlin(-1,1,0,bank[id].global_level,bank[id][parameter].slope) -- this is so super important!
    if util.round(bank[id][parameter].prev_slope,0.05) ~= util.round(bank[id][parameter].slope,0.05) then
      if not bank[id][bank[id].id].enveloped then
        softcut.level(id+1,bank[id][bank[id].id].level * _l.get_global_level(id))
        softcut.level_cut_cut(id+1,5,(bank[id][bank[id].id].left_delay_level*bank[id][bank[id].id].level)*_l.get_global_level(id))
        softcut.level_cut_cut(id+1,6,(bank[id][bank[id].id].right_delay_level*bank[id][bank[id].id].level)*_l.get_global_level(id))
      end
      -- print(highest_to_lowest)
      -- softcut.level(id+1,bank[id][bank[id].id].level * highest_to_lowest)
      -- softcut.level(id+1,bank[id][bank[id].id].level * _l.get_global_level(id))
    end
  elseif parameter == "filter_lfo" then
    softcut.post_filter_fc(id+1,util.linlin(-1,1,8000,12000,bank[id][parameter].slope))
  elseif parameter == "macro_lfo" then
    macros.lfo_process(id,macro[id].lfo.slope)
  elseif parameter == "delay_filter_lfo" then
    del.lfo_process(id,"filter",delay[id].filter_lfo.slope)
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

  end
end

function lfos.process_encoder(n,d,target,parameter)
  if target == "pan_lfo" then
    local _p_ = page.pans
    local focused;
    if bank[_p_.bank].focus_hold == true then
      focused_pad[_p_.bank] = bank[_p_.bank].focus_pad
      focused = true
    else
      focused_pad[_p_.bank] = bank[_p_.bank].id
      focused = false
    end
    local b = bank[_p_.bank]
    local f = focused_pad[_p_.bank]
    
    if parameter == "LFO" then
      local pre_active = b[f].pan_lfo.active
      b[f].pan_lfo.active = d > 0 and true or false
      if not focused then
        params:set("pan_lfo_active_".._p_.bank,d > 0 and 2 or 1)
      end

      if b.id == f then
        if pre_active ~= b[f].pan_lfo.active then
          b.pan_lfo.counter = lfos.find_the_current(_p_.bank,target)
          b.pan_lfo.active = b[f].pan_lfo.active
          b.pan_lfo.slope = b[f].pan
        end
        if not b.pan_lfo.active then
          softcut.pan(_p_.bank+1,b[f].pan)
          b.pan_lfo.slope = b[f].pan
        end
      end
    elseif parameter == "SHP" then
      local current_index = tab.key(lfo_types,b[f].pan_lfo.waveform)
      current_index = util.clamp(current_index + d,1,#lfo_types)
      b[f].pan_lfo.waveform = lfo_types[current_index]
      if not focused then
        params:set("pan_lfo_waveform_".._p_.bank,current_index)
      end
      if b.id == f then
        b.pan_lfo.waveform = b[f].pan_lfo.waveform
      end
    elseif parameter == "DPTH" then
      b[f].pan_lfo.depth = util.clamp(b[f].pan_lfo.depth + d,1,200)
      if not focused then
        params:set("pan_lfo_depth_".._p_.bank,b[f].pan_lfo.depth)
      end
      if b.id == f then
        b.pan_lfo.depth = b[f].pan_lfo.depth
      end
    elseif parameter == "RATE" then
      b[f].pan_lfo.rate_index = util.clamp(b[f].pan_lfo.rate_index + d,1,#lfo_rates.values)
      b[f].pan_lfo.freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[b[f].pan_lfo.rate_index])
      if not focused then
        params:set("pan_lfo_rate_".._p_.bank,b[f].pan_lfo.rate_index)
      end
      if b.id == f then
        b.pan_lfo.freq = b[f].pan_lfo.freq
        b.pan_lfo.counter = lfos.respect_the_current(_p_.bank,"pan_lfo")
      end
    end

  elseif target == "macro_lfo" then

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