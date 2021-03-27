local lfos = {}

local focused_pad = {nil,nil,nil}
local last_slew = {nil,nil,nil}

function lfos.init()

  lfo_types =
  {
    "sine",
    "sqr",
    "s+h"
  }
  lfo_rates = {["names"] = {}, ["values"] = {}}
  lfo_rates.names = {
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
    elseif bank[id][bank[id].id][parameter].waveform == "s+h" then
      slope = make_sh(id,parameter)
    end
    bank[id][parameter].prev = slope
    bank[id][parameter].slope = math.max(-1.0, math.min(1.0, slope)) * (bank[id][parameter].depth * 0.01) + bank[id][parameter].offset
    bank[id][parameter].counter = bank[id][parameter].counter + bank[id][parameter].freq
    lfos.process(id,parameter)
  end
end

function lfos.process(id,parameter)
  if parameter == "pan_lfo" then
    softcut.pan(id+1, bank[id][parameter].slope)
    if menu == 4 and id == page.pans.bank then
      screen_dirty = true
    end
  end
end

function lfos.process_cheat(b,p)
  for i = 1,#lfo_destinations do
     bank[b][lfo_destinations[i]].active =  bank[b][p][lfo_destinations[i]].active
     bank[b][lfo_destinations[i]].counter = 1
     bank[b][lfo_destinations[i]].depth =  bank[b][p][lfo_destinations[i]].depth
     bank[b][lfo_destinations[i]].freq =  bank[b][p][lfo_destinations[i]].freq
     bank[b][lfo_destinations[i]].waveform =  bank[b][p][lfo_destinations[i]].waveform
     if lfo_destinations[i] == "pan_lfo" then
      bank[b][lfo_destinations[i]].slope = bank[b][p].pan
      bank[b][lfo_destinations[i]].offset = bank[b][p].pan
      softcut.pan(b+1,bank[b][p].pan)
     end
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
        if not b.pan_lfo.active then
          softcut.pan(_p_.bank+1,b[f].pan)
          b.pan_lfo[_p_.bank].counter = 1
          b.pan_lfo[_p_.bank].slope = b[f].pan
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