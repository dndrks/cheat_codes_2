-- hnds
--
-- Lua lfo's for script
-- parameters.
-- ----------
--
-- v0.5 @justmat + @dan_derks

local number_of_outputs = 3

local options = {
  lfotypes = {
    "sine",
    "sqr",
    "s+h"
  }
}

pan_lfo = {}
for i = 1, number_of_outputs do
  pan_lfo[i] = {
    freq = 1,
    counter = 1,
    waveform = options.lfotypes[1],
    slope = 0,
    depth = 100,
    offset = 0,
    enabled = false
  }
end

-- redefine in user script ---------
for i = 1, number_of_outputs do
  pan_lfo[i].lfo_targets = {"none"}
end

function lfo.process()
  print(pan_lfo[1].slope)
  -- print(pan_lfo[1].counter)
end
------------------------------------


function lfo.scale(old_value, old_min, old_max, new_min, new_max)
  -- scale ranges
  local old_range = old_max - old_min

  if old_range == 0 then
    old_range = new_min
  end

  local new_range = new_max - new_min
  local new_value = (((old_value - old_min) * new_range) / old_range) + new_min

  return new_value
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


function lfo.init()

  local lfo_metro = clock.run(function()
    while true do
      clock.sleep(0.01)
      for i = 1, number_of_outputs do
        -- if params:get(i .. "lfo") == 2 then
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
        -- end
      end
      lfo.process()
    end
  end)
  
end

function lfo.hz_to_bpm(target,bars)
  pan_lfo[target].freq = 1/((clock.get_beat_sec()*4) * bars)
  print(pan_lfo[target].freq)
  -- if 0.5s == 2 then
  -- 2 bars
  -- (clock.get_beat_sec()*4) * bars
  -- 1/((clock.get_beat_sec()*4) * bars)
end


return lfo