-- cheat codes: yellow
--          a sample playground
-- rev: 210701
-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
-- need help?
-- please visit:
-- l.llllllll.co/cheat-codes-yellow
-- -------------------------------

if util.file_exists(_path.code.."passthrough") then
  local passthru = include 'passthrough/lib/passthrough'
  passthru.init()
end

function developer_mode()
  params:set("rec_loop_1",2)
  params:set("one_shot_clock_div",4)
  params:set("one_shot_threshold",70)
end

if util.file_exists(_path.code.."namesizer") then
  Namesizer = include 'namesizer/lib/namesizer'
end

local grid = util.file_exists(_path.code.."midigrid") and include "midigrid/lib/midigrid" or grid

function push_to_cc2(encoder, d)
  -- translate the bank of 8 encoders to whatever params you want!
  local param_map = 
  {
    [1] = "macro 1"
  , [2] = nil
  , [3] = nil
  , [4] = nil
  , [5] = nil
  , [6] = nil
  , [7] = nil
  , [8] = nil
  }
  if param_map[encoder] ~= nil then
    params:delta(param_map[encoder], d == 1 and 1 or -1)
  end
end

if util.file_exists(_path.code.."mx.samples") then
  -- mxsamples = include 'mx.samples/lib/mx.samples'
  -- engine.name = "MxSamples"
  -- mxcc = mxsamples:new()
  -- print("available instruments: ")
  -- tab.print(mxcc:list_instruments())
end

function deep_copy(orig)
  local orig_type = type(orig)
  local copy;
  if orig_type == "table" then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deep_copy(orig_key)] = deep_copy(orig_value)
    end
    setmetatable(copy, deep_copy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

local pattern_time = include 'lib/cc_pattern_time'
MU = require "musicutil"
UI = require "ui"
lattice = require "lattice"
fileselect = require 'fileselect'
textentry = require 'textentry'
_ca = include 'lib/clip_actions'
_lfos = include 'lib/lfos'
main_menu = include 'lib/main_menu'
encoder_actions = include 'lib/encoder_actions'
arc_actions = include 'lib/arc_actions'
rightangleslice = include 'lib/zilchmos'
start_up = include 'lib/start_up'
speed_dial = include 'lib/_menus/speed_dial'
grid_actions = include 'lib/grid_actions'
easingFunctions = include 'lib/easing'
arps = include 'lib/arp_actions'
-- rnd = include 'lib/rnd_actions'
del = include 'lib/delay'
rytm = include 'lib/euclid'
mc = include 'lib/midicheat'
filters = include 'lib/filters'
-- sharer = include 'lib/sharer'
macros = include 'lib/macros'
transport = include 'lib/transport'
_gleds = include 'lib/grid_leds'
p_gate = include 'lib/p_gate'
_dough = include 'lib/doughstretch'
_ps = include 'lib/speed_dial_pages/pattern_saver'
_fs = include 'lib/speed_dial_pages/filter_saver'
_live = include 'lib/livecode'
math.randomseed(os.time())
variable_fade_time = 0.01
--with positive playback rates, the buffer is actually read from / written to up to (loop end + fade time).
-- with negative rates, up to (loop start - fade time).
splash_done = true
softcut_voices_are_paused = {false,false,false}

function wrap(n, min, max)
  if max >= min then
    local y = n
    local d = max - min + 1
    while y > max do
      y = y - d
    end
    while y < min do
      y = y + d
    end
    return y
  else
    error("max needs to be greater than min")
  end
end

macro = {}
for i = 1,8 do
  macro[i] = macros.new_macro()
end

held_keys = {}
for i = 1,3 do
  held_keys[i] = {}
end

p_gate.init()
_ps.init()
_fs.init()

function rec_ended_callback()
  -- for i = 1,3 do
  --   if bank[i].id == 1 then
  --     cheat(i,1)
  --   end
  -- end
end

function make_a_gif(filename,time)
  local steps = time*24
  local gif_step = 1
  local dirnames = {"/home/we/dust/tmp", "/home/we/dust/tmp/frames"}
  for i = 1,2 do
    if os.rename(dirnames[i], dirnames[i]) == nil then
      os.execute("mkdir " .. dirnames[i])
    end
  end
  while gif_step <= steps do
    _norns.screen_export_png("/home/we/dust/tmp/frames/"..string.format("%04d",gif_step)..".gif")
    gif_step = gif_step + 1
    clock.sleep(1/24)
  end
  print("creating gif...")
  os.execute("convert -delay "..(100/24).." -dispose previous -loop 0 /home/we/dust/tmp/frames/*.gif "..'home/we/dust/gifs/'..filename..'.gif')
  -- print("converting gif...")
  -- os.execute("convert home/we/dust/image.gif -gamma 1.25 -filter point -resize 400% -gravity center -background black -extent 120% home/we/dust/image.gif")
  os.execute("rm -r /home/we/dust/tmp/frames/")
  print("done!")
end

function screenshot()
  if recording_screen then
  -- os.execute("mkdir /home/we/dust/tmp")
  -- os.execute("mkdir /home/we/dust/tmp/frames")
  -- local which_screen = string.match(string.match(string.match(norns.state.script,"/home/we/dust/code/(.*)"),"/(.*)"),"(.+).lua")
  -- _norns.screen_export_png("/home/we/dust/"..which_screen.."-"..os.time()..".png")
    _norns.screen_export_png("/home/we/dust/"..gif_step..".png")
    gif_step = gif_step + 1
  end
end

-- waveform stuff
local interval = 0
waveform_samples = {}
bank_waveform_scale = 20
live_waveform_scale = 20
waveform_scale = 25

function on_render(ch, start, i, s)
  -- cursor = util.clamp(cursor, 1, #s)
  waveform_samples = s
  interval = i
  -- if menu ~= 1 then screen_dirty = true end
  if ch == 2 then
    if start < 33 then
      clip[1].waveform_samples = s
    elseif start < 65 then
      clip[2].waveform_samples = s
    else
      clip[3].waveform_samples = s
    end
  elseif ch == 1 then
    if start < live[2].min then
      rec[1].waveform_samples = s
    elseif start < live[3].min then
      rec[2].waveform_samples = s
    else
      rec[3].waveform_samples = s
    end
  end
    
end

function update_waveform(buffer,winstart,winend,samples)
  -- softcut.render_buffer(buffer, winstart+variable_fade_time, (winend - winstart)-variable_fade_time, 128)
  softcut.render_buffer(buffer, winstart, (winend - winstart), 128)
end

--/ waveform stuff

function r()
  norns.script.load(norns.state.script)
end

tau = math.pi * 2
arc_param = {}
arc_switcher = {}
for i = 1,3 do
  arc_param[i] = 1
  --arc_switcher[i] = 0
  arc_switcher[i] = {}
end
arc_control = {}
for i = 1,3 do
  arc_control[i] = i
end
arc_meta_focus = 1

arc_offset = 0 --IMPORTANT TO REVISIT

clip = {}
for i = 1,3 do
  clip[i] = {}
  clip[i].length = 90
  clip[i].sample_length = 8
  clip[i].start_point = nil
  clip[i].end_point = nil
  clip[i].mode = 1
  clip[i].waveform_samples = {}
  clip[i].waveform_rendered = false
  clip[i].channel = 1
  clip[i].collage = false
end

pre_cc2_sample = { false, false, false }

clip[1].min = 1
clip[1].max = 1 + clip[1].sample_length
clip[2].min = 33
clip[2].max = clip[2].min + clip[2].sample_length
clip[3].min = 65
clip[3].max = clip[3].min + clip[3].sample_length

live = {}
for i = 1,3 do
  live[i] = {}
  live[i].waveform_samples = {}
end
live[1].min = 1
live[1].max = 33
live[2].min = 33
live[2].max = 65
live[3].min = 65
live[3].max = 97

SOS_recording = {}
for i = 1,3 do
  SOS_recording[i] = false
end

help_menu = "welcome"

pattern_saver = { {},{},{} }
for i = 1,3 do
  pattern_saver[i].active = false
  pattern_saver[i].source = i
  pattern_saver[i].save_slot = nil
  pattern_saver[i].load_slot = 0
  pattern_saver[i].saved = {}
  pattern_saver[i].clock = nil
  for j = 1,8 do
    pattern_saver[i].saved[j] = 0
  end
end

pattern_deleter = { {},{},{} }
for i = 1,3 do
  pattern_deleter[i].active = false
  pattern_deleter[i].clock = nil
end

env_counter = {}
for i = 1,3 do
  env_counter[i] = metro.init()
  env_counter[i].time = 0.01
  env_counter[i].butt = 1
  env_counter[i].l_del_butt = 0
  env_counter[i].r_del_butt = 0
  env_counter[i].stage = nil
  -- env_counter[i].mode = 1 -- this needs to be per pad!!
  env_counter[i].event = function() envelope(i) end
end

slew_counter = {}

for i = 1,3 do
  slew_counter[i] = metro.init()
  slew_counter[i].time = 0.01
  slew_counter[i].count = 100
  slew_counter[i].current = 0.00
  slew_counter[i].event = function() easing_slew(i) end
  slew_counter[i].ease = easingFunctions.inSine
  slew_counter[i].beginVal = 0
  slew_counter[i].endVal = 1
  slew_counter[i].change =  slew_counter[i].endVal - slew_counter[i].beginVal
  slew_counter[i].beginQ = 0
  slew_counter[i].endQ = 0
  slew_counter[i].changeQ = slew_counter[i].endQ - slew_counter[i].beginQ
  slew_counter[i].duration = (slew_counter[i].count/100)-0.01
  slew_counter[i].slewedVal = 0
  slew_counter[i].prev_tilt = 0
  slew_counter[i].next_tilt = 0
  slew_counter[i].prev_q = 0
  slew_counter[i].next_q = 0
end

quantize = 1
quantize_events = {}
for i = 1,3 do
  quantize_events[i] = {}
end

grid_pat_quantize = 1
grid_pat_quantize_events = {}
for i = 1,3 do
  grid_pat_quantize_events[i] = {}
end

--[[
grid_pat_quantizer = {}
for i = 1,3 do
  grid_pat_quantizer[i] = {}
  grid_pat_quantizer[i] = metro.init()
  grid_pat_quantizer[i].time = 0.25
  grid_pat_quantizer[i].count = -1
  --grid_pat_quantizer[i].event = function() grid_pat_q_clock(i) end
  grid_pat_quantizer[i].event = function() end
  grid_pat_quantizer[i]:start()
end
--]]

function cheat_clock_synced(i)
  if tab.count(quantize_events[i]) > 0 then
    cheat(quantize_events[i].bank,quantize_events[i].pad)
      local kill_this = quantize_events[i].pad
      clock.run(function()
        clock.sync(1/4)
        if not tab.contains(held_keys[i],kill_this) then
          grid_actions.kill_note(i,kill_this)
        end
      end
      )
    quantize_events[i] = {}
  end
end

function how_many_bars(bank)
  local total_pattern_time = 0
  for i = 1,#grid_pat[bank].event do
    total_pattern_time = total_pattern_time + grid_pat[bank].time[i]
  end
  local time_per_bar = clock.get_beat_sec()*4
  local this_many_bars = math.floor((total_pattern_time/time_per_bar)+0.5)
  -- need at least ONE bar, so...
  if this_many_bars == 0 then this_many_bars = 1 end
  return this_many_bars
end

function better_grid_pat_q_clock(i)
  if grid_pat[i].rec == 1 then
    grid_actions.rec_stop(i)
    midi_clock_linearize(i)
    grid_pat[i].loop = 1
    if grid_pat[i].count > 0 then
      grid_pat[i].tightened_start = 1
      if grid_pat[i].auto_snap == 1 then
        print("auto-snap")
        snap_to_bars(i,how_many_bars(i))
      end
    end
  elseif grid_pat[i].count == 0 then
    grid_pat[i]:rec_start()
  elseif grid_pat[i].play == 1 then
    -- grid_pat[i]:stop()
    stop_pattern(grid_pat[i])
  elseif grid_pat[i].tightened_start == 1 then
    grid_pat[i].tightened_start = 0
    grid_pat[i].step = grid_pat[i].start_point
    quantized_grid_pat[i].current_step = grid_pat[i].start_point
    quantized_grid_pat[i].sub_step = 1
  else
    grid_pat[i].tightened_start = 1
  end
end

function snap_to_bars(bank,bar_count)
  if grid_pat[bank].rec == 0 and grid_pat[bank].count > 0 then 
    local total_time = 0
    for i = 1,#grid_pat[bank].event do
      total_time = total_time + grid_pat[bank].time[i]
    end
    print("before total: "..total_time)
    if old_pat_time == nil then
      old_pat_time = table.clone(grid_pat[bank].time)
    end
    local bar_time = ((clock.get_beat_sec()*4)*bar_count)/total_time
    for k = 1,grid_pat[bank].count do
      grid_pat[bank].time[k] = grid_pat[bank].time[k] * bar_time
    end
    total_time = 0
    for i = 1,#grid_pat[bank].event do
      total_time = total_time + grid_pat[bank].time[i]
    end
    print("after total: "..total_time)
    snap_to_bars_midi(bank,bar_count)
  end
end

local snakes = 
{ [1] = { 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16 }
, [2] = { 1,2,3,4,8,7,6,5,9,10,11,12,16,15,14,13 }
, [3] = { 1,5,9,13,2,6,10,14,3,7,11,15,4,8,12,16 }
, [4] = { 1,5,9,13,14,10,6,2,3,7,11,15,16,12,8,4 }
, [5] = { 1,2,3,4,8,12,16,15,14,13,9,5,6,7,11,10 }
, [6] = { 13,14,15,16,12,8,4,3,2,1,5,9,10,11,7,6 }
, [7] = { 1,2,5,9,6,3,4,7,10,13,14,11,8,12,15,16 }
, [8] = { 1,6,11,16,15,10,5,2,7,12,8,3,9,14,13,4 }
}

function random_grid_pat(which,mode)

  local pattern = grid_pat[which]

  -- if pattern.playmode == 1 then
  --   pattern.playmode = 2
  --   pattern.rec_clock_time = 8
  -- end
  
  if mode == 1 then
    for i = #pattern.time,2,-1 do
      local j = math.random(i)
      pattern.time[i], pattern.time[j] = pattern.time[j], pattern.time[i]
    end
  elseif mode == 2 then
    stop_pattern(pattern)
    for i = #pattern.event,2,-1 do
      local j = math.random(i)
      local original, shuffled = pattern.event[i], pattern.event[j]
      if original ~= "pause" and shuffled ~= "pause" then
        original.id, shuffled.id = shuffled.id, original.id
        original.rate, shuffled.rate = shuffled.rate, original.rate
        original.loop, shuffled.loop = shuffled.loop, original.loop
        original.mode, shuffled.mode = shuffled.mode, original.mode
        original.pause, shuffled.pause = shuffled.pause, original.pause
        original.start_point, shuffled.start_point = shuffled.start_point, original.start_point
        original.clip, shuffled.clip = shuffled.clip, original.clip
        original.end_point = original.end_point
        original.rate_adjusted, shuffled.rate_adjusted = shuffled.rate_adjusted, original.rate_adjusted
        original.y, shuffled.y = shuffled.y, original.y
        original.x, shuffled.x = shuffled.x, original.x
        original.action, shuffled.action = shuffled.action, original.action
        original.i, shuffled.i = shuffled.i, original.i
        original.previous_rate, shuffled.previous_rate = shuffled.previous_rate, original.previous_rate
        original.row, shuffled.row = shuffled.row, original.row
        original.con, shuffled.con = shuffled.con, original.con
        original.bank, shuffled.bank = shuffled.bank, original.bank
      else
        original, shuffled = shuffled, original
      end
    end
  elseif mode == 3 then
    local auto_pat = params:get("random_patterning_"..which)
    if auto_pat ~= 1 then
      params:set("pattern_"..which.."_quantization", 2)
      local vals_to_dur = {4,8,16,32,64,math.random(4,32)}
      local note_val = params:get("rand_pattern_"..which.."_note_length")
      pattern.rec_clock_time = vals_to_dur[note_val]
    end
    if pattern.playmode == 3 or pattern.playmode == 4 then
      pattern.playmode = 2
    end
    local potential_total = pattern.rec_clock_time*4
    -- local count = auto_pat == 1 and math.random(2,24) or 16
    -- local count = auto_pat == 1 and (pattern.rec_clock_time * 4) or 16
    local count = auto_pat == 1 and (pattern.rec_clock_time * 8) or 32
    if pattern.count > 0 or pattern.rec == 1 then
      grid_actions.rec_stop(which)
      stop_pattern(pattern)
      pattern.tightened_start = 0
      pattern:clear()
      pattern_saver[which].load_slot = 0
    end
    pattern.rand_generated = true
    pattern.rand_step_count = 0
    for i = 1,count do
      pattern.event[i] = {}
      local constructed = pattern.event[i]
      if i%2 == 1 then
        constructed.id = auto_pat == 1 and math.random(1,16) or snakes[auto_pat-1][i]
      else
        constructed.id = pattern.event[i-1].id
      end
      if i%2 == 1 then
        constructed.id = constructed.id
        local assigning_pad = bank[which][constructed.id]
        local new_rates = 
        { [1] = math.pow(2,math.random(-3,-1))*((math.random(1,2)*2)-3)
        , [2] = math.pow(2,math.random(-1,1))*((math.random(1,2)*2)-3)
        , [3] = math.pow(2,math.random(1,2))*((math.random(1,2)*2)-3)
        , [4] = math.pow(2,math.random(-2,2))*((math.random(1,2)*2)-3)
        , [5] = assigning_pad.rate
        }
        constructed.rate = new_rates[pattern.random_pitch_range]
        local pre_rate = assigning_pad.rate
        assigning_pad.rate = constructed.rate
        local new_levels = 
        { [0.125] = 1.75
        , [0.25]  = 1.5
        , [0.5]   = 1.25
        , [1.0]   = 1.0
        , [2.0]   = 0.75
        , [4.0]   = 0.5
        }
        if pre_rate == assigning_pad.rate then
          assigning_pad.level = assigning_pad.level
        else
          assigning_pad.level = assigning_pad.level == 0 and 0 or new_levels[math.abs(constructed.rate)]
        end
        constructed.loop = assigning_pad.loop
        constructed.mode = assigning_pad.mode
        constructed.pause = assigning_pad.pause
        constructed.start_point = (math.random(10,75)/10)+(32*(assigning_pad.clip-1))
        constructed.clip = assigning_pad.clip
        constructed.end_point = constructed.start_point + (math.random(1,15)/10)
        constructed.rate_adjusted = false
        assigning_pad.fifth = false
        constructed.x = (5*(which-1)+1)+(math.ceil(constructed.id/4)-1)
        if (constructed.id % 4) ~= 0 then
          constructed.y = 9-(constructed.id % 4)
        else
          constructed.y = 5
        end
        constructed.action = "pads"
        constructed.i = which

        local tempo = clock.get_beat_sec()
        local divisors = { 4,2,1,0.5,0.25,math.pow(2,math.random(-2,2)) }
        local note_length = (tempo / divisors[params:get("rand_pattern_"..which.."_note_length")])
        pattern.time[i] = note_length
        pattern.time_beats[i] = pattern.time[i] / tempo
        pattern:calculate_quantum(i)
      else
        constructed.id = constructed.id
        constructed.i = which
        constructed.action = "pads-release"
        local tempo = clock.get_beat_sec()
        local divisors = { 4,2,1,0.5,0.25,math.pow(2,math.random(-2,2)) }
        local note_length = (tempo / divisors[params:get("rand_pattern_"..which.."_note_length")])
        pattern.time[i] = 0.01
        pattern.time_beats[i] = pattern.time[i] / tempo
        -- pattern:calculate_quantum(i)
      end
    end
    pattern.count = count
    pattern.start_point = 1
    pattern.end_point = count
  end
  midi_clock_linearize(which)
  if pattern.quantize == 0 then
    if pattern.auto_snap == 1 then
      print("auto-snap")
      snap_to_bars(which,how_many_bars(which))
    end
    start_pattern(pattern)
    pattern.loop = 1
  else
    pattern.loop = 1
    if pattern.count > 0 then
      pattern.tightened_start = 1
      if pattern.auto_snap == 1 then
        print("auto-snap")
        snap_to_bars(which,how_many_bars(which))
      end
    end
  end
end

function print_my_g_p_q(bank)
  for i = #quantized_grid_pat[bank].event,1,-1 do
    print(i)
    tab.print(quantized_grid_pat[bank].event[i])
  end
end

function snap_to_bars_midi(bank,bar_count)
  local entry_count = 0
  local target_entry_count = bar_count*16
  for i = 1,#quantized_grid_pat[bank].event do
    entry_count = entry_count + #quantized_grid_pat[bank].event[i]
  end
  print("before trimming midi event count: "..entry_count)
  if entry_count < target_entry_count then
    for i = 1,target_entry_count-entry_count do
      table.insert(quantized_grid_pat[bank].event[#quantized_grid_pat[bank].event],"nothing")
    end
  elseif entry_count > target_entry_count then
    --print("subtracting...")
    local last_event = #quantized_grid_pat[bank].event
    local last_group = #quantized_grid_pat[bank].event
    --print("last event: "..last_event)
    local distance_count = entry_count - target_entry_count
    print("removing "..distance_count.." event")
    local current_count = 0
    
    while current_count < distance_count do
      if last_group > 0 then
        if #quantized_grid_pat[bank].event[last_group] > 1 and quantized_grid_pat[bank].event[last_group][#quantized_grid_pat[bank].event[last_group]] == "nothing" then
          local check_table = #quantized_grid_pat[bank].event
          --print("removing: "..quantized_grid_pat[bank].event[last_group][#quantized_grid_pat[bank].event[last_group]].." from group "..last_group..", entry "..#quantized_grid_pat[bank].event[last_group])
          table.remove(quantized_grid_pat[bank].event[last_group])
          current_count = current_count + 1
          if current_count == distance_count then print("done now!") break end
          --print("current count :" .. current_count)
        elseif #quantized_grid_pat[bank].event[last_group] == 1 and quantized_grid_pat[bank].event[last_group][#quantized_grid_pat[bank].event[last_group]] == "something" then
          --print("skipping: "..quantized_grid_pat[bank].event[last_group][#quantized_grid_pat[bank].event[last_group]].." from group "..last_group..", entry "..#quantized_grid_pat[bank].event[last_group])
          last_group = last_group - 1
        elseif #quantized_grid_pat[bank].event[last_group] == 1 and quantized_grid_pat[bank].event[last_group][#quantized_grid_pat[bank].event[last_group]] == "nothing" then
          --print("there's only nothing in group "..last_group..", but removing it")
          table.remove(quantized_grid_pat[bank].event[last_group])
          --print_my_g_p_q(1)
          current_count = current_count + 1
          if current_count == distance_count then print("done now!") break end
          --print("current count :" .. current_count)
          last_group = last_group - 1
        elseif quantized_grid_pat[bank].event[last_group][#quantized_grid_pat[bank].event[last_group]] == nil then
          --print("A NIL IN"..last_group)
          table.remove(quantized_grid_pat[bank].event,last_group)
          last_group = last_group - 1
          --break
        end
      elseif last_group == 0 then
        --print("still got some left!!!: "..current_count.." / "..distance_count)
        table.remove(quantized_grid_pat[bank].event)
        current_count = current_count + 1
      end
    end
    quantized_grid_pat[bank].current_step = grid_pat[bank].start_point
    quantized_grid_pat[bank].sub_step = 1
  end
  
  local entry_count = 0
  for i = 1,#quantized_grid_pat[bank].event do
    entry_count = entry_count + #quantized_grid_pat[bank].event[i]
  end
  print("after trimming midi event count: "..entry_count)
  if entry_count ~= target_entry_count then
    --doubletap? is this ok??
    snap_to_bars_midi(bank,bar_count)
  end
end

function copy_entire_pattern(bank)
  original_pattern = {}
  original_pattern[bank] = {}
  original_pattern[bank].time = table.clone(grid_pat[bank].time)
  original_pattern[bank].event = {}
  for i = 1,#grid_pat[bank].event do
    original_pattern[bank].event[i] = {}
    -- new stuff!
    if grid_pat[bank].event[i] ~= "pause" then
      for k,v in pairs(grid_pat[bank].event[i]) do
        original_pattern[bank].event[i][k] = v
      end
    else
      original_pattern[bank].event[i] = "pause"
    end
  end
  original_pattern[bank].quantum = {}
  for k,v in pairs(grid_pat[bank].quantum) do
    original_pattern[bank].quantum[k] = v
  end
  original_pattern[bank].time_beats = {}
  for k,v in pairs(grid_pat[bank].time_beats) do
    original_pattern[bank].time_beats[k] = v
  end
  -- /new stuff!
  original_pattern[bank].metro = {}
  original_pattern[bank].metro.props = {}
  original_pattern[bank].metro.props.time = grid_pat[bank].metro.props.time
  original_pattern[bank].prev_time = grid_pat[bank].prev_time
  original_pattern[bank].count = grid_pat[bank].count
  original_pattern[bank].start_point = grid_pat[bank].start_point
  original_pattern[bank].end_point = grid_pat[bank].end_point
  original_pattern[bank].mode = grid_pat[bank].mode
  -- new stuff
  original_pattern[bank].rec_clock_time = grid_pat[bank].rec_clock_time
  --/ new stuff
  if grid_pat[bank].playmode ~= nil then
    if grid_pat[bank].playmode ~= 1 then
      original_pattern[bank].playmode = 2
    else
      original_pattern[bank].playmode = 1
    end
  else
    original_pattern[bank].playmode = 1
  end
end

function copy_metatable(obj)
  if type(obj) ~= 'table' then return obj end
  local res = setmetatable({}, getmetatable(obj))
  for k, v in pairs(obj) do res[copy_metatable(k)] = copy_metatable(v) end
  return res
end

function commit_midi_to_disk(target)

end

function update_pattern_bpm(bank)
  grid_pat[bank].time_factor = 1*(synced_to_bpm/params:get("clock_tempo"))
end

function table.clone(org)
  return {table.unpack(org)}
end

function calc_rec_clock_time(target)
  local total_time = 0
  for i = 1,#grid_pat[target].time_beats do
    total_time = total_time + grid_pat[target].time_beats[i]
  end
  grid_pat[target].rec_clock_time = util.round(total_time)
end

function unpack_quantized_table(target)
  for i = 1,#quantized_grid_pat[target].event do
    grid_pat[target].quantum[i] = #quantized_grid_pat[target].event[i] * 0.25
    grid_pat[target].time_beats[i] = grid_pat[target].time[i] / clock.get_beat_sec()
  end
  calc_rec_clock_time(target)
end

function midi_clock_linearize(bank)
  -- quantized_grid_pat[bank].event = {}
  -- for i = 1,grid_pat[bank].count do
  --   quantized_grid_pat[bank].clicks[i] = math.floor((grid_pat[bank].time[i] / (clock.get_beat_sec()/4))+0.5)
  --   quantized_grid_pat[bank].event[i] = {} -- critical
  --   if grid_pat[bank].time[i] == 0 or quantized_grid_pat[bank].clicks[i] == 0 then
  --     quantized_grid_pat[bank].event[i][1] = "nothing"
  --   else
  --     for j = 1,quantized_grid_pat[bank].clicks[i] do
  --       if j == 1 then
  --         quantized_grid_pat[bank].event[i][1] = "something"
  --       else
  --         quantized_grid_pat[bank].event[i][j] = "nothing"
  --       end
  --     end
  --   end
  -- end
  -- quantized_grid_pat[bank].current_step = grid_pat[bank].start_point
  -- quantized_grid_pat[bank].sub_step = 1
  print("see line 737 -- midi_clock_linearize")
end

function midi_clock_linearize_overdub(bank)
  local curr = quantized_grid_pat[bank].current_step + 1
  local sub = quantized_grid_pat[bank].sub_step
  local removed = #quantized_grid_pat[bank].event[quantized_grid_pat[bank].current_step] - quantized_grid_pat[bank].sub_step
  for i = quantized_grid_pat[bank].sub_step,#quantized_grid_pat[bank].event[quantized_grid_pat[bank].current_step] do
    table.remove(quantized_grid_pat[bank].event[curr-1],sub)
  end
  table.insert(quantized_grid_pat[bank].event,curr,{"something"})
  if removed ~= 0 then
    for i = 1,removed do
      table.insert(quantized_grid_pat[bank].event[curr],"nothing")
    end
  end
  if quantized_grid_pat[bank].current_step < grid_pat[bank].end_point then
    quantized_grid_pat[bank].current_step = quantized_grid_pat[bank].current_step + 1
  else
    quantized_grid_pat[bank].current_step = 1
  end
  quantized_grid_pat[bank].sub_step = 1
end

key1_hold = false
key1_hold_and_modify = false
key2_hold_counter = metro.init()
key2_hold_counter.time = 0.25
key2_hold_counter.count = 1
key2_hold_counter.event = function()
  key2_hold = true
  if menu == 2 then
    _loops.key2_activate()
  elseif menu == 9 then
    screen_dirty = true
  elseif menu == "MIDI_config" then
    screen_dirty = true
  end
end

key2_hold = false
key2_hold_and_modify = false

grid_alt = false
-- grid.alt_pp = 0
-- grid.alt_delay = false
grid_loop_mod = 0

local function crow_flush()
  crow.reset()
  crow.clear()
end

local function crow_init()
  -- for i = 1,4 do
  --   crow.output[i].action = "{to(5,0),to(0,0.05)}"
  --   print("output["..i.."] initialized")
  -- end
  crow.input[2].mode("change",2,0.1,"rising")
  crow.input[2].change = _ca.buff_freeze
end

local function process_stream_1(v)
  params:set("macro 1",util.round(util.linlin(0,params:get("crow input 1 max voltage"),0,127,v)))
end

local function process_stream_2(v)
  params:set("macro 2",util.round(util.linlin(0,params:get("crow input 2 max voltage"),0,127,v)))
end

function set_crow_input(id,type)
  if type == 3 then
    crow.input[id].mode("stream",0.05)
    if id == 1 then
      crow.input[1].stream = process_stream_1
    elseif id == 2 then
      crow.input[2].stream = process_stream_2
    end
  elseif type == 2 then
    crow.input[id].mode("change",2,0.1,"rising")
    crow.input[id].change = _ca.buff_freeze
  elseif type == 4 then
    crow.input[id].mode("change",2,0.1,"rising")
    crow.input[id].change = transport.crow_toggle
  elseif type == 5 then
    crow.input[id].mode("change",2,0.1,"both")
    crow.input[id].change = transport.crow_toggle
  elseif type == 6 then
    crow.input[id].mode("change",2,0.1,"rising")
    crow.input[id].change = transport.crow_toggle_now
  elseif type == 1 then
    crow.input[id].mode('none')
  end
end

zilch_leds =
{   [1] = {{0},{0},{0}}
  , [2] = {{0,0},{0,0},{0,0}}
  , [3] = {{0,0,0},{0,0,0},{0,0,0}}
  , [4] = {{0,0,0,0},{0,0,0,0},{0,0,0,0}}
}

function init()

  amp_in = {}
  local amp_src = {"amp_in_l","amp_in_r"}
  for i = 1,2 do
    amp_in[i] = poll.set(amp_src[i])
    amp_in[i].time = 0.01
    amp_in[i].callback = function(val)
      if val > params:get("one_shot_threshold")/10000 then
        if rec[rec.focus].state == 0 then
          _ca.toggle_buffer(rec.focus)
        end
        amp_in[i]:stop()
      end
    end
  end

  -- sharer.setup("cheat_codes_yellow")

  clock.run(check_page_for_k1)

  collection_loaded = false

  all_loaded = false

  for i = 1,3 do
    norns.enc.sens(i,2)
  end
  
  grid_p = {}
  arc_p = {}
  midi_p = {}
  
  rec = {}
  rec.state = 1
  rec.pause = false
  rec.clip = 1
  rec.start_point = 1
  rec.end_point = 9
  rec.loop = 1
  rec.clear = 0
  rec.rate_offset = 1.0
  rec.stopped = false
  rec.play_segment = 1

  rec.focus = 1

  for i = 1,3 do
    rec[i] = {}
    rec[i].state = 0
    rec[i].pause = false
    rec[i].clip = 1
    rec[i].start_point = live[i].min
    rec[i].end_point = live[i].max
    rec[i].loop = 1
    rec[i].clear = 1
    rec[i].rate_offset = 1.0
    rec[i].waveform_samples = {}
    rec[i].queued = false
  end

  params:add_group("GRID + ARC",8)
  params:add_separator("GRID")
  params:add_option("LED_style","LED style",{"varibright","4-step","grayscale"},1)
  params:set_action("LED_style",
  function()
    grid_dirty = true
  end)
  params:add_option("grid_size","grid size",{"128","64"},1)
  params:set_action("grid_size",
  function(x)
    grid_dirty = true
    if x == 2 then
      params:set("LED_style",2)
    end
  end)
  params:add_option("vert rotation", "vert rotation",{"usb on top","usb on bottom"},1)
  params:set_action("vert rotation",
  function(x)
    if x == 1 then
      g:rotation(0)
    else
      g:rotation(2)
    end
    grid_dirty = true
  end
  )
  params:add_option("midigrid?","midigrid?",{"no","yes"},1)
  params:set_action("midigrid?",
  function(x)
    if x == 2 then
      params:set("grid_size",2)
    end
  end)

  -- params:add_separator("hotkey config")

  params:add_option("alt_corner","alt+corner action",{"none","tap-tempo","transport"},1)
  params:hide("alt_corner")

  params:add_separator("ARC")
  params:add_option("arc_size","arc size",{4,2},1)
  params:set_action("arc_size", function(x)
  end)


  params:add_group("CROW IN/OUT",5)
  for i = 1,2 do
    params:add_option("crow input "..i,"crow in "..i,{"none","trig to record","cont to macro "..i,"trig: transport","gate: transport"},1)
    params:set_action("crow input "..i,
    function(x)
      set_crow_input(i,x)

    end)
    params:add_number("crow input "..i.." max voltage","crow in "..i.." max voltage",1,10,8)
  end
  params:add_option("crow output 4", "crow out 4",{"none","transport pulse","transport gate"},1)
  params:set_action("crow output 4",
    function(x)

    end)
  
  params:add_separator("cheat codes params")
  
  params:add_group("collections",8)
  params:add_separator("load/save")
  params:add_trigger("load", "load collection")
  params:set_action("load",
  function(x)
    local dirname = _path.data.."cheat_codes_yellow/"
    if os.rename(dirname, dirname) == nil then
      os.execute("mkdir " .. dirname)
    end
    local dirname = _path.data.."cheat_codes_yellow/names/"
    if os.rename(dirname, dirname) == nil then
      os.execute("mkdir " .. dirname)
    end
    fileselect.enter(_path.data.."cheat_codes_yellow/names/", named_loadstate)
  end)
  params:add_option("collect_live","collect Live buffers?",{"no","yes"},2)
  params:hide("collect_live")

  params:add_trigger("save", "save new collection")
  params:set_action("save", function(x)
    if Namesizer ~= nil then
      textentry.enter(pre_save,Namesizer.phonic_nonsense().."_"..Namesizer.phonic_nonsense(),'alphanumeric and - _ only')
    else
      textentry.enter(pre_save,'alphanumeric and - _ only')
    end
  end)
  params:add_separator("danger zone!")
  params:add_trigger("overwrite_coll", "overwrite loaded collection")
  -- params:set_action("overwrite_coll", function(x) fileselect.enter(_path.data.."cheat_codes_yellow/names/", named_overwrite) end)
  params:set_action("overwrite_coll", function(x)
    if selected_coll ~= 0 then
      named_overwrite(_path.data.."cheat_codes_yellow/names/"..selected_coll..".cc2")
    end
  end)
  params:add_trigger("delete_coll", "delete collection")
  params:set_action("delete_coll", function(x) fileselect.enter(_path.data.."cheat_codes_yellow/names/", pre_delete) end)
  params:add_trigger("save default collection", "save default collection")
  params:set_action("save default collection", function()
    clock.run(save_screen,"DEFAULT")
    _norns.key(1,1)
    _norns.key(1,0)
    -- screen_dirty = true
  end)
  
  -- menu = 1
  
  -- for i = 1,4 do
  --   crow.output[i].action = "{to(5,0),to(0,0.05)}"
  -- end
  crow.count = {}
  crow.count_execute = {}
  for i = 1,3 do
    crow.count[i] = 1
    crow.count_execute[i] = 1
  end

  screen.line_width(1)

  local etap = 0
  local edelta = 1
  local prebpm = 110
  
  clock_counting = 0
  
  grid_pat = {}
  for i = 1,3 do
    grid_pat[i] = pattern_time.new("grid_pat["..i.."]")
    grid_pat[i].process = grid_pattern_execute
    grid_pat[i].tightened_start = 0
    grid_pat[i].auto_snap = 0
    grid_pat[i].quantize = 0
    grid_pat[i].playmode = 1
    grid_pat[i].random_pitch_range = 5
    grid_pat[i].rec_clock_time = 8
    grid_pat[i].random_notes_held = {}
  end
  
  quantized_grid_pat = {}
  for i = 1,3 do
    quantized_grid_pat[i] = {}
    quantized_grid_pat[i].clicks = {}
    quantized_grid_pat[i].event = {}
    quantized_grid_pat[i].sub_step = 1
    quantized_grid_pat[i].current_step = grid_pat[i].start_point
  end
  
  step_seq = {}
  for i = 1,3 do
    step_seq[i] = {}
    step_seq[i].active = 1
    step_seq[i].current_step = 1
    step_seq[i].current_pat = nil
    step_seq[i].rate = 1
    step_seq[i].start_point = 1
    step_seq[i].end_point = 16
    step_seq[i].length = (step_seq[i].end_point - step_seq[i].start_point) + 1
    step_seq[i].meta_step = 1
    step_seq[i].meta_duration = 1
    step_seq[i].meta_meta_step = 1
    step_seq[i].held = 0
    for j = 1,16 do
      step_seq[i][j] = {}
      step_seq[i][j].meta_meta_duration = 4
      step_seq[i][j].assigned = 0 --necessary?
      step_seq[i][j].assigned_to = 0
      step_seq[i][j].loop_pattern = 1
    end
    step_seq[i].meta_meta_duration = 4
    step_seq[i].loop_held = 0
  end
  
  function internal_clocking_tightened(bank)
    local current = quantized_grid_pat[bank].current_step
    local sub_step = quantized_grid_pat[bank].sub_step
    if current == 0 then
      current = grid_pat[bank].start_point
    end
    if grid_pat[bank].tightened_start == 1 and grid_pat[bank].count > 0 and current <= grid_pat[bank].end_point and quantized_grid_pat[bank].event[current] ~= nil then
      if quantized_grid_pat[bank].event[current][sub_step] == "something" then
        --print(current, sub_step, "+++")
        if grid_pat[bank].step == 0 then
          grid_pat[bank].step = grid_pat[bank].start_point
        end
        if quantized_grid_pat[bank].current_step == 0 then
          quantized_grid_pat[bank].current_step = grid_pat[bank].start_point
        end
        grid_pattern_execute(grid_pat[bank].event[quantized_grid_pat[bank].current_step])
      elseif quantized_grid_pat[bank].event[current][sub_step] == "nothing" then
        -- nothing!
        if grid_pat[bank].step == 0 then
          grid_pat[bank].step = grid_pat[bank].start_point
        end
        if quantized_grid_pat[bank].current_step == 0 then
          print("if you see this message, tell dan!")
          quantized_grid_pat[bank].current_step = grid_pat[bank].start_point
        end
      elseif quantized_grid_pat[bank].event[current][sub_step] == nil and #quantized_grid_pat[bank].event == grid_pat[bank].end_point then
        print(current.." is nil!")
        table.remove(quantized_grid_pat[bank].event,current)
        grid_pat[bank].end_point = grid_pat[bank].end_point - 1
        quantized_grid_pat[bank].current_step = quantized_grid_pat[bank].current_step + 1
        quantized_grid_pat[bank].sub_step = 1
      elseif quantized_grid_pat[bank].event[current][sub_step] == nil then
        print("skipping bank "..bank..", step "..current..", sub "..sub_step.."...unsure what to do")
        quantized_grid_pat[bank].current_step = quantized_grid_pat[bank].current_step + 1
        quantized_grid_pat[bank].sub_step = 1
      end
      --increase sub_step now
      --if quantized_grid_pat[bank].current_step > #quantized_grid_pat[bank].event or quantized_grid_pat[bank].current_step > #grid_pat[bank].event then
      if quantized_grid_pat[bank].current_step > grid_pat[bank].end_point then
        quantized_grid_pat[bank].current_step = grid_pat[bank].start_point
      end
      if quantized_grid_pat[bank].sub_step == #quantized_grid_pat[bank].event[quantized_grid_pat[bank].current_step] then
        quantized_grid_pat[bank].sub_step = 0
        --if we're at the end of the events in this step, move to the next step
        if grid_pat[bank].step == grid_pat[bank].end_point then
          grid_pat[bank].step = 0
          --quantized_grid_pat[bank].current_step = 0
        end
        --if quantized_grid_pat[bank].current_step == #quantized_grid_pat[bank].event then
        if quantized_grid_pat[bank].current_step == grid_pat[bank].end_point then
          quantized_grid_pat[bank].current_step = grid_pat[bank].start_point - 1
        end
        grid_pat[bank].step = grid_pat[bank].step + 1
        quantized_grid_pat[bank].current_step = quantized_grid_pat[bank].current_step +1
        --quantized_grid_pat[bank].current_step = quantized_grid_pat[bank].current_step + 1
      end
      quantized_grid_pat[bank].sub_step = quantized_grid_pat[bank].sub_step + 1
    else
      quantized_grid_pat[bank].current_step = 1
    end
  end

  params:add_number("bpm", "bpm", 1, 480,80)
  bpm = params:get("bpm")
  params:hide("bpm")
  
  params:add_group("hidden [timing]",6)
  params:hide("hidden [timing]")
  params:add_option("quantize_pads", "(see [timing] menu)", { "no", "yes" })
  params:set_action("quantize_pads", function(x) quantize = x-1 end)
  params:add_option("quantize_pats", "(see [timing] menu)", { "no", "yes" })
  params:set_action("quantize_pats", function(x)
    grid_pat_quantize = x-1
    for i = 1,3 do
      grid_pat[i].quantize = x-1
    end
  end)
  params:add_number("quant_div", "(see [timing] menu)", 1, 5, 4)
  params:add_number("quant_div_pats", "(see [timing] menu)", 1, 5, 4)
  params:add_option("lock_pat", "(see [timing] menu)", {"no", "yes"} )
  params:add{type = "trigger", id = "sync_pat", name = "(see [timing] menu)"}

  params:default()
  
  grid_page = 0
  grid_page_64 = 0
  bank_64 = 1
  
  _ca.init()
  _lfos.init()
  main_menu.init()
  del.init()
  
  index = 0
  
  edit = "all"
  
  start_up.init()
  
  params:add_group("crow utils",2)
  params:hide("crow utils")
  
  params:add{type = "trigger", id = "init_crow", name = "initialize crow", action = crow_init}
  params:add{type = "trigger", id = "clear_crow", name = "(reset/clear crow)", action = crow_flush}

  bank = {}
  reset_all_banks(bank)
  
  params:bang()
  
  selected_coll = 0
  
  --GRID
  selected = {}
  fingers = {}
  counter_two = {}
  for i = 1,3 do
    selected[i] = {}
    selected[i].x = 1 + (5*(i-1))
    selected[i].y = 8
    selected[i].id = 1
    for k = 1,4 do
      fingers[k] = {}
      fingers[k].dt = 1
      fingers[k].t1 = 0
      fingers[k].t = 0
      fingers[k][i] = {}
      fingers[k][i].con = {}
    end
  end

  function record_zilchmo_4(prev,sel,row,con)
    grid_p[sel] = {}
    grid_p[sel].i = sel
    grid_p[sel].action = "zilchmo"
    grid_p[sel].con = con
    grid_p[sel].row = row
    grid_p[sel].bank = sel
    grid_p[sel].id = selected[sel].id
    grid_p[sel].x = selected[sel].x
    grid_p[sel].y = selected[sel].y
    grid_p[sel].previous_rate = prev
    grid_p[sel].rate = prev
    grid_p[sel].start_point = bank[sel][bank[sel].id].start_point
    grid_p[sel].end_point = bank[sel][bank[sel].id].end_point
    grid_pat[sel]:watch(grid_p[sel])
  end

  function record_arp()
  end

  counter_two = {}
  -- counter_two.key_up = metro.init()
  -- counter_two.key_up.time = 0.05
  -- counter_two.key_up.count = 1
  -- counter_two.key_up.event = function()
  --   zilchmo(2,selected_zilchmo_bank)
  -- end
  -- counter_two.key_up:stop()
  
  quantized_grid_pat = {}
  for i = 1,3 do
    quantized_grid_pat[i] = {}
    quantized_grid_pat[i].clicks = {}
    quantized_grid_pat[i].event = {}
    quantized_grid_pat[i].sub_step = 1
    quantized_grid_pat[i].current_step = 1
  end

  arc_pat = {{},{},{}}
  for i = 1,3 do
    for j = 1,4 do
      arc_pat[i][j] = pattern_time.new("arc_pat["..i.."]["..j.."]")
      arc_pat[i][j].process = new_arc_pattern_execute
    end
  end

  for i=1,3 do
    cheat(i,bank[i].id)
  end

  grid_dirty = true

  function draw_grid()
    if grid_dirty then
      _gleds.grid_redraw()
      grid_dirty = false
    end
  end

  function draw_screen()
    if screen_dirty then
      redraw()
      screen_dirty = false
    end
  end

  function draw_waveform()
    if menu == 2 and page.loops.sel ~= 5 then
      local rec_on = 0;
      for i = 1,3 do
        if rec[i].state == 1 then
          rec_on = i
        end
      end
      if rec_on ~= 0 and rec[rec_on].state == 1 then
        if page.loops.sel < 4 then
          local pad = bank[page.loops.sel][bank[page.loops.sel].id]
          update_waveform(1,key1_hold and pad.start_point or live[rec_on].min,key1_hold and pad.end_point or live[rec_on].max,128)
        elseif page.loops.sel == 4 then
          update_waveform(1,key1_hold and rec[rec.focus].start_point or live[rec_on].min,key1_hold and rec[rec.focus].end_point or live[rec_on].max,128)
        end
      end
      if page.loops.sel < 4 then
        if (params:get("SOS_enabled_1") == 1 or params:get("SOS_enabled_2") == 1 or params:get("SOS_enabled_3") == 1 ) and not page.loops.zoomed_mode then
          local pad = bank[page.loops.sel][bank[page.loops.sel].id]
          local min = pad.mode == 1 and live[pad.clip].min or clip[pad.clip].min
          local max = pad.mode == 1 and live[pad.clip].max or clip[pad.clip].max
          update_waveform(1,key1_hold and pad.start_point or min,key1_hold and pad.end_point or max,128)
        elseif (params:get("SOS_enabled_1") == 1 or params:get("SOS_enabled_2") == 1 or params:get("SOS_enabled_3") == 1 ) and page.loops.zoomed_mode then
          local pad = bank[page.loops.sel][bank[page.loops.sel].id]
          update_waveform(1,pad.start_point,pad.end_point or max,128)
        end
      -- need to draw LIVE here...
      end
      screen_dirty = true
    end
  end

  function force_waveform_redraw()
    for i = 1,3 do
      local pad = bank[i][bank[i].id]
      local min = pad.mode == 1 and live[pad.clip].min or clip[pad.clip].min
      local max = pad.mode == 1 and live[pad.clip].max or clip[pad.clip].max
      update_waveform(1,min,max,128)
    end
  end
  
  softcut.poll_start_phase()
  
  filter_types = {"lp", "hp", "bp", "lp/hp"}
  
  rec_state_watcher = metro.init()
  rec_state_watcher.time = 0.05
  rec_state_watcher.event = function()
    if rec[rec.focus].loop == 0 then
      if rec[rec.focus].state == 1 then
        if rec[rec.focus].end_point < poll_position_new[1] +0.015 then -- could do 0.005?
          rec[rec.focus].state = 0
          rec_state_watcher:stop()
          rec.stopped = true
          grid_dirty = true
          rec_ended_callback()
          -- if menu == 2 then
          --   if page.loops.sel ~= 5 then screen_dirty = true end
          --   -- print("stopped")
          -- end
        end
      end
    end
  end
  rec_state_watcher.count = -1
  
  already_saved()

  params:add_separator("cheat codes external zone")

  params:add_group("OSC setup",3)
  params:add_text("osc_IP", "source OSC IP", "192.168.")
  params:set_action("osc_IP", function() dest = {tostring(params:get("osc_IP")), tonumber(params:get("osc_port"))} end)
  params:add_text("osc_port", "OSC port", "9000")
  params:set_action("osc_port", function() dest = {tostring(params:get("osc_IP")), tonumber(params:get("osc_port"))} end)
  params:add{type = "trigger", id = "refresh_osc", name = "refresh OSC [K3]", action = function()
    params:set("osc_IP","none")
    params:set("osc_port","none")
    osc_communication = false
    osc_echo = false
  end}

  params:add_group("MIDI note/OP-Z setup",16)
  params:add_option("midi_control_enabled", "enable MIDI control?", {"no","yes"},1)
  -- params:add_option("midi_control_device", "MIDI control device",{"port 1", "port 2", "port 3", "port 4"},1)
  
  local vports = {}
  local function refresh_params_vports()
    for i = 1,#midi.vports do
      vports[i] = midi.vports[i].name ~= "none" and util.trim_string_to_width(midi.vports[i].name,70) or tostring(i)..": [device]"
    end
  end

  refresh_params_vports()

  params:add_option("midi_control_device", "MIDI ctrl dev",vports,1)
  params:add_option("midi_echo_enabled", "enable MIDI echo?", {"no","yes"},1)
  local bank_names = {"(a)","(b)","(c)"}
  params:add_separator("channel")
  params:add_option("midi_control_channel_distribution", "channel distribution: ",{"multi","single"})
  params:set_action("midi_control_channel_distribution", function(x)
    if all_loaded then
       
      if x == 2 then
        for i = 1,3 do params:set("bank_"..i.."_midi_channel",params:get("bank_1_midi_channel")) end
      end
    end
  end)
  for i = 1,3 do
    params:add_number("bank_"..i.."_midi_channel", "bank "..bank_names[i].." pad channel:",1,16,i)
    params:set_action("bank_"..i.."_midi_channel", function(x)
      if all_loaded then
        
        if params:get("midi_control_channel_distribution") == 2 then
          for j = 1,3 do
            params:set("bank_"..(j~=i and j or i).."_midi_channel",x)
          end
        end
      end
    end)
  end
  params:add_separator("note = pad 1")
  for i = 1,3 do
    params:add_number("bank_"..i.."_pad_midi_base", "bank "..bank_names[i].." midi base:",0,111,53)
  end
  params:add_separator("zilchmo")
  for i = 1,3 do
    params:add_option("bank_"..i.."_midi_zilchmo_enabled", "bank "..bank_names[i].." midi zilchmo?", {"no","yes"},2)
  end

  params:add_group("MIDI encoder setup",7)
  params:add_option("midi_enc_control_enabled", "enable MIDI enc control?", {"no","yes"},1)
  params:add_option("midi_enc_control_device", "MIDI enc dev",vports,2)
  params:add_option("midi_enc_echo_enabled", "enable MIDI enc echo?", {"no","yes"},1)
  params:add_trigger("ping_for_MFT","refresh for MFT (K3)")
  params:set_action("ping_for_MFT",function(x) ping_midi_devices() end)
  local bank_names = {"(a)","(b)","(c)"}
  for i = 1,3 do
    params:add_number("bank_"..i.."_midi_enc_channel", "bank "..bank_names[i].." enc channel:",1,16,i)
  end

  mc.pad_to_note_params()

  params:add_separator("meta")

  macros:add_params()

  crow_init()
  
  task_id = clock.run(globally_clocked)
  -- pad_press_quant_triplets = clock.run(pad_clock_triplets)
  pad_press_quant = clock.run(pad_clock)
  random_rec = clock.run(random_rec_clock)

  params:set_action("clock_tempo",
  function(x)
    local source = params:string("clock_source")
    if source == "internal" then clock.internal.set_tempo(x)
    elseif source == "link" then clock.link.set_tempo(x) end
    norns.state.clock.tempo = x
    update_tempo()
  end)
  
  if params:string("clock_source") == "internal" then
    -- clock.internal.start(params:get("clock_tempo"))
    clock.internal.start()
  end

  -- local midi_dev_max;
  -- for k,v in pairs(midi.devices) do
  --   midi_dev_max = midi.devices[k].id
  -- end
  -- for i = 1,midi_dev_max do
  --   if midi.devices[i] ~= nil and midi.devices[i].name == "Midi Fighter Twister" then
  --     params:set("midi_enc_control_enabled",2)
  --     params:set("midi_enc_control_device",midi.devices[i].port)
  --     params:set("midi_enc_echo_enabled",2)
  --     mft_connected = true
  --   end
  --   -- if midi.devices[i] ~= nil and midi.devices[i].name == "OP-Z" then
  --   --   params:set("midi_control_enabled",2)
  --   --   params:set("midi_control_device",midi.devices[i].port)
  --   --   params:set("midi_echo_enabled",2)
  --   --   opz_connected = true
  --   -- end
  -- end

  ping_midi_devices()

  midi_dev = {}
  for j = 1,#midi.vports do
    midi_dev[j] = midi.connect(j)
    local trigger_bank = {nil,nil,nil}
    local b_ch = {}
    midi_dev[j].event = function(data)
      if midi_dev[j].name == "Ableton Push 2 1" and data[1] == 176 then
        if data[2] >= 71 and data[2] <= 78 then
          push_to_cc2(data[2]-70,data[3])
        end
      end
      screen_dirty = true
      local d = midi.to_msg(data)
      if d.type == "start" then
        if transport.vars.midi_transport_in[j] then
          if params:string("clock_source") == "internal" or params:string("clock_source") == "midi" then
            transport.start_from_midi_message()
          end
        end
      elseif d.type == "stop" then
        if transport.vars.midi_transport_in[j] then
          if params:string("clock_source") == "internal" or params:string("clock_source") == "midi" then
            transport.stop_from_midi_message()
          end
        end
      elseif d.type == "continue" then
        if transport.vars.midi_transport_in[j] then
          if params:string("clock_source") == "internal" or params:string("clock_source") == "midi" then
            if transport.is_running then
              transport.stop_from_midi_message()
            else
              transport.start_from_midi_message()
            end
          end
        end
      end
      if params:get("midi_control_enabled") == 2 and j == params:get("midi_control_device") then
        local received_ch;
        -- local b_ch = {}
        for i = 1,3 do
          if d.ch == params:get("bank_"..i.."_midi_channel") then
            -- received_ch = i
            b_ch[i] = d.ch
          else
            b_ch[i] = nil
          end
        end
        for i = 1,3 do
          if b_ch[i] ~= nil then
        -- local i = received_ch
            if d.note ~= nil and i ~= nil then
              if d.note >= params:get("bank_"..i.."_pad_midi_base") and d.note <= params:get("bank_"..i.."_pad_midi_base") + (not midi_alt and 15 or 22) then
                if not midi_alt then
                  if d.type == "note_on" then
                    mc.cheat(i,d.note-(params:get("bank_"..i.."_pad_midi_base")-1))
                    if midi_pat[i].rec == 1 and midi_pat[i].count == 0 then
                    end
                    midi_pattern_watch(i, d.note-(params:get("bank_"..i.."_pad_midi_base")-1))
                    if menu == 9 then
                      page.arps.sel = i
                      arps.momentary(i, bank[i].id, "on")
                    end
                  elseif d.type == "note_off" then
                    if menu == 9 then
                      if not arp[i].hold and page.arps.sel == i  then
                        local targeted_pad = d.note-(params:get("bank_"..i.."_pad_midi_base")-1)
                        arps.momentary(i, targeted_pad, "off")
                      end
                    end
                  end
                elseif midi_alt then
                  if params:get("bank_"..i.."_midi_zilchmo_enabled") == 2 and d.type == "note_on" then
                    mc.zilch(i,d.note-(params:get("bank_"..i.."_pad_midi_base")-1))
                  end
                end
              elseif d.note == params:get("bank_"..i.."_pad_midi_base") + 23 then
                if d.type == "note_on" then
                  midi_alt = true
                else
                  midi_alt = false
                end
              end
            end
            if d.type == "cc" and params:get("midi_echo_enabled") == 2 then
              if d.cc == 1 then
                mc.move_start(bank[i][bank[i].id],d.val)
              elseif d.cc == 2 then
                mc.move_end(bank[i][bank[i].id],d.val)
              elseif d.cc == 3 then
                mc.adjust_filter(i,d.val)
              elseif d.cc == 4 then
                mc.adjust_pad_level(bank[i][bank[i].id],d.val)
              end
            end
          end
        end
      elseif params:get("midi_enc_control_enabled") == 2 and j == params:get("midi_enc_control_device") then
        -- TODO: refine this, shouldn't have to call all 3...
        if midi_dev[j].name ~= "Midi Fighter Twister" then 
          for i = 1,3 do
            if d.ch == params:get("bank_"..i.."_midi_enc_channel") then
              if d.type == "cc" then
                if d.cc == 1 then
                  mc.move_start(bank[i][bank[i].id],d.val)
                elseif d.cc == 2 then
                  mc.move_end(bank[i][bank[i].id],d.val)
                elseif d.cc == 3 then
                  mc.adjust_filter(i,d.val)
                elseif d.cc == 4 then
                  mc.adjust_pad_level(bank[i][bank[i].id],d.val)
                end
              end
            end
          end
        
        elseif midi_dev[j].name == "Midi Fighter Twister" then
          
          -- tab.print(d)

          local function check_focus_hold(id)
            if bank[id].focus_hold == true then
              return bank[id].focus_pad
            else
              return bank[id].id
            end
          end

          if d.ch == 1 or d.ch == 5 then
            if d.cc == 0 or d.cc == 16 or d.cc == 32 then
              local id = math.floor(d.cc/16)+1
              encoder_actions.change_pad(bank[id][check_focus_hold(id)].bank_id, d.val == 63 and -1 or 1)
              if bank[id].focus_hold then
                mc.mft_redraw(bank[id][bank[id].focus_pad],"all")
              end
            elseif d.cc == 1 or d.cc == 17 or d.cc == 33 then
              -- pad start point
              local id = math.floor(d.cc/16)+1
              local resolution = loop_enc_resolution[id] / 10
              encoder_actions.move_start(bank[id][check_focus_hold(id)], (d.val == 63 and (d.ch == 1 and -0.1 or -0.01) or (d.ch == 1 and 0.1 or 0.01))/resolution)
              mc.mft_redraw(bank[id][check_focus_hold(id)],"start_point")
              if bank[id].focus_hold == false then
                encoder_actions.sc.move_start(id)
              end
            elseif d.cc == 2 or d.cc == 18 or d.cc == 34 then
              -- pad end point
              local id = math.floor(d.cc/16)+1
              local resolution = loop_enc_resolution[id] / 10
              encoder_actions.move_end(bank[id][check_focus_hold(id)], (d.val == 63 and (d.ch == 1 and -0.1 or -0.01) or (d.ch == 1 and 0.1 or 0.01))/resolution)
              mc.mft_redraw(bank[id][check_focus_hold(id)],"end_point")
              if bank[id].focus_hold == false then
                encoder_actions.sc.move_end(id)
              end
            elseif d.cc == 3 or d.cc == 19 or d.cc == 35 then
              -- pad window
              local id = math.floor(d.cc/16)+1
              local resolution = loop_enc_resolution[id] / 10
              encoder_actions.move_play_window(bank[id][check_focus_hold(id)], (d.val == 63 and (d.ch == 1 and -0.1 or -0.01) or (d.ch == 1 and 0.1 or 0.01))/resolution)
              mc.mft_redraw(bank[id][check_focus_hold(id)],"start_point")
              mc.mft_redraw(bank[id][check_focus_hold(id)],"end_point")
              if bank[id].focus_hold == false then
                encoder_actions.sc.move_play_window(id)
              end
            elseif d.cc == 4 or d.cc == 20 or d.cc == 36 then
              --pad level
              local id = math.floor(d.cc/16)+1
              bank[id][check_focus_hold(id)].level = util.clamp(bank[id][check_focus_hold(id)].level+(d.val == 63 and (d.ch == 1 and -0.01 or -0.001) or (d.ch == 1 and 0.01 or 0.001)),0,2)
              if bank[id][check_focus_hold(id)].envelope_mode == 2 or bank[id][check_focus_hold(id)].enveloped == false then
                if bank[id].focus_hold == false then
                  softcut.level_slew_time(id+1,1.0)
                  -- softcut.level(id+1,bank[id][check_focus_hold(id)].level*bank[id].global_level)
                  softcut.level(id+1,bank[id][check_focus_hold(id)].level*_l.get_global_level(id))
                  -- softcut.level_cut_cut(id+1,5,(bank[id][check_focus_hold(id)].left_delay_level*bank[id][check_focus_hold(id)].level)*bank[id].global_level)
                  -- softcut.level_cut_cut(id+1,6,(bank[id][check_focus_hold(id)].right_delay_level*bank[id][check_focus_hold(id)].level)*bank[id].global_level)
                  _l.calc_delay_sends(id,check_focus_hold(id),{"L","R"})
                end
              end
              mc.mft_redraw(bank[id][check_focus_hold(id)],"pad_level")
            elseif d.cc == 5 or d.cc == 21 or d.cc == 37 then
              --bank level
              local id = math.floor(d.cc/16)+1
              bank[id].global_level = util.clamp(bank[id].global_level+(d.val == 63 and (d.ch == 1 and -0.01 or -0.001) or (d.ch == 1 and 0.01 or 0.001)),0,2)
              if bank[id][check_focus_hold(id)].envelope_mode == 2 or bank[id][check_focus_hold(id)].enveloped == false then
                if bank[id].focus_hold == false then
                  softcut.level_slew_time(id+1,1.0)
                  -- softcut.level(id+1,bank[id][check_focus_hold(id)].level*bank[id].global_level)
                  softcut.level(id+1,bank[id][check_focus_hold(id)].level*_l.get_global_level(id))
                  -- softcut.level_cut_cut(id+1,5,(bank[id][check_focus_hold(id)].left_delay_level*bank[id][check_focus_hold(id)].level)*bank[id].global_level)
                  -- softcut.level_cut_cut(id+1,6,(bank[id][check_focus_hold(id)].right_delay_level*bank[id][check_focus_hold(id)].level)*bank[id].global_level)
                  _l.calc_delay_sends(id,check_focus_hold(id),{"L","R"})
                end
              end
              mc.mft_redraw(bank[id][check_focus_hold(id)],"bank_level")
            elseif d.cc == 6 or d.cc == 22 or d.cc == 38 then
              --pad semitones
              local id = math.floor(d.cc/16)+1
              local current_offset = (math.log(bank[id][check_focus_hold(id)].offset)/math.log(0.5))*-12
              current_offset = util.clamp(current_offset+(d.val == 63 and -1 or 1)/32,-1,1)
              if current_offset > -0.0001 and current_offset < 0.0001 then
                current_offset = 0
              end
              bank[id][check_focus_hold(id)].offset = math.pow(0.5, -current_offset / 12)
              if d.ch == 5 then
                local this_pad = check_focus_hold(id)
                for i = 1,16 do
                  bank[id][i].offset = bank[id][check_focus_hold(id)].offset
                end
              end
              if bank[id][check_focus_hold(id)].pause == false and bank[id].id == check_focus_hold(id) then
                if bank[id].focus_hold == false then
                  softcut.rate(id+1, bank[id][check_focus_hold(id)].rate*bank[id][check_focus_hold(id)].offset)
                end
              end
              mc.mft_redraw(bank[id][check_focus_hold(id)],"pad_offset")
            elseif d.cc == 7 or d.cc == 23 or d.cc == 39 then
              --pad rate
              local id = math.floor(d.cc/16)+1
              local rates ={-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
              if bank[id][check_focus_hold(id)].fifth then
                bank[id][check_focus_hold(id)].fifth = false
              end
              if tab.key(rates,bank[id][check_focus_hold(id)].rate) == nil then
                bank[id][check_focus_hold(id)].rate = 1
              end
              bank[id][check_focus_hold(id)].rate = rates[util.clamp(tab.key(rates,bank[id][check_focus_hold(id)].rate)+(d.val == 63 and -1 or 1),1,#rates)]
              if d.ch == 5 then
                local this_pad = check_focus_hold(id)
                for i = 1,16 do
                  bank[id][i].rate = bank[id][check_focus_hold(id)].rate
                end
              end
              if bank[id][check_focus_hold(id)].pause == false and bank[id].id == check_focus_hold(id) then
                if bank[id].focus_hold == false then
                  softcut.rate(id+1, bank[id][check_focus_hold(id)].rate*bank[id][check_focus_hold(id)].offset)
                end
              end
              mc.mft_redraw(bank[id][check_focus_hold(id)],"pad_rate")
            elseif d.cc == 8 or d.cc == 24 or d.cc == 40 then
              --pad / bank pan
              local id = math.floor(d.cc/16)+1
              if d.ch == 5 then
                local pre_pan = bank[id][check_focus_hold(id)].pan
                for i = 1,16 do
                  bank[id][i].pan = util.clamp(pre_pan+(d.val == 63 and -0.01 or 0.01),-1,1)
                end
              elseif d.ch == 1 then
                bank[id][check_focus_hold(id)].pan = util.clamp(bank[id][check_focus_hold(id)].pan+(d.val == 63 and -0.01 or 0.01),-1,1)
              end
              softcut.pan(id+1, bank[id][check_focus_hold(id)].pan)
              bank[id].pan_lfo.offset = bank[id][check_focus_hold(id)].pan
              mc.mft_redraw(bank[id][check_focus_hold(id)],"pan")
            elseif d.cc == 10 or d.cc == 26 or d.cc == 42 then
              --bank / pad filter cutoff
              local id = math.floor(d.cc/16)+1
              if d.ch == 5 then
                if slew_counter[id] ~= nil then
                  slew_counter[id].prev_tilt = bank[id][check_focus_hold(id)].tilt
                end
                bank[id][check_focus_hold(id)].tilt = util.clamp(bank[id][check_focus_hold(id)].tilt+(d.val == 63 and -0.01 or 0.01),-1,1)
                if d.val == 63 then
                  if util.round(bank[id][check_focus_hold(id)].tilt*100) < 0 and util.round(bank[id][check_focus_hold(id)].tilt*100) > -9 then
                    bank[id][check_focus_hold(id)].tilt = -0.10
                  elseif util.round(bank[id][check_focus_hold(id)].tilt*100) > 0 and util.round(bank[id][check_focus_hold(id)].tilt*100) < 32 then
                    bank[id][check_focus_hold(id)].tilt = 0.0
                  end
                elseif d.val == 65 and util.round(bank[id][check_focus_hold(id)].tilt*100) > 0 and util.round(bank[id][check_focus_hold(id)].tilt*100) < 32 then
                  bank[id][check_focus_hold(id)].tilt = 0.32
                end
                if bank[id].focus_hold == false then
                  slew_filter(id,slew_counter[id].prev_tilt,bank[id][check_focus_hold(id)].tilt,bank[id][check_focus_hold(id)].q,bank[id][check_focus_hold(id)].q,15)
                end
              elseif d.ch == 1 then
                if slew_counter[id] ~= nil then
                  slew_counter[id].prev_tilt = bank[id][bank[id].id].tilt
                end
                for j = 1,16 do
                  bank[id][j].tilt = util.clamp(bank[id][j].tilt+(d.val == 63 and -0.01 or 0.01),-1,1)
                  if d.val == 63 then
                    if util.round(bank[id][j].tilt*100) < 0 and util.round(bank[id][j].tilt*100) > -9 then
                      bank[id][j].tilt = -0.10
                    elseif util.round(bank[id][j].tilt*100) > 0 and util.round(bank[id][j].tilt*100) < 32 then
                      bank[id][j].tilt = 0.0
                    end
                  elseif d.val == 65 and util.round(bank[id][j].tilt*100) > 0 and util.round(bank[id][j].tilt*100) < 32 then
                    bank[id][j].tilt = 0.32
                  end
                end
                if bank[id].focus_hold == false then
                  slew_filter(id,slew_counter[id].prev_tilt,bank[id][bank[id].id].tilt,bank[id][bank[id].id].q,bank[id][bank[id].id].q,15)
                end
              end
              mc.mft_redraw(bank[id][check_focus_hold(id)],"filter_tilt")
            elseif d.cc == 11 or d.cc == 27 or d.cc == 43 then
              --bank / pad filter q
              local id = math.floor(d.cc/16)+1
              params:delta("filter "..id.." q",(d.val == 63 and -0.5 or 0.5)*-1)
              mc.mft_redraw(bank[id][check_focus_hold(id)],"filter_q")
            elseif d.cc == 12 or d.cc == 28 or d.cc == 44 then
              -- pad / bank L delay send
              local id = math.floor(d.cc/16)+1
              local k = 3
              local v = d.cc == 12 and 1 or (d.cc == 28 and 3 or 5)
              local target = bank[id]
              local prm = {"left_delay_level","right_delay_level"}
              if d.ch == 5 then
                for i = 1,16 do
                  target[i][prm[1]] = util.clamp(target[i][prm[1]] + (d.val == 63 and -0.1 or 0.1),0,1)
                  if delay_links[del.lookup_prm(k,v)] then
                    target[i][prm[1 == 1 and 2 or 1]] = target[i][prm[1]]
                  end
                end
              elseif d.ch == 1 then
                target[check_focus_hold(id)][prm[1]] = util.clamp(target[check_focus_hold(id)][prm[1]] + d/10,0,1)
                if delay_links[del.lookup_prm(k,v)] then
                  target[check_focus_hold(id)][prm[1 == 1 and 2 or 1]] = target[check_focus_hold(id)][prm[1]]
                end
              end
              grid_dirty = true
              if target[check_focus_hold(id)].enveloped == false then
                -- softcut.level_cut_cut(util.round(item/2)+1,1+4,(target[check_focus_hold(id)][prm[1]]*target[check_focus_hold(id)].level)*target.global_level)
                softcut.level_cut_cut(util.round(item/2)+1,1+4,(target[check_focus_hold(id)][prm[1]]*target[check_focus_hold(id)].level)*_l.get_global_level(id))
                if delay_links[del.lookup_prm(k,v)] then
                  local this_one = 1 == 1 and 2 or 1
                  -- softcut.level_cut_cut(util.round(item/2)+1,(this_one)+4,(target[check_focus_hold(id)][prm[this_one]]*target[check_focus_hold(id)].level)*target.global_level)
                  softcut.level_cut_cut(util.round(item/2)+1,(this_one)+4,(target[check_focus_hold(id)][prm[this_one]]*target[check_focus_hold(id)].level)*_l.get_global_level(id))
                end
              end
            end
          elseif d.ch == 2 then
            if d.cc == 0 or d.cc == 16 or d.cc == 32 then
              local id = math.floor(d.cc/16)+1
              bank[id].focus_hold = d.val == 127 and true or false
              mc.mft_redraw(bank[id][check_focus_hold(id)],"all")
              grid_dirty = true
            end
          elseif d.ch == 4 then
            if d.val == 127 then
              if d.cc == 0 or d.cc == 1 or d.cc == 2 then
                mc.mft_redraw(bank[d.cc+1][check_focus_hold(d.cc+1)],"all")
              end
            end
          end
        end
        
      end
    end
  end

  midi_alt = false

  midi_pat = {}
  for i = 1,3 do
    midi_pat[i] = pattern_time.new("midi_pat["..i.."]")
    midi_pat[i].process = midi_pattern_execute
    midi_pat[i].tightened_start = 0
    midi_pat[i].auto_snap = 0
    midi_pat[i].quantize = 0
    midi_pat[i].playmode = 1
    midi_pat[i].random_pitch_range = 5
    midi_pat[i].clock_time = 4
    midi_pat[i].rec_clock_time = 8
    midi_pat[i].first_touch = false
  end

  for i = 1,3 do
    arps.init(i)
  end

  -- for i = 1,3 do
  --   rnd.init(i)
  -- end

  rytm.init()
  transport.init()
  _dough.init()
  speed_dial.init()

  if g then grid_dirty = true end
  
  -- all_loaded = true
  
  metro_persistent_state_restore = metro.init(persistent_state_restore, 0.1, 1)
  metro_persistent_state_restore:start()

  hardware_redraw = metro.init(
    function()
      if all_loaded then
        draw_grid()
        arc_redraw()
        draw_screen()
        draw_waveform()
      end
    end
    , 1/30, -1)
  hardware_redraw:start()

  for i = 1,3 do
    update_waveform(1,live[i].min,live[i].max,128)
  end

  local default_file = io.open("/home/we/dust/data/cheat_codes_yellow/names/DEFAULT.cc2", "r")
  if default_file == nil then
    menu = 1
    print("~~~~~> no user defaults defined: save a collection as DEFAULT to establish <~~~~~")
  else
    clock.run(function()
      local preload_bpm = params:get("clock_tempo")
      clock.sleep(0.25)
      named_loadstate("/home/we/dust/data/cheat_codes_yellow/names/DEFAULT.cc2")
      -- _norns.key(1,1)
      -- _norns.key(1,0)
      params:set("clock_tempo",preload_bpm)
    end)
    -- named_loadstate("/home/we/dust/data/cheat_codes_yellow/names/DEFAULT.cc2")
  end

end

---

function ping_midi_devices()
  mft_connected = false
  local midi_dev_max;
  for k,v in pairs(midi.devices) do
    midi_dev_max = midi.devices[k].id
  end
  for i = 1,midi_dev_max do
    if midi.devices[i] ~= nil and midi.devices[i].name == "Midi Fighter Twister" then
      params:set("midi_enc_control_enabled",2)
      params:set("midi_enc_control_device",midi.devices[i].port ~= nil and midi.devices[i].port or 1)
      params:set("midi_enc_echo_enabled",2)
      mft_connected = true
    end
    -- if midi.devices[i] ~= nil and midi.devices[i].name == "OP-Z" then
    --   params:set("midi_control_enabled",2)
    --   params:set("midi_control_device",midi.devices[i].port)
    --   params:set("midi_echo_enabled",2)
    --   opz_connected = true
    -- end
  end
  screen_dirty = true
  if all_loaded and mft_connected then
    for i = 1,3 do
      mc.mft_redraw(bank[i][bank[i].id],"all")
    end
  end
end

function sync_clock_to_loop(source,style)
  if style ~= "imported_sample" then
    local dur = 0
    local pattern_id;
    if style == "audio" then
      dur = source.end_point-source.start_point
    elseif style == "pattern" then
      pattern_id = string.match(source.name,"%d+")
      if params:string("sync_clock_to_pattern_"..pattern_id) == "yes" then
        for i = source.start_point,source.end_point do
          dur = dur + source.time[i]
        end
      end
    elseif style == "imported_sample" then
      dur = source.sample_length
    end
    if dur > 0 then
      local quarter = dur/4
      local derived_bpm = 60/quarter
      while derived_bpm < 70 do
        derived_bpm = derived_bpm * 2
        if derived_bpm > 160 then break end
      end
      while derived_bpm > 160 do
        derived_bpm = derived_bpm/2
        if derived_bpm <= 70 then break end
      end
      if params:get("clock_midi_out") ~= 1 then
        params:set("clock_tempo",util.round(derived_bpm))
      else
        params:set("clock_tempo",util.round(derived_bpm,0.01))
      end
    end
  elseif style == "imported_sample" then
    params:set("clock_tempo", source.original_bpm)
  end
end

function midi_pattern_watch(target,note)
  if note ~= "pause" then
    midi_p[target] = {}
    midi_p[target].note = note
    midi_p[target].target = target
    midi_pat[target]:watch(midi_p[target])
  else
    midi_pat[target]:watch("pause")
  end
end

function grid_pattern_watch(target,style,rel_pad)
  if style == nil then
    grid_p[target] = {}
    grid_p[target].action = "pads"
    grid_p[target].i = target
    grid_p[target].id = selected[target].id
    grid_p[target].x = selected[target].x
    grid_p[target].y = selected[target].y
    grid_p[target].rate = bank[target][bank[target].id].rate
    grid_p[target].start_point = bank[target][bank[target].id].start_point
    grid_p[target].end_point = bank[target][bank[target].id].end_point
    grid_p[target].rate_adjusted = false
    grid_p[target].loop = bank[target][bank[target].id].loop
    grid_p[target].pause = bank[target][bank[target].id].pause
    grid_p[target].mode = bank[target][bank[target].id].mode
    grid_p[target].clip = bank[target][bank[target].id].clip
    grid_pat[target]:watch(grid_p[target])
  elseif style == "pause" then
    grid_pat[target]:watch("pause")
  elseif style == "release" then
    grid_p[target] = {}
    grid_p[target].action = "pads-release"
    grid_p[target].i = target
    grid_p[target].id = rel_pad
    grid_pat[target]:watch(grid_p[target])
  end
end

function midi_pattern_execute(entry)
  if entry ~= nil then
    if entry ~= "pause" then
      mc.cheat(entry.target, entry.note)
      -- midi_cheat(entry.note, entry.target)
    end
  end
end

function clear_arps_from_pattern_restart(i)
  if i~= nil then
    if arp[i].enabled
    and not arp[i].pause
    -- and not arp[i].gate.active
    and pattern_gate[i][1].active and pattern_gate[i][2].active
    then
      arps.clear(i)
    end
  end
end

function dumb_thing_to_try()
  clock.run(function()
    while true do
      clock.sync(grid_pat[1].rec_clock_time)
      stop_pattern(grid_pat[1])
      grid_pat[1]:start()
    end
  end
)
end

function alt_synced_loop(target,state)
  if transport.is_running then
    if state == "restart" then
      clock.sync(params:get("launch_quantization") == 1 and 1 or 4)
      print("restarting")
    end
    clear_arps_from_pattern_restart(target.event[target.count].i)
    target:start()
    target.synced_loop_runner = 1
    -- print("alt_synced",clock.get_beats(),target)
    while true do
      clock.sync(1/4)
      if target.synced_loop_runner == target.rec_clock_time * 4 then
        target.synced_loop_runner = 1
        -- print(clock.get_beats(), target.synced_loop_runner)
        local overdub_flag = target.overdub
        -- target:stop()
        stop_pattern(target,"no kill")
        -- print("stopping")
        if overdub_flag == 1 then
          target.overdub = 1
        end
        if target.loop == 1 then
          clear_arps_from_pattern_restart(target.event[target.count].i)
          target:start()
          -- print("and then start...")
        end
      else
        target.synced_loop_runner =  target.synced_loop_runner + 1
      end
    end
  end
end

function stop_pattern(target,style)
  if target.clock ~= nil and style ~= "no kill" then
    clock.cancel(target.clock)
    target.clock = nil
  end
  local function wipe_slate(b)
    for i = 1,#grid_pat[b].event do
      if tab.contains(held_keys[b],grid_pat[b].event[i].id) then
        print(">>>***"..b,i,grid_pat[b].event[i].id, clock.get_beats())
        grid_actions.kill_note(b,grid_pat[b].event[i].id)
      end
    end
    if pattern_gate[b][1] and pattern_gate[b][2] and arp[b].enabled and not arp[b].hold then
      arp[b].down = 0
    end
  end
  target:stop()
  if target.name == "grid_pat[1]" then
    wipe_slate(1)
  elseif target.name == "grid_pat[2]" then
    wipe_slate(2)
  elseif target.name == "grid_pat[3]" then
    wipe_slate(3)
  end
end

function start_pattern(target,state)
  if not transport.is_running then
    print("should start transport...")
    transport.toggle_transport()
  end
  if transport.is_running then
    -- print("new start")
    if target.playmode == 2 then
      if target.clock ~= nil then clock.cancel(target.clock) end
      target.clock = clock.run(alt_synced_loop, target, state == nil and "restart" or "jumpstart")
    else
      target:start()
    end
  end
end

function synced_record_start(target,i)
  --midi_pat[i].sync_hold = true
  target.sync_hold = true
  clock.sync(4)
  --midi_pat[i]:rec_start()
  target:rec_start()
  --midi_pat[i].sync_hold = false
  target.sync_hold = false
  if target == midi_pat[i] then
    midi_pattern_watch(i, "pause")
  elseif target == grid_pat[i] then
    grid_pattern_watch(i, "pause")
  end
  clock.run(synced_pattern_record,target,i)
end

function synced_pattern_record(target,i)
  clock.sleep(clock.get_beat_sec()*target.rec_clock_time)
  if target.rec_clock ~= nil then
    if target == midi_pat[i] then
      target:rec_stop()
    else
      grid_actions.rec_stop(i)
    end
    pattern_length_to_bars(target, "destructive")
    if target.time[1] ~= nil and target.time[1] < clock.get_beat_sec()/4 and target.event[1] == "pause" then
      print("we could lose the first event..."..target.count, target.end_point)
      local butts = 0
      for i = 1,target.count do
        butts = butts + target.time[i]
      end
      -- print(butts)
      target.time[2] = target.time[2] + target.time[1]
      target.time_beats[2] = target.time_beats[2] + target.time_beats[1]
      table.remove(target.event,1)
      table.remove(target.time,1)
      table.remove(target.time_beats,1)
      target.count = #target.event
      target.end_point = target.count
      -- print(target.count, target.end_point)
    end
    if target.count > 0 then -- just in case the recording was canceled...
      --target:start()
      print("started first run..."..clock.get_beats())
      if target.clock ~= nil then print("canceled double clock "..clock.get_beats()) clock.cancel(target.clock) end
      target.clock = clock.run(alt_synced_loop, target)
    end
  else
    print("clock got canceled already, not going to restart it")
  end
end

function quantize_pattern_times(target, resolution)
  local goal = clock.get_beat_sec()/4
  local adjusted = nil
  for i = 1,target.count do
    target.quantum[i]= util.round(target.time[i] / goal)
    print("quantizes to "..target.quantum[i].." sixteenth notes")
    --[[
    if target.quantum[i] == 0 then
      table.remove(target.event,i)
      table.remove(target.time,i)
      table.remove(target.quantum,i)
    end
    --]]
  end
end

function pattern_length_to_bars(target, style)
  if target.rec == 0 and target.count > 0 then 
    local total_time = 0
    for i = target.start_point,target.end_point do
      total_time = total_time + target.time[i]
    end
    local clean_bars_from_time = util.round(total_time/(clock.get_beat_sec()*4),0.25)
    local add_time = ((clock.get_beat_sec()*4) * clean_bars_from_time) - total_time
    print(add_time, clean_bars_from_time)
    if style == "destructive" then
      target.time[#target.event] = target.time[#target.event] + add_time
    end
    target.clock_time = 4 * clean_bars_from_time
  end
end

function shuffle_midi_pat(target)
  pattern = midi_pat[target]
  for i = #pattern.event,2,-1 do
    local j = math.random(i)
    if pattern.event[j] ~= "pause" then
      local original, shuffled = pattern.event[i], pattern.event[j]
      original.note, shuffled.note = shuffled.note, original.note
      original.target, shuffled.target = shuffled.target, original.target
    end
  end
end

function random_midi_pat(target)
  local pattern = midi_pat[target]
  local auto_pat = params:get("random_patterning_"..target)
  local count = auto_pat == 1 and math.random(4,24) or 16
  if pattern.count > 0 or pattern.rec == 1 then
    pattern:rec_stop()
    stop_pattern(pattern)
    pattern:clear()
  end
  for i = 1,count do
    pattern.event[i] = {}
    local constructed = pattern.event[i]
    constructed.note = auto_pat == 1 and math.random(1,16) or snakes[auto_pat-1][i]
    constructed.target = target
    local assigning_pad = bank[target][constructed.note]
    local new_rates = 
    { [1] = math.pow(2,math.random(-3,-1))*((math.random(1,2)*2)-3)
    , [2] = math.pow(2,math.random(-1,1))*((math.random(1,2)*2)-3)
    , [3] = math.pow(2,math.random(1,2))*((math.random(1,2)*2)-3)
    , [4] = math.pow(2,math.random(-2,2))*((math.random(1,2)*2)-3)
    , [5] = assigning_pad.rate
    }
    assigning_pad.rate = new_rates[pattern.random_pitch_range]
    local new_levels = 
    { [0.125] = 1.75
    , [0.25]  = 1.5
    , [0.5]   = 1.25
    , [1.0]   = 1.0
    , [2.0]   = 0.75
    , [4.0]   = 0.5
    }
    assigning_pad.level = new_levels[math.abs(assigning_pad.rate)]
    local tempo = clock.get_beat_sec()
    local divisors = { 4,2,1,0.5,0.25,math.pow(2,math.random(-2,2)) }
    local note_length = (tempo / divisors[params:get("rand_pattern_"..target.."_note_length")])
    pattern.time[i] = note_length
    pattern.time_beats[i] = pattern.time[i] / tempo
    pattern:calculate_quantum(i)
  end
  pattern.count = count
  pattern.start_point = 1
  pattern.end_point = count
  pattern_length_to_bars(pattern, "destructive")
  print("2216")
  start_pattern(pattern)
end

---

function pad_clock_triplets()
  while true do
    clock.sync(1/6)
    for i = 1,3 do
      cheat_clock_synced(i)
    end
  end
end

function pad_clock()
  while true do
    clock.sync(1/4)
    for i = 1,3 do
      cheat_clock_synced(i)
    end
  end
end

function random_rec_clock()
  while true do
    local lbr = {1,2,4}
    local rler = rec_loop_enc_resolution
    local rec_distance = rec[rec.focus].end_point - rec[rec.focus].start_point
    local bar_count = params:get("rec_loop_enc_resolution") > 2 and (((rec_distance)/(1/rler)) / (rler))*(2*lbr[params:get("live_buff_rate")]) or (rec_distance/clock.get_beat_sec())/4
    clock.sync(params:get("rec_loop_"..rec.focus) == 1 and 4 or bar_count)
    local random_rec_prob = params:get("random_rec_clock_prob_"..rec.focus)
    if random_rec_prob > 0 then
      local random_rec_comp = math.random(0,100)
      if random_rec_comp < random_rec_prob then
        if params:get("rec_loop_"..rec.focus) == 1 then
          _ca.toggle_buffer(rec.focus,true)
        elseif params:get("rec_loop_"..rec.focus) == 2 and rec[rec.focus].end_point < poll_position_new[1] +0.015 then
          _ca.toggle_buffer(rec.focus,true)
        end
      end
    end
  end
end

function run_one_shot_rec_clock()
  one_shot_rec_clock = clock.run(one_shot_clock)
end

function cancel_one_shot_rec_clock()
  print("cancel_one_shot_rec_clock: executing")
  if one_shot_rec_clock ~= nil then
    clock.cancel(one_shot_rec_clock)
  end
  -- rec[rec.focus].state = 0
  _ca.buff_freeze()
  rec_state_watcher:stop()
  rec.stopped = true
  grid_dirty = true
  if menu == 2 then
    if page.loops.sel ~= 5 then
      screen_dirty = true
    end
  end
  one_shot_rec_clock = nil
  rec[rec.focus].end_point = poll_position_new[1]
  update_waveform(1,key1_hold and rec[rec.focus].start_point or live[rec.focus].min,key1_hold and rec[rec.focus].end_point or live[rec.focus].max,128)

end

function one_shot_clock()
  rec[rec.focus].queued = true
  if rec[rec.focus].state == 1 and rec_state_watcher.is_running then
    rec_state_watcher:stop()
  end
  if params:get("one_shot_clock_div") < 3 then
    local divs = {1,4}
    local rate = divs[params:get("one_shot_clock_div")]
    clock.sync(rate)
  end
  -- softcut.loop_start(1,rec[rec.focus].start_point-0.05)
  if params:string("one_shot_clock_div") ~= "threshold" then
    softcut.loop_start(1,rec[rec.focus].start_point-(params:get("one_shot_latency_offset")))
  else
    softcut.loop_start(1,rec[rec.focus].start_point+params:get("one_shot_latency_offset"))
  end
  if params:string("one_shot_clock_div") ~= "threshold" then
    softcut.position(1,rec[rec.focus].start_point-((params:get("one_shot_latency_offset")-0.01))) -- TODO CLARIFY IF THIS IS REAL ANYMORE
  else
    softcut.position(1,rec[rec.focus].start_point+params:get("one_shot_latency_offset")) -- TODO CLARIFY IF THIS IS REAL ANYMORE
  end
  softcut.loop_end(1,rec[rec.focus].end_point)
  -- softcut.position(1,rec[rec.focus].start_point+0.01)
  softcut.pre_level(1,params:get("live_rec_feedback_"..rec.focus))
  softcut.rec_level(1,1)
  rec.play_segment = rec.focus
  rec[rec.focus].state = 1
  rec.stopped = false
  rec_state_watcher:start()
  if rec[rec.focus].clear == 1 then rec[rec.focus].clear = 0 end
  grid_dirty = true
  rec[rec.focus].queued = false
end

function compare_rec_resolution(x)
  local current_mult = (rec[rec.focus].end_point - rec[rec.focus].start_point) / (1/rec_loop_enc_resolution)
  local resolutions =
    { [1] = 10
    , [2] = 100
    , [3] = 1/(clock.get_beat_sec()/4)
    , [4] = 1/(clock.get_beat_sec()/2)
    , [5] = 1/(clock.get_beat_sec())
    , [6] = (1/(clock.get_beat_sec()))/2
    , [7] = (1/(clock.get_beat_sec()))/4
    }
  rec_loop_enc_resolution = resolutions[x]
  if x > 2 then
    local lbr = {1,2,4}
    rec[rec.focus].end_point = rec[rec.focus].start_point + (((1/rec_loop_enc_resolution)*current_mult)/lbr[params:get("live_buff_rate")])
    softcut.loop_start(1,rec[rec.focus].start_point)
    softcut.loop_end(1,rec[rec.focus].end_point)
    if menu ~= 1 then screen_dirty = true end
  end
end

function compare_loop_resolution(target,x)
  for i = 1,16 do
    local pad = bank[target][i]
    local resolutions =
      { [1] = 10
      , [2] = 100
      , [3] = 1/(clock.get_beat_sec()/4)
      , [4] = 1/(clock.get_beat_sec()/2)
      , [5] = 1/(clock.get_beat_sec())
      , [6] = (1/(clock.get_beat_sec()))/2
      , [7] = (1/(clock.get_beat_sec()))/4
      }
    loop_enc_resolution[pad.bank_id] = resolutions[x]
    if x > 2 then
      pad.end_point = pad.start_point + (((1/loop_enc_resolution[pad.bank_id])))
    end
  end
  softcut.loop_start(target+1,bank[target][bank[target].id].start_point)
  softcut.loop_end(target+1,bank[target][bank[target].id].end_point)
  if menu ~= 1 then screen_dirty = true end
end

function globally_clocked()
  while true do
    clock.sync(1/4)
    -- if menu == 7 or menu == "transport_config" then
    --   if menu ~= 1 then screen_dirty = true end
    -- end
    if menu == 7 or menu == "transport_config" or (menu == 1 and transport.is_running) then
      screen_dirty = true
    end
    if norns.cpu_avg > 40 then
      print("norns CPU above 40: "..norns.cpu_avg)
    end
    -- TODO CONFIRM THIS SHOULD HAPPEN:
    if menu == 2 then
      screen_dirty = true
    end
    -- update_tempo()
    for i = 1,3 do
      if grid_pat[i].led == nil then
        grid_pat[i].led = 0
        grid_dirty = true
      end
      if grid_pat[i].rec == 1 then
        local blink = math.fmod(clock.get_beats(),1)
        if blink <= 0.25 then
          blink = 1
        elseif blink <= 0.5 then
          blink = 2
        elseif blink <= 0.75 then
          blink = 3
        else
          blink = 4
        end
        if blink == 1 then
          grid_pat[i].led = 1
          grid_dirty = true
        else
          grid_pat[i].led = 0
          grid_dirty = true
        end
      end
    end
    for i = 1,3 do
      if grid_pat[i].tightened_start == 1 then
        internal_clocking_tightened(i)
      end
    end
    -- print("butts")
    -- grid_dirty = true
  end
end

osc_in = function(path, args, from)
  if osc_communication ~= true then
    params:set("osc_IP",from[1])
    params:set("osc_port",from[2])
    osc_communication = true
  end
  for i = 1,3 do
    local target = bank[i][bank[i].id]
    if path == "/pad_sel_"..i then
      if args[1] ~= 0 then
        bank[i].id = util.round(args[1])
        cheat(i,bank[i].id)
        if menu ~= 1 then screen_dirty = true end
      end
    elseif path == "/randomize_this_bank_"..i then
      random_grid_pat(i,3)
      for j = 2,16 do
        bank[i][j].start_point = (math.random(10,30)/10)+(32*(bank[i][j].clip-1))
        bank[i][j].end_point = bank[i][j].start_point + (math.random(10,60)/10)
        bank[i][j].pan = math.random(-100,100)/100
      end
      grid_actions.rec_stop(i)
      -- grid_pat[i]:stop()
      stop_pattern(grid_pat[i])
      grid_pat[i].tightened_start = 0
    elseif path == "/pad_rate_"..i then
      target.rate = args[1]
      softcut.rate(i+1,target.rate)
    elseif path == "/bank_rate_"..i then
      for j = 1,16 do
        bank[i][j].rate = args[1]
      end
      softcut.rate(i+1,target.rate)
    elseif path == "/pad_rev_"..i then
      target.rate = target.rate * - 1
      softcut.rate(i+1,target.rate)
    elseif path == "/bank_rev_"..i then
      local direction;
      if target.rate > 0 then
        direction = 1
      else
        direction = -1
      end
      for j = 1,16 do
        bank[i][j].rate = math.abs(bank[i][j].rate)*(-1*direction)
      end
      softcut.rate(i+1,target.rate)
    elseif path == "/bank_rand_rate_"..i then
      for j = 1,16 do
        bank[i][j].rate = math.pow(2,math.random(-3,2))*((math.random(1,2)*2)-3)
      end
      softcut.rate(i+1,target.rate)
    elseif path == "/sixteenths_"..i then
      for j = 1,16 do
        local pad = bank[i][j]
        local duration = pad.mode == 1 and 32 or clip[pad.clip].sample_length
        local s_p = pad.mode == 1 and live[pad.clip].min or clip[pad.clip].min
        pad.end_point = pad.start_point + (clock.get_beat_sec()/4)
      end
      softcut.loop_start(i+1,target.start_point)
      softcut.loop_end(i+1,target.end_point)
    elseif path == "/chop_"..i then
      for j = 1,16 do
        local duration;
        local pad = bank[i][j]
        if pad.mode == 1 then
          --slice within bounds
          duration = rec[rec.focus].end_point-rec[rec.focus].start_point
          local s_p = rec[rec.focus].start_point+(32*(pad.clip-1))
          pad.start_point = (s_p+(duration/16) * (pad.pad_id-1))
          pad.end_point = (s_p+((duration/16) * (pad.pad_id)))
        else
          duration = pad.mode == 1 and 32 or clip[pad.clip].sample_length
          pad.start_point = ((duration/16)*(pad.pad_id-1)) + clip[pad.clip].min
          pad.end_point = pad.start_point + (duration/16)
        end
      end
      softcut.loop_start(i+1,target.start_point)
      softcut.loop_end(i+1,target.end_point)
    elseif path == "/rand_loop_points_"..i then
      for j = 1,16 do
        local duration, max_end, min_start;
        local pad = bank[i][j]
        if pad.mode == 1 and pad.clip == rec.focus then
          duration = rec[rec.focus].end_point-rec[rec.focus].start_point
          max_end = math.floor(pad.end_point * 100)-10
          if max_end < math.floor(rec[rec.focus].start_point * 100) then
            min_start = math.floor(((duration*(pad.clip-1))+1) * 100)
          else
            min_start = math.floor(rec[rec.focus].start_point * 100) -- this sucks...
          end
        elseif pad.mode == 2 then
          max_end = math.floor(pad.end_point * 100)
          min_start = math.floor(clip[pad.clip].min * 100)
        else
          duration = pad.mode == 1 and 32 or math.modf(clip[pad.clip].sample_length)
          max_end = math.floor(pad.end_point * 100)
          min_start = math.floor(((duration*(pad.clip-1))+1) * 100)
        end
        pad.start_point = math.random(min_start,max_end)/100
        if pad.mode == 1 and pad.clip == rec.focus then
          duration = rec[rec.focus].end_point-rec[rec.focus].start_point
          max_end = math.floor(rec[rec.focus].end_point*100)
          if pad.start_point > rec[rec.focus].start_point then
            min_start = math.floor(pad.start_point * 100)+10
          else
            min_start = math.floor(rec[rec.focus].start_point * 100)
          end
        elseif pad.mode == 2 then
          max_end = math.floor(clip[pad.clip].max * 100)
          min_start = math.floor(pad.start_point * 100)
        else
          duration = util.round(clip[pad.clip].sample_length)
          max_end = math.floor(((duration*pad.clip)+1) * 100)
          min_start = math.floor(pad.start_point * 100)
        end
        pad.end_point = math.random(min_start,max_end)/100
      end
      softcut.loop_start(i+1,target.start_point)
      softcut.loop_end(i+1,target.end_point)
    elseif path == "/filter_cut_bank_"..i then
      encoder_actions.set_filter_cutoff(i,args[1])
    end
  end
end

osc.event = osc_in

function osc_redraw(i)
  if osc_echo then
    local target = bank[i][bank[i].id]
    osc.send(dest, "/pad_start_point_"..i, {target.start_point})
    osc.send(dest, "/pad_end_point_"..i, {target.end_point})
    osc.send(dest, "/pad_rate_"..i, {target.rate})
  end
end

poll_position_new = {}
playhead_at_endpoint = {false,false,false}

phase = function(n, x)
  poll_position_new[n] = x
  if n > 1 and n < 5 and menu == 2 then
    -- if util.round(x,0.01) == util.round(bank[n-1][bank[n-1].id].end_point,0.01) then
    if bank[n-1][bank[n-1].id].rate > 0 then
      if math.modf(util.round(x,0.01)*100) == math.modf(bank[n-1][bank[n-1].id].end_point*100) then
        playhead_at_endpoint[n-1] = true
      else
        playhead_at_endpoint[n-1] = false
      end
    elseif bank[n-1][bank[n-1].id].rate < 0 then
      if math.modf(util.round(x,0.01)*100) == math.modf(bank[n-1][bank[n-1].id].start_point*100) then
        playhead_at_endpoint[n-1] = true
      else
        playhead_at_endpoint[n-1] = false
      end
    end
  end
end

function update_tempo()
  compare_rec_resolution(params:get("rec_loop_enc_resolution"))
  for i = 1,3 do
    compare_loop_resolution(i,params:get("loop_enc_resolution_"..i))
  end
  for i = 1,3 do
    for j = 1,16 do
      bank[i][j].envelope_time = (clock.get_beat_sec() * lfo_rates.values[bank[i][j].envelope_rate_index]) * 4
      bank[i][j].pan_lfo.freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[bank[i][j].pan_lfo.rate_index])
    end
    bank[i].level_lfo.freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[bank[i].level_lfo.rate_index])
    env_counter[i].time = (bank[i][bank[i].id].envelope_time/(bank[i][bank[i].id].level/0.05))
    del.sync_lfos()
    macros.sync_lfos()
    _dough.scale_sample_to_main(i)
    --quantizer[i].time = interval
    --grid_pat_quantizer[i].time = interval_pats
  end
end

function rec_count()
  rec_time = rec_time + 0.01
end

function sixteen_slices(x)
  local s_p = rec[rec.focus].start_point
  local e_p = rec[rec.focus].end_point
  local distance = e_p-s_p
  local b = bank[x]
  local pad = b.focus_hold and b.focus_pad or b.id
  local function map_em(i)
    b[i].start_point = s_p+((distance/16) * (i-1))
    b[i].end_point = s_p+((distance/16) * (i))
    b[i].clip = rec.focus
  end
  if not b.focus_hold then
    for i = 1,16 do
      map_em(i)
    end
  else
    map_em(pad)
  end
  if b[b.id].loop == true then
    cheat(x,b.id)
  end
end

function rec_to_pad(b)
  local s_p = rec[rec.focus].start_point
  local e_p = rec[rec.focus].end_point
  local distance = e_p-s_p
  bank[b][bank[b].id].start_point = s_p+((distance/16) * (bank[b].id-1))
  bank[b][bank[b].id].end_point = s_p+((distance/16) * (bank[b].id))
  bank[b][bank[b].id].clip = rec.focus
  if bank[b][bank[b].id].loop == true then
    cheat(b,bank[b].id)
  end
end

function pad_to_rec(b)
  local pad = bank[b][bank[b].id]
  local s_p = pad.start_point-(32*(pad.clip-1))
  local e_p = pad.end_point-(32*(pad.clip-1))
  rec[rec.focus].start_point = s_p+(32*(rec.focus-1))
  rec[rec.focus].end_point = e_p+(32*(rec.focus-1))
  softcut.loop_start(1,rec[rec.focus].start_point)
  softcut.loop_end(1,rec[rec.focus].end_point-0.01)
  softcut.position(1,rec[rec.focus].start_point)
end

function reset_all_banks( banks )
  cross_filter = {} -- TODO put into the banks
  for i = 1,3 do
    banks[i] = {}
    local b = banks[i] -- alias
    b.id = 1 -- currently playing pad_id
    b.ext_clock = 1
    b.focus_hold = false
    b.focus_pad = 1
    b.random_mode = 3
    b.crow_execute = 1
    b.snap_to_bars = 1
    b.quantize_press = 0 -- not real, just keeping for continuity...
    b.quantize_press_div = 1 -- not real, just keeping for continuity...
    b.quantized_press = false
    b.quantized_press_div = 1
    b.alt_lock = false
    b.global_level = 1.0

    -- b.pan_lfo =
    -- {
    --   freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[15]),
    --   counter = 1,
    --   waveform = lfo_types[1],
    --   slope = 0,
    --   depth = 100,
    --   offset = 0,
    --   active = false,
    --   loop = true
    -- }

    -- b.level_lfo =
    -- {
    --   freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[15]),
    --   counter = 1,
    --   waveform = lfo_types[1],
    --   slope = 0,
    --   depth = 100,
    --   offset = 0,
    --   active = false,
    --   loop = true,
    --   rate_index = 15
    -- }

    -- b.filter_lfo =
    -- {
    --   freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[15]),
    --   counter = 1,
    --   waveform = lfo_types[1],
    --   slope = 0,
    --   depth = 100,
    --   offset = 0,
    --   active = false,
    --   loop = true
    -- }


    for k = 1,16 do
-- TODO suggest nesting tables for delay,filter,tilt etc
      b[k] = {}
      local pad = b[k] --alias
      pad.bank_id           = i -- capture which bank we're in
      pad.pad_id            = k -- capture which pad of 16
      pad.clip              = 1 -- TODO make this a table with length for start/end calculation
      pad.mode              = 1
        -- TODO these are both identical to zilchmos.start_end_default()
      pad.start_point       = 1+((32/16) * (pad.pad_id-1))
      pad.end_point         = 1+((32/16) *  pad.pad_id)
      pad.start_offset      = 0
      pad.sample_end        = 8
      pad.rate              = 1.0
      pad.left_delay_time   = 0.5 -- [delay] controls these
      pad.right_delay_time  = 0.5 -- [delay] controls these
      pad.pause             = false
      pad.play_mode         = "latch"
      pad.level             = 1.0
      pad.left_delay_level  = 1
      pad.right_delay_level = 1
      pad.loop              = false
      pad.fifth             = false
      pad.pan               = 0.0
      pad.pan_lfo           = {}
      pad.pan_lfo.waveform  = "sine"
      pad.pan_lfo.freq      = 1/((clock.get_beat_sec()*4))
      pad.pan_lfo.depth     = 100
      pad.pan_lfo.active    = false
      pad.pan_lfo.rate_index= 15
      pad.pan_lfo.loop      = true
      -- FIXME these are both just 0.5. why compute them? could instead call that fn?
      pad.left_delay_pan    = util.linlin(-1,1,0,1,pad.pan) * pad.left_delay_level
      pad.right_delay_pan   = util.linlin(-1,1,1,0,pad.pan) * pad.right_delay_level
      pad.fc                = 12000
      pad.q                 = 2.0
      pad.lp                = 1.0
      pad.hp                = 0.0
      pad.bp                = 0.0
      pad.fd                = 0.0
      pad.br                = 0.0
      pad.tilt              = 0
      pad.tilt_ease_type    = 1
      pad.tilt_ease_time    = 50
      pad.cf_fc             = 12000
      pad.cf_lp             = 0
      pad.cf_hp             = 0
      pad.cf_dry            = 1
      pad.cf_exp_dry        = 1
      pad.filter_type       = 4

      pad.enveloped         = false
      pad.envelope_mode     = 0
      pad.envelope_time     = (clock.get_beat_sec() * lfo_rates.values[15]) * 4
      pad.envelope_loop     = false
      pad.envelope_rate_index = 15

      pad.level_lfo           = {}
      pad.level_lfo.waveform  = "sine"
      pad.level_lfo.freq      = 1/((clock.get_beat_sec()*4) * lfo_rates.values[15])
      pad.level_lfo.depth     = 100
      pad.level_lfo.active    = false
      pad.level_lfo.rate_index= 15
      pad.level_lfo.loop      = true

      pad.filter_lfo           = {}
      pad.filter_lfo.waveform  = "sine"
      pad.filter_lfo.freq      = 1/((clock.get_beat_sec()*4) * lfo_rates.values[15])
      pad.filter_lfo.depth     = 100
      pad.filter_lfo.active    = false
      pad.filter_lfo.rate_index= 15
      pad.filter_lfo.loop      = true

      pad.clock_resolution  = 4
      pad.offset            = 1.0
      pad.send_pad_note     = true
      pad.left_delay_thru   = false
      pad.right_delay_thru  = false
      pad.rate_slew         = 0
      pad.arp_time          = 1/4

      pad.dough_stretch     = true
      pad.drone             = false
    end
    cross_filter[i]         = {}
    cross_filter[i].fc      = 12000
    cross_filter[i].lp      = 0
    cross_filter[i].hp      = 0
    cross_filter[i].dry     = 1
    cross_filter[i].exp_dry = 1

    b.pan_lfo =
    {
      freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[15]),
      counter = (math.asin(b[b.id].pan) + (tau/(1/((clock.get_beat_sec()*4) * lfo_rates.values[15]))))/(tau/100),
      waveform = lfo_types[1],
      slope = 0,
      depth = 100,
      offset = 0,
      active = false,
      loop = true
    }

    b.level_lfo =
    {
      freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[15]),
      counter = 1,
      waveform = lfo_types[1],
      slope = 0,
      depth = 100,
      offset = 0,
      active = false,
      loop = true,
      rate_index = 15
    }

    b.filter_lfo =
    {
      freq = 1/((clock.get_beat_sec()*4) * lfo_rates.values[15]),
      counter = 1,
      waveform = lfo_types[1],
      slope = 0,
      depth = 100,
      offset = 0,
      active = false,
      loop = true
    }

    cheat(i,bank[i].id)
  end
end

function find_the_key(t,val)
  for k,v in pairs(t) do
    if v == val then return k end
  end
  return nil
end

function cheat(b,i,silent)
  local pad = bank[b][i]
  b = util.round(b)
  i = util.round(i)
  if all_loaded and silent == nil then
    mc.midi_note_from_pad(util.round(b),util.round(i))
    mc.route_midi_mod(b,i)
    -- if softcut_voices_are_paused[b] == true then
    --   softcut.play(b+1,1)
    -- end
  end
  if env_counter[b].is_running then
    env_counter[b]:stop()
  end
  softcut.rate_slew_time(b+1,pad.rate_slew)
  if pad.enveloped and not pad.pause then
    if pad.envelope_mode == 1 then
      env_counter[b].butt = pad.level + 0.05
      env_counter[b].l_del_butt = pad.left_delay_level
      env_counter[b].r_del_butt = pad.right_delay_level
      softcut.level_slew_time(b+1,0.05)
      -- softcut.level(b+1,pad.level*bank[b].global_level)
      softcut.level(b+1,pad.level*_l.get_global_level(b))
      _l.calc_delay_sends(b,i,{"L","R"})
      -- softcut.level_cut_cut(b+1,5,(pad.level*bank[b].global_level)*pad.left_delay_level)
      -- softcut.level_cut_cut(b+1,6,(pad.level*bank[b].global_level)*pad.right_delay_level)
      if pad.level > 0.05 then
        env_counter[b].time = (pad.envelope_time/(util.round(pad.level/0.05)+1))
      end
    elseif pad.envelope_mode == 2 or pad.envelope_mode == 3 then
      softcut.level_slew_time(b+1,0.01)
      -- softcut.level(b+1,0*bank[b].global_level)
      softcut.level(b+1,0*_l.get_global_level(b))
      softcut.level_cut_cut(b+1,5,0)
      softcut.level_cut_cut(b+1,6,0)
      env_counter[b].butt = 0
      env_counter[b].l_del_butt = 0
      env_counter[b].r_del_butt = 0
      if pad.envelope_mode == 3 then env_counter[b].stage = "rising" end
      if pad.level > 0.05 then
        env_counter[b].time = (pad.envelope_time/(util.round(pad.level/0.05)+(pad.level<1.1 and 1 or 0))) * (pad.envelope_mode == 3 and 0.5 or 1)
      end
    end
    env_counter[b]:start()
    -- print("start of env: "..clock.get_beats())
  elseif not pad.enveloped and not pad.pause then
    softcut.level_slew_time(b+1,0.01)
    -- softcut.level(b+1,pad.level*bank[b].global_level)
    softcut.level(b+1,pad.level*_l.get_global_level(b))
    -- _lfos.process_cheat(b,i,"level_lfo")
    if not delay[1].send_mute then
      if pad.left_delay_thru then
        softcut.level_cut_cut(b+1,5,pad.left_delay_level)
      else
        -- softcut.level_cut_cut(b+1,5,(pad.left_delay_level*pad.level)*bank[b].global_level)
        _l.calc_delay_sends(b,i,{"L"})
      end
    end
    if not delay[2].send_mute then
      if pad.right_delay_thru then
        softcut.level_cut_cut(b+1,6,pad.right_delay_level)
      else
        -- softcut.level_cut_cut(b+1,6,(pad.right_delay_level*pad.level)*bank[b].global_level)
        _l.calc_delay_sends(b,i,{"R"})
      end
    end
  end
  -- OH ALL THIS SUCKS TODO FIXME
  -- if pad.end_point - pad.start_point < 0.11 then
  --   pad.end_point = pad.start_point + 0.1
  -- end
  if pad.mode == 1 then
    if pad.end_point == 9 or pad.end_point == 17 or pad.end_point == 25 then
      pad.end_point = pad.end_point-0.01
    end
  end
  --/ OH ALL THIS SUCKS TODO FIXME
  if pad.pause == false then
    softcut.rate(b+1,pad.rate*pad.offset)
  else
    softcut.rate(b+1,0)
  end
  if params:string("doughstretch_mode_"..b) == "off" then
    -- softcut.fade_time(b+1,variable_fade_time) -- doesn't need to be defined every cheat
  end
  softcut.loop_start(b+1,pad.start_point)
  if dough_stretch~=nil then
    if params:string("doughstretch_mode_"..b) ~= "off" then
      dough_stretch[b].pos = pad.start_point
      dough_stretch[b].enabled = pad.dough_stretch
    end
  end
  softcut.loop_end(b+1,pad.end_point)
  softcut.buffer(b+1,pad.mode)
  if pad.loop == false then
    softcut.loop(b+1,0)
  else
    softcut.loop(b+1,1)
  end
  if pad.rate > 0 then
    -- softcut.position(b+1,pad.start_point+0.05)
    softcut.position(b+1,pad.start_point+variable_fade_time)
  elseif pad.rate < 0 then
    -- softcut.position(b+1,pad.end_point-variable_fade_time-0.05)
    softcut.position(b+1,pad.end_point-variable_fade_time-0.01)
  end
  -- if slew_counter[b] ~= nil then
  --   slew_counter[b].next_tilt = pad.tilt
  --   slew_counter[b].next_q = pad.q
  --   if pad.tilt_ease_type == 1 then
  --     if slew_counter[b].slewedVal ~= nil and math.floor(slew_counter[b].slewedVal*10000) ~= math.floor(slew_counter[b].next_tilt*10000) then
  --       if math.floor(slew_counter[b].prev_tilt*10000) ~= math.floor(slew_counter[b].slewedVal*10000) then
  --         slew_counter[b].interrupted = 1
  --         slew_filter(util.round(b),slew_counter[b].slewedVal,slew_counter[b].next_tilt,slew_counter[b].prev_q,slew_counter[b].next_q,pad.tilt_ease_time)
  --       else
  --         slew_counter[b].interrupted = 0
  --         slew_filter(util.round(b),slew_counter[b].prev_tilt,slew_counter[b].next_tilt,slew_counter[b].prev_q,slew_counter[b].next_q,pad.tilt_ease_time)
  --       end
  --     end
  --   elseif pad.tilt_ease_type == 2 then
  --     slew_filter(util.round(b),slew_counter[b].prev_tilt,slew_counter[b].next_tilt,slew_counter[b].prev_q,slew_counter[b].next_q,pad.tilt_ease_time)
  --   end
  -- end
  -- softcut.pan(b+1,pad.pan)
  -- _p.process_cheat(b,i)
  _lfos.process_cheat(b,i,"pan_lfo")
  -- _lfos.process_cheat(b,i,"level_lfo")
  del.update_delays()
  -- if slew_counter[b] ~= nil then
  --   slew_counter[b].prev_tilt = pad.tilt
  --   slew_counter[b].prev_q = pad.q
  -- end
  previous_pad = bank[b].id
  if bank[b].crow_execute == 1 then
    if pad.send_pad_note then
      -- crow.output[b]()
    end
  end
  --dangerous??
  local rate_array = {-4.0,-2.0,-1.0,-0.5,-0.25,-0.125,0.125,0.25,0.5,1.0,2.0,4.0}
  local s = {}
  for k,v in pairs(rate_array) do
    s[v]=k
  end
  if pad.fifth == false then
    if s[pad.rate] ~= nil then
      params:set("rate "..tonumber(string.format("%.0f",b)),s[pad.rate],true) -- TODO: confirm silent update is good...
    else
      pad.fifth = true
    end
  end
  mc.params_redraw(pad)
  if osc_communication == true then
    osc_redraw(b)
  end

  if all_loaded and params:get("midi_control_enabled") == 1 and params:get("midi_echo_enabled") == 2 then
    mc.redraw(pad)
  end

  if all_loaded and params:get("midi_enc_echo_enabled") == 2 then
    if midi_dev[params:get("midi_enc_control_device")].name == "Midi Fighter Twister" then
      if bank[pad.bank_id].focus_hold == false then
        mc.mft_redraw(pad,"all")
      end
    else
      mc.enc_redraw(pad)
    end
  end

  -- redraw waveform if it's zoomed in and the pad changes
  -- TODO UPDATE FOR GUHHHH
  -- if menu == 2 and page.loops.sel == b and page.loops.frame == 2 and not key2_hold and key1_hold then
  -- if menu == 2 and page.loops.sel == b and not key2_hold and key1_hold then
  if menu == 2 and page.loops.sel == b and key2_hold then
    local focused_pad;
    if bank[page.loops.sel].focus_hold then
      focused_pad = bank[page.loops.sel].focus_pad
    elseif grid_pat[page.loops.sel].play == 0 and midi_pat[page.loops.sel].play == 0 and not arp[page.loops.sel].playing and rytm.track[page.loops.sel].k == 0 then
      focused_pad = bank[page.loops.sel].id
    else
      focused_pad = bank[page.loops.sel].focus_pad
    end
    local mode = bank[page.loops.sel][focused_pad].mode
    local min = bank[page.loops.sel][focused_pad].start_point
    local max = bank[page.loops.sel][focused_pad].end_point
    update_waveform(mode,min,max,128)
  end

  if all_loaded and silent == nil then
    if softcut_voices_are_paused[b] == true then
      softcut.play(b+1,1)
    end
  end

end

function envelope(i)
  -- softcut.level_slew_time(i+1,0.1)
  if bank[i][bank[i].id].envelope_mode == 1 then
    falling_envelope(i)
  elseif bank[i][bank[i].id].envelope_mode == 2 then
    rising_envelope(i)
  elseif bank[i][bank[i].id].envelope_mode == 3 then
    if env_counter[i].stage == nil then env_counter[i].stage = "rising" end
    if env_counter[i].stage == "rising" then
      rising_envelope(i)
    elseif env_counter[i].stage == "falling" then
      falling_envelope(i)
    end
  end
end

function sidechain(source,target)
  if source.envelope_mode == 1 then
    rising_envelope(target.bank_id)
    -- a falling source would mean a rising target
  elseif source.envelope_mode == 2 then
    -- a rising source would mean a falling target
  elseif source.envelope_mode == 3 then
    -- a rise/fall source would mean a fall/rise target
  end
end

function falling_envelope(i)
  if env_counter[i].butt > 0.05 then
    env_counter[i].butt = env_counter[i].butt - 0.05
  else
    env_counter[i].butt = 0
  end
  if util.round(env_counter[i].butt,0.05) > 0 and bank[i][bank[i].id].level > 0 then
    -- print("butt: "..env_counter[i].butt, clock.get_beats())
    local e_c = util.clamp(easingFunctions[n_s](env_counter[i].butt,0,1,1),0,bank[i][bank[i].id].level)
    -- print(e_c,env_counter[i].butt)
    if bank[i][bank[i].id].envelope_time >= 0.1 then
      softcut.level_slew_time(i+1,0.05)
    else
      softcut.level_slew_time(i+1,0.01)
    end
     -- TODO: shouldn't have to declare this^^
    -- softcut.level(i+1,e_c*bank[i].global_level)
    softcut.level(i+1,e_c*_l.get_global_level(i))
    local del_levels = {"left_delay_level","right_delay_level"}
    for j = 1,2 do
      if delay[j].send_mute then
        if bank[i][bank[i].id][del_levels[j]] == 0 then
          -- softcut.level_cut_cut(i+1,4+j,(e_c*bank[i].global_level)*1)
          softcut.level_cut_cut(i+1,4+j,(e_c*_l.get_global_level(i))*1)
        else
          -- softcut.level_cut_cut(i+1,4+j,(e_c*bank[i].global_level)*0)
          softcut.level_cut_cut(i+1,4+j,(e_c*_l.get_global_level(i))*0)
        end
      else
        -- softcut.level_cut_cut(i+1,4+j,(e_c*bank[i].global_level)*bank[i][bank[i].id][del_levels[j]])
        softcut.level_cut_cut(i+1,4+j,(e_c*_l.get_global_level(i))*bank[i][bank[i].id][del_levels[j]])
      end
    end
  else
    -- print("end of fall: "..clock.get_beats())
    env_counter[i]:stop()
    softcut.level_slew_time(i+1,1.0)
    -- softcut.level(i+1,0*bank[i].global_level)
    softcut.level(i+1,0*_l.get_global_level(i))
    env_counter[i].butt = bank[i][bank[i].id].level+0.05
    softcut.level_cut_cut(i+1,5,0)
    softcut.level_cut_cut(i+1,6,0)
    if bank[i][bank[i].id].envelope_mode == 3 then
      env_counter[i].stage = nil
      env_counter[i].butt = 0
    end
    if bank[i][bank[i].id].envelope_loop == true then
      env_counter[i]:start()
    end
  end
end

function rising_envelope(i)
  env_counter[i].butt = env_counter[i].butt + 0.05
  if env_counter[i].butt < bank[i][bank[i].id].level then
    local e_c = util.clamp(easingFunctions[n_s](env_counter[i].butt,0,1,1),0,bank[i][bank[i].id].level)
    softcut.level_slew_time(i+1,0.01)
    -- softcut.level(i+1,e_c*bank[i].global_level)
    softcut.level(i+1,e_c*_l.get_global_level(i))
    for j = 1,2 do
      if delay[j].send_mute then
        if bank[i][bank[i].id].left_delay_level == 0 then
          -- softcut.level_cut_cut(i+1,4+j,(e_c*bank[i].global_level)*1)
          softcut.level_cut_cut(i+1,4+j,(e_c*_l.get_global_level(i))*1)
        else
          -- softcut.level_cut_cut(i+1,4+j,(e_c*bank[i].global_level)*0)
          softcut.level_cut_cut(i+1,4+j,(e_c*_l.get_global_level(i))*0)
        end
      else
        -- softcut.level_cut_cut(i+1,4+j,(e_c*bank[i].global_level)*bank[i][bank[i].id].left_delay_level)
        softcut.level_cut_cut(i+1,4+j,(e_c*_l.get_global_level(i))*bank[i][bank[i].id].left_delay_level)
      end
    end
  else
    env_counter[i]:stop()
    -- softcut.level(i+1,bank[i][bank[i].id].level*bank[i].global_level)
    softcut.level(i+1,bank[i][bank[i].id].level*_l.get_global_level(i))
    env_counter[i].butt = 0
    local del_thrus = {"left_delay_thru","right_delay_thru"}
    local del_sides = {"left_delay_level","right_delay_level"}
    for j = 1,2 do
      if bank[i][bank[i].id][del_thrus[j]] then
        softcut.level_cut_cut(i+1,4+j,bank[i][bank[i].id][del_sides[j]])
      else
        -- softcut.level_cut_cut(i+1,4+j,(bank[i][bank[i].id][del_sides[j]]*bank[i][bank[i].id].level)*bank[i].global_level)
        softcut.level_cut_cut(i+1,4+j,(bank[i][bank[i].id][del_sides[j]]*bank[i][bank[i].id].level)*_l.get_global_level(i))
      end
    end
    softcut.level_slew_time(i+1,1.0)
    if bank[i][bank[i].id].envelope_mode == 3 then
      -- rise fall envelope, fall stage
      env_counter[i].stage = "falling"
      softcut.level_slew_time(i+1,0.01)
      env_counter[i].butt = bank[i][bank[i].id].level+0.05
      if bank[i][bank[i].id].level > 0.05 then
        env_counter[i].time = (bank[i][bank[i].id].envelope_time/(util.round(bank[i][bank[i].id].level/0.05)+1)) * 0.5
      end
      env_counter[i]:start()
    end
    if bank[i][bank[i].id].envelope_loop == true then
      env_counter[i]:start()
    end
  end
end

function slew_filter(i,prevVal,nextVal,prevQ,nextQ,count)
  slew_counter[i]:stop()
  slew_counter[i].current = 0
  slew_counter[i].count = count
  slew_counter[i].duration = (slew_counter[i].count/100)-0.01
  slew_counter[i].beginVal = prevVal
  slew_counter[i].endVal = nextVal
  slew_counter[i].change = slew_counter[i].endVal - slew_counter[i].beginVal
  slew_counter[i].beginQ = prevQ
  slew_counter[i].endQ = nextQ
  slew_counter[i].changeQ = slew_counter[i].endQ - slew_counter[i].beginQ
  slew_counter[i]:start()
end

function easing_slew(i)
  slew_counter[i].slewedVal = slew_counter[i].ease(slew_counter[i].current,slew_counter[i].beginVal,slew_counter[i].change,slew_counter[i].duration)
  slew_counter[i].slewedQ = slew_counter[i].ease(slew_counter[i].current,slew_counter[i].beginQ,slew_counter[i].changeQ,slew_counter[i].duration)
  slew_counter[i].current = slew_counter[i].current + 0.01
  if grid_alt and all_loaded then
    -- try_tilt_process(i,bank[i].id,slew_counter[i].slewedVal,slew_counter[i].slewedQ)
  elseif all_loaded then
    for j = 1,16 do
      -- try_tilt_process(i,j,slew_counter[i].slewedVal,slew_counter[i].slewedQ)
    end
  end
  if menu == 5 then
    if menu ~= 1 then screen_dirty = true end
  end
end

--- Linear interpolation between a and b
function lerp(a,b,t)
  return a+(b-a)*t
end

--- Finds the t value that would return v in a lerp between a and b
function invlerp(a,b,v)
  return (v-a)/(b-a)
end

function try_tilt_process(b,i,t,rq)
  if util.round(t*100) < 0 then
    bank[b][i].cf_lp = math.abs(t)
    bank[b][i].cf_dry = 1+t
    if util.round(t*100) >= -24 then
      bank[b][i].cf_exp_dry = (util.linexp(0,1,1,101,bank[b][i].cf_dry)-1)/100
    elseif util.round(t*100) <= -24 and util.round(t*100) >= -50 then
      bank[b][i].cf_exp_dry = (util.linexp(0.4,1,1,101,bank[b][i].cf_dry)-1)/100
    elseif util.round(t*100) < -50 then
      bank[b][i].cf_exp_dry = 0
    end
    bank[b][i].cf_fc = util.linexp(0,1,16000,10,bank[b][i].cf_lp)
    params:set("filter "..b.." cutoff",bank[b][i].cf_fc)
    if bank[b][i].filter_type == 4 then
      params:set("filter "..b.." lp", math.abs(bank[b][i].cf_exp_dry-1))
      params:set("filter "..b.." dry", bank[b][i].cf_exp_dry)
      if params:get("filter "..b.." hp") ~= 0 then
        params:set("filter "..b.." hp", 0)
      end
      if bank[b][i].cf_hp ~= 0 then
        bank[b][i].cf_hp = 0
      end
    else
      params:set("filter "..b.." lp", 0)
      params:set("filter "..b.." hp", 0)
      params:set("filter "..b.." dry", 0)
      params:set("filter "..b.." bp", 1)
    end
  elseif util.round(t*100) > 0 then
    bank[b][i].cf_hp = math.abs(t)
    bank[b][i].cf_fc = util.linexp(0,1,10,12000,bank[b][i].cf_hp)
    bank[b][i].cf_dry = 1-t
    bank[b][i].cf_exp_dry = (util.linexp(0,1,1,101,bank[b][i].cf_dry)-1)/100
    params:set("filter "..b.." cutoff",bank[b][i].cf_fc)
    if bank[b][i].filter_type == 4 then
      params:set("filter "..b.." hp", math.abs(bank[b][i].cf_exp_dry-1))
      params:set("filter "..b.." dry", bank[b][i].cf_exp_dry)
      if params:get("filter "..b.." lp") ~= 0 then
        params:set("filter "..b.." lp", 0)
      end
      if bank[b][i].cf_lp ~= 0 then
        bank[b][i].cf_lp = 0
      end
    else
      params:set("filter "..b.." lp", 0)
      params:set("filter "..b.." hp", 0)
      params:set("filter "..b.." dry", 0)
      params:set("filter "..b.." bp", 1)
    end
  elseif util.round(t*100) == 0 then
    bank[b][i].cf_fc = 12000
    bank[b][i].cf_lp = 0
    bank[b][i].cf_hp = 0
    bank[b][i].cf_dry = 1
    bank[b][i].cf_exp_dry = 1
    -- if bank[b][i].filter_type == 4 then
    --   params:set("filter "..b.." cutoff",12000)
    --   params:set("filter "..b.." lp", 0)
    --   params:set("filter "..b.." hp", 0)
    --   params:set("filter "..b.." dry", 1)
    -- end
  end
  -- softcut.post_filter_rq(b+1,rq)
end

function adjust_key1_timing()
  if menu == 1 then
    metro[31].time = 0.25
  elseif menu ~= 6 then
    if metro[31].time ~= 0.1 then metro[31].time = 0.1 end
  elseif menu == 6 then
    if page.delay[page.delay.focus].menu == 1 and page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu] == 5 then
      metro[31].time = 0.01
    else
      if metro[31].time ~= 0.1 then metro[31].time = 0.1 end
    end
  -- else
  --   metro[31].time = 0.01
  end
end

function midi_pattern_recording(id,state)
  if state == "start" then
    if midi_pat[id].playmode == 1 then
      midi_pat[id]:rec_start()
    else
      midi_pat[id].rec_clock = clock.run(synced_record_start,midi_pat[id],id)
    end
  elseif state == "stop" then
    midi_pat[id]:rec_stop()
    if midi_pat[id].playmode == 1 then
      start_pattern(midi_pat[id])
    elseif midi_pat[id].playmode == 2 then
      midi_pat[id]:rec_stop()
      if midi_pat[id].rec_clock ~= nil then
        clock.cancel(midi_pat[id].rec_clock)
      end
      if midi_pat[id].clock ~= nil then
        print("clearing clock: "..midi_pat[id].clock)
        clock.cancel(midi_pat[id].clock)
      end
      midi_pat[id]:clear()
    end
  end
end

function toggle_midi_pattern_overdub(id)
  if midi_pat[id].play == 1 then
    midi_pat[id].overdub = midi_pat[id].overdub == 0 and 1 or 0
  end
end

local pre_k1_midi_page = nil

function key(n,z)
  if menu == "load screen" then
  elseif menu == "macro_config" then
    macros.key(n,z)
  elseif menu == "MIDI_config" then
    mc.key(n,z)
  elseif menu == "transport_config" then
    transport.key(n,z)
  elseif menu == "overwrite screen" then
    if z == 1 then
      if collection_overwrite_clock ~= nil then
        clock.cancel(collection_overwrite_clock)
      end
      print("cancel overwrite")
      clock.run(canceled_save)
    end
  elseif menu == "delete screen" then
    if z == 1 then
      if collection_delete_clock ~= nil then
        clock.cancel(collection_delete_clock)
      end
      print("cancel delete")
      clock.run(canceled_delete)
    end
  elseif menu == 2 then
    main_menu.process_key("loops",n,z)
  elseif menu == 3 then
    main_menu.process_key("levels",n,z)
  elseif menu == 4 then
    main_menu.process_key("pans",n,z)
  elseif menu == 5 then
    main_menu.process_key("filters",n,z)
  elseif menu == 9 then
    main_menu.process_key("arps",n,z)
  else
    if n == 3 and z == 1 then
      if menu == 1 then
        if key1_hold then
          menu = "MIDI_config"
          key1_hold = false
        else
          menu = page.main_sel + 1
          if menu == 4 then
            main_menu.reset_view("pans")
          end
          if menu == 10 then menu = "macro_config" end
        end
      elseif menu == 2 then
        -- local id = page.loops_sel
        if key2_hold then
          if page.loops.sel < 4 then
            local id = page.loops.sel
            bank[id][bank[id].id].loop = not bank[id][bank[id].id].loop
            if bank[id][bank[id].id].loop then
              softcut.loop(id+1,1)
              cheat(id,bank[id].id)
            else
              softcut.loop(id+1,0)
            end
            if page.loops.frame == 1 then
              for i = 1,16 do
                bank[id][i].loop = bank[id][bank[id].id].loop
              end
            end
          elseif page.loops.sel == 4 then
            if rec[rec.focus].loop == 0 and params:string("one_shot_clock_div") == "threshold" and not grid_alt then
              _ca.threshold_rec_handler()
            else
              _ca.toggle_buffer(rec.focus)
            end
          elseif page.loops.sel == 5 then
            if page.loops.meta_sel < 4 then
              for i = 1,16 do
                rightangleslice.start_end_default(bank[page.loops.meta_sel][i])
              end
            elseif page.loops.meta_sel == 4 then
              if rec[rec.focus].loop == 0 and params:string("one_shot_clock_div") == "threshold" and not grid_alt then
                if rec[rec.focus].queued then
                  amp_in[1]:stop()
                  amp_in[2]:stop()
                  rec[rec.focus].queued = false
                else
                  amp_in[1]:start()
                  amp_in[2]:start()
                  rec[rec.focus].queued = true
                end
              else
                _ca.toggle_buffer(rec.focus)
              end
            end
          end
          grid_dirty = true
          key2_hold_and_modify = true
        end
        if not key1_hold and not key2_hold then
          page.loops.frame = (page.loops.frame%2)+1
        elseif key1_hold and not key2_hold then
          if page.loops.sel < 4 then
            local id = page.loops.sel
            if page.loops.frame == 2 then
              local which_pad;
              if bank[id].focus_hold then
                which_pad = bank[id].focus_pad
              elseif grid_pat[id].play == 0 and midi_pat[id].play == 0 and not arp[id].playing and rytm.track[id].k == 0 then
                which_pad = bank[id].id
              else
                which_pad = bank[id].focus_pad
              end
              -- rightangleslice.init(4,id,'23')
              rightangleslice.start_end_random(bank[id][which_pad])
              update_waveform(bank[id][which_pad].mode,bank[id][which_pad].start_point,bank[id][which_pad].end_point,128)
              -- if grid_pat[id].play == 1 and midi_pat[id].play == 0 and not arp[id].playing and rytm.track[id].k == 0 then
                if bank[id].id == which_pad then
                  rightangleslice.sc.start_end(bank[id][which_pad],id)
                end
              -- end
            else
              if bank[id][bank[id].id].mode == 2 then
                _norns.key(1,1)
                _norns.key(1,0)
                fileselect.enter(_path.audio,function(n) _ca.sample_callback(n,bank[id][bank[id].id].clip) end)
              end
            end
          elseif page.loops.sel == 4 and page.loops.frame == 2 then
            -- something else
          elseif page.loops.sel == 5 and page.loops.frame == 2 then
            if page.loops.meta_sel < 4 then
              -- sync to next
              local id = page.loops.meta_sel
              local src_bank_num = (id == 1 or id == 2) and 3 or 2
              local src_bank     = bank[src_bank_num]
              local src_pad      = src_bank[src_bank.id]
              -- -- shift start/end by the difference between clips
              local reasonable_max = bank[id][bank[id].id].mode == 1 and 32 or clip[bank[id][bank[id].id].clip].sample_length
              if src_pad.end_point <= reasonable_max then
                bank[id][bank[id].id].start_point = src_pad.start_point
                bank[id][bank[id].id].end_point = src_pad.end_point
                rightangleslice.sc.start_end( bank[id][bank[id].id], id )
                -- maybe a risk:
                -- print(id+1,src_pad.bank_id+1)
                -- softcut.position(id+1,poll_position_new[src_pad.bank_id+1])
                -- /
              end
            end
          end
        end
      elseif menu == 6 then
        if not key1_hold then
          page.delay.focus = page.delay.focus == 1 and 2 or 1
          screen_dirty = true
        end
        if page.delay.section == 2 then
          if key1_hold then
            local k = page.delay[page.delay.focus].menu
            local v = page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu]
            del.links(del.lookup_prm(k,v))
            if k == 1 and v == 5 then
              delay[page.delay.focus == 1 and 2 or 1].feedback_mute = not delay[page.delay.focus == 1 and 2 or 1].feedback_mute
            elseif k == 1 and v == 4 then
              delay[page.delay.focus == 1 and 2 or 1].reverse = delay[page.delay.focus].reverse
            end
            if delay_links[del.lookup_prm(k,v)] then
              local sides = {"L","R"}
              params:set("delay "..sides[page.delay.focus == 1 and 2 or 1]..": "..del.lookup_prm(k,v),params:get("delay "..sides[page.delay.focus]..": "..del.lookup_prm(k,v)))
              grid_dirty = true
            end
          else
            
          end
        elseif page.delay.section == 1 then
          if key1_hold then
            del.link_all(page.delay[page.delay.focus].menu)
          else
            page.delay.section = page.delay.section == 1 and 2 or 1
          end
        end
      elseif menu == 7 then
        local time_nav = page.time_sel
        local id = time_nav
        if key2_hold then
          key2_hold_and_modify = true
        else
          if time_nav >= 1 and time_nav < 4 then
            if g.device == nil and grid_pat[time_nav].count == 0 then
              if page.time_page_sel[time_nav] == 1 then
                if midi_pat[time_nav].playmode < 3 then
                  if midi_pat[time_nav].rec == 0 then
                    if midi_pat[time_nav].count == 0 and not key1_hold then
                      midi_pattern_recording(time_nav,"start")
                    elseif midi_pat[time_nav].count ~= 0 and not key1_hold then
                      toggle_midi_pattern_overdub(time_nav)
                    end
                  elseif midi_pat[time_nav].rec == 1 then
                    midi_pattern_recording(time_nav,"stop")
                  end
                end
              end
            end
            if page.time_page_sel[time_nav] == 2 then
              -- if g.device ~= nil then
              if get_grid_connected() then
                random_grid_pat(id,2)
              else
                shuffle_midi_pat(id)
              end
            elseif page.time_page_sel[time_nav] == 4 then
              if not key1_hold then
                -- if g.device ~= nil then
                if get_grid_connected() then
                  random_grid_pat(id,3)
                else
                  random_midi_pat(id)
                end
              end
            end
            if key1_hold then
              if grid_pat[id].count > 0 then
                grid_actions.rec_stop(id)
                -- grid_pat[id]:stop()
                stop_pattern(grid_pat[id])
                grid_pat[id].tightened_start = 0
                grid_pat[id]:clear()
                pattern_saver[id].load_slot = 0
              end
              if midi_pat[id].count > 0 then
                midi_pat[id]:rec_stop()
                if midi_pat[id].clock ~= nil then
                  print("clearing clock: "..midi_pat[id].clock)
                  clock.cancel(midi_pat[id].clock)
                end
                midi_pat[id]:clear()
              end
            end
          elseif time_nav >= 4 then
            if a.device ~= nil then
              local pattern = arc_pat[time_nav-3][page.time_page_sel[time_nav]]
              if page.time_page_sel[page.time_sel] <= 4 then
                if not key1_hold then
                  if pattern.rec == 0 and pattern.play == 0 and pattern.count == 0 then
                    pattern:rec_start()
                  elseif pattern.rec == 1 then
                    pattern:rec_stop()
                    pattern:start()
                  elseif pattern.play == 1 then
                    pattern:stop()
                  elseif (pattern.rec == 0 and pattern.play == 0 and pattern.count > 0) then
                    pattern:start()
                  end
                else
                  pattern:clear()
                end
              else
                for i = 1,4 do
                  if page.time_page_sel[page.time_sel] == 5 then
                    if arc_pat[time_nav-3][i].count > 0 then
                      arc_pat[time_nav-3][i]:start()
                    end
                  elseif page.time_page_sel[page.time_sel] == 6 then
                    arc_pat[time_nav-3][i]:stop()
                  elseif page.time_page_sel[page.time_sel] == 7 then
                    arc_pat[time_nav-3][i]:clear()
                  end
                end
              end
            end
          end
        end
      elseif menu == 8 then

        if key1_hold then
          rytm.reset_pattern(rytm.track_edit)
        else
          rytm.screen_focus = rytm.screen_focus == "left" and "right" or "left"
        end

      elseif menu == 9 then

      elseif menu == 10 then
        if key1_hold then
          local rnd_bank = page.rnd_page
          local rnd_slot = page.rnd_page_sel[rnd_bank]
          local state = tostring(rnd[rnd_bank][rnd_slot].playing)
          rnd.transport(rnd_bank,rnd_slot,state == "false" and "on" or "off")
          if state == "true" then
            rnd.restore_default(rnd_bank,rnd_slot)
          end
        else
          -- page.rnd_page_section = page.rnd_page_section == 1 and 2 or 1
        end
      end


    elseif n == 2 and z == 1 then
      if menu == 1 then
        if key1_hold then
          -- menu = "macro_config"
          key1_hold = false
        else
          menu = "transport_config"
        end
      elseif menu == 7 and not key1_hold then
        -- key2_hold = true
        key2_hold_counter:start()
        key2_hold_and_modify = false
      elseif menu == 2 then
        if page.loops.frame == 2 and key1_hold then
          if page.loops.sel == 4 then
            _ca.buff_flush()
            -- print("press")
          elseif page.loops.sel < 4 then
            sync_clock_to_loop(bank[page.loops.sel][bank[page.loops.sel].id],"audio")
          elseif page.loops.sel == 5 then
            if page.loops.meta_sel < 4 then
              -- THIS SHOULD CHECK TO SEE IF PAD LOCKED...
              -- sync to next
              local id = page.loops.meta_sel
              local src_bank_num = id == 1 and 2 or 1
              local src_bank     = bank[src_bank_num]
              local src_pad      = src_bank[src_bank.id]
              -- -- shift start/end by the difference between clips
              local reasonable_max = bank[id][bank[id].id].mode == 1 and 32 or clip[bank[id][bank[id].id].clip].sample_length
              if src_pad.end_point <= reasonable_max then
                bank[id][bank[id].id].start_point = src_pad.start_point
                bank[id][bank[id].id].end_point = src_pad.end_point
                rightangleslice.sc.start_end( bank[id][bank[id].id], id )
                -- softcut.position(id+1, bank[id][bank[id].id].start_point )
              end
            end
          end
        end
      end
    elseif n == 2 and z == 0 and key2_hold == false and menu == 7 and not key1_hold then
      key2_hold_counter:stop()
      menu = 1
    elseif n == 2 and z == 0 and key2_hold_and_modify then
      key2_hold = false
      key2_hold_and_modify = false
    elseif n == 2 and z == 0 and not key2_hold_and_modify then
      key2_hold = false
      key2_hold_and_modify = false
      if menu == 11 then
        if help_menu ~= "welcome" then
          help_menu = "welcome"
        else
          menu = 1
        end
      elseif menu == 8 then
        if key1_hold then
          rytm.reset_all_patterns()
        else
          menu = 1
        end
      elseif menu == 10 then
        if key1_hold then
          for i = 1,#rnd.targets do
            rnd.transport(page.rnd_page,i,"off")
            rnd.restore_default(page.rnd_page,i)
          end
        else
          menu = 1
        end
      elseif menu == 6 then
        if key1_hold then
          if page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu] == 4 then
            local k = page.delay[page.delay.focus].menu
            local v = page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu]
            del.quick_action(page.delay.focus, "reverse")
          end
        else
          menu = 1
        end
      elseif menu == 2 then
        if page.loops.frame == 2 and key1_hold then
          if page.loops.sel == 4 then
            -- _ca.buff_flush()
            -- print("release???")
          elseif page.loops.sel < 4 then
            sync_clock_to_loop(bank[page.loops.sel][bank[page.loops.sel].id],"audio")
          end
        end
      else
        menu = 1
      end
      if menu == 6 and page.delay[page.delay.focus].menu == 1 and page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu] == 4 then
        -- just need a logic break
      elseif menu ~= 2 and menu ~= 8 then
        if key1_hold == true then key1_hold = false end
      end
    end

    if n == 1 and z == 1 then
      if menu == 11 then
        if key1_hold == false then
          key1_hold = true
        else
          key1_hold = false
        end
      elseif menu == 6 then
        key1_hold = true
        if page.delay[page.delay.focus].menu == 1 and page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu] == 5 then
          if delay_links["feedback"] then
            del.quick_action(1,"feedback_mute",z)
            del.quick_action(2,"feedback_mute",z)
          else
            del.quick_action(page.delay.focus,"feedback_mute",z)
          end
          grid_dirty = true
        end
      elseif menu == 7 then
        key1_hold = true
      elseif menu == 8 then
        key1_hold = true
      elseif menu == 9 then
        -- key1_hold = true
        -- page.arps.alt[page.arps.sel] = not page.arps.alt[page.arps.sel]
      else
        key1_hold = true
        if menu == 2 and page.loops.sel < 4 and page.loops.frame == 2 and not key2_hold then
          local focused_pad;
          if bank[page.loops.sel].focus_hold then
            focused_pad = bank[page.loops.sel].focus_pad
          elseif grid_pat[page.loops.sel].play == 0 and midi_pat[page.loops.sel].play == 0 and not arp[page.loops.sel].playing and rytm.track[page.loops.sel].k == 0 then
            focused_pad = bank[page.loops.sel].id
          else
            focused_pad = bank[page.loops.sel].focus_pad
          end
          local mode = bank[page.loops.sel][focused_pad].mode
          local min = bank[page.loops.sel][focused_pad].start_point
          local max = bank[page.loops.sel][focused_pad].end_point
          update_waveform(mode,min,max,128)
        elseif menu == 2 and page.loops.sel < 4 and page.loops.frame == 2 and key2_hold then
          if bank[page.loops.sel][bank[page.loops.sel].id].mode == 2 then
            _norns.key(1,0)
            fileselect.enter(_path.audio,function(n) _ca.sample_callback(n,bank[page.loops.sel][bank[page.loops.sel].id].clip) end)
            if key2_hold then key2_hold = false end
          end
        elseif menu == 2 and page.loops.sel == 4 and page.loops.frame == 2 then
          update_waveform(1,rec[rec.focus].start_point,rec[rec.focus].end_point,128)
        elseif menu == 2 and page.loops.sel == 5 and page.loops.frame == 2 then
          if not key2_hold then
            local id = page.loops.meta_sel
            if id < 4 and (grid_pat[id].play == 1 or midi_pat[id].play == 1 or arp[id].playing or rytm.track[id].k ~= 0) then
              bank[id].focus_pad = bank[id].id
            -- page.loops.focus_hold[page.loops.meta_sel] = not page.loops.focus_hold[page.loops.meta_sel]
            end
          elseif key2_hold then
            if page.loops.meta_sel < 4 then
              for i = 1,16 do
                rightangleslice.end_sixteenths(bank[page.loops.meta_sel][i])
                -- rightangleslice.start_end_default(bank[page.loops.meta_sel][i])
              end
              key1_hold = false -- right??
            end
          end
        end
      end
      
    elseif n == 1 and z == 0 then
      if menu == 2 and page.loops.sel < 4 and not key2_hold then
        local mode = bank[page.loops.sel][bank[page.loops.sel].id].mode
        local min =
        { live[bank[page.loops.sel][bank[page.loops.sel].id].clip].min
        , clip[bank[page.loops.sel][bank[page.loops.sel].id].clip].min
        }
        local max =
        { live[bank[page.loops.sel][bank[page.loops.sel].id].clip].max
        , clip[bank[page.loops.sel][bank[page.loops.sel].id].clip].max
        }
        update_waveform(mode,min[mode],max[mode],128)
      elseif menu == 2 and page.loops.sel == 4 then
        update_waveform(1,live[rec.focus].min,live[rec.focus].max,128)
      end 
      if menu ~= 5 and menu ~= 11 then
        key1_hold = false
      end
      if menu == 6 then
        if page.delay[page.delay.focus].menu == 1 and page.delay[page.delay.focus].menu_sel[page.delay[page.delay.focus].menu] == 5 then
          if delay_links["feedback"] then
            del.quick_action(1,"feedback_mute",z)
            del.quick_action(2,"feedback_mute",z)
          else
            del.quick_action(page.delay.focus,"feedback_mute",z)
          end
          grid_dirty = true
        end
      end
      if menu == 7 then
        if page.time_sel < 4 then
          if key1_hold_and_modify == false then
            local time_nav = page.time_sel
            local id = time_nav
            if midi_pat[id].play == 1 then
              if midi_pat[id].clock ~= nil then
                clock.cancel(midi_pat[id].clock)
                print("pausing clock")
                midi_pat[id].step = 1
              end
              midi_pat[id]:stop()
            else
              if midi_pat[id].count > 0 then
                if midi_pat[id].playmode == 1 then
                  --midi_pat[id]:start()
                  -- print("4060")
                  start_pattern(midi_pat[id])
                elseif midi_pat[id].playmode == 2 then
                  -- print("line 2387")
                  --midi_pat[id].clock = clock.run(synced_loop, midi_pat[id], "restart")
                  if midi_pat[id].clock ~= nil then clock.cancel(midi_pat[id].clock) end
                  midi_pat[id].clock = clock.run(alt_synced_loop, midi_pat[id], "restart")
                end
              end
            end
            if grid_pat[id].count > 0 then
              if grid_pat[id].quantize == 0 then
                if grid_pat[id].play == 1 then
                  --grid_pat[id]:stop()
                  stop_pattern(grid_pat[id])
                else
                  --grid_pat[id]:start()
                  start_pattern(grid_pat[id])
                end
              else
                grid_pat[id].tightened_start = (grid_pat[id].tightened_start + 1)%2
                grid_pat[id].step = grid_pat[id].start_point
                quantized_grid_pat[id].current_step = grid_pat[id].start_point
                quantized_grid_pat[id].sub_step = 1
              end
            end
          else
            key1_hold_and_modify = false
          end
        end
      end
    end
  end
  adjust_key1_timing()
  screen_dirty = true
  grid_dirty = true
end

function check_page_for_k1()
  while true do
    clock.sleep(0.25)
    if _menu.mode and metro[31].time ~= 0.25 then
      metro[31].time = 0.25
    elseif not _menu.mode and metro[31].time == 0.25 and menu ~= 1 then
      metro[31].time = 0.1
    end
  end
end

function enc(n,d)
  encoder_actions.init(n,d)
  adjust_key1_timing()
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.font_size(8)
  main_menu.draw()
  screen.update()
end

--GRID
g = grid.connect()

function get_grid_connected()
  if g.device == nil and grid == nil then
    return false
  elseif g.device ~= nil or (grid ~= nil and params:string("midigrid?") == "yes") then
    return true
  else
    return false
  end
end

function grid.add(dev)
  grid_dirty = true
end

function g.add(dev)
  grid_dirty = true
end

g.key = function(x,y,z)
  grid_actions.init(x,y,z)
end

--/ length mods


--/GRID

function grid_pattern_execute(entry)
  if entry ~= nil then
    if entry ~= "pause" then
      local i = entry.i
      local should_happen = pattern_gate[i][2].active and p_gate.check_prob(pattern_gate[i][2])
        -- print(clock.get_beats().."<<<<<<<")
      if entry.action == "pads" then
        if (not arp[i].enabled and not arp[i].playing and not pattern_gate[i][1].active) 
        or (not arp[i].enabled and not arp[i].playing and pattern_gate[i][1].active and pattern_gate[i][2].active) 
        or ((arp[i].enabled or arp[i].playing) and not pattern_gate[i][1].active and pattern_gate[i][2].active)
        or ((not arp[i].enabled and arp[i].playing) and (pattern_gate[i][1].active and pattern_gate[i][2].active)) then
          if should_happen or not pattern_gate[i][2].active then
            local a_p; -- this will index the arc encoder recorders
            if arc_param[i] == 1 or arc_param[i] == 2 or arc_param[i] == 3 then
              a_p = 1
            else
              a_p = arc_param[i] - 2
            end
            if params:get("zilchmo_patterning") == 2 then
              bank[i][entry.id].rate = entry.rate
            end
            selected[i].id = entry.id
            selected[i].x = entry.x
            selected[i].y = entry.y
            bank[i].id = selected[i].id
            grid_actions.add_held_key(i,selected[i].id)
            if params:get("zilchmo_patterning") == 2 then
              bank[i][bank[i].id].mode = entry.mode
              bank[i][bank[i].id].clip = entry.clip
            end
            if arc_param[i] ~= 4 and #arc_pat[i][a_p].event == 0 then -- TODO what is this?
              if params:get("zilchmo_patterning") == 2 then
                bank[i][bank[i].id].start_point = entry.start_point
                bank[i][bank[i].id].end_point = entry.end_point
              end
            end
            if (rytm.track[i].k == 0 and not pattern_gate[i][3].active)
            or (rytm.track[i].k ~= 0 and not pattern_gate[i][3].active) then
              if not bank[i].quantized_press then
                cheat(i, bank[i].id)
              else
                quantize_events[i] = {["bank"] = i, ["pad"] = bank[i].id}
              end
            end
            -- here, add the clock call for note off...
            if grid_pat[i].rand_generated then
              grid_pat[i].rand_step_count = wrap(grid_pat[i].rand_step_count+1,grid_pat[i].start_point,grid_pat[i].end_point)
              table.insert(grid_pat[i].random_notes_held,selected[i].id)
              -- if grid_pat[i].rand_step_count % (params:get("rand_pattern_"..i.."_polyphony")+1) == 0 then
              if grid_pat[i].rand_step_count % (params:get("rand_pattern_"..i.."_polyphony")+1) == 0 then
                print("eeee!")
                if #grid_pat[i].random_notes_held > 1 then
                  for j = #grid_pat[i].random_notes_held-1,1,-1 do
                    print("killing", i,grid_pat[i].random_notes_held[j])
                    grid_actions.kill_note(i,grid_pat[i].random_notes_held[j])
                  end
                  grid_pat[i].random_notes_held = {}
                end
              end
            end
          end

        elseif arp[i].enabled
        and not arp[i].pause
        -- and not arp[i].gate.active
        and pattern_gate[i][1].active and pattern_gate[i][2].active
        then
          if should_happen or not pattern_gate[i][2].active then
            -- print("4002 add:",entry.id)
            if arp[i].down == 0 and params:string("arp_"..i.."_hold_style") == "last pressed" then
              for j = #arp[i].notes,1,-1 do
                arps.remove_momentary(i,j)
              end
            end
            arps.momentary(i, entry.id, "on")
            arp[i].down = arp[i].down + 1
          end
        end
      elseif string.match(entry.action, "zilchmo") then
        local a_p; -- this will index the arc encoder recorders
        if arc_param[i] == 1 or arc_param[i] == 2 or arc_param[i] == 3 then
          a_p = 1
        else
          a_p = arc_param[i] - 2
        end
        if params:get("zilchmo_patterning") == 2 then
          if should_happen or not pattern_gate[i][2].active then
            bank[i][entry.id].rate = entry.rate
            rightangleslice.init(entry.row,entry.bank,entry.con)

            local depth = {'(%d)','(%d)(%d)','(%d)(%d)(%d)','(%d)(%d)(%d)(%d)'}
            local y1,y2,y3,y4 = entry.con:match(depth[#entry.con])
            
            zilch_leds[4][entry.bank][y1 ~= nil and 5-tonumber(y1)] = 1
            zilch_leds[4][entry.bank][y2 ~= nil and 5-tonumber(y2)] = 1
            zilch_leds[4][entry.bank][y3 ~= nil and 5-tonumber(y3)] = 1
            zilch_leds[4][entry.bank][y4 ~= nil and 5-tonumber(y4)] = 1

            clock.run(recorded_zilch_zero,entry.bank)
            if arc_param[i] ~= 4 and #arc_pat[i][a_p].event == 0 then -- TODO what is this?
              bank[i][bank[i].id].start_point = entry.start_point
              bank[i][bank[i].id].end_point = entry.end_point
              softcut.loop_start(i+1,bank[i][bank[i].id].start_point)
              softcut.loop_end(i+1,bank[i][bank[i].id].end_point)
            end
          end
        end

      elseif entry.action == "pads-release" then
        if should_happen or not pattern_gate[i][2].active then
          local released_pad = entry.id
          if bank[i][released_pad].play_mode == "momentary" and released_pad == selected[i].id then
            softcut.rate(i+1,0)
            softcut.position(i+1,bank[i][released_pad].start_point)
            softcut.loop_start(i+1,bank[i][released_pad].start_point)
            softcut.loop_end(i+1,bank[i][released_pad].end_point)
          end
          grid_actions.remove_held_key(i,released_pad)
          if not arp[i].enabled then
            -- mc.midi_note_off_from_pad(i,released_pad)
            mc.global_note_off(i,released_pad)
          end
          if arp[i].enabled
          and not pattern_gate[i][1].active
          and pattern_gate[i][2].active
          then
            if not grid_alt then
              grid_actions.kill_note(i,released_pad)
            end
          end
          if arp[i].enabled
          and not arp[i].pause
          -- and not arp[i].gate.active
          and pattern_gate[i][1].active and pattern_gate[i][2].active
          then
            -- print("4052 release:",released_pad)
            if (arp[i].enabled and not arp[i].hold) then
              if params:string("arp_"..i.."_hold_style") ~= "sequencer" then
                arps.momentary(i, released_pad, "off")
              end
              arp[i].down = arp[i].down - 1
            elseif (arp[i].enabled and arp[i].hold and not arp[i].pause) then
              arp[i].down = arp[i].down - 1
            end
          end
        end
      end
      grid_dirty = true
      if menu ~= 1 then screen_dirty = true end
    end
  end
end

function recorded_zilch_zero(bank)
  clock.sleep(0.1)
  for i = 1,4 do
    zilch_leds[4][bank][i] = 0
  end
  grid_dirty = true
end

function new_arc_pattern_execute(entry)
  local i = entry.i1
  local j = entry.i2
  local id = arc_control[i]
  local param = entry.param
  if param ~= 4 then
    local which_pad = entry.pad

    if arc_pat[i][j].step ~= 0 then
      if arc_pat[i][j].step > 1 then
        if params:get("arc_patterning") == 2 then
          if arc_pat[i][j].event[arc_pat[i][j].step].pad ~= arc_pat[i][j].event[arc_pat[i][j].step-1].pad then
            bank[id].id = arc_pat[i][j].event[arc_pat[i][j].step].pad
            selected[id].x = (math.ceil(bank[id].id/4)+(5*(id-1)))
            selected[id].y = 8-((bank[id].id-1)%4)
            cheat(id,arc_pat[i][j].event[arc_pat[i][j].step].pad)
            slew_filter(id,entry.prev_tilt,entry.tilt,bank[id][bank[id].id].q,bank[id][bank[id].id].q,15)
            grid_dirty = true
          end
        end
      elseif arc_pat[i][j].step == 1 then
        if params:get("arc_patterning") == 2 then
          bank[id].id = arc_pat[i][j].event[arc_pat[i][j].step].pad
          selected[id].x = (math.ceil(bank[id].id/4)+(5*(id-1)))
          selected[id].y = 8-((bank[id].id-1)%4)
          cheat(id,arc_pat[i][j].event[arc_pat[i][j].step].pad)
          slew_filter(id,arc_pat[i][j].event[arc_pat[i][j].count].tilt,entry.tilt,bank[id][bank[id].id].q,bank[id][bank[id].id].q,15)
          grid_dirty = true
        end
      end 
    elseif arc_pat[i][j].step == 0 then
      arc_pat[i][j].step = 1
      if params:get("arc_patterning") == 2 then
        bank[id].id = arc_pat[i][j].event[arc_pat[i][j].step].pad
        selected[id].x = (math.ceil(bank[id].id/4)+(5*(id-1)))
        selected[id].y = 8-((bank[id].id-1)%4)
        cheat(id,arc_pat[i][j].event[arc_pat[i][j].step].pad)
        slew_filter(id,arc_pat[i][j].event[arc_pat[i][j].count].tilt,entry.tilt,bank[id][bank[id].id].q,bank[id][bank[id].id].q,15)
        grid_dirty = true
      end
    end
    
    if entry.param == 1 or entry.param == 2 or entry.param == 3 then
      bank[id][which_pad].start_point = (entry.start_point + (32*(bank[id][which_pad].clip-1)) + arc_offset)
      bank[id][which_pad].end_point = (entry.end_point + (32*(bank[id][which_pad].clip-1)) + arc_offset)
      if bank[id].id == which_pad then
        softcut.loop_start(id+1, (entry.start_point + (32*(bank[id][which_pad].clip-1))) + arc_offset)
        softcut.loop_end(id+1, (entry.end_point + (32*(bank[id][which_pad].clip-1))) + arc_offset)
      end
    elseif entry.param == 5 then
      bank[id][which_pad].level = (entry.level + arc_offset)
      bank[id].global_level = (entry.global_level + arc_offset)
      if bank[id].id == which_pad then
        -- softcut.level(id+1, (entry.level + arc_offset)*bank[id].global_level)
        softcut.level(id+1, (entry.level + arc_offset)*_l.get_global_level(id))
      end
    elseif entry.param == 6 then
      bank[id][which_pad].pan = (entry.pan + arc_offset)
      if bank[id].id == which_pad then
        softcut.pan(id+1, (entry.pan + arc_offset))
      end
    end
  else
    slew_filter(id,entry.prev_tilt,entry.tilt,bank[id][bank[id].id].q,bank[id][bank[id].id].q,15)
  end
  if menu ~= 1 then screen_dirty = true end
end

function arc_delay_pattern_execute(entry)
  local i = entry.i
  local side = entry.delay_focus
  arc_p[4].delay_focus = side
  if side == "L" then
    arc_p[4].left_delay_value = entry.left_delay_value
    params:set("delay L: div/mult",entry.left_delay_value)
  else
    arc_p[4].right_delay_value = entry.right_delay_value
    params:set("delay R: div/mult",entry.right_delay_value)
  end
  if menu ~= 1 then screen_dirty = true end
end

function zilchmo(k,i)
  rightangleslice.init(k,i)
  _gleds.clear_lit()
  -- grid_redraw()
  grid_dirty = true
  if menu ~= 1 then screen_dirty = true end
end

function pad_copy(destination, source)
  destination = deep_copy(source)
  -- for k,v in pairs(source) do
  --   if k ~= bank_id and k ~= pad_id and type(v) ~= "table" then
  --     destination[k] = v
  --   elseif k ~= bank_id and k ~= pad_id and type(v) == "table" then
  --     print("trying to copy a table")
  --   end
  -- end
end

a = arc.connect()
arc_d = {}
for i = 1,3 do
  arc_d[i] = {}
end

a.delta = function(n,d)
  arc_d[n] = d
  arc_actions.init(n,arc_d[n])
end

arc_redraw = function()
  a:all(0)
  local which_pad = nil
  local this_bank;
  local arc_min;
  local arc_max;

  for i = 1,(params:string("arc_size") == 4 and 3 or 1) do
    i = (params:string("arc_size") == 4 and i or bank_64)
    local which_enc = params:string("arc_size") == 4 and i or 1
    if bank[i].focus_hold == false then
      which_pad = bank[i].id
    else
      which_pad = bank[i].focus_pad
    end

    if arc_param[i] == 1 then
      local minimum = bank[i][which_pad].mode == 1 and live[bank[i][which_pad].clip].min or clip[bank[i][which_pad].clip].min
      local maximum = bank[i][which_pad].mode == 1 and live[bank[i][which_pad].clip].max or clip[bank[i][which_pad].clip].max
      local start_to_led = bank[i][which_pad].start_point
      local end_to_led = bank[i][which_pad].end_point
      a:segment(which_enc, util.linlin(minimum, maximum, tau*(1/4), tau*1.23, start_to_led), util.linlin(minimum, maximum, (tau*(1/4))+0.1, tau*1.249999, end_to_led), 15)
    end
    if arc_param[i] == 2 or arc_param[i] == 3 then
      local minimum = bank[i][which_pad].mode == 1 and live[bank[i][which_pad].clip].min or clip[bank[i][which_pad].clip].min
      local maximum = bank[i][which_pad].mode == 1 and live[bank[i][which_pad].clip].max or clip[bank[i][which_pad].clip].max
      local start_to_led = math.floor(util.linlin(minimum,maximum,1,64,bank[i][which_pad].start_point))
      local end_to_led = math.floor(util.linlin(minimum,maximum,1,64,bank[i][which_pad].end_point))
      local playhead_to_led = util.linlin(minimum,maximum,1,64,poll_position_new[i+1])
      a:led(which_enc,(math.floor(playhead_to_led))+16,5)
      a:led(which_enc, arc_param[i] == 2 and (start_to_led+16) or (end_to_led+17),15)
      a:led(which_enc, arc_param[i] == 2 and (end_to_led+17) or (start_to_led+16),8)
    end
    if arc_param[i] == 4 then
      local cutoff_to_led = params:get("filter cutoff "..i)
      cutoff_to_led = util.round(util.explin(20,20000,22,78,cutoff_to_led))
      a:led(which_enc,cutoff_to_led-2,5)
      a:led(which_enc,cutoff_to_led-1,8)
      a:led(which_enc,cutoff_to_led,15)
      a:led(which_enc,cutoff_to_led+1,8)
      a:led(which_enc,cutoff_to_led+2,5)
    end
    if arc_param[i] == 5 then
      local level_to_led;
      if key1_hold or bank[i].alt_lock or grid_alt then
        level_to_led = bank[i].global_level
      else
        level_to_led = bank[i][bank[i].id].level
      end
      for j = 1,17 do
        a:led(which_enc,(math.floor(util.linlin(0,2,5,70,(level_to_led)-(1/8*j))))+16,15)
      end
    end
    if arc_param[i] == 6 then
      local pan_to_led = bank[i][bank[i].id].pan
      a:led(which_enc,(math.floor(util.linlin(-1,1,10,55,pan_to_led)))+22,4)
      a:led(which_enc,(math.floor(util.linlin(-1,1,10,55,pan_to_led)))+17,15)
      a:led(which_enc,(math.floor(util.linlin(-1,1,10,55,pan_to_led)))+12,4)
    end
  end

  arc_meta_level = {}
  for i = 1,6 do
    arc_meta_level[i] = util.round(arc_meta_focus) == i and 15 or 5
    a:led((params:string("arc_size") == 4 and 4 or 2),((i-1)*8)+25,arc_meta_level[i])
  end

  a:refresh()
end

--file loading

function persistent_state_save()
  local dirname = _path.data.."cheat_codes_yellow/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local file = io.open(_path.data.. "cheat_codes_yellow/persistent_state.data", "w+")
  io.output(file)
  io.write("midi_control_enabled: "..params:get("midi_control_enabled").."\n")
  io.write("midi_control_device: "..params:get("midi_control_device").."\n")
  io.write("midi_echo_enabled: "..params:get("midi_echo_enabled").."\n")
  for i = 1,3 do
    io.write("bank_"..i.."_midi_channel: "..params:get("bank_"..i.."_midi_channel").."\n")
    io.write("bank_"..i.."_pad_midi_base: "..params:get("bank_"..i.."_pad_midi_base").."\n")
  end
  io.write("preview_clip_change: "..params:get("preview_clip_change").."\n")
  io.write("zilchmo_patterning: "..params:get("zilchmo_patterning").."\n")
  io.write("LED_style: "..params:get("LED_style").."\n")
  io.write("vert rotation: "..params:get("vert rotation").."\n")
  io.write("arc_patterning: "..params:get("arc_patterning").."\n")
  for i = 1,3 do
    io.write("bank_"..i.."_midi_zilchmo_enabled: "..params:get("bank_"..i.."_midi_zilchmo_enabled").."\n")
  end
  io.write("grid_size: "..params:get("grid_size").."\n")
  io.write("global_pad_to_midi_note_enabled: "..params:get("global_pad_to_midi_note_enabled").."\n")
  io.write("global_pad_to_midi_note_destination: "..params:get("global_pad_to_midi_note_destination").."\n")
  io.write("global_pad_to_midi_note_channel: "..params:get("global_pad_to_midi_note_channel").."\n")
  io.write("global_pad_to_midi_note_scale: "..params:get("global_pad_to_midi_note_scale").."\n")
  io.write("global_pad_to_midi_note_root: "..params:get("global_pad_to_midi_note_root").."\n")
  io.write("global_pad_to_midi_note_root_octave: "..params:get("global_pad_to_midi_note_root_octave").."\n")
  for i = 1,3 do
    io.write(i.."_pad_to_midi_note_enabled: "..params:get(i.."_pad_to_midi_note_enabled").."\n")
    io.write(i.."_pad_to_midi_note_destination: "..params:get(i.."_pad_to_midi_note_destination").."\n")
    io.write(i.."_pad_to_midi_note_channel: "..params:get(i.."_pad_to_midi_note_channel").."\n")
    io.write(i.."_pad_to_midi_note_scale: "..params:get(i.."_pad_to_midi_note_scale").."\n")
    io.write(i.."_pad_to_midi_note_root: "..params:get(i.."_pad_to_midi_note_root").."\n")
    io.write(i.."_pad_to_midi_note_root_octave: "..params:get(i.."_pad_to_midi_note_root_octave").."\n")
  end
  io.write("global_pad_to_jf_note_enabled: "..params:get("global_pad_to_jf_note_enabled").."\n")
  io.write("global_pad_to_wsyn_note_enabled: "..params:get("global_pad_to_wsyn_note_enabled").."\n")
  for i = 1,3 do
    io.write(i.."_pad_to_jf_note_enabled: "..params:get(i.."_pad_to_jf_note_enabled").."\n")
    io.write(i.."_pad_to_jf_note_velocity: "..params:get(i.."_pad_to_jf_note_velocity").."\n")
    io.write(i.."_pad_to_wsyn_note_enabled: "..params:get(i.."_pad_to_wsyn_note_enabled").."\n")
    io.write(i.."_pad_to_wsyn_note_velocity: "..params:get(i.."_pad_to_wsyn_note_velocity").."\n")
  end
  io.write("visual_metro: "..params:get("visual_metro").."\n")
  io.write("midigrid?: "..params:get("midigrid?").."\n")
  io.write("start_transport_at_launch: "..params:get("start_transport_at_launch").."\n")
  for i = 1,16 do
    io.write("port_"..i.."_start_stop_out: "..params:get("port_"..i.."_start_stop_out").."\n")
    io.write("port_"..i.."_start_stop_in: "..params:get("port_"..i.."_start_stop_in").."\n")
    io.write("port_"..i.."_clock_out: "..params:get("port_"..i.."_clock_out").."\n")
  end
  for i = 1,3 do
    io.write("start_arp_"..i.."_at_launch: "..params:get("start_arp_"..i.."_at_launch").."\n")
  end
  io.write("arc_size: "..params:get("arc_size").."\n")
  io.close(file)
end

function count_lines_in(file)
  lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return #lines
end

function persistent_state_restore()
  local file = io.open(_path.data .. "cheat_codes_yellow/persistent_state.data", "r")
  if file then
    io.input(file)
    for i = 1,count_lines_in(_path.data.. "cheat_codes_yellow/persistent_state.data") do
      local s = io.read()
      local param,val = s:match("(.+): (.+)")
      params:set(param,tonumber(val))
    end
    io.close(file)
  end
  all_loaded = true
  mc.init()
  clock.run(
    function()
      clock.sleep(1)
      -- if (params:string("start_transport_at_launch") == "yes" and params:string("clock_source") == "internal") then
      if params:string("clock_source") == "internal" then
        -- clock.transport.start()
      end
    end
  )
  if params:get("cut_input_adc") == -inf then
    params:set("cut_input_adc",0)
  end
  metro.free(metro_persistent_state_restore.props.id)
end

function named_overwrite(path)
  if path ~= 'cancel' then
    local file = io.open(path, "r")
    if file then
      io.input(file)
      local collection = io.read()
      io.close(file)
      pre_overwrite(collection)
    end
  else
    print("nothing overwritten")
  end
end

function named_delete(path)
  if path ~= 'cancel' then
    local file = io.open(path, "r")
    if file then
      io.input(file)
      os.remove(path)
      io.close(file)
      print("collection deleted")
    end
  end
end

function pre_overwrite(text)
  if text ~= 'cancel' then
    collection_overwrite_clock = clock.run(overwrite_screen,text)
    _norns.key(1,1)
    _norns.key(1,0)
  else
    print("nothing overwritten")
  end
end

function pre_delete(text)
  if text ~= 'cancel' then
    collection_delete_clock = clock.run(delete_screen,text)
    _norns.key(1,1)
    _norns.key(1,0)
  else
    print("nothing deleted")
  end
end

function pre_save(text)
  local name_filepath = _path.data.."cheat_codes_yellow/names/"
  existing_names = {}
  for i in io.popen("ls "..name_filepath):lines() do
    if string.find(i,"%.cc2$") then table.insert(existing_names,name_filepath..i) end
  end
  if text ~= 'cancel' and text ~= nil and not tab.contains(existing_names,"/home/we/dust/data/cheat_codes_yellow/names/"..text..".cc2") then
    collection_save_clock = clock.run(save_screen,text)
    _norns.key(1,1)
    _norns.key(1,0)
  elseif text == 'cancel' or text == nil then
    print("canceled, nothing saved")
  elseif tab.contains(existing_names,"/home/we/dust/data/cheat_codes_yellow/names/"..text..".cc2") then
    print(text.." already used, will not overwrite")
    clock.run(save_fail_screen,text)
    _norns.key(1,1)
    _norns.key(1,0)
  end
end

function named_savestate(text)

  -- ok, so if working with mkdir, i want the dirname to include ' '
  -- if working with util.file_exists, i want the dirname to not include ' '
  
  local collection = text
  local dirname = _path.data.."cheat_codes_yellow/"
  -- local collection = tonumber(string.format("%.0f",params:get("collection")))
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  local dirname = _path.data.."cheat_codes_yellow/names/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local name_file = io.open(_path.data .. "cheat_codes_yellow/names/"..collection..".cc2", "w+")
  io.output(name_file)
  io.write(collection)
  io.close(name_file)
  
  local dirname = _path.data.."cheat_codes_yellow/collection-"..collection.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  local dirnames = {"banks/","params/","arc-rec/","patterns/","step-seq/","arps/","euclid/","filters/","rnd/","delays/","rec/","misc/","midi_output_maps/","macros/"}
  for i = 1,#dirnames do
    local directory = _path.data.."cheat_codes_yellow/collection-"..collection.."/"..dirnames[i]
    -- if os.rename(directory, directory) == nil then
    if not util.file_exists(directory) then
      os.execute("mkdir " .. directory)
    end
  end

  for i = 1,3 do
    tab.save(bank[i],_path.data .. "cheat_codes_yellow/collection-"..collection.."/banks/"..i..".data")
    tab.save(step_seq[i],_path.data .. "cheat_codes_yellow/collection-"..collection.."/step-seq/"..i..".data")
    tab.save(arp[i],_path.data .. "cheat_codes_yellow/collection-"..collection.."/arps/"..i..".data")
    tab.save(rytm.track[i],_path.data .. "cheat_codes_yellow/collection-"..collection.."/euclid/euclid"..i..".data")
    tab.save(filter[i],_path.data .. "cheat_codes_yellow/collection-"..collection.."/filters/filter"..i..".data")
    tab.save(rnd[i],_path.data .. "cheat_codes_yellow/collection-"..collection.."/rnd/"..i..".data")
    _ca.collect_samples(i,collection)
    -- if params:get("collect_live") == 2 then
    --   _ca.collect_samples(i,collection)
    -- end
  end

  for i = 1,2 do
    tab.save(delay[i],_path.data .. "cheat_codes_yellow/collection-"..collection.."/delays/delay"..(i == 1 and "L" or "R")..".data")
  end
  tab.save(delay_links,_path.data .. "cheat_codes_yellow/collection-"..collection.."/delays/delay-links.data")
  
  params:write(_path.data.."cheat_codes_yellow/collection-"..collection.."/params/all.pset")
  
  -- ultimately, i'll want to remember the mappings of specific devices for specific collections...
  -- norns.pmap.rev[dev][ch][cc]
  -- dev = vport ID...
  -- so, see if there are any mappings and if not then ignore that shit...
  -- otherwise, grab the device name
  -- if the device is present, then the mapping can restore
  -- if not, fuck it.
  -- might also need to `norns.pmap.assign(name,m.dev,m.ch,m.cc)`

  mc.save_mappings(collection)

  tab.save(rec,_path.data .. "cheat_codes_yellow/collection-"..collection.."/rec/rec[rec.focus].data")

  disk_save_patterns(collection)

  selected_coll = collection
  --/ GRID pattern save

  -- MIDI pattern save
  for i = 1,3 do
    save_midi_pattern(i)
  end
  --/ MIDI pattern save

  -- ARC rec save
  local arc_rec_dirty = {false,false,false}
  for i = 1,3 do
    for j = 1,4 do
      if arc_pat[i][j].count > 0 then
        arc_rec_dirty[i] = true
      end
    end
    if arc_rec_dirty[i] then
      save_arc_pattern(i)
    else
      local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/arc-rec/encoder-"..i..".data", "r")
      if file then
        io.input(file)
        os.remove(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/arc-rec/encoder-"..i..".data")
        io.close(file)
      end
    end
  end
  --/ ARC rec save

  -- misc save
  local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/misc/misc.data", "w+")
  if file then
    io.output(file)
    io.write("clock_tempo: "..params:get("clock_tempo").."\n")
    io.close(file)
  end

  for i = 1,3 do
    local directory = _path.data.."cheat_codes_yellow/collection-"..selected_coll.."/midi_output_maps/bank_"..i.."/"
    if os.rename(directory, directory) == nil then
      os.execute("mkdir " .. directory)
    end
  end
  --/ misc save

  -- midi_output_maps save
  local mc_tables =
  {
    "midi_notes"
  , "midi_notes_channels"
  , "midi_notes_velocities"
  , "midi_ccs"
  , "midi_ccs_channels"
  , "midi_ccs_values"
  }
  
  for i = 1,3 do
    for j = 1,#mc_tables do
      local mc_filepath = _path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/midi_output_maps/bank_"..i.."/"..mc_tables[j]..".data"
      local file = io.open(mc_filepath, "w+")
      if file then
        io.output(file)
        tab.save(mc[mc_tables[j]][i].entries,mc_filepath)
        io.close(file)
      end
    end
  end

  for i = 1,8 do
    local macro_filepath = _path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/macros/"..i..".data"
    local file = io.open(macro_filepath, "w+")
    if file then
      io.output(file)
      tab.save(macro[i].params,macro_filepath)
      io.close(file)
    end
  end

  --/ midi_output_maps save

end

function named_loadstate(path)
  local file = io.open(path, "r")
  softcut_voices_are_paused = {}
  if file then
    for i = 1,3 do
      softcut.play(i+1,0)
      softcut_voices_are_paused[i] = true
      -- softcut.level(i+1,0)
    end
    splash_done = false
    print("loading...")
    for j = 1,3 do
      for k = 1,7 do
        if rnd[j][k].clock ~= nil then
          -- print(rnd[j][k].clock)
          clock.cancel(rnd[j][k].clock)
        end
      end
    end
    print(path)
    io.input(file)
    local collection = io.read()
    io.close(file)
    selected_coll = collection
    collection_loaded = true
    if collection == "DEFAULT" then
      zilchmo_animation = clock.run(default_load_screen)
    else
      clock.run(load_screen)
    end
    _norns.key(1,1)
    _norns.key(1,0)
    screen_dirty = true
    all_loaded = false
    reset_all_banks(bank)
    params:read(_path.data.."cheat_codes_yellow/collection-"..collection.."/params/all.pset")
    -- persistent_state_restore()
    if tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/rec/rec[rec.focus].data") ~= nil then
      rec = tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/rec/rec[rec.focus].data")
      if rec.stopped == nil then rec.stopped = false end
      if rec.play_segment == nil then rec.play_segment = rec.focus end
      softcut.loop_start(1,rec[rec.focus].start_point)
      softcut.loop_end(1,rec[rec.focus].end_point-0.01)
    end
    for i = 1,3 do
      if tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/banks/"..i..".data") ~= nil then
        local pre_open = deep_copy(bank[i])
        bank[i] = tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/banks/"..i..".data")
        for k,v in pairs(pre_open) do
          if bank[i][k] == nil then
            print(v)
            bank[i][k] = deep_copy(v)
          end
        end
        for j = 1,16 do
          for k,v in pairs(pre_open[j]) do
            if bank[i][j][k] == nil then
              bank[i][j][k] = v
              -- print(">>>>>>"..k)
            end
          end
        end
        if bank[i][bank[i].id].loop then
          softcut.loop(i+1,1)
          cheat(i,bank[i].id)
        end
      end
      if tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/step-seq/"..i..".data") ~= nil then
        step_seq[i] = tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/step-seq/"..i..".data")
      end
      if tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/arps/"..i..".data") ~= nil then
        local pre_open = deep_copy(arp[i])
        arp[i] = tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/arps/"..i..".data")
        for k,v in pairs(pre_open) do
          if arp[i][k] == nil then
            -- print(v)
            arp[i][k] = deep_copy(v)
          end
        end
      end
      for j = 1,#rnd[i] do
        rnd[i][j].lattice:destroy()
      end
      if tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/rnd/"..i..".data") ~= nil then
        rnd[i] = tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/rnd/"..i..".data")
        for j = 1,#rnd[i] do
          rnd[i][j].lattice = rnd_lattice:new_pattern{
            action = function() rnd.lattice_advance(i,j) end,
            division = rnd[i][j].time/4,
            enabled = true
          }
        end
      end

      local mc_tables =
      {
        "midi_notes"
      , "midi_notes_channels"
      , "midi_notes_velocities"
      , "midi_ccs"
      , "midi_ccs_channels"
      , "midi_ccs_values"
      }

      for j = 1,#mc_tables do
        if tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/midi_output_maps/bank_"..i.."/"..mc_tables[j]..".data") ~= nil then
          mc[mc_tables[j]][i].entries = tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/midi_output_maps/bank_"..i.."/"..mc_tables[j]..".data")
        end
      end

      if util.file_exists(_path.dust.."audio/ccy_live-audio/"..collection.."/".."ccy_"..collection.."-"..i..".wav") then
        _ca.reload_collected_samples(_path.dust.."audio/ccy_live-audio/"..collection.."/".."ccy_"..collection.."-"..i..".wav",i)
      else
        print("don't worry, but no file: ".._path.dust.."audio/ccy_live-audio/"..collection.."/".."ccy_"..collection.."-"..i..".wav")
        print("^ just a heads up, in case you were expecting a live recording to pre-load :)")
      end
      
      if tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/euclid/euclid"..i..".data") ~= nil then
        rytm.track[i] = tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/euclid/euclid"..i..".data")
        if rytm.track[i].runner == nil then rytm.track[i].runner = 0 end
      end
      -- rytm.reset_all_patterns() -- i deactivated this so that a loaded pattern wouldn't auto-start euclid...
      
    end

    arps.restore_collection()
    rytm.restore_collection()
    filters.restore_collection(collection)

    for i = 1,8 do
      if tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/macros/"..i..".data") ~= nil then
        macro[i].params = tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/macros/"..i..".data")
      end
    end

    for i = 1,2 do
      if tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/delays/delay"..(i == 1 and "L" or "R")..".data") ~= nil then
        local pre_open = deep_copy(delay[i])
        delay[i] = tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/delays/delay"..(i == 1 and "L" or "R")..".data")
        for k,v in pairs(pre_open) do
          if delay[i][k] == nil then
            delay[i][k] = deep_copy(v)
          end
        end
      end
    end

    if tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/delays/delay-links.data") ~= nil then
      delay_links = tab.load(_path.data .. "cheat_codes_yellow/collection-"..collection.."/delays/delay-links.data")
    end

    -- GRID pattern restore
    if selected_coll ~= collection then
    elseif selected_coll == collection then
      cleanup()
    end
    -- one_point_two()
    queue_saved_patterns()
    -- / GRID pattern restore

    for i = 1,3 do
      load_arc_pattern(i)
    end

    for i = 1,3 do
      midi_pat[i]:restore_defaults()
      local dirname = _path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/midi"..i..".data"
      if os.rename(dirname, dirname) ~= nil then
        load_midi_pattern(i)
      end
    end

    --TODO confirm this is ok, not a namespace collision?
    local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/misc/misc.data", "r")
    if file then
      io.input(file)
      params:set("clock_tempo", tonumber(string.match(io.read(), ': (.*)')))
      io.close(file)
    end

  else
    _norns.key(1,1)
    _norns.key(1,0)
    collection_loaded = false
    clock.run(load_fail_screen)
  end

  ping_midi_devices()
  -- if file then
  --   if tab.load(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/params/mappings.txt") ~= nil then
  --     norns.pmap.rev = tab.load(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/params/mappings.txt")
  --     norns.pmap.data = tab.load(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/params/map-data.txt")
  --     -- BUT, i want the device to be present or reassigned...
  --   end
  -- end
    
  if not lfo_metro.is_running then
    lfo_metro:start()
  end
  grid_dirty = true
  all_loaded = true
end

function test_load(slot,destination)
  if pattern_saver[destination].saved[slot-((destination-1)*8)] == 1 then
    if grid_pat[destination].play == 1 then
      grid_pat[destination]:clear()
    elseif arp[destination].playing then
      arp[destination].pause = true
      arp[destination].playing = false
    elseif grid_pat[destination].tightened_start == 1 then -- not relevant?
      grid_pat[destination].tightened_start = 0
      grid_pat[destination].step = grid_pat[destination].start_point-1
      quantized_grid_pat[destination].current_step = grid_pat[destination].start_point
      quantized_grid_pat[destination].sub_step = 1
    end
    -- load_pattern(slot,destination)
    new_load_pattern(slot,destination)
    if grid_pat[destination].count > 0 then
      -- print("5091", destination)
      start_pattern(grid_pat[destination],"jumpstart")
    -- elseif #arp[destination].notes > 0 then
    elseif tab.count(arp[destination].notes) > 0 then
      local arp_start =
      {
        ["fwd"] = arp[destination].start_point - 1
      , ["bkwd"] = arp[destination].end_point + 1
      , ["pend"] = arp[destination].start_point
      , ["rnd"] = arp[destination].start_point - 1
      }
      arp[destination].step = arp_start[arp[destination].mode]
      arp[destination].pause = false
      arp[destination].playing = true
      if arp[destination].mode == "pend" then
        arp_direction[destination] = "negative"
      end
      arps.tick(destination,"test_load")
    end
  end
end

function redux_save_pattern(source,slot,style)
  if meta_grid_pattern == nil then meta_grid_pattern = {} end
  if meta_grid_pattern[source] == nil then meta_grid_pattern[source] = {} end
  if meta_grid_pattern[source][slot] == nil then meta_grid_pattern[source][slot] = {} end
  if style == "pattern" then
    -- if meta_grid_pattern == nil then meta_grid_pattern = {} end
    -- if meta_grid_pattern[source] == nil then meta_grid_pattern[source] = {} end
    -- if meta_grid_pattern[source][slot] == nil then meta_grid_pattern[source][slot] = {} end
    table.insert(meta_grid_pattern[source][slot],"stored pad pattern: collection "..selected_coll.." + slot "..slot)
    table.insert(meta_grid_pattern[source][slot],grid_pat[source].count)
    for i = 1,grid_pat[source].count do
      table.insert(meta_grid_pattern[source][slot],grid_pat[source].time[i])
      if grid_pat[source].event[i] ~= "pause" then
        table.insert(meta_grid_pattern[source][slot],grid_pat[source].event[i].id)
        table.insert(meta_grid_pattern[source][slot],grid_pat[source].event[i].rate)
        table.insert(meta_grid_pattern[source][slot],tostring(grid_pat[source].event[i].loop))
        if grid_pat[source].event[i].mode ~= nil then
          table.insert(meta_grid_pattern[source][slot],grid_pat[source].event[i].mode)
        else
          table.insert(meta_grid_pattern[source][slot],"nil")
        end
        table.insert(meta_grid_pattern[source][slot],tostring(grid_pat[source].event[i].pause))
        table.insert(meta_grid_pattern[source][slot],grid_pat[source].event[i].start_point)
        if grid_pat[source].event[i].clip ~= nil then
          table.insert(meta_grid_pattern[source][slot],grid_pat[source].event[i].clip)
        else
          table.insert(meta_grid_pattern[source][slot],"nil")
        end
        table.insert(meta_grid_pattern[source][slot],grid_pat[source].event[i].end_point)
        if grid_pat[source].event[i].rate_adjusted ~= nil then
          table.insert(meta_grid_pattern[source][slot],tostring(grid_pat[source].event[i].rate_adjusted))
        else
          table.insert(meta_grid_pattern[source][slot],"nil")
        end
        table.insert(meta_grid_pattern[source][slot],grid_pat[source].event[i].y)
        table.insert(meta_grid_pattern[source][slot],grid_pat[source].event[i].x)
        table.insert(meta_grid_pattern[source][slot],tostring(grid_pat[source].event[i].action))
        table.insert(meta_grid_pattern[source][slot],grid_pat[source].event[i].i)
        if grid_pat[source].event[i].previous_rate ~= nil then
          table.insert(meta_grid_pattern[source][slot],grid_pat[source].event[i].previous_rate)
        else
          table.insert(meta_grid_pattern[source][slot],"nil")
        end
        if grid_pat[source].event[i].row ~=nil then
          table.insert(meta_grid_pattern[source][slot],grid_pat[source].event[i].row)
        else
          table.insert(meta_grid_pattern[source][slot],"nil")
        end
        if grid_pat[source].event[i].con ~= nil then
          table.insert(meta_grid_pattern[source][slot],grid_pat[source].event[i].con)
        else
          table.insert(meta_grid_pattern[source][slot],"nil")
        end
        if grid_pat[source].event[i].bank ~= nil and #grid_pat[source].event > 0 then
          table.insert(meta_grid_pattern[source][slot],grid_pat[source].event[i].bank)
        else
          table.insert(meta_grid_pattern[source][slot],"nil")
        end
      else
        table.insert(meta_grid_pattern[source][slot],"pause")
      end
    end
    --/new stuff!

    table.insert(meta_grid_pattern[source][slot],grid_pat[source].metro.props.time)
    table.insert(meta_grid_pattern[source][slot],grid_pat[source].prev_time)
    table.insert(meta_grid_pattern[source][slot],"which playmode?")
    table.insert(meta_grid_pattern[source][slot],grid_pat[source].playmode)
    table.insert(meta_grid_pattern[source][slot],"start point")
    table.insert(meta_grid_pattern[source][slot],grid_pat[source].start_point)
    table.insert(meta_grid_pattern[source][slot],"end point")
    table.insert(meta_grid_pattern[source][slot],grid_pat[source].end_point)

    --new stuff, quantum and time_beats!
    table.insert(meta_grid_pattern[source][slot],"cheat codes 2.0")
    for i = 1,grid_pat[source].count do
      table.insert(meta_grid_pattern[source][slot],grid_pat[source].quantum[i])
      table.insert(meta_grid_pattern[source][slot],grid_pat[source].time_beats[i])
    end
    --/new stuff, quantum and time_beats!

    -- new stuff, quant or unquant + rec_clock_time
    table.insert(meta_grid_pattern[source][slot],grid_pat[source].mode)
    table.insert(meta_grid_pattern[source][slot],grid_pat[source].rec_clock_time)
  elseif style =="arp" then
    -- save_pattern(source,slot,style)
    meta_grid_pattern[source][slot] = deep_copy(arp[source])
  end
end

function disk_save_patterns(coll)
  local buckets = {"arp","grid","euclid"}
  for b = 1,#buckets do
    local dest = buckets[b]
    local dirname = _path.data.."cheat_codes_yellow/collection-"..coll.."/"
    if os.rename(dirname, dirname) == nil then
      os.execute("mkdir " .. dirname)
    end
    local dirname = _path.data.."cheat_codes_yellow/collection-"..coll.."/patterns/"
    if os.rename(dirname, dirname) == nil then
      os.execute("mkdir " .. dirname)
    end
    local dirname = _path.data.."cheat_codes_yellow/collection-"..coll.."/patterns/"..dest.."/"
    if os.rename(dirname, dirname) == nil then
      os.execute("mkdir " .. dirname)
    end
    for i = 1,3 do
      local dirname = _path.data.."cheat_codes_yellow/collection-"..coll.."/patterns/"..dest.."/"..i.."/"
      if os.rename(dirname, dirname) == nil then
        os.execute("mkdir " .. dirname)
      end
      for j = 1,#pattern_data[i][dest] do
        tab.save(pattern_data[i][dest][j],dirname..j..".data")
      end
    end
  end
end

function already_saved()
  for i = 1,24 do
    local line_count = 0
    local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/"..i..".data", "r")
    if file then
      io.input(file)
      for lines in io.lines(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/"..i..".data") do
        line_count = line_count + 1
      end
      if line_count > 0 then
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 1
      else
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 0
        -- print("killing yr file4387")
        os.remove(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/"..i..".data")
      end
      io.close(file)
    else
      local current = math.floor((i-1)/8)+1
      pattern_saver[current].saved[i-(8*(current-1))] = 0
    end
  end
end

function one_point_two()
  for i = 1,24 do
    local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/"..i..".data", "r")
    if file then
      io.input(file)
      local current = math.floor((i-1)/8)+1
      load_pattern(i,current)
      io.close(file)
    end
  end
  for i = 1,3 do
    grid_actions.rec_stop(i)
    stop_pattern(grid_pat[i])
    -- grid_pat[i]:stop()
    grid_pat[i].tightened_start = 0
    grid_pat[i]:clear()
    pattern_saver[i].load_slot = 0
  end
end

function clear_zero()
  for i = 1,24 do
    local file = io.open(_path.data .. "cheat_codes_yellow/collection-0/patterns/"..i..".data", "r")
    if file then
      io.input(file)
      local line_count = 0
      for lines in io.lines(_path.data .. "cheat_codes_yellow/collection-0/patterns/"..i..".data") do
        line_count = line_count + 1
      end
      if line_count > 0 then
        os.remove(_path.data .. "cheat_codes_yellow/collection-0/patterns/"..i..".data")
        print("cleared default pattern")
      end
      io.close(file)
    end
  end
end

function delete_pattern(i,slot)
  meta_grid_pattern[i][slot] = nil
end

function queue_saved_patterns()
  local buckets = {"arp","grid","euclid"}
  for b = 1,#buckets do
    local dest = buckets[b]
    for i = 1,3 do
      for j = 1,8 do
        pattern_data[i][dest][j] = tab.load(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/"..dest.."/"..i.."/"..j..".data")
      end
    end
  end
end

function get_line(filename, line_number)
  local i = 0
  for line in io.lines(filename) do
    i = i + 1
    if i == line_number then
      return line
    end
  end
  return nil -- line not found
end

function build_pattern_queue(slot,destination)
  local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/"..slot..".data", "r")
  if file then
    -- io.input(file)
    if meta_grid_pattern == nil then meta_grid_pattern = {} end
    if meta_grid_pattern[destination] == nil then meta_grid_pattern[destination] = {} end
    if meta_grid_pattern[destination][slot] == nil then meta_grid_pattern[destination][slot] = {} end
    local first_line = get_line(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/"..slot..".data",1)
    if first_line ~= "return {" then
      for line in file:lines() do
        meta_grid_pattern[destination][slot][#meta_grid_pattern[destination][slot]+1] = line
      end
    else
      meta_grid_pattern[destination][slot] = tab.load(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/"..slot..".data")
    end
    io.close(file)
    pattern_saver[destination].saved[slot-(8*(destination-1))] = 1
  else
    -- print("no grid patterns for bank "..destination..", slot "..slot)
    pattern_saver[destination].saved[slot-(8*(destination-1))] = 0
  end
end

function new_load_pattern(slot,destination)
  if meta_grid_pattern[destination][slot] ~= nil then
    if meta_grid_pattern[destination][slot][1] == "stored pad pattern: collection "..selected_coll.." + slot "..slot then
      grid_pat[destination].event = {}
      grid_pat[destination].count = tonumber(meta_grid_pattern[destination][slot][2])
      local skip_pause = false
      -- pause only ever happens at meta_grid_pattern[destination][slot][4]...
      if meta_grid_pattern[destination][slot][4] == "pause" then
        grid_pat[destination].event[1] = "pause"
        grid_pat[destination].time[1] = tonumber(meta_grid_pattern[destination][slot][3])
        skip_pause = true
      end
      for i = skip_pause and 2 or 1,grid_pat[destination].count do -- it's chunks of 17
        local c_l;
        if skip_pause then
          c_l = ((i + ((i-1)*17))+2)-16
        else
          c_l = (i + ((i-1)*17))+2
        end
        -- if destination == 1 then print(c_l) end
        grid_pat[destination].time[i] = tonumber(meta_grid_pattern[destination][slot][c_l])
        local pause_or_id = meta_grid_pattern[destination][slot][c_l+1]
        grid_pat[destination].event[i] = {}
        if pause_or_id ~= "pause" then
          grid_pat[destination].event[i].id = {}
          grid_pat[destination].event[i].rate = {}
          grid_pat[destination].event[i].loop = {}
          grid_pat[destination].event[i].mode = {}
          grid_pat[destination].event[i].pause = {}
          grid_pat[destination].event[i].start_point = {}
          grid_pat[destination].event[i].clip = {}
          grid_pat[destination].event[i].end_point = {}
          grid_pat[destination].event[i].rate_adjusted = {}
          grid_pat[destination].event[i].y = {}
          grid_pat[destination].event[i].x = {}
          grid_pat[destination].event[i].action = {}
          grid_pat[destination].event[i].i = {}
          grid_pat[destination].event[i].previous_rate = {}
          grid_pat[destination].event[i].row = {}
          grid_pat[destination].event[i].con = {}
          grid_pat[destination].event[i].bank = nil
          grid_pat[destination].event[i].id = tonumber(pause_or_id)
          grid_pat[destination].event[i].rate = tonumber(meta_grid_pattern[destination][slot][c_l+2])
          local loop_to_boolean = meta_grid_pattern[destination][slot][c_l+3]
          if loop_to_boolean == "true" then
            grid_pat[destination].event[i].loop = true
          else
            grid_pat[destination].event[i].loop = false
          end
          grid_pat[destination].event[i].mode = tonumber(meta_grid_pattern[destination][slot][c_l+4])
          local pause_to_boolean = meta_grid_pattern[destination][slot][c_l+5]
          if pause_to_boolean == "true" then
            grid_pat[destination].event[i].pause = true
          else
            grid_pat[destination].event[i].pause = false
          end
          grid_pat[destination].event[i].start_point = tonumber(meta_grid_pattern[destination][slot][c_l+6])
          grid_pat[destination].event[i].clip = tonumber(meta_grid_pattern[destination][slot][c_l+7])
          grid_pat[destination].event[i].end_point = tonumber(meta_grid_pattern[destination][slot][c_l+8])
          local rate_adjusted_to_boolean = meta_grid_pattern[destination][slot][c_l+9]
          if rate_adjusted_to_boolean == "true" then
            grid_pat[destination].event[i].rate_adjusted = true
          else
            grid_pat[destination].event[i].rate_adjusted = false
          end
          grid_pat[destination].event[i].y = tonumber(meta_grid_pattern[destination][slot][c_l+10])
          local loaded_x = tonumber(meta_grid_pattern[destination][slot][c_l+11])
          grid_pat[destination].event[i].action = meta_grid_pattern[destination][slot][c_l+12]
          grid_pat[destination].event[i].i = destination
          local source = tonumber(meta_grid_pattern[destination][slot][c_l+13])
          if destination < source then
            grid_pat[destination].event[i].x = loaded_x - (5*(source-destination))
          elseif destination > source then
            grid_pat[destination].event[i].x = loaded_x + (5*(destination-source))
          elseif destination == source then
            grid_pat[destination].event[i].x = loaded_x
          end
          grid_pat[destination].event[i].previous_rate = tonumber(meta_grid_pattern[destination][slot][c_l+14])
          grid_pat[destination].event[i].row = tonumber(meta_grid_pattern[destination][slot][c_l+15])
          grid_pat[destination].event[i].con = meta_grid_pattern[destination][slot][c_l+16]
          local loaded_bank = tonumber(meta_grid_pattern[destination][slot][c_l+17])
          if loaded_bank ~= nil then
            if destination < source then
              grid_pat[destination].event[i].bank = loaded_bank - (5*(source-destination))
            elseif destination > source then
              grid_pat[destination].event[i].bank = loaded_bank + (5*(source-destination))
            elseif destination == source then
              grid_pat[destination].event[i].bank = loaded_bank
            end
          end
        else
          grid_pat[destination].event[i] = "pause"
        end

      end
      local last_line = ((meta_grid_pattern[destination][slot][2] + ((meta_grid_pattern[destination][slot][2]-1)*17))+2)+(skip_pause and 1 or 17)
      local end_line = #meta_grid_pattern[destination][slot]
      grid_pat[destination].metro.props.time = tonumber(meta_grid_pattern[destination][slot][last_line+1])
      grid_pat[destination].prev_time = tonumber(meta_grid_pattern[destination][slot][last_line+2])
      if meta_grid_pattern[destination][slot][last_line+3] == "which playmode?" then
        local pm = tonumber(meta_grid_pattern[destination][slot][last_line+4])
        if pm ~= 1 then
          grid_pat[destination].playmode = 2
        else
          grid_pat[destination].playmode = 1
        end
      else
        grid_pat[destination].playmode = 1
      end
      --set_pattern_mode(grid_pat[destination],destination)
      if meta_grid_pattern[destination][slot][last_line+5] == "start point" then
        grid_pat[destination].start_point = tonumber(meta_grid_pattern[destination][slot][last_line+6])
      else
        grid_pat[destination].start_point = 1
      end
      if meta_grid_pattern[destination][slot][last_line+7] == "end point" then
        grid_pat[destination].end_point = tonumber(meta_grid_pattern[destination][slot][last_line+8])
      else
        grid_pat[destination].end_point = grid_pat[destination].count
      end
      if meta_grid_pattern[destination][slot][last_line+9] == "cheat codes 2.0" then
        for i = 1,grid_pat[destination].count do
          local c_l = (i + ((i-1)))+9
          grid_pat[destination].quantum[i] = tonumber(meta_grid_pattern[destination][slot][c_l])
          grid_pat[destination].time_beats[i] = tonumber(meta_grid_pattern[destination][slot][c_l+1])
        end
        grid_pat[destination].mode = meta_grid_pattern[destination][slot][end_line-1]
        grid_pat[destination].rec_clock_time = tonumber(meta_grid_pattern[destination][slot][end_line])
        ignore_external_timing = true
      end
    else
      -- print("it's an arp!")
      -- arp[destination] = tab.load(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/"..slot..".data")
      arp[destination] = deep_copy(meta_grid_pattern[destination][slot])
      ignore_external_timing = true
    end
    if not ignore_external_timing then
      print("see load_external_timing")
    end
  else
    print("no grid patterns to load!")
  end
end

function load_pattern(slot,destination)
  local ignore_external_timing = false
  local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/"..slot..".data", "r")
  if file then
    io.input(file)
    if io.read() == "stored pad pattern: collection "..selected_coll.." + slot "..slot then
      grid_pat[destination].event = {}
      grid_pat[destination].count = tonumber(io.read())
      for i = 1,grid_pat[destination].count do
        grid_pat[destination].time[i] = tonumber(io.read())
        local pause_or_id = io.read()
        grid_pat[destination].event[i] = {}
        if pause_or_id ~= "pause" then
          grid_pat[destination].event[i].id = {}
          grid_pat[destination].event[i].rate = {}
          grid_pat[destination].event[i].loop = {}
          grid_pat[destination].event[i].mode = {}
          grid_pat[destination].event[i].pause = {}
          grid_pat[destination].event[i].start_point = {}
          grid_pat[destination].event[i].clip = {}
          grid_pat[destination].event[i].end_point = {}
          grid_pat[destination].event[i].rate_adjusted = {}
          grid_pat[destination].event[i].y = {}
          grid_pat[destination].event[i].x = {}
          grid_pat[destination].event[i].action = {}
          grid_pat[destination].event[i].i = {}
          grid_pat[destination].event[i].previous_rate = {}
          grid_pat[destination].event[i].row = {}
          grid_pat[destination].event[i].con = {}
          grid_pat[destination].event[i].bank = nil
          grid_pat[destination].event[i].id = tonumber(pause_or_id)
          grid_pat[destination].event[i].rate = tonumber(io.read())
          local loop_to_boolean = io.read()
          if loop_to_boolean == "true" then
            grid_pat[destination].event[i].loop = true
          else
            grid_pat[destination].event[i].loop = false
          end
          grid_pat[destination].event[i].mode = tonumber(io.read())
          local pause_to_boolean = io.read()
          if pause_to_boolean == "true" then
            grid_pat[destination].event[i].pause = true
          else
            grid_pat[destination].event[i].pause = false
          end
          grid_pat[destination].event[i].start_point = tonumber(io.read())
          grid_pat[destination].event[i].clip = tonumber(io.read())
          grid_pat[destination].event[i].end_point = tonumber(io.read())
          local rate_adjusted_to_boolean = io.read()
          if rate_adjusted_to_boolean == "true" then
            grid_pat[destination].event[i].rate_adjusted = true
          else
            grid_pat[destination].event[i].rate_adjusted = false
          end
          grid_pat[destination].event[i].y = tonumber(io.read())
          local loaded_x = tonumber(io.read())
          grid_pat[destination].event[i].action = io.read()
          grid_pat[destination].event[i].i = destination
          local source = tonumber(io.read())
          if destination < source then
            grid_pat[destination].event[i].x = loaded_x - (5*(source-destination))
          elseif destination > source then
            grid_pat[destination].event[i].x = loaded_x + (5*(destination-source))
          elseif destination == source then
            grid_pat[destination].event[i].x = loaded_x
          end
          grid_pat[destination].event[i].previous_rate = tonumber(io.read())
          grid_pat[destination].event[i].row = tonumber(io.read())
          grid_pat[destination].event[i].con = io.read()
          local loaded_bank = tonumber(io.read())
          if loaded_bank ~= nil then
            if destination < source then
              grid_pat[destination].event[i].bank = loaded_bank - (5*(source-destination))
            elseif destination > source then
              grid_pat[destination].event[i].bank = loaded_bank + (5*(source-destination))
            elseif destination == source then
              grid_pat[destination].event[i].bank = loaded_bank
            end
          end
        else
          grid_pat[destination].event[i] = "pause"
        end

      end
      grid_pat[destination].metro.props.time = tonumber(io.read())
      grid_pat[destination].prev_time = tonumber(io.read())
      if io.read() == "which playmode?" then
        local pm = tonumber(io.read())
        if pm ~= 1 then
          grid_pat[destination].playmode = 2
        else
          grid_pat[destination].playmode = 1
        end
      else
        grid_pat[destination].playmode = 1
      end
      --set_pattern_mode(grid_pat[destination],destination)
      if io.read() == "start point" then
        grid_pat[destination].start_point = tonumber(io.read())
      else
        grid_pat[destination].start_point = 1
      end
      if io.read() == "end point" then
        grid_pat[destination].end_point = tonumber(io.read())
      else
        grid_pat[destination].end_point = grid_pat[destination].count
      end
      if io.read() == "cheat codes 2.0" then
        for i = 1,grid_pat[destination].count do
          grid_pat[destination].quantum[i] = tonumber(io.read())
          grid_pat[destination].time_beats[i] = tonumber(io.read())
        end
        grid_pat[destination].mode = io.read()
        grid_pat[destination].rec_clock_time = tonumber(io.read())
        ignore_external_timing = true
      end
    else
      -- print("it's an arp!")
      arp[destination] = tab.load(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/"..slot..".data")
      ignore_external_timing = true
    end

    io.close(file)
    if not ignore_external_timing then
      print("see load_external_timing")
    end
  else
    print("no grid patterns to load!")
  end
end

function midi_panic()
  print("# ending held MIDI notes")
  for i = 1,128 do
    for j = 1,3 do
      for z = 1,16 do
      midi_dev[params:get(j.."_pad_to_midi_note_destination")]:note_off(i, nil, z)
      end
    end
  end
  for i = 1,3 do
    for j = 1,16 do
      mc.global_note_off(i,j)
    end
  end
end

function cleanup()

  -- print("cleaning up")

  persistent_state_save()

  metro[31].time = 0.25

  for i = 1,3 do
    env_counter[i]:stop()
  end

  lfo_metro:stop()

  midi_panic()
  -- print("cleaned up")
end

-- arc pattern stuff!

function save_arc_pattern(which)
  local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/arc-rec/encoder-"..which..".data", "w+")
  io.output(file)
  io.write("stored arc pattern: collection "..selected_coll.." + encoder "..which.."\n")
  for j = 1,4 do
    io.write("total events in recording "..j..": "..arc_pat[which][j].count .. "\n")
    for i = 1,arc_pat[which][j].count do
      io.write("event "..i.." time: "..arc_pat[which][j].time[i] .. "\n")
      io.write("event "..i.." i1: "..arc_pat[which][j].event[i].i1 .. "\n")
      io.write("event "..i.." i2: "..arc_pat[which][j].event[i].i2 .. "\n")
      io.write("event "..i.." param: "..arc_pat[which][j].event[i].param .. "\n")
      io.write("event "..i.." pad: "..arc_pat[which][j].event[i].pad .. "\n")
      io.write("event "..i.." start point: "..arc_pat[which][j].event[i].start_point .. "\n")
      io.write("event "..i.." end point: "..arc_pat[which][j].event[i].end_point .. "\n")
      io.write("event "..i.." prev tilt: "..arc_pat[which][j].event[i].prev_tilt .. "\n")
      io.write("event "..i.." tilt: "..arc_pat[which][j].event[i].tilt .. "\n")
      io.write("event "..i.." pan: "..arc_pat[which][j].event[i].pan .. "\n")
      io.write("event "..i.." level: "..arc_pat[which][j].event[i].level .. "\n")
      io.write("event "..i.." global level: "..arc_pat[which][j].event[i].global_level .. "\n")
    end
    io.write("recording "..j.." props time: "..arc_pat[which][j].metro.props.time .. "\n")
    io.write("recording "..j.." prev time: "..arc_pat[which][j].prev_time .. "\n")
    io.write("recording "..j.." start point: " .. arc_pat[which][j].start_point .. "\n")
    io.write("recording "..j.." end point: " .. arc_pat[which][j].end_point .. "\n")
  end
  io.close(file)
  print("saved arc pattern for encoder "..which)
end

function load_arc_pattern(which)
  local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/arc-rec/encoder-"..which..".data", "r")
  if file then
    io.input(file)
    if io.read() == "stored arc pattern: collection "..selected_coll.." + encoder "..which then
      for j = 1,4 do
        arc_pat[which][j].event = {}
        arc_pat[which][j].count = tonumber(string.match(io.read(), ': (.*)'))
        for i = 1,arc_pat[which][j].count do
          arc_pat[which][j].time[i] = tonumber(string.match(io.read(), ': (.*)'))
          arc_pat[which][j].event[i] = {}
          arc_pat[which][j].event[i].i1 = {}
          arc_pat[which][j].event[i].i2 = {}
          arc_pat[which][j].event[i].param = {}
          arc_pat[which][j].event[i].pad = {}
          arc_pat[which][j].event[i].start_point = {}
          arc_pat[which][j].event[i].end_point = {}
          arc_pat[which][j].event[i].prev_tilt = {}
          arc_pat[which][j].event[i].tilt = {}
          arc_pat[which][j].event[i].pan = {}
          arc_pat[which][j].event[i].level = {}
          arc_pat[which][j].event[i].global_level = {}
          --
          arc_pat[which][j].event[i].i1 = tonumber(string.match(io.read(), ': (.*)'))
          arc_pat[which][j].event[i].i2 = tonumber(string.match(io.read(), ': (.*)'))
          arc_pat[which][j].event[i].param = tonumber(string.match(io.read(), ': (.*)'))
          arc_pat[which][j].event[i].pad =tonumber(string.match(io.read(), ': (.*)'))
          arc_pat[which][j].event[i].start_point = tonumber(string.match(io.read(), ': (.*)'))
          arc_pat[which][j].event[i].end_point = tonumber(string.match(io.read(), ': (.*)'))
          arc_pat[which][j].event[i].prev_tilt = tonumber(string.match(io.read(), ': (.*)'))
          arc_pat[which][j].event[i].tilt = tonumber(string.match(io.read(), ': (.*)'))
          arc_pat[which][j].event[i].pan = tonumber(string.match(io.read(), ': (.*)'))
          arc_pat[which][j].event[i].level = tonumber(string.match(io.read(), ': (.*)'))
          arc_pat[which][j].event[i].global_level = tonumber(string.match(io.read(), ': (.*)'))
        end
        arc_pat[which][j].metro.props.time = tonumber(string.match(io.read(), ': (.*)'))
        arc_pat[which][j].prev_time = tonumber(string.match(io.read(), ': (.*)'))
        arc_pat[which][j].start_point = tonumber(string.match(io.read(), ': (.*)'))
        arc_pat[which][j].end_point = tonumber(string.match(io.read(), ': (.*)'))
      end
    end
    io.close(file)
    grid_dirty = true
  else
    -- print("no arc patterns to load")
  end
end

function save_midi_pattern(which)
  local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/midi"..which..".data", "w+")
  io.output(file)
  if midi_pat[which].count > 0 then
    io.write("stored midi pattern: collection "..selected_coll..", pattern "..which.."\n")
    io.write("total: "..midi_pat[which].count .. "\n")
    for i = 1,midi_pat[which].count do
      io.write("unquant time: "..midi_pat[which].time[i] .. "\n")
      --io.write("quant duration: "..midi_pat[which].time_beats[i] .. "\n")
      io.write("quant duration: 0.8".."\n")
      io.write("target: "..midi_pat[which].event[i].target .. "\n")
      io.write("note: "..midi_pat[which].event[i].note .. "\n")
    end
    io.write("metro props time: "..midi_pat[which].metro.props.time .. "\n")
    io.write("metro prev time: "..midi_pat[which].prev_time .. "\n")
    io.write("pattern start point: " .. midi_pat[which].start_point .. "\n")
    io.write("pattern end point: " .. midi_pat[which].end_point .. "\n")
    io.write("playmode: " .. midi_pat[which].playmode .. "\n")
    io.write("random_pitch_range: " .. midi_pat[which].random_pitch_range .. "\n")
    io.write("rec_clock_time: " .. midi_pat[which].rec_clock_time .. "\n")
  else
    io.write("no data present")
  end
  io.close(file)
  print("saved midi pattern "..which)
end

function load_midi_pattern(which)
  local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..selected_coll.."/patterns/midi"..which..".data", "r")
  if file then
    io.input(file)
    if io.read() == "stored midi pattern: collection "..selected_coll..", pattern "..which then
      midi_pat[which].event = {}
      midi_pat[which].count = tonumber(string.match(io.read(), ': (.*)'))
      for i = 1,midi_pat[which].count do
        midi_pat[which].time[i] = tonumber(string.match(io.read(), ': (.*)'))
        midi_pat[which].time_beats[i] = tonumber(string.match(io.read(), ': (.*)'))
        midi_pat[which].event[i] = {}
        midi_pat[which].event[i].target = tonumber(string.match(io.read(), ': (.*)'))
        midi_pat[which].event[i].note = tonumber(string.match(io.read(), ': (.*)'))
        --
      end
      midi_pat[which].metro.props.time = tonumber(string.match(io.read(), ': (.*)'))
      midi_pat[which].prev_time = tonumber(string.match(io.read(), ': (.*)'))
      midi_pat[which].start_point = tonumber(string.match(io.read(), ': (.*)'))
      midi_pat[which].end_point = tonumber(string.match(io.read(), ': (.*)'))
      local full_param, first, second;
      for i = 1,3 do
        full_param = io.read()
        first = full_param:match("(.+):")
        second = full_param:match(": (.*)")
        midi_pat[which][first] = full_param ~= nil and tonumber(second) or midi_pat[which][first]
      end
      print("loaded midi pat "..which)
    end
    io.close(file)
  else
    print("no midi patterns to load")
  end
end