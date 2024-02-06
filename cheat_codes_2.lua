-- cheat codes 2
--          a sample playground
-- rev: 240206 - LTS13
-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
-- need help?
-- please visit:
-- l.llllllll.co/cheat-codes-2
-- -------------------------------

if tonumber(norns.version.update) < 221214 then
  norns.script.clear()
  norns.script.load('code/cheat_codes_2/lib/fail_state-update.lua')
end

if not util.file_exists(_path.code..'cheat_codes_2/lib/nb/lib/') then
  norns.script.clear()
  norns.script.load('code/cheat_codes_2/lib/fail_state-nb.lua')
end

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

function grid.add(dev)
  grid_dirty = true
end

midigrid_present = util.file_exists(_path.code.."midigrid") and grid.vports[1].name == 'none'

grid_device = midigrid_present and include "midigrid/lib/mg_128" or grid

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

-- if util.file_exists(_path.code.."mx.samples") then
--   mxsamples = include 'mx.samples/lib/mx.samples'
--   engine.name = "MxSamples"
--   mxcc = mxsamples:new()
--   print("available instruments: ")
--   tab.print(mxcc:list_instruments())
-- end

engine.name = 'PolyPerc'

function metronome_audio()
  while true do
    clock.sync(1)
    if params:string("metronome_audio_state") == "on" and transport.is_running then
      if util.round(clock.get_beats()%4) == 0 then
        engine.hz(params:get("metronome_one_beat_pitch"))
      else
        engine.hz(params:get("metronome_alt_beat_pitch"))
      end
    end
  end
end

local pattern_time = include 'lib/cc_pattern_time'
MU = require "musicutil"
UI = require "ui"
lattice = require "lattice"
fileselect = require 'fileselect'
textentry = require 'textentry'
main_menu = include 'lib/main_menu'
encoder_actions = include 'lib/encoder_actions'
arc_actions = include 'lib/arc_actions'
rightangleslice = include 'lib/zilchmos'
start_up = include 'lib/start_up'
grid_actions = include 'lib/grid_actions'
easingFunctions = include 'lib/easing'
arps = include 'lib/arp_actions'
rnd = include 'lib/rnd_actions'
del = include 'lib/delay'
rytm = include 'lib/euclid'
mc = include 'lib/midicheat'
-- sharer = include 'lib/sharer'
macros = include 'lib/macros'
transport = include 'lib/transport'
speed_dial = include 'lib/speed_dial'
_lfos = include 'lib/lfos'
_lfos.max_per_group = 9
math.randomseed(os.time())
splash_done = true
actively_loading_collection = false
cc_json = include 'lib/cc_json'
nb = include 'lib/nb/lib/nb'

macro = {}
for i = 1,8 do
  macro[i] = macros.new_macro()
end

-- thank you zack (@infinitedigits) for pioneering aubiogo on norns!!!
cursors = {{},{},{}}
detecting_onsets_popup = {}
detected_onsets_popup = {}

osc_fun={
  progressbar=function(args)
    -- print(args[1],tonumber(args[2]))
    detecting_onsets_popup = {state = true, percent = args[2], id = tonumber(string.match(args[1],"%d+"))}
  end,
  aubiodone=function(args)
    local id=tonumber(args[1])
    stuff=args[2]
    local data=cc_json.parse(stuff)
    if data==nil then
      print("error getting onset data!")
      do return end
    end
    if data.error~=nil then
      print("error getting onset data: "..data.error)
      do return end
    end
    if data.result==nil then
      print("no onset results!")
      do return end
    end
    cursors[id] = data.result
    if not util.file_exists(_path.data..'/cheat_codes_2/cursors/') then
      util.make_dir(_path.data..'/cheat_codes_2/cursors/')
    end
    tab.save(data.result,_path.data..'/cheat_codes_2/cursors/'..params:string('clip '..id..' sample')..'.cursors')
    params:hide('detect_onsets_'..id)
    params:show('clear_onsets_'..id)
    detecting_onsets_popup = {state = false, percent = nil, id = nil}
    detected_onsets_popup = {state = true, id = id}
    for b = 1,3 do
      for i = 1,16 do
        if bank[b][i].mode == 2 and bank[b][i].clip == id then
          rightangleslice.start_end_default(bank[b][i])
        end
      end
    end
    clock.run(clear_detected_onsets_popup)
    _menu.rebuild_params()
    -- print(id)
  end,
}

function clear_detected_onsets_popup()
  clock.sleep(clip[detected_onsets_popup.id].sample_rate < 48000 and 2 or 1)
  detected_onsets_popup = {state = false, id = nil}
end

function detect_onsets(id,file)
  if util.file_exists(_path.data..'/cheat_codes_2/cursors/'..params:string('clip '..id..' sample')..'.cursors') then
    cursors[id] = tab.load(_path.data..'/cheat_codes_2/cursors/'..params:string('clip '..id..' sample')..'.cursors')
    params:hide('detect_onsets_'..id)
    params:show('clear_onsets_'..id)
    detecting_onsets_popup = {state = false, percent = nil, id = nil}
    detected_onsets_popup = {state = true, id = id}
    for b = 1,3 do
      for i = 1,16 do
        if bank[b][i].mode == 2 and bank[b][i].clip == id then
          rightangleslice.start_end_default(bank[b][i])
        end
      end
    end
    clock.run(clear_detected_onsets_popup)
    _menu.rebuild_params()
  else
    os.execute(_path.code.."zxcvbn/lib/aubiogo/aubiogo --id "..id.." --filename '"..file.."' --num 16 &")
  end
end

SOS = {}

function SOS.sync_to_recordhead(source,target)
  -- expects source: x, target: bank[x][y]
  if target.mode == 1 and target.clip == source then
    softcut.loop_start(target.bank_id+1,rec[source].start_point)
    softcut.loop_end(target.bank_id+1,rec[source].end_point)
    -- softcut.voice_sync(target.bank_id,0,0.1)
    softcut.position(target.bank_id+1,poll_position_new[1]+0.01)
    softcut.loop(target.bank_id+1,1)
    target.start_point = rec[source].start_point
    target.end_point = rec[source].end_point
    target.loop = true
  end
end

function SOS.voice_overwrite(target)
  -- this should just 1:1 replace the corresponding Live clip
  softcut.pre_level(target.bank_id+1,1)
  softcut.rec_level(target.bank_id+1,1)
  softcut.level_input_cut(1,target.bank_id+1,1)
  softcut.level_input_cut(2,target.bank_id+1,1)
  softcut.rec(target.bank_id+1,1)
end

function SOS.voice_sync(source,target)
  -- expects source: bank[x][y], target: bank[z][a]
  softcut.loop_start(target.bank_id+1,source.start_point)
  softcut.loop_end(target.bank_id+1,source.end_point)
  softcut.position(target.bank_id+1,poll_position_new[source.bank_id+1])
  target.start_point = source.start_point
  target.end_point = source.end_point
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

function record_screen(state)
  if state == 1 then
    gif_step = 1
    recording_screen = true
  else
    recording_screen = false
  end
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
scale = 25

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
    if start < 9 then
      rec[1].waveform_samples = s
    elseif start < 17 then
      rec[2].waveform_samples = s
    else
      rec[3].waveform_samples = s
    end
  end
    
end

function update_waveform(buffer,winstart,winend,samples)
  softcut.render_buffer(buffer, winstart, winend - winstart, 128)
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
live[1].max = 9
live[2].min = 9
live[2].max = 17
live[3].min = 17
live[3].max = 25

help_menu = "welcome"

function f1()
  softcut.post_filter_lp(2,0)
  softcut.post_filter_hp(2,1)
  softcut.post_filter_fc(2,10)
  params:set("filter 1 cutoff",10)
end

function f2()
  softcut.post_filter_hp(2,0)
  softcut.post_filter_lp(2,1)
  softcut.post_filter_fc(2,12000)
  params:set("filter 1 cutoff",12000)
end

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

function cheat_clock_synced(i)
  if quantize_events[i].bank ~= nil then
    cheat(quantize_events[i].bank,quantize_events[i].pad)
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
    grid_pat[i]:rec_stop()
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
    grid_pat[i]:stop()
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
  print(mode)

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
      -- params:set("pattern_"..which.."_quantization", 2)
      local vals_to_dur = {4,8,16,32,64,math.random(4,32)}
      local note_val = params:get("rand_pattern_"..which.."_note_length")
      pattern.rec_clock_time = vals_to_dur[note_val]
    end
    if pattern.playmode == 3 or pattern.playmode == 4 then
      pattern.playmode = 2
    end
    local potential_total = pattern.rec_clock_time*4
    -- local count = auto_pat == 1 and math.random(2,24) or 16
    local count = auto_pat == 1 and (pattern.rec_clock_time * 4) or 16
    if pattern.count > 0 or pattern.rec == 1 then
      pattern:rec_stop()
      stop_pattern(pattern)
      pattern.tightened_start = 0
      pattern:clear()
      pattern_saver[which].load_slot = 0
    end
    for i = 1,count do
      pattern.event[i] = {}
      local constructed = pattern.event[i]
      constructed.id = auto_pat == 1 and math.random(1,16) or snakes[auto_pat-1][i]
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
      constructed.start_point = (math.random(10,75)/10)+(8*(assigning_pad.clip-1))
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
  grid_pat[bank].time_factor = 1*(synced_to_bpm/bpm)
end

function table.clone(org)
  return {table.unpack(org)}
end

function midi_clock_linearize(bank)
  quantized_grid_pat[bank].event = {}
  for i = 1,grid_pat[bank].count do
    quantized_grid_pat[bank].clicks[i] = math.floor((grid_pat[bank].time[i] / (clock.get_beat_sec()/4))+0.5)
    quantized_grid_pat[bank].event[i] = {} -- critical
    if grid_pat[bank].time[i] == 0 or quantized_grid_pat[bank].clicks[i] == 0 then
      quantized_grid_pat[bank].event[i][1] = "nothing"
    else
      for j = 1,quantized_grid_pat[bank].clicks[i] do
        if j == 1 then
          quantized_grid_pat[bank].event[i][1] = "something"
        else
          quantized_grid_pat[bank].event[i][j] = "nothing"
        end
      end
    end
  end
  quantized_grid_pat[bank].current_step = grid_pat[bank].start_point
  quantized_grid_pat[bank].sub_step = 1
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

function count_key2()
  clock.sleep(0.25)
  key2_hold = true
  screen_dirty = true
end

key2_hold = false
key2_hold_and_modify = false

grid_alt = false
grid_loop_mod = 0

local function crow_flush()
  norns.crow.init() -- clears & inits both crow & norns-support-of-crow
end

local function crow_init()
  for i = 1,4 do
    crow.output[i].action = "{to(5,0),to(0,0.05)}"
    print("output["..i.."] initialized")
  end
  crow.input[2].mode("change",2,0.1,"rising")
  crow.input[2].change = buff_freeze
end

-- crow hotplug support
norns.crow.add = function()
  norns.crow.init()
  crow_init()
  if params:get("jf_toggle") == 2 then
    crow.ii.jf.mode(1)
  end
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
    crow.input[id].change = buff_freeze
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

local lit = {}

zilch_leds =
{   [1] = {{0},{0},{0}}
  , [2] = {{0,0},{0,0},{0,0}}
  , [3] = {{0,0,0},{0,0,0},{0,0,0}}
  , [4] = {{0,0,0,0},{0,0,0,0},{0,0,0,0}}
}

function init()

  type_of_pattern_loaded = {"grid","grid","grid"}
  loading_arp_from_grid = {nil,nil,nil}
  loading_euclid_from_grid = {nil,nil,nil}
  loading_free_from_grid = {nil,nil,nil}
  
  engine.release(0.1)
  amp_in = {}
  local amp_src = {"amp_in_l","amp_in_r"}
  for i = 1,2 do
    amp_in[i] = poll.set(amp_src[i])
    amp_in[i].time = 0.01
    amp_in[i].callback = function(val)
      if val > params:get("one_shot_threshold")/10000 then
        if rec[rec.focus].state == 0 then
          toggle_buffer(rec.focus)
        end
        amp_in[i]:stop()
      end
    end
  end

  -- sharer.setup("cheat_codes_2")

  clock.run(check_page_for_k1)

  collection_loaded = false

  all_loaded = false
  
  ec4_focus = false -- to check for EC4 focus hold
  ec4_shift = false -- to check if EC4 fine tune/secondary mode is enabled
  
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
    rec[i].start_point = 1+(8*(i-1))
    rec[i].end_point = 9+(8*(i-1))
    rec[i].loop = 1
    rec[i].clear = 1
    rec[i].rate_offset = 1.0
    rec[i].waveform_samples = {}
    rec[i].queued = false
    rec[i].last_purged = 0
  end

  rec.transport_queued = false

  params:add_group("GRID/ARC",6)
  params:add_option("LED_style","grid LED style",{"varibright","4-step","grayscale"},1)
  params:set_action("LED_style",
  function()
    grid_dirty = true
    if all_loaded then
      persistent_state_save()
    end
  end)
  params:add_option("grid_size","grid size",{"128/256","64"},1)
  params:set_action("grid_size",
  function(x)
    if x == 1 then
      if g.cols * g.rows == 256 then
        g:rotation(3)
      else
        g:rotation(params:get('vert rotation') == 1 and 0 or 2)
      end
    elseif x == 2 then
      g:rotation(params:get('vert rotation') == 1 and 0 or 2)
      params:set("LED_style",2)
    end
    grid_dirty = true
    if all_loaded then
      persistent_state_save()
    end
  end)
  params:add_option("vert rotation", "vert rotation",{"usb on top","usb on bottom"},1)
  params:set_action("vert rotation",
  function(x)
    if x == 1 then
      g:rotation(0)
    elseif x == 2 then
      g:rotation(2)
    end
    grid_dirty = true
    if all_loaded then
      persistent_state_save()
    end
  end
  )
  params:add_option("midigrid?","midigrid?",{"no","yes"},1)
  params:set_action("midigrid?",
  function(x)
    if all_loaded then
      persistent_state_save()
    end
  end)
  params:add_option("arc_size","arc size (64-grid only)",{4,2},1)
  params:set_action("arc_size",
    function(x)
      if x == 2 then
        params:set("grid_size",2)
      end
      if all_loaded then
        persistent_state_save()
      end
    end)

  -- params:add_separator("hotkey config")

  params:add_option("alt_corner","alt+corner action",{"none","tap-tempo","transport"},1)
  params:hide("alt_corner")


  params:add_group("CROW IN/OUT",5)
  for i = 1,2 do
    params:add_option("crow input "..i,"crow in "..i,{"none","trig to record","cont to macro "..i,"trig: transport","gate: transport"},1)
    params:set_action("crow input "..i,
    function(x)
      set_crow_input(i,x)
      if all_loaded then
        persistent_state_save()
      end
    end)
    params:add_number("crow input "..i.." max voltage","crow in "..i.." max voltage",1,10,8)
  end
  params:add_option("crow output 4", "crow out 4",{"none","transport pulse","transport gate"},1)
  params:set_action("crow output 4",
  function(x)
    if all_loaded then
      persistent_state_save()
    end
  end)

  nb:init()
  params:add_separator('nb params')
  local bank_names = {'A', 'B', 'C'}
  for i = 1,3 do
    nb:add_param("nb_"..i, "bank "..bank_names[i]) -- adds a voice selector param to your script.
  end
  nb:add_player_params() -- Adds the parameters for the selected voices to your script.

  params:add_separator("cheat codes params")
  
  params:add_group("collections (load/save)",8)
  params:add_separator("load/save")
  params:add_trigger("load", "load collection")
  params:set_action("load",
  function(x)
    local dirname = _path.data.."cheat_codes_2/"
    if os.rename(dirname, dirname) == nil then
      os.execute("mkdir " .. dirname)
    end
    local dirname = _path.data.."cheat_codes_2/names/"
    if os.rename(dirname, dirname) == nil then
      os.execute("mkdir " .. dirname)
    end
    fileselect.enter(_path.data.."cheat_codes_2/names/", named_loadstate)
  end)
  params:add_option("collect_live","collect Live buffers?",{"no","yes"})
  params:add_trigger("save", "save new collection")
  params:set_action("save", function(x)
    if not actively_loading_collection then
      print('entering collection save menu')
      if Namesizer ~= nil then
        textentry.enter(pre_save,Namesizer.phonic_nonsense().."_"..Namesizer.phonic_nonsense())
      else
        textentry.enter(pre_save,nil)
      end
    end
  end)
  params:add_separator("danger zone!")
  params:add_trigger("overwrite_coll", "overwrite loaded collection")
  -- params:set_action("overwrite_coll", function(x) fileselect.enter(_path.data.."cheat_codes_2/names/", named_overwrite) end)
  params:set_action("overwrite_coll", function(x)
    if selected_coll ~= 0 then
      named_overwrite(_path.data.."cheat_codes_2/names/"..selected_coll..".cc2")
    end
  end)
  params:add_trigger("delete_coll", "delete collection")
  params:set_action("delete_coll", function(x) fileselect.enter(_path.data.."cheat_codes_2/names/", pre_delete) end)
  params:add_trigger("save default collection", "save default collection")
  params:set_action("save default collection", function()
    clock.run(save_screen,"DEFAULT")
    _norns.key(1,1)
    _norns.key(1,0)
    -- screen_dirty = true
  end)
  
  -- menu = 1
  
  for i = 1,4 do
    crow.output[i].action = "{to(5,0),to(0,0.05)}"
  end
  _crow = {}
  _crow.count = {}
  _crow.count_execute = {}
  for i = 1,3 do
    _crow.count[i] = 1
    _crow.count_execute[i] = 1
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
  
  page = {}
  page.loops = {}
  page.loops.frame = 1
  page.loops.sel = 1
  page.loops.meta_sel = 1
  page.loops.meta_option_set = {1,1,1,1}
  page.loops.top_option_set = {1,1,1,1}
  page.loops.focus_hold = {false, false, false, false}
  page.main_sel = 1
  page.loops_sel = 1
  page.loops_page = 0
  page.loops_view = {4,1,1,1}
  page.levels = {}
  page.levels.sel = 0
  -- page.levels_sel = 0
  page.pans = {}
  page.pans.sel = 1
  page.panning_sel = 1
  page.filters = {}
  page.filters.sel = 0
  -- page.filtering_sel = 0
  page.arc_sel = 0
  page.delay_sel = 0
  -- page.delay_section = 1
  -- page.delay_focus = 1
  page.delay = {{},{}}
  page.delay.section = 1
  page.delay.focus = 1
  for i = 1,2 do
    page.delay[i].menu = 1
    page.delay[i].menu_sel = {1,1,1}
  end
    
  page.time_sel = 1
  page.time_page = {}
  page.time_page_sel = {}
  page.time_scroll = {}
  for i = 1,6 do
    page.time_page[i] = 1
    page.time_page_sel[i] = 1
    page.time_scroll[i] = 1
  end
  page.time_arc_loop = {1,1,1}
  page.track_sel = {}
  page.track_page = 1
  page.track_page_section = {}
  for i = 1,4 do
    page.track_sel[i] = 1
    page.track_page_section[i] = 1
  end
  page.track_param_sel = {}
  for i = 1,3 do
    page.track_param_sel[i] = 1
  end
  page.arp_page_sel = 1
  page.arp_param = {1,1,1}
  page.arp_param_group = {}
  for i = 1,3 do
    page.arp_param_group[i] = 1
  end
  page.rnd_page = 1
  page.rnd_page_section = 1
  page.rnd_page_sel = {}
  page.rnd_page_edit = {}
  for i = 1,3 do
    page.rnd_page_sel[i] = 1
    page.rnd_page_edit[i] = 1
  end
  page.midi_setup = 1
  page.midi_focus = "header"
  page.midi_bank = 1

  page.macros = {}
  page.macros.selected_macro = 1
  page.macros.section = 1
  page.macros.param_sel = {}
  page.macros.edit_focus = {}
  page.macros.mode = "setup"
  for i = 1,8 do
    page.macros.param_sel[i] = 1
    page.macros.edit_focus[i] = 1
  end

  page.transport = {}
  page.transport.foci = {"TRANSPORT","TAP","CLICK"}
  page.transport.focus = "TRANSPORT"
  
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
      grid_redraw()
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
    if menu == 2 then
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
      screen_dirty = true
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
          -- rec_ended_callback()
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

  params:add_group("OSC setup",4)
  params:add_text("osc_IP", "source OSC IP", "192.168.")
  params:set_action("osc_IP", function() dest = {tostring(params:get("osc_IP")), tonumber(params:get("osc_port"))} end)
  params:add_text("osc_port", "OSC port", "9000")
  params:set_action("osc_port", function() dest = {tostring(params:get("osc_IP")), tonumber(params:get("osc_port"))} end)
  params:add_option("touchosc_echo", "TouchOSC echo?", {"no","yes"}, 2)
  params:set_action("touchosc_echo", function()
    if all_loaded then
      persistent_state_save()
    end
  end)
  params:add{type = "trigger", id = "refresh_osc", name = "refresh OSC [K3]", action = function()
    params:set("osc_IP","none")
    params:set("osc_port","none")
    osc_communication = false
    osc_echo = false
  end}

  params:add_group("MIDI note/OP-Z setup",16)
  params:add_option("midi_control_enabled", "enable MIDI control?", {"no","yes"},1)
  params:set_action("midi_control_enabled", function() if all_loaded then persistent_state_save() end end)
  -- params:add_option("midi_control_device", "MIDI control device",{"port 1", "port 2", "port 3", "port 4"},1)
  
  local vports = {}
  local function refresh_params_vports()
    for i = 1,#midi.vports do
      vports[i] = midi.vports[i].name ~= "none" and util.trim_string_to_width(midi.vports[i].name,70) or tostring(i)..": [device]"
    end
  end

  refresh_params_vports()

  params:add_option("midi_control_device", "MIDI ctrl dev",vports,1)
  params:set_action("midi_control_device", function() if all_loaded then persistent_state_save() end end)
  params:add_option("midi_echo_enabled", "enable MIDI echo?", {"no","yes"},1)
  params:set_action("midi_echo_enabled", function() if all_loaded then persistent_state_save() end end)
  local bank_names = {"(a)","(b)","(c)"}
  params:add_separator("channel")
  params:add_option("midi_control_channel_distribution", "channel distribution: ",{"multi","single"})
  params:set_action("midi_control_channel_distribution", function(x)
    if all_loaded then
      persistent_state_save() 
      if x == 2 then
        for i = 1,3 do params:set("bank_"..i.."_midi_channel",params:get("bank_1_midi_channel")) end
      end
    end
  end)
  for i = 1,3 do
    params:add_number("bank_"..i.."_midi_channel", "bank "..bank_names[i].." pad channel:",1,16,i)
    params:set_action("bank_"..i.."_midi_channel", function(x)
      if all_loaded then
        persistent_state_save()
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
    params:set_action("bank_"..i.."_pad_midi_base", function() if all_loaded then persistent_state_save() end end)
  end
  params:add_separator("zilchmo")
  for i = 1,3 do
    params:add_option("bank_"..i.."_midi_zilchmo_enabled", "bank "..bank_names[i].." midi zilchmo?", {"no","yes"},2)
    params:set_action("bank_"..i.."_midi_zilchmo_enabled", function() if all_loaded then persistent_state_save() end end)
  end

  params:add_group("MIDI encoder setup",7)
  params:add_option("midi_enc_control_enabled", "enable MIDI enc control?", {"no","yes"},1)
  params:set_action("midi_enc_control_enabled", function() if all_loaded then persistent_state_save() end end)
  params:add_option("midi_enc_control_device", "MIDI enc dev",vports,2)
  params:set_action("midi_enc_control_device", function() if all_loaded then persistent_state_save() end end)
  params:add_option("midi_enc_echo_enabled", "enable MIDI enc echo?", {"no","yes"},1)
  params:set_action("midi_enc_echo_enabled", function() if all_loaded then persistent_state_save() end end)
  params:add_trigger("ping_for_MFT","refresh for MFT (K3)")
  params:set_action("ping_for_MFT",function(x) ping_midi_devices() end)
  local bank_names = {"(a)","(b)","(c)"}
  for i = 1,3 do
    params:add_number("bank_"..i.."_midi_enc_channel", "bank "..bank_names[i].." enc channel:",1,16,i)
    params:set_action("bank_"..i.."_midi_enc_channel", function() if all_loaded then persistent_state_save() end end)
  end

  mc.pad_to_note_params()

  params:add_separator("meta")

  macros:add_params()

  crow_init()
  
  task_id = clock.run(globally_clocked)
  pad_press_quantA = clock.run(pad_clock,1)
  pad_press_quantB = clock.run(pad_clock,2)
  pad_press_quantC = clock.run(pad_clock,3)
  random_rec = clock.run(random_rec_clock)
  
  if params:string("clock_source") == "internal" then
    clock.internal.start(bpm)
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
                      page.arp_page_sel = i
                      arps.momentary(i, bank[i].id, "on")
                    end
                  elseif d.type == "note_off" then
                    if menu == 9 then
                      if not arp[i].hold and page.arp_page_sel == i  then
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
        if midi_dev[j].name ~= "Midi Fighter Twister" and midi_dev[j].name ~= "Faderfox EC4" then 
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
        
        elseif midi_dev[j].name == "Midi Fighter Twister" or midi_dev[j].name == "Faderfox EC4" then
          
          -- tab.print(d)

          local function check_focus_hold(id)
            if bank[id].focus_hold == true then
              return bank[id].focus_pad
            else
              return bank[id].id
            end
          end

          if d.ch == 1 or d.ch == 5 then
            if midi_dev[j].name == "Faderfox EC4" and d.type == "note_on" and (d.note == 12 or d.note == 28 or d.note == 44) then
              ec4_focus = true
            elseif midi_dev[j].name == "Faderfox EC4" and d.type == "note_on" and (d.note == 13 or d.note == 29 or d.note == 45) then
              ec4_shift = true
            elseif d.cc == 0 or d.cc == 16 or d.cc == 32 then
              local id = math.floor(d.cc/16)+1
              if midi_dev[j].name == "Faderfox EC4" and ec4_focus == true then
                bank[id].focus_hold = true
              end
              encoder_actions.change_pad(bank[id][check_focus_hold(id)].bank_id, d.val == 63 and -1 or 1)
              if bank[id].focus_hold then
                mc.mft_redraw(bank[id][bank[id].focus_pad],"all")
              end
            elseif d.cc == 1 or d.cc == 17 or d.cc == 33 then
              -- pad start point
              local id = math.floor(d.cc/16)+1
              local resolution = loop_enc_resolution[id] / 10
              encoder_actions.move_start(bank[id][check_focus_hold(id)], (d.val == 63 and ((d.ch == 1 and ec4_shift == false) and -0.1 or -0.01) or ((d.ch == 1 and ec4_shift == false) and 0.1 or 0.01))/resolution)
              mc.mft_redraw(bank[id][check_focus_hold(id)],"start_point")
              if bank[id].focus_hold == false then
                encoder_actions.sc.move_start(id)
              end
            elseif d.cc == 2 or d.cc == 18 or d.cc == 34 then
              -- pad end point
              local id = math.floor(d.cc/16)+1
              local resolution = loop_enc_resolution[id] / 10
              encoder_actions.move_end(bank[id][check_focus_hold(id)], (d.val == 63 and ((d.ch == 1 and ec4_shift == false) and -0.1 or -0.01) or ((d.ch == 1 and ec4_shift == false) and 0.1 or 0.01))/resolution)
              mc.mft_redraw(bank[id][check_focus_hold(id)],"end_point")
              if bank[id].focus_hold == false then
                encoder_actions.sc.move_end(id)
              end
            elseif d.cc == 3 or d.cc == 19 or d.cc == 35 then
              -- pad window
              local id = math.floor(d.cc/16)+1
              local resolution = loop_enc_resolution[id] / 10
              encoder_actions.move_play_window(bank[id][check_focus_hold(id)], (d.val == 63 and ((d.ch == 1 and ec4_shift == false) and -0.1 or -0.01) or ((d.ch == 1 and ec4_shift == false) and 0.1 or 0.01))/resolution)
              mc.mft_redraw(bank[id][check_focus_hold(id)],"start_point")
              mc.mft_redraw(bank[id][check_focus_hold(id)],"end_point")
              if bank[id].focus_hold == false then
                encoder_actions.sc.move_play_window(id)
              end
            elseif d.cc == 4 or d.cc == 20 or d.cc == 36 then
              --pad level
              local id = math.floor(d.cc/16)+1
              bank[id][check_focus_hold(id)].level = util.clamp(bank[id][check_focus_hold(id)].level+(d.val == 63 and ((d.ch == 1 and ec4_shift == false) and -0.01 or -0.001) or ((d.ch == 1 and ec4_shift == false) and 0.01 or 0.001)),0,2)
              if bank[id][check_focus_hold(id)].envelope_mode == 2 or bank[id][check_focus_hold(id)].enveloped == false then
                if bank[id].focus_hold == false then
                  softcut.level_slew_time(id+1,1.0)
                  softcut.level(id+1,bank[id][check_focus_hold(id)].level*bank[id].global_level)
                  softcut.level_cut_cut(id+1,5,(bank[id][check_focus_hold(id)].left_delay_level*bank[id][check_focus_hold(id)].level)*bank[id].global_level)
                  softcut.level_cut_cut(id+1,6,(bank[id][check_focus_hold(id)].right_delay_level*bank[id][check_focus_hold(id)].level)*bank[id].global_level)
                end
              end
              mc.mft_redraw(bank[id][check_focus_hold(id)],"pad_level")
            elseif d.cc == 5 or d.cc == 21 or d.cc == 37 then
              --bank level
              local id = math.floor(d.cc/16)+1
              bank[id].global_level = util.clamp(bank[id].global_level+(d.val == 63 and ((d.ch == 1 and ec4_shift == false) and -0.01 or -0.001) or ((d.ch == 1 and ec4_shift == false) and 0.01 or 0.001)),0,2)
              if bank[id][check_focus_hold(id)].envelope_mode == 2 or bank[id][check_focus_hold(id)].enveloped == false then
                if bank[id].focus_hold == false then
                  softcut.level_slew_time(id+1,1.0)
                  softcut.level(id+1,bank[id][check_focus_hold(id)].level*bank[id].global_level)
                  softcut.level_cut_cut(id+1,5,(bank[id][check_focus_hold(id)].left_delay_level*bank[id][check_focus_hold(id)].level)*bank[id].global_level)
                  softcut.level_cut_cut(id+1,6,(bank[id][check_focus_hold(id)].right_delay_level*bank[id][check_focus_hold(id)].level)*bank[id].global_level)
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
              if d.ch == 5 or ec4_shift == true then
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
              if d.ch == 5 or ec4_shift == true then
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
              if d.ch == 5 or ec4_shift == true then
                local pre_pan = bank[id][check_focus_hold(id)].pan
                for i = 1,16 do
                  bank[id][i].pan = util.clamp(pre_pan+(d.val == 63 and -0.01 or 0.01),-1,1)
                end
              elseif d.ch == 1 then
                bank[id][check_focus_hold(id)].pan = util.clamp(bank[id][check_focus_hold(id)].pan+(d.val == 63 and -0.01 or 0.01),-1,1)
              end
              softcut.pan(id+1, bank[id][check_focus_hold(id)].pan)
              mc.mft_redraw(bank[id][check_focus_hold(id)],"pan")
            elseif d.cc == 10 or d.cc == 26 or d.cc == 42 then
              --bank / pad filter cutoff
              local id = math.floor(d.cc/16)+1
              if d.ch == 5 or ec4_shift == true then
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
                softcut.level_cut_cut(util.round(item/2)+1,1+4,(target[check_focus_hold(id)][prm[1]]*target[check_focus_hold(id)].level)*target.global_level)
                if delay_links[del.lookup_prm(k,v)] then
                  local this_one = 1 == 1 and 2 or 1
                  softcut.level_cut_cut(util.round(item/2)+1,(this_one)+4,(target[check_focus_hold(id)][prm[this_one]]*target[check_focus_hold(id)].level)*target.global_level)
                end
              end
            elseif d.type == "note_off" and (d.note == 13 or d.note == 29 or d.note == 45) then
              ec4_shift = false
            elseif d.type == "note_off" and (d.note == 12 or d.note == 28 or d.note == 44) then
              ec4_focus = false
              local id = math.floor(d.note/16)+1
              bank[id].focus_hold = false
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

  for i = 1,3 do
    rnd.init(i)
  end

  rytm.init()
  transport.init()

  if g then grid_dirty = true end
  
  -- all_loaded = true

  clock.run(
    function()
      clock.sleep(0.1)
      persistent_state_restore()
      print("restoring persistent state data")
    end
  )

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
  viz_metro_advance = 1

  clock.run(function()
    while true do
      clock.sync(1)
      viz_metro_advance = util.wrap(viz_metro_advance+1,1,4)
      if menu == 1 then
        screen_dirty = true
      end
    end
  end)

  for i = 1,3 do
    update_waveform(1,live[i].min,live[i].max,128)
  end

  local default_file = io.open("/home/we/dust/data/cheat_codes_2/names/DEFAULT.cc2", "r")
  if default_file == nil then
    menu = 1
    print("~~~~~> no user defaults defined: save a collection as DEFAULT to establish <~~~~~")
  else
    clock.run(function()
      local preload_bpm = params:get("clock_tempo")
      clock.sleep(0.25)
      named_loadstate("/home/we/dust/data/cheat_codes_2/names/DEFAULT.cc2")
      -- _norns.key(1,1)
      -- _norns.key(1,0)
      params:set("clock_tempo",preload_bpm)
    end)
    -- named_loadstate("/home/we/dust/data/cheat_codes_2/names/DEFAULT.cc2")
  end

  speed_dial:init()

  audio.level_eng_cut(util.dbamp(-math.huge))
  norns.state.mix.cut_input_eng = -math.huge
  clock.run(metronome_audio)
  if g.cols * g.rows == 256 then
    g:rotation(3)
    grid_dirty = true
  end
end

---

function ping_midi_devices()
  mft_connected = false
  ec4_connected = false
  local midi_dev_max;
  for k,v in pairs(midi.devices) do
    midi_dev_max = midi.devices[k].id
  end
  for i = 1,midi_dev_max do
    if midi.devices[i] ~= nil and (midi.devices[i].name == "Midi Fighter Twister" or midi.devices[i].name == "Faderfox EC4") then
      params:set("midi_enc_control_enabled",2)
      params:set("midi_enc_control_device",midi.devices[i].port ~= nil and midi.devices[i].port or 1)
      params:set("midi_enc_echo_enabled",2)
      if midi.devices[i].name == "Midi Fighter Twister" then
        mft_connected = true
      elseif midi.devices[i].name == "Faderfox EC4" then
        ec4_connected = true
      end
    end
    -- if midi.devices[i] ~= nil and midi.devices[i].name == "OP-Z" then
    --   params:set("midi_control_enabled",2)
    --   params:set("midi_control_device",midi.devices[i].port)
    --   params:set("midi_echo_enabled",2)
    --   opz_connected = true
    -- end
  end
  screen_dirty = true
  if all_loaded and (mft_connected or ec4_connected) then
    for i = 1,3 do
      mc.mft_redraw(bank[i][bank[i].id],"all")
    end
  end
end

function sync_clock_to_loop(source,style)
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

function grid_pattern_watch(target,pad)
  if pad ~= "pause" then
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
  else
    grid_pat[target]:watch("pause")
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

function start_synced_loop(target)
  if target.count > 0 then
    --pattern_length_to_bars(target)
    target.clock = clock.run(synced_loop, target)
  end
end

function synced_loop(target, state)
  --clock.sleep(clock.get_beat_sec()*target.rec_clock_time)

  clock.sync(1)
  if state == "restart" then
    target:start()
  end
  --^ would this be problematic?

  --clock.sync(4)
  while true do
    --print("syncing to..."..target.clock_time, clock.get_beats())
    clock.sync(target.clock_time)
    local overdub_flag = target.overdub
    target:stop()
    if overdub_flag == 1 then
      target.overdub = 1
    end
    target:start()
  end
end

function alt_synced_loop(target,state,style,mod_table)
  if transport.is_running then
    if state == "restart" then
      if params:get("launch_quantization") ~= 3 then
        clock.sync(params:get("launch_quantization") == 1 and 1 or 4)
      end
    end
    if style == "delayed_load" then
      load_pattern(mod_table[1],mod_table[2])
      print("delayed load...")
    end
    local name_to_id = {"grid_pat[1]","grid_pat[2]","grid_pat[3]"}
    
    if type_of_pattern_loaded[tab.key(name_to_id,target.name)] == "arp" then
      -- print("arp thing")
      if grid_pat[tab.key(name_to_id,target.name)].play == 1 then
        grid_pat[tab.key(name_to_id,target.name)]:stop()
        -- grid_pat[tab.key(name_to_id,target.name)]:clear()
      end
      local destination = tab.key(name_to_id,target.name)
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
    elseif type_of_pattern_loaded[tab.key(name_to_id,target.name)] == "grid" then
      -- print("grid thing")
      if arp[tab.key(name_to_id,target.name)].playing and source ~= "from_grid" then
        -- arp[tab.key(name_to_id,target.name)].pause = true
        -- arp[tab.key(name_to_id,target.name)].playing = false
        arps.clear(tab.key(name_to_id,target.name))
      end
      target:start()
      print("starting from alt sync "..clock.get_beats())
      target.synced_loop_runner = 1
      -- print("alt_synced",clock.get_beats(),target)
      while true do
        clock.sync(1/4,1/128)
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
            -- clear_arps_from_pattern_restart(target.event[target.count].i)
            -- print("!!"..song_atoms.bank[tab.key(name_to_id,target.name)].lane[song_atoms.bank[tab.key(name_to_id,target.name)].current]["arp"].target, song_atoms.bank[tab.key(name_to_id,target.name)].runner)
            -- if song_atoms.bank[tab.key(name_to_id,target.name)].lane[song_atoms.bank[tab.key(name_to_id,target.name)].current]["arp"].target == -1 then
            --   print("heyyy should stop yeah??")
            -- end
            target:start()
            -- print("and then start "..clock.get_beats())
          end
        else
          target.synced_loop_runner =  target.synced_loop_runner + 1
        end
      end
    elseif type_of_pattern_loaded[tab.key(name_to_id,target.name)] == "euclid" then
      print("hi alt euclid!!")
    end
  end 
end

function stop_pattern(target,style)
  if target.clock ~= nil and style ~= "no kill" then
    clock.cancel(target.clock)
    target.clock = nil
  end
  target:stop()
end

function start_pattern(target,start_type,style,mod_table)

  if not transport.is_running then
    print("starting transport...")
    if transport.is_running then
      clock.transport.stop()
    else
      if params:string("clock_source") == "internal" then
        transport.pending = true
        clock.internal.start(-0.1)
      else
        transport.pending = true
        transport.cycle = 1
        clock.transport.start()
      end
    end
  end
  if transport.is_running then
    if target.playmode == 2 then
      if target.clock ~= nil then clock.cancel(target.clock) end
      -- print(mod_table,style,style == nil,(style ~= nil and "delayed_load" or nil))
      -- print("...."..(style ~= nil and style or ""))
      target.clock = clock.run(alt_synced_loop, target, start_type ~= nil and start_type or "restart",(style ~= nil and "delayed_load" or nil),(mod_table ~= nil and mod_table or nil))
    else
      local name_to_id = {"grid_pat[1]","grid_pat[2]","grid_pat[3]"}
      local destination = tab.key(name_to_id,target.name)
      if start_type ~= "jumpstart" then
      -- print("what else can i do but start the pattern?")
        if loading_free_from_grid[destination] ~= nil then
          clock.cancel(loading_free_from_grid[destination])
        end
        loading_free_from_grid[destination] = 
        clock.run(
          function()
            if params:get("launch_quantization") ~= 3 then
              clock.sync(params:get("launch_quantization") == 1 and 1 or 4)
            end
            if mod_table ~= nil then
              load_pattern(mod_table[1],mod_table[2])
              print("starting a pattern!", type_of_pattern_loaded[destination])
              if type_of_pattern_loaded[destination] == "grid" then
                if arp[destination].playing then
                  arps.toggle("stop",destination)
                end
                target:start()
              end
            else
              print("????")
              print("starting a pattern2")
              target:start()
            end
          end
        )
      else
        target:start()
      end
    end
  end

end

function synced_record_start(target,i)
  --midi_pat[i].sync_hold = true
  target.sync_hold = true
  clock.sync(4,-1/16)
  --midi_pat[i]:rec_start()
  target:rec_start()
  --midi_pat[i].sync_hold = false
  target.sync_hold = false
  if target == midi_pat[i] then
    midi_pattern_watch(i, "pause")
  elseif target == grid_pat[i] then
    grid_pattern_watch(i, "pause")
  end
  grid_pat[i].synced_pat_clock = clock.run(synced_pattern_record,target)
end

function synced_pattern_record(target)
  clock.sleep((clock.get_beat_sec()*target.rec_clock_time)+ (clock.get_beat_sec()*1/8))
  if target.rec_clock ~= nil then
    target:rec_stop()
    pattern_length_to_bars(target, "destructive")
    if target.time[1] ~= nil and target.time[1] < clock.get_beat_sec()/4 and target.event[1] == "pause" then
      print("we could lose the first event..."..target.count, target.end_point)
      local butts = 0
      for i = 1,target.count do
        butts = butts + target.time[i]
      end
      print(butts)
      target.time[2] = target.time[2] + target.time[1]
      target.time_beats[2] = target.time_beats[2] + target.time_beats[1]
      table.remove(target.event,1)
      table.remove(target.time,1)
      table.remove(target.time_beats,1)
      target.count = #target.event
      target.end_point = target.count
      for i = 1,target.count do
        target:calculate_quantum(i)
      end
    end
    target.time[1] = target.time[1] - (clock.get_beat_sec()*1/8)
    local ideal = clock.get_beat_sec()*target.rec_clock_time
    local butts = 0
    for i = 1,target.count do
      butts = butts + target.time[i]
    end
    target.time[#target.time] = target.time[#target.time] + (ideal - butts)
    if target.count > 0 then -- just in case the recording was canceled...
      --target:start()
      print("started first run..."..clock.get_beats())
      --target.clock = clock.run(synced_loop, target)
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
  start_pattern(pattern)
end

---

function pad_clock(i)
  while true do
    clock.sync(params:get("pattern_"..i.."_quantization_num")/(params:get("pattern_"..i.."_quantization_denum")/4))
    cheat_clock_synced(i)
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
          toggle_buffer(rec.focus,true)
        elseif params:get("rec_loop_"..rec.focus) == 2 and rec[rec.focus].end_point < poll_position_new[1] +0.015 then
          toggle_buffer(rec.focus,true)
        end
      end
    end
  end
end

function run_one_shot_rec_clock()
  one_shot_rec_clock = clock.run(one_shot_clock)
end

function cancel_one_shot_rec_clock(punch_out)
  if one_shot_rec_clock ~= nil then
    clock.cancel(one_shot_rec_clock)
  end
  rec[rec.focus].state = 0
  rec_state_watcher:stop()
  rec.stopped = true
  grid_dirty = true
  if menu == 2 then
    if page.loops.sel ~= 5 then
      screen_dirty = true
    end
  end
  one_shot_rec_clock = nil
  if punch_out then
    rec[rec.focus].end_point = poll_position_new[1]
  end
end

function one_shot_clock()
  softcut.level_slew_time(1,0)
  softcut.fade_time(1,0)
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

function step_sequence_super_clock()
  while true do
    clock.sync(1/4)
    for i = 1,3 do
      step_sequence(i)
    end
  end
end

function toggle_meta(state)
  if state == "start" then
    if step_sequence_clock ~= nil then
      clock.cancel(step_sequence_clock)
    end
    for target = 1,3 do
      step_seq[target].meta_meta_step = 1
      step_seq[target].meta_step = 1
      step_seq[target].current_step = step_seq[target].start_point
      if step_seq[target].active == 1 and step_seq[target][step_seq[target].current_step].assigned_to ~= 0 then
        test_load(step_seq[target][step_seq[target].current_step].assigned_to+(((target)-1)*8),target)
      end
    end
    step_sequence_clock = clock.run(step_sequence_super_clock)
    screen.dirty = true
  elseif state == "stop" then
    if step_sequence_clock ~= nil then
      clock.cancel(step_sequence_clock)
    end
  end
end

function globally_clocked()
  while true do
    clock.sync(1/4)
    if menu == 7 or menu == "transport_config" then
      if menu ~= 1 then screen_dirty = true end
    end
    if menu == 2 then
      screen_dirty = true
    end
    update_tempo()
    -- step_sequence()
    for i = 1,3 do
      -- step_sequence(i)
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
    if grid_page_64 == 2 then
      grid_blink_64 = math.fmod(clock.get_beats(),1)
      if grid_blink_64 <= 0.25 then
        show_me_grid_blink = true
        grid_dirty = true
      else
        show_me_grid_blink = false
        grid_dirty = true
      end
    end
    -- print("butts")
    -- grid_dirty = true
  end
end

osc_in = function(path, args, from)

  if path == '/progressbar' or path == '/aubiodone' then
    if string.sub(path,1,1)=="/" then
      path=string.sub(path,2)
    end
    if osc_fun[path] ~= 'progressbar' or 'aubiodone' then
      osc_fun[path](args)
    end
    return
  else
    if osc_communication ~= true then
      params:set("osc_IP",from[1])
      params:set("osc_port",from[2])
      osc_communication = true
    end
    for i = 1,3 do
      local target = bank[i][bank[i].id]
      -- if path:find('^'.."/pad_sel_"..i) then
      if string.match(path,"/pad_sel_"..i) then
        local pad_target = tonumber(path:match("^.*%_(.*)"))
        if args[1] == 1 then
          grid_actions.pad_down(i,pad_target)
        elseif args[1] == 0 then
          grid_actions.pad_up(i,pad_target)
        end
      elseif string.match(path,"/grid_pat_"..i) then
        if args[1] == 1 then
          grid_actions.grid_pat_handler(i)
        end
      elseif string.match(path,"/arp_"..i) then
        if args[1] == 1 then
          if not grid_alt then
            grid_actions.arp_handler(i)
          else
            grid_actions.kill_arp(i)
          end
        end
      elseif path == "/randomize_this_bank_"..i then
        random_grid_pat(i,3)
        for j = 2,16 do
          bank[i][j].start_point = (math.random(10,30)/10)+(8*(bank[i][j].clip-1))
          bank[i][j].end_point = bank[i][j].start_point + (math.random(10,60)/10)
          bank[i][j].pan = math.random(-100,100)/100
        end
        grid_pat[i]:rec_stop()
        grid_pat[i]:stop()
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
          local duration = pad.mode == 1 and 8 or clip[pad.clip].sample_length
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
            local s_p = rec[rec.focus].start_point+(8*(pad.clip-1))
            pad.start_point = (s_p+(duration/16) * (pad.pad_id-1))
            pad.end_point = (s_p+((duration/16) * (pad.pad_id)))
          else
            duration = pad.mode == 1 and 8 or clip[pad.clip].sample_length
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
            duration = pad.mode == 1 and 8 or math.modf(clip[pad.clip].sample_length)
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
  grid_dirty = true
  screen_dirty = true
end

osc.event = osc_in

function osc_redraw(i)
  if params:string("touchosc_echo") == "yes" then
    local target = bank[i][bank[i].id]
    osc.send(dest, "/param/start point "..i, {params:get("start point "..i)})
    osc.send(dest, "/param/end point "..i, {params:get("end point "..i)})
    osc.send(dest, "/param/level "..i, {params:get("level "..i)})
    osc.send(dest, "/param/pan "..i, {params:get("pan "..i)})
    osc.send(dest, "/param/loop_"..i, {bank[i][bank[i].id].loop == true and 0 or 1})
  end
end

poll_position_new = {}

phase = function(n, x)
  poll_position_new[n] = x
  -- if menu == 2 then
    -- local rec_on = 0;
    -- for i = 1,3 do
    --   if rec[i].state == 1 then
    --     rec_on = i
    --   end
    -- end
    -- if rec_on ~= 0 and rec[rec_on].state == 1 then
    --   if page.loops.sel < 4 then
    --     local pad = bank[page.loops.sel][bank[page.loops.sel].id]
    --     update_waveform(1,key1_hold and pad.start_point or live[rec_on].min,key1_hold and pad.end_point or live[rec_on].max,128)
    --   elseif page.loops.sel == 4 then
    --     update_waveform(1,key1_hold and rec[rec.focus].start_point or live[rec_on].min,key1_hold and rec[rec.focus].end_point or live[rec_on].max,128)
    --   end
    -- end
    -- screen_dirty = true
    -- if page.loops.sel ~= 5 then screen_dirty = true end
  -- end
end

function update_tempo()
  local pre_bpm = bpm
  params:set("bpm", util.round(clock.get_tempo()))
  bpm = params:get("bpm") -- FIXME this is where the global bpm is defined
  local t = params:get("bpm")
  local d = params:get("quant_div")
  local d_pat = params:get("quant_div_pats")
  local interval = (60/t) / d
  local interval_pats = (60/t) / d_pat
  if pre_bpm ~= bpm then
    compare_rec_resolution(params:get("rec_loop_enc_resolution"))
    for i = 1,3 do
      compare_loop_resolution(i,params:get("loop_enc_resolution_"..i))
    end
    if math.abs(pre_bpm - bpm) >= 1 then
      --print("a change in time!")
    end
  end
  for i = 1,3 do
    --quantizer[i].time = interval
    --grid_pat_quantizer[i].time = interval_pats
  end
end

function rec_count()
  rec_time = rec_time + 0.01
end

function step_sequence(i)
  if transport.is_running then
  -- for i = 1,3 do
    if step_seq[i].active == 1 then
      step_seq[i].meta_step = step_seq[i].meta_step + 1
      if step_seq[i].meta_step > step_seq[i].meta_duration then step_seq[i].meta_step = 1 end
      if step_seq[i].meta_step == 1 then
        step_seq[i].meta_meta_step = step_seq[i].meta_meta_step + 1
        if step_seq[i].meta_meta_step > step_seq[i][step_seq[i].current_step].meta_meta_duration then step_seq[i].meta_meta_step = 1 end
        if step_seq[i].meta_meta_step == 1 then
          step_seq[i].current_step = step_seq[i].current_step + 1
          if step_seq[i].current_step > step_seq[i].end_point then step_seq[i].current_step = step_seq[i].start_point end
          local current = step_seq[i].current_step
          if grid_pat[i].rec == 0 and step_seq[i][current].assigned_to ~= 0 then
            pattern_saver[i].load_slot = step_seq[i][current].assigned_to
            test_load(step_seq[i][current].assigned_to+((i-1)*8),i)
            grid_pat[i].loop = step_seq[i][current].loop_pattern
          end
        end
      end
    end
  -- end
  end
  if grid_page == 1 then
    grid_dirty = true
  end
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
  local s_p = pad.start_point-(8*(pad.clip-1))
  local e_p = pad.end_point-(8*(pad.clip-1))
  rec[rec.focus].start_point = s_p+(8*(rec.focus-1))
  rec[rec.focus].end_point = e_p+(8*(rec.focus-1))
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
    b.quantize_press = 0
    b.quantize_press_div = 1
    b.alt_lock = false
    b.global_level = 1.0
    for k = 1,16 do
-- TODO suggest nesting tables for delay,filter,tilt etc
      b[k] = {}
      local pad = b[k] --alias
      pad.bank_id           = i -- capture which bank we're in
      pad.pad_id            = k -- capture which pad of 16
      pad.clip              = 1 -- TODO make this a table with length for start/end calculation
      pad.mode              = 1
        -- TODO these are both identical to zilchmos.start_end_default()
      pad.start_point       = 1+((8/16) * (pad.pad_id-1))
      pad.end_point         = 1+((8/16) *  pad.pad_id)
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
      pad.envelope_time     = 3.0
      pad.envelope_loop     = false
      pad.clock_resolution  = 4
      pad.offset            = 1.0
      pad.crow_pad_execute  = 1
      pad.left_delay_thru   = false
      pad.right_delay_thru  = false
      pad.rate_slew         = 0
      pad.arp_time          = 1/4
    end
    cross_filter[i]         = {}
    cross_filter[i].fc      = 12000
    cross_filter[i].lp      = 0
    cross_filter[i].hp      = 0
    cross_filter[i].dry     = 1
    cross_filter[i].exp_dry = 1
    cheat(i,bank[i].id)
  end
end

function find_the_key(t,val)
  for k,v in pairs(t) do
    if v == val then return k end
  end
  return nil
end

function cheat(b,i)
  b = util.round(b)
  i = util.round(i)
  local pad = bank[b][i]
  if all_loaded then
    mc.midi_note_from_pad(b,i)
    mc.route_midi_mod(b,i)
  end
  if env_counter[b].is_running then
    env_counter[b]:stop()
  end
  softcut.rate_slew_time(b+1,pad.rate_slew)
  if pad.enveloped and not pad.pause then
    if pad.envelope_mode == 1 then
      env_counter[b].butt = pad.level
      env_counter[b].l_del_butt = pad.left_delay_level
      env_counter[b].r_del_butt = pad.right_delay_level
      softcut.level_slew_time(b+1,0.05)
      softcut.level(b+1,pad.level*bank[b].global_level)
      softcut.level_cut_cut(b+1,5,(pad.level*bank[b].global_level)*pad.left_delay_level)
      softcut.level_cut_cut(b+1,6,(pad.level*bank[b].global_level)*pad.right_delay_level)
    elseif pad.envelope_mode == 2 or pad.envelope_mode == 3 then
      softcut.level_slew_time(b+1,0.01)
      softcut.level(b+1,0*bank[b].global_level)
      softcut.level_cut_cut(b+1,5,0)
      softcut.level_cut_cut(b+1,6,0)
      env_counter[b].butt = 0
      env_counter[b].l_del_butt = 0
      env_counter[b].r_del_butt = 0
      if pad.envelope_mode == 3 then env_counter[b].stage = "rising" end
    end
    if pad.level > 0.05 then
    -- if (pad.envelope_time/(pad.level/0.05)) ~= inf then
      env_counter[b].time = (pad.envelope_time/(pad.level/0.05)) -- buggy, what am i trying to do here??
    end
    env_counter[b]:start()
  elseif not pad.enveloped and not pad.pause then
    softcut.level_slew_time(b+1,0.1)
    softcut.level(b+1,pad.level*bank[b].global_level)
    if not delay[1].send_mute then
      if pad.left_delay_thru then
        softcut.level_cut_cut(b+1,5,pad.left_delay_level)
      else
        softcut.level_cut_cut(b+1,5,(pad.left_delay_level*pad.level)*bank[b].global_level)
      end
    end
    if not delay[2].send_mute then
      if pad.right_delay_thru then
        softcut.level_cut_cut(b+1,6,pad.right_delay_level)
      else
        softcut.level_cut_cut(b+1,6,(pad.right_delay_level*pad.level)*bank[b].global_level)
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
  softcut.fade_time(b+1,params:get("loop_fade_time_"..b)/1000)
  softcut.loop_start(b+1,pad.start_point)
  softcut.loop_end(b+1,pad.end_point)
  softcut.buffer(b+1,pad.mode)
  if pad.pause == false then
    softcut.rate(b+1,pad.rate*pad.offset)
  else
    softcut.rate(b+1,0)
  end
  if pad.loop == false then
    softcut.loop(b+1,0)
  else
    softcut.loop(b+1,1)
  end
  if pad.rate > 0 then
      -- softcut.position(b+1,pad.start_point+0.05)
      softcut.position(b+1,pad.start_point+params:get("loop_fade_time_"..b)/1000)
  elseif pad.rate < 0 then
      -- softcut.position(b+1,pad.end_point-params:get("loop_fade_time_"..b)/1000-0.05)
      softcut.position(b+1,pad.end_point-params:get("loop_fade_time_"..b)/1000)
  end
  if slew_counter[b] ~= nil then
    slew_counter[b].next_tilt = pad.tilt
    slew_counter[b].next_q = pad.q
    if pad.tilt_ease_type == 1 then
      if slew_counter[b].slewedVal ~= nil and math.floor(slew_counter[b].slewedVal*10000) ~= math.floor(slew_counter[b].next_tilt*10000) then
        if math.floor(slew_counter[b].prev_tilt*10000) ~= math.floor(slew_counter[b].slewedVal*10000) then
          slew_counter[b].interrupted = 1
          slew_filter(b,slew_counter[b].slewedVal,slew_counter[b].next_tilt,slew_counter[b].prev_q,slew_counter[b].next_q,pad.tilt_ease_time)
        else
          slew_counter[b].interrupted = 0
          slew_filter(b,slew_counter[b].prev_tilt,slew_counter[b].next_tilt,slew_counter[b].prev_q,slew_counter[b].next_q,pad.tilt_ease_time)
        end
      end
    elseif pad.tilt_ease_type == 2 then
      slew_filter(b,slew_counter[b].prev_tilt,slew_counter[b].next_tilt,slew_counter[b].prev_q,slew_counter[b].next_q,pad.tilt_ease_time)
    end
  end
  softcut.pan(b+1,pad.pan)
  update_delays()
  if slew_counter[b] ~= nil then
    slew_counter[b].prev_tilt = pad.tilt
    slew_counter[b].prev_q = pad.q
  end
  previous_pad = bank[b].id
  -- if bank[b].crow_execute == 1 then
  --   if pad.crow_pad_execute == 1 then
  --     crow.output[b]()
  --   end
  -- end
  --dangerous??
  local s = {
    [-4.0] = 1,
    [-2.0] = 2,
    [-1.0] = 3,
    [-0.5] = 4,
    [-0.25] = 5,
    [-0.125] = 6,
    [0.125] = 7,
    [0.25] = 8,
    [0.5] = 9,
    [1.0] = 10,
    [2.0] = 11,
    [4.0] = 12
  }
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
    if midi_dev[params:get("midi_enc_control_device")].name == "Midi Fighter Twister" or midi_dev[params:get("midi_enc_control_device")].name == "Faderfox EC4" then
      if bank[pad.bank_id].focus_hold == false then
        mc.mft_redraw(pad,"all")
      end
    else
      mc.enc_redraw(pad)
    end
  end

  -- redraw waveform if it's zoomed in and the pad changes
  if menu == 2 and page.loops.sel == b and page.loops.frame == 2 and not key2_hold and key1_hold then
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

function falling_envelope(i)
  if env_counter[i].butt > 0.05 then
    env_counter[i].butt = env_counter[i].butt - 0.05
  else
    env_counter[i].butt = 0
  end
  if env_counter[i].butt > 0 and bank[i][bank[i].id].level > 0 then
    softcut.level_slew_time(i+1,0.05)
    softcut.level(i+1,env_counter[i].butt*bank[i].global_level)
    -- softcut.level_cut_cut(i+1,5,(env_counter[i].butt*bank[i].global_level)*bank[i][bank[i].id].left_delay_level)
    -- softcut.level_cut_cut(i+1,6,(env_counter[i].butt*bank[i].global_level)*bank[i][bank[i].id].right_delay_level)
    if delay[1].send_mute then
      if bank[i][bank[i].id].left_delay_level == 0 then
        softcut.level_cut_cut(i+1,5,(env_counter[i].butt*bank[i].global_level)*1)
      else
        softcut.level_cut_cut(i+1,5,(env_counter[i].butt*bank[i].global_level)*0)
      end
    else
      softcut.level_cut_cut(i+1,5,(env_counter[i].butt*bank[i].global_level)*bank[i][bank[i].id].left_delay_level)
    end
    if delay[2].send_mute then
      if bank[i][bank[i].id].right_delay_level == 0 then
        softcut.level_cut_cut(i+1,6,(env_counter[i].butt*bank[i].global_level)*1)
      else
        softcut.level_cut_cut(i+1,6,(env_counter[i].butt*bank[i].global_level)*0)
      end
    else
      softcut.level_cut_cut(i+1,6,(env_counter[i].butt*bank[i].global_level)*bank[i][bank[i].id].right_delay_level)
    end
  else
    env_counter[i]:stop()
    softcut.level_slew_time(i+1,1.0)
    softcut.level(i+1,0*bank[i].global_level)
    env_counter[i].butt = bank[i][bank[i].id].level
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
    softcut.level_slew_time(i+1,0.1)
    softcut.level(i+1,env_counter[i].butt*bank[i].global_level)
    -- softcut.level_cut_cut(i+1,5,env_counter[i].butt*(bank[i][bank[i].id].left_delay_level*bank[i].global_level))
    -- softcut.level_cut_cut(i+1,6,env_counter[i].butt*(bank[i][bank[i].id].right_delay_level*bank[i].global_level))
    if delay[1].send_mute then
      if bank[i][bank[i].id].left_delay_level == 0 then
        softcut.level_cut_cut(i+1,5,(env_counter[i].butt*bank[i].global_level)*1)
      else
        softcut.level_cut_cut(i+1,5,(env_counter[i].butt*bank[i].global_level)*0)
      end
    else
      softcut.level_cut_cut(i+1,5,(env_counter[i].butt*bank[i].global_level)*bank[i][bank[i].id].left_delay_level)
    end
    if delay[2].send_mute then
      if bank[i][bank[i].id].right_delay_level == 0 then
        softcut.level_cut_cut(i+1,6,(env_counter[i].butt*bank[i].global_level)*1)
      else
        softcut.level_cut_cut(i+1,6,(env_counter[i].butt*bank[i].global_level)*0)
      end
    else
      softcut.level_cut_cut(i+1,6,(env_counter[i].butt*bank[i].global_level)*bank[i][bank[i].id].right_delay_level)
    end
  else
    env_counter[i]:stop()
    softcut.level(i+1,bank[i][bank[i].id].level*bank[i].global_level)
    env_counter[i].butt = 0
    if bank[i][bank[i].id].left_delay_thru then
      softcut.level_cut_cut(i+1,5,bank[i][bank[i].id].left_delay_level)
    else
      softcut.level_cut_cut(i+1,5,(bank[i][bank[i].id].left_delay_level*bank[i][bank[i].id].level)*bank[i].global_level)
    end
    if bank[i][bank[i].id].right_delay_thru then
      softcut.level_cut_cut(i+1,6,bank[i][bank[i].id].left_delay_level)
    else
      softcut.level_cut_cut(i+1,6,(bank[i][bank[i].id].left_delay_level*bank[i][bank[i].id].level)*bank[i].global_level)
    end
    softcut.level_slew_time(i+1,1.0)
    if bank[i][bank[i].id].envelope_mode == 3 then
      env_counter[i].stage = "falling"
      softcut.level_slew_time(i+1,0.05)
      env_counter[i].butt = bank[i][bank[i].id].level
      if bank[i][bank[i].id].level > 0.05 then
      -- if bank[i][bank[i].id].envelope_time/(bank[i][bank[i].id].level/0.05) ~= inf then
        env_counter[i].time = (bank[i][bank[i].id].envelope_time/(bank[i][bank[i].id].level/0.05))
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
    process_tilt("pad",i,bank[i].id,slew_counter[i].slewedVal,slew_counter[i].slewedQ)
  elseif all_loaded then
    process_tilt("bank",i,nil,slew_counter[i].slewedVal,slew_counter[i].slewedQ)
  end
  if menu == 5 then
    if menu ~= 1 then screen_dirty = true end
  end
end

local function local_tilt(b,i,t,rq)
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
    if bank[b][i].cf_hp ~= 0 then
      bank[b][i].cf_hp = 0
    end
  elseif util.round(t*100) > 0 then
    bank[b][i].cf_hp = math.abs(t)
    bank[b][i].cf_fc = util.linexp(0,1,10,12000,bank[b][i].cf_hp)
    bank[b][i].cf_dry = 1-t
    bank[b][i].cf_exp_dry = (util.linexp(0,1,1,101,bank[b][i].cf_dry)-1)/100
    if bank[b][i].cf_lp ~= 0 then
      bank[b][i].cf_lp = 0
    end
  elseif util.round(t*100) == 0 then
    bank[b][i].cf_fc = 12000
    bank[b][i].cf_lp = 0
    bank[b][i].cf_hp = 0
    bank[b][i].cf_dry = 1
    bank[b][i].cf_exp_dry = 1
  end
end

function process_tilt(style,b,i,t,rq)
  if style == "pad" then
    local_tilt(b,i,t,rq)
  elseif style == "bank" then
    for j = 1,16 do
      local_tilt(b,j,t,rq)
    end
  end
  local focused_pad = style == "pad" and i or bank[b].id
  if util.round(t*100) < 0 then
    params:set("filter "..b.." cutoff",bank[b][focused_pad].cf_fc)
    params:set("filter "..b.." lp", math.abs(bank[b][focused_pad].cf_exp_dry-1))
    params:set("filter "..b.." dry", bank[b][focused_pad].cf_exp_dry)
    if params:get("filter "..b.." hp") ~= 0 then
      params:set("filter "..b.." hp", 0)
    end
  elseif util.round(t*100) > 0 then
    params:set("filter "..b.." cutoff",bank[b][focused_pad].cf_fc)
    params:set("filter "..b.." hp", math.abs(bank[b][focused_pad].cf_exp_dry-1))
    params:set("filter "..b.." dry", bank[b][focused_pad].cf_exp_dry)
    if params:get("filter "..b.." lp") ~= 0 then
      params:set("filter "..b.." lp", 0)
    end
  elseif util.round(t*100) == 0 then
    params:set("filter "..b.." cutoff",12000)
    params:set("filter "..b.." lp", 0)
    params:set("filter "..b.." hp", 0)
    params:set("filter "..b.." dry", 1)
  end
  softcut.post_filter_rq(b+1,rq)
end

function buff_freeze()
  softcut.recpre_slew_time(1,0.05)
  softcut.level_slew_time(1,0.05)
  softcut.fade_time(1,0.01)
  rec[rec.focus].state = (rec[rec.focus].state + 1)%2
  softcut.rec_level(1,rec[rec.focus].state)
  if rec[rec.focus].state == 1 then
    softcut.pre_level(1,params:get("live_rec_feedback_"..rec.focus))
  else
    softcut.pre_level(1,1)
  end
end

function buff_flush(segment)
  local points = {{1,9},{9,17},{17,25}}
  softcut.buffer_clear_region_channel(1,rec[segment].start_point, (rec[segment].end_point-rec[segment].start_point)+0.01)
  rec[segment].state = 0
  rec[segment].clear = 1
  if poll_position_new[1] >= points[segment][1] and poll_position_new[1] <= points[segment][2] then
    softcut.rec_level(1,0)
  end
  -- update_waveform(1,rec[segment].start_point, rec[segment].end_point,128)
  grid_dirty = true
  if buff_purge(segment) then
    softcut.buffer_clear_region_channel(1,points[segment][1], (points[segment][2]-points[segment][1])+0.01)
    if params:string("live_purge_resets_loop_"..segment) == "yes" then
      rec[segment].start_point = points[segment][1]
      rec[segment].end_point = points[segment][2]
      if poll_position_new[1] >= points[segment][1] and poll_position_new[1] <= points[segment][2] then
        softcut.loop_start(1,rec[segment].start_point)
        softcut.loop_end(1,rec[segment].end_point)
      end
    end
  end
  if key1_hold then
    update_waveform(1,rec[segment].start_point, rec[segment].end_point,128)
  else
    update_waveform(1,points[segment][1],points[segment][2],128)
  end
end

function buff_purge(segment)
  if util.time() - rec[segment].last_purged < 0.25 then
    return true
  else
    rec[segment].last_purged = util.time()
  end
end

function buff_pause()
  rec[rec.focus].pause = not rec[rec.focus].pause
  softcut.rate(1,rec[rec.focus].pause and 0 or 1) -- TODO make this dynamic to include rec rate offsets
end

function threshold_rec_handler()
  if rec[rec.focus].queued then
    amp_in[1]:stop()
    amp_in[2]:stop()
    rec[rec.focus].queued = false
  elseif not rec[rec.focus].queued and rec[rec.focus].state == 0 then
    amp_in[1]:start()
    amp_in[2]:start()
    rec[rec.focus].queued = true
    for i = 1,3 do
      if i~=rec.focus and rec[i].state == 1 then
        softcut.rec_level(1,0)
        softcut.pre_level(1,params:get("live_rec_feedback_"..i))
      end
    end
  elseif not rec[rec.focus].queued and rec[rec.focus].state == 1 then
    rec[rec.focus].end_point = poll_position_new[1]
    update_waveform(1,key1_hold and rec[rec.focus].start_point or live[rec.focus].min,key1_hold and rec[rec.focus].end_point or live[rec.focus].max,128)
  end
end

function toggle_buffer(i,untrue_alt,delayed)

  grid_dirty = true
  local old_clip = rec.focus

  for j = 1,3 do
    if j ~= i then
      rec[j].state = 0
    end
  end

  rec.focus = i

  local punch_out = false

  -- if params:string("rec_loop_"..rec.focus) == "1-shot" then
    if params:string("one_shot_punch") == "yes" and rec[rec.focus].state == 1 then
      punch_out = true
    end
  -- end

  if params:string("start_rec_loop_at_launch") == "no"
  or (params:string("start_rec_loop_at_launch") == "yes" and transport.is_running)
  or (params:string("start_rec_loop_at_launch") == "yes" and not transport.is_running and rec[rec.focus].state == 1)
  then
    if rec[rec.focus].loop == 0 and params:string("one_shot_clock_div") == "threshold" and rec[rec.focus].queued then
      softcut.level_slew_time(1,0)
      softcut.fade_time(1,0)
      one_shot_clock()
    else
      softcut.level_slew_time(1,0.05)
      softcut.fade_time(1,0.01)
      if rec[rec.focus].loop == 0 and not grid_alt then
        if rec[rec.focus].state == 0 then
          run_one_shot_rec_clock() -- this runs only if not recording
        elseif rec[rec.focus].state == 1 and rec_state_watcher.is_running then -- can have both conditions, right?
          cancel_one_shot_rec_clock(punch_out)
        end
      elseif rec[rec.focus].loop == 0 and (grid_alt and untrue_alt ~= nil) then
        -- buff_flush()
      elseif rec[rec.focus].loop == 1 and not grid_alt then
        if one_shot_rec_clock ~= nil then
          cancel_one_shot_rec_clock(punch_out)
        end
        softcut.loop_start(1,rec[rec.focus].start_point)
        softcut.loop_end(1,rec[rec.focus].end_point-0.01)
      end
    end
    
    rec.play_segment = rec.focus
    softcut.loop(1,rec[rec.focus].loop)
    if rec.stopped == true then
      rec.stopped = false
      if rec[rec.focus].loop == 1 then
        softcut.position(1,rec[rec.focus].start_point)
      end
    end
    if rec[rec.focus].loop == 1 then
      if old_clip ~= rec.focus then rec[rec.focus].state = 0 end
      buff_freeze()
      if rec[rec.focus].clear == 1 then
        rec[rec.focus].clear = 0
      end
    end
    -- end
    grid_dirty = true
    update_waveform(1,key1_hold and rec[rec.focus].start_point or live[rec.focus].min,key1_hold and rec[rec.focus].end_point or live[rec.focus].max,128)
    -- update_waveform(1,live[rec.focus].min,live[rec.focus].max,128)
  else
    if rec.transport_queued == nil then
      rec.transport_queued = true
      rec[rec.focus].queued = true
    else
      rec.transport_queued = not rec.transport_queued
      rec[rec.focus].queued = false
    end
  end
end

function update_delays()
  for i = 1,2 do
    if delay[i].mode == "clocked" then
      local delay_rate_to_time = clock.get_beat_sec() * delay[i].clocked_length * delay[i].modifier
      local delay_time = delay_rate_to_time + (41 + (30*(i-1)))
      delay[i].end_point = delay_time
      softcut.loop_end(i+4,delay[i].end_point)
    else
      softcut.loop_end(i+4,delay[i].free_end_point)
    end
  end
end

function sample_callback(path,i)
  if path ~= "cancel" and path ~= "" then
    load_sample(path,i)
  end
  _norns.key(1,1)
  _norns.key(1,0)
  key1_hold = false
end

function load_sample(file,sample)
  local old_min = clip[sample].min
  local old_max = clip[sample].max
  if file ~= "-" then
    local ch, len, sr = audio.file_info(file)
    if len/48000 < 32 then
      clip[sample].sample_length = len/48000
    else
      clip[sample].sample_length = 32
    end
    clip[sample].sample_rate = sr
    softcut.buffer_clear_region_channel(2,1+(32*(sample-1)),32)
    softcut.buffer_read_mono(file, 0, 1+(32*(sample-1)),clip[sample].sample_length + 0.05, 1, 2)
    -- softcut.buffer_read_mono(file, 0, 1+(32*(sample-1)),clip[sample].sample_length, 1, 2)
    clip_table()
    for p = 1,16 do
      for b = 1,3 do
        if bank[b][p].mode == 2 and bank[b][p].clip == sample and pre_cc2_sample[b] == false then
          scale_loop_points(bank[b][p], old_min, old_max, clip[sample].min, clip[sample].max)
        end
      end
    end
    if util.file_exists(_path.code.."zxcvbn/lib/aubiogo/aubiogo") then
      params:show('detect_onsets_'..sample)
      params:hide('clear_onsets_'..sample)
      _menu.rebuild_params()
    end
    cursors[sample] = {}
  end
  for i = 1,3 do
    pre_cc2_sample[i] = false
  end
  update_waveform(2,clip[sample].min,clip[sample].max,128)
  clip[sample].waveform_samples = waveform_samples
  if params:get("clip "..sample.." sample") ~= file then
    params:set("clip "..sample.." sample", file, 1)
  end
  -- for i = 1,3 do
  --   if bank[i][bank[i].id].mode == 2 and bank[i][bank[i].id].clip == sample then
  --     softcut.position(i+1,bank[i][bank[i].id].start_point)
  --   end
  -- end
end

function save_sample(i)
  local dirname = _path.dust.."audio/cc2_saved_samples/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local name = "cc2_"..os.date("%y%m%d_%X-buff")..i..".wav"
  local save_pos = i - 1
  softcut.buffer_write_mono(_path.dust.."/audio/cc2_saved_samples/"..name,1+(8*save_pos),8,1)
end

function collect_samples(i,collection) -- this works!!!
  local dirname = _path.dust.."audio/cc2_live-audio/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local dirname = _path.dust.."audio/cc2_live-audio/"..collection.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local name = "cc2_"..collection.."-"..i..".wav"
  local save_pos = i - 1
  softcut.buffer_write_mono(_path.dust.."audio/cc2_live-audio/"..collection.."/"..name,1+(8*save_pos),8,1)
end

function reload_collected_samples(file,sample)
  if rec[rec.focus].state == 1 then
    buff_freeze()
  end
  if file ~= "-" then
    softcut.buffer_read_mono(file, 0, 1+(8 * (sample-1)), 8, 1, 1)
    print("reloaded previous session's audio")
  end
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
  else
    if n == 3 and z == 1 then
      if menu == 1 then
        if key1_hold then
          menu = "MIDI_config"
          key1_hold = false
        else
          menu = page.main_sel + 1
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
              threshold_rec_handler()
            else
              toggle_buffer(rec.focus)
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
                toggle_buffer(rec.focus)
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
                fileselect.enter(_path.audio,function(n) sample_callback(n,bank[id][bank[id].id].clip) end)
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
              local reasonable_max = bank[id][bank[id].id].mode == 1 and 8 or clip[bank[id][bank[id].id].clip].sample_length
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
      elseif menu == 3 then
        local level_nav = (page.levels.sel + 1)%4
        page.levels.sel = level_nav
      elseif menu == 5 then
        local filter_nav = (page.filters.sel + 1)%4
        page.filters.sel = filter_nav
      elseif menu == 6 then
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
            page.delay.section = page.delay.section == 1 and 2 or 1
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
            if get_grid_connected() or osc_communication then
              grid_actions.grid_pat_handler(id)
            else
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
              if get_grid_connected() or osc_communication then
                random_grid_pat(id,2)
              else
                shuffle_midi_pat(id)
              end
            elseif page.time_page_sel[time_nav] == 4 then
              if not key1_hold then
                -- if g.device ~= nil then
                if get_grid_connected() or osc_communication then
                  random_grid_pat(id,3)
                else
                  random_midi_pat(id)
                end
              end
            end
            if key1_hold then
              if grid_pat[id].count > 0 then
                grid_pat[id]:rec_stop()
                grid_pat[id]:stop()
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
          -- params:set("euclid_mute_"..rytm.track_edit,params:get("euclid_mute_"..rytm.track_edit) == 0 and 1 or 0)
        else
          rytm.screen_focus = rytm.screen_focus == "left" and "right" or "left"
        end

      elseif menu == 9 then
        if not key2_hold then
          grid_actions.arp_handler(page.arp_page_sel)
        else
          key2_hold_and_modify = true
          grid_actions.kill_arp(page.arp_page_sel)
        end
        -- arp[page.arp_page_sel].hold = not arp[page.arp_page_sel].hold
        -- local id = page.arp_page_sel
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
        --     -- else
        --     --   arp[id].step = arp[id].start_point-1
        --     --   arp[id].pause = false
        --     --   arp[id].playing = true
        --     end
        --   end
        -- end
        grid_dirty = true


        -- if not arp[page.arp_page_sel].hold then
        --   arps.clear(page.arp_page_sel)
        -- end
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
          page.rnd_page_section = page.rnd_page_section == 1 and 2 or 1
        end
      end


    elseif n == 2 and z == 1 then
      if menu == 1 then
        if key1_hold then
          menu = "macro_config"
          key1_hold = false
        else
          menu = "transport_config"
        end
      elseif (menu == 2 or menu == 7 or menu == 9) and not key1_hold then
        -- key2_hold = true
        key2_hold_counter = clock.run(count_key2)
        key2_hold_and_modify = false
      elseif menu == 2 then
        if page.loops.frame == 2 and key1_hold then
          if page.loops.sel == 4 then
            buff_flush(rec.focus)
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
              local reasonable_max = bank[id][bank[id].id].mode == 1 and 8 or clip[bank[id][bank[id].id].clip].sample_length
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
    elseif n == 2 and z == 0 and key2_hold == false and (menu == 2 or menu == 7 or menu == 9) and not key1_hold then
      clock.cancel(key2_hold_counter)
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
            -- buff_flush()
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
      if menu == 5 or menu == 11 then
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
        key1_hold = true
        arp[page.arp_page_sel].alt = not arp[page.arp_page_sel].alt
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
            fileselect.enter(_path.audio,function(n) sample_callback(n,bank[page.loops.sel][bank[page.loops.sel].id].clip) end)
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
                  start_pattern(midi_pat[id])
                elseif midi_pat[id].playmode == 2 then
                  print("line 2387")
                  --midi_pat[id].clock = clock.run(synced_loop, midi_pat[id], "restart")
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
  main_menu.init()
  if detecting_onsets_popup.state then
    screen.rect(1,11,127,44)
    screen.level(15)
    screen.fill()
    screen.rect(2,12,125,42)
    screen.level(0)
    screen.fill()
    screen.level(15)
    screen.font_size(8)
    screen.move(64,25)
    screen.text_center('detecting onsets:')
    screen.font_size(15)
    if clip[detecting_onsets_popup.id].sample_rate < 48000 then
      screen.move(64,42)
    else
      screen.move(64,44)
    end
    screen.text_center(detecting_onsets_popup.percent..'%')
    screen.font_size(8)
    if clip[detecting_onsets_popup.id].sample_rate < 48000 then
      screen.move(64,52)
      screen.text_center('use 48khz for best results')
    end
  elseif detected_onsets_popup.state then
    screen.rect(1,11,127,44)
    screen.level(15)
    screen.fill()
    screen.rect(2,12,125,42)
    screen.level(0)
    screen.fill()
    screen.level(15)
    screen.font_size(8)
    screen.move(64,28)
    screen.font_size(15)
    screen.text_center('onsets')
    if detected_onsets_popup.id ~= nil and clip[detected_onsets_popup.id].sample_rate < 48000 then
      screen.move(64,42)
    else
      screen.move(64,45)
    end
    screen.text_center('detected!')
    screen.font_size(8)
    if detected_onsets_popup.id ~= nil and clip[detected_onsets_popup.id].sample_rate < 48000 then
      screen.move(64,52)
      screen.text_center('use 48khz for best results')
    end
  end
  screen.update()
end

--GRID
g = grid_device.connect()

function get_grid_connected()
  if grid_device.is_midigrid ~= nil and grid_device.is_midigrid == true then
    params:set("midigrid?",2)
  end
  if g.device == nil and grid_device == nil then
    return false
  elseif g.device ~= nil or (grid_device ~= nil and params:string("midigrid?") == "yes") then
    return true
  else
    return false
  end
end

function grid_device.add(dev)
  grid_dirty = true
end

g.key = function(x,y,z)
  grid_actions.init(x,y,z)
end

function jump_live(i,s,y,z)

  local pad = bank[i][s]

  local old_duration = pad.mode == 1 and 8 or clip[pad.clip].sample_length
  local old_clip = pad.clip
  local old_min = (1+(old_duration*(old_clip-1)))
  local old_max = ((old_duration+1)+(old_duration*(old_clip-1)))
  local old_range = old_min - old_max
  pad.clip = math.abs(y-5)
  local new_duration = pad.mode == 1 and 8 or clip[pad.clip].sample_length
  local new_clip = pad.clip
  --local new_min = (1+(new_duration*(pad.clip-1)))
  if pad.mode == 1 then
    local new_min = (1+(new_duration*(pad.clip-1)))
    local new_max = ((new_duration+1)+(new_duration*(pad.clip-1)))
    local new_range = new_max - new_min
    local current_difference = (pad.end_point - pad.start_point) -- is this where it gets weird?
    pad.start_point = (((pad.start_point - old_min) * new_range) / old_range) + new_min
    pad.end_point = pad.start_point + current_difference
  end


--[[
  for go = 1,2 do
    local old_min = (1+(duration*(bank[i][s].clip-1)))
    local old_max = ((duration+1)+(duration*(bank[i][s].clip-1)))
    local old_range = old_min - old_max
    bank[i][s].clip = math.abs(y-5)
    local new_min = (1+(duration*(bank[i][s].clip-1)))
    local new_max = ((duration+1)+(duration*(bank[i][s].clip-1)))
    local new_range = new_max - new_min
    local current_difference = (bank[i][s].end_point - bank[i][s].start_point)
    bank[i][s].start_point = (((bank[i][s].start_point - old_min) * new_range) / old_range) + new_min
    bank[i][s].end_point = bank[i][s].start_point + current_difference
    if menu == 11 then
      which_bank = i
      help_menu = "buffer jump"
    end
  end
  --]]

  if menu == 11 then
    which_bank = i
    help_menu = "buffer jump"
  end
end

function clip_table()
  clip[1].min = 1
  clip[1].max = clip[1].min + clip[1].sample_length
  --clip[2].min = clip[1].max
  clip[2].min = 33
  clip[2].max = clip[2].min + clip[2].sample_length
  --clip[3].min = clip[2].max
  clip[3].min = 65
  clip[3].max = clip[3].min + clip[3].sample_length
end

-- length mods

function scale_loop_points(pad,old_min,old_max,new_min,new_max)
  --local pad = bank[b][p]
  local duration = pad.end_point - pad.start_point
  pad.start_point = util.linlin(old_min,old_max,new_min,new_max,pad.start_point)
  --pad.end_point = util.linlin(old_min,old_max,new_min,new_max,pad.end_point)
  if pad.start_point + duration > new_max then
    pad.end_point = new_max
  else
    pad.end_point = pad.start_point + duration
  end
end

function change_mode(target,old_mode)
  local live_min = live[target.clip].min
  local live_max = live[target.clip].max
  local clip_min = clip[target.clip].min
  local clip_max = clip[target.clip].max
  local duration = target.end_point - target.start_point
  if old_mode == 1 then
    target.start_point = util.linlin(live_min,live_max,clip_min,clip_max,target.start_point)
  elseif old_mode == 2 then
    target.start_point = util.linlin(clip_min,clip_max,live_min,live_max,target.start_point)
  end
  if target.start_point + duration > (old_mode == 1 and clip[target.clip].max or live[target.clip].max) then
    target.end_point = (old_mode == 1 and clip[target.clip].max or live[target.clip].max)
  else
    target.end_point = target.start_point + duration
  end
end

function jump_clip(bank_id,pad_id,new_clip)
  local pad = bank[bank_id][pad_id]
  local current_difference = (pad.end_point - pad.start_point)
  if pad.mode == 2 then
    local old_clip = pad.clip
    pad.clip = new_clip
    pad.start_point = util.linlin(clip[old_clip].min,clip[old_clip].max,clip[pad.clip].min,clip[pad.clip].max,pad.start_point)
    if pad.start_point + current_difference > clip[pad.clip].max then
      pad.end_point = clip[pad.clip].max
    else
      pad.end_point = pad.start_point + current_difference
    end
  else
    local old_clip = pad.clip
    pad.clip = new_clip
    pad.start_point = util.linlin(live[old_clip].min,live[old_clip].max,live[pad.clip].min,live[pad.clip].max,pad.start_point)
    if pad.start_point + current_difference > live[pad.clip].max then
      pad.end_point = live[pad.clip].max
    else
      pad.end_point = pad.start_point + current_difference
    end
  end
end

--/ length mods

function grid_entry(e)
  if e.state > 0 then
    lit[e.id] = {}
    lit[e.id].x = e.x
    lit[e.id].y = e.y
  else
    if lit[e.id] ~= nil then
      lit[e.id] = nil
    end
  end
  -- grid_redraw()
  grid_dirty = true
end

led_maps =
--                    {   VB,4S,GS  }
{
  -- main page
  ["square_off"]          =   {3,4,15}
  , ["square_selected"]   =   {15,15,0}
  , ["square_dim"]        =   {5,8,0}
  , ["zilchmo_off"]       =   {3,4,15} -- is this right?
  , ["zilchmo_on"]        =   {15,12,0}
  , ["pad_pause"]         =   {15,12,15}
  , ["pad_play"]          =   {3,4,0}
  , ["rec_record"]        =   {9,8,15}
  , ["rec_overdub"]       =   {9,8,15}
  , ["rec_play"]          =   {15,12,15}
  , ["rec_pause"]         =   {5,4,0}
  , ["rec_off"]           =   {3,0,0}
  , ["arc_rec_rec"]       =   {15,12,15}
  , ["arc_rec_play"]      =   {9,8,15}
  , ["arc_rec_pause"]     =   {5,4,0}
  , ["arc_rec_off"]       =   {0,0,0}
  , ["arc_param_show"]    =   {5,4,0}
  , ["grid_alt_on"]       =   {15,12,15}
  , ["grid_alt_off"]      =   {3,4,0}
  , ["clip"]              =   {8,8,15}
  , ["mode"]              =   {6,8,15}
  , ["loop_on"]           =   {4,8,15}
  , ["loop_off"]          =   {2,4,0}
  , ["arp_on"]            =   {4,4,0}
  , ["arp_pause"]         =   {4,8,15}
  , ["arp_play"]          =   {10,12,15}
  , ["live_empty"]        =   {3,4,0}
  , ["live_rec"]          =   {10,12,15}
  , ["live_pause"]        =   {5,8,0}
  , ["alt_on"]            =   {15,12,15}
  , ["alt_off"]           =   {3,4,0}
  , ["focus_on"]          =   {10,8,15}
  -- , ["focus_soft"]        =   {10,8,15}

  -- seq page
  , ["step_no_data"]      =   {2,4,0}
  , ["step_yes_data"]     =   {4,8,15}
  , ["step_loops"]        =   {4,8,15}
  , ["slot_saved"]        =   {7,8,0}
  , ["slot_empty"]        =   {2,4,0}
  , ["slot_loaded"]       =   {15,15,15}
  , ["step_current"]      =   {15,15,15}
  , ["step_held"]         =   {9,8,15}
  , ["loop_duration"]     =   {4,4,0}
  , ["meta_duration"]     =   {4,4,15}
  , ["meta_step_hi"]      =   {6,8,15}
  , ["meta_step_lo"]      =   {2,4,0}
  , ["loop_mod_hi"]       =   {12,12,15}
  , ["loop_mod_lo"]       =   {3,4,0}

  -- delay page
  , ["bundle_empty"]      =   {2,4,0}
  , ["bundle_saved"]      =   {7,8,0}
  , ["bundle_loaded"]     =   {15,12,15}
  , ["time_to_led.5"]     =   {5,4,15}
  , ["time_to_led.25"]    =   {10,8,15}
  , ["time_to_led.125"]   =   {15,12,15}
  , ["time_to_led2"]      =   {3,4,15}
  , ["time_to_led4"]      =   {6,8,15}
  , ["time_to_led8"]      =   {12,12,15}
  , ["time_to_led16"]     =   {15,12,15}
  , ["reverse_on"]        =   {7,8,15}
  , ["reverse_off"]       =   {3,4,0}
  , ["wobble_on"]         =   {15,12,15}
  , ["wobble_off"]        =   {0,0,0}
  , ["level_lo"]          =   {2,4,0}
  , ["level_hi"]          =   {7,8,15}
  , ["selected_bank"]     =   {7,8,15}
  , ["unselected_bank"]   =   {2,4,0}
  , ["64_bank_send"]      =   {4,8,15}
  
  -- misc
  , ["page_led"]          =   {{0,0,15},{7,8,15},{15,12,15}}
  , ["off"]               =   {0,0,0}
}

function draw_zilch(x,y,z)
  g:led(x,y,z == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
end

function grid_redraw()
  -- if g.device ~= nil then
  if get_grid_connected() then
    if params:string("grid_size") == "128/256" then
      g:all(0)
      local edition = params:get("LED_style")
      
      if grid_page == 0 then
        
        for j = 0,2 do
          for k = 1,4 do
            k = k+(5*j)
            for i = 8,5,-1 do
              g:led(k,i,led_maps["square_off"][edition])
            end
          end
        end
        
        for i = 0,1 do
          for x = 4+i,14+i,5 do
            for j = 1,3+i do
              g:led(x,j,zilch_leds[i == 0 and 3 or 4][util.round(x/5)][j] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
            end
          end
        end

        for x = 3,13,5 do
          for j = 1,2 do
            g:led(x,j,zilch_leds[2][util.round(x/5)][j] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
          end
        end
        
        for i = 1,3 do
          local target = grid_pat[i]
          if target.rec == 1 then
            g:led(2+(5*(i-1)),1,(9*target.led))
          elseif (target.quantize == 0 and target.play == 1) or (target.quantize == 1 and target.tightened_start == 1) then
            if target.overdub == 0 then
              g:led(2+(5*(i-1)),1,9)
            else
              g:led(2+(5*(i-1)),1,15)
            end
          elseif target.count > 0 then
            g:led(2+(5*(i-1)),1,5)
          else
            g:led(2+(5*(i-1)),1,3)
          end
        end
        
        for i = 1,3 do
          local a_p; -- this will index the arc encoder recorders
          if arc_param[i] == 1 or arc_param[i] == 2 or arc_param[i] == 3 then
            a_p = 1
          else
            a_p = arc_param[i] - 2
          end
          if arc_pat[i][a_p].rec == 1 then
            g:led(16,5-i,led_maps["arc_rec_rec"][edition])
          elseif arc_pat[i][a_p].play == 1 then
            g:led(16,5-i,led_maps["arc_rec_play"][edition])
          elseif arc_pat[i][a_p].count > 0 then
            g:led(16,5-i,led_maps["arc_rec_pause"][edition])
          else
            g:led(16,5-i,led_maps["arc_rec_off"][edition])
          end
        end
        
        if a.device ~= nil then
          for i = 1,3 do
            for j = 5,15,5 do
              g:led(j,8,arc_param[j/5] == 1 and 5 or 0)
              g:led(j,7,arc_param[j/5] == 2 and 5 or 0)
              g:led(j,6,arc_param[j/5] == 3 and 5 or 0)
              if arc_param[j/5] == 4 then
                for k = 8,6,-1 do
                  g:led(j,k,led_maps["arc_param_show"][edition])
                end
              elseif arc_param[j/5] == 5 then
                g:led(j,8,led_maps["arc_param_show"][edition])
                g:led(j,7,led_maps["arc_param_show"][edition])
              elseif arc_param[j/5] == 6 then
                g:led(j,7,led_maps["arc_param_show"][edition])
                g:led(j,6,led_maps["arc_param_show"][edition])
              end
            end
          end
        end
        
        for i = 1,3 do
          if bank[i].focus_hold == false then
            g:led(selected[i].x, selected[i].y, led_maps["square_selected"][edition])
            if i == nil then print("2339") end
            if bank[i].id == nil then print("2340", i) end
            if bank[i][bank[i].id].pause == nil then print("2341") end
            if bank[i][bank[i].id].pause == true then
              g:led(3+(5*(i-1)),1,led_maps["pad_pause"][edition])
              g:led(3+(5*(i-1)),2,led_maps["pad_pause"][edition])
            else
              -- g:led(3+(5*(i-1)),1,led_maps["pad_play"][edition])
              -- g:led(3+(5*(i-1)),2,led_maps["pad_play"][edition])
              g:led(3+(5*(i-1)),1,zilch_leds[2][i][1] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
              g:led(3+(5*(i-1)),2,zilch_leds[2][i][2] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
            end
          else
            local focus_x = (math.ceil(bank[i].focus_pad/4)+(5*(i-1)))
            local focus_y = 8-((bank[i].focus_pad-1)%4)
            g:led(selected[i].x, selected[i].y, led_maps["square_dim"][edition])
            g:led(focus_x, focus_y, led_maps["square_selected"][edition])
            if bank[i][bank[i].focus_pad].pause == true then
              g:led(3+(5*(i-1)),1,led_maps["square_selected"][edition])
              g:led(3+(5*(i-1)),2,led_maps["square_selected"][edition])
            else
              g:led(3+(5*(i-1)),1,led_maps["square_off"][edition])
              g:led(3+(5*(i-1)),2,led_maps["square_off"][edition])
            end
          end
        end
        
        for i = 1,3 do
          if bank[i].focus_hold then
            g:led(4+(5*(i-1)),4,(10*bank[i][bank[i].focus_pad].crow_pad_execute)+5)
          end
          -- if bank[i].focus_hold == true then
          --   g:led(5*i,5,(10*bank[i][bank[i].focus_pad].crow_pad_execute)+5)
          -- else
          --   local alt = bank[i].alt_lock and 1 or 0
          --   g:led(5*i,5,15*alt)
          -- end
          local alt = bank[i].alt_lock and 1 or 0
          g:led(5*i,5,15*alt)
        end
        
        for i,e in pairs(lit) do
          g:led(e.x, e.y,led_maps["zilchmo_on"][edition])
        end
        
        g:led(16,8,(grid_alt and led_maps["alt_on"][edition] or led_maps["alt_off"][edition]))
        
        for i = 1,3 do
          
          local focused = bank[i].focus_hold == false and bank[i][bank[i].id] or bank[i][bank[i].focus_pad]

          g:led(1 + (5*(i-1)), math.abs(focused.clip-5),led_maps["clip"][edition])
          g:led(2 + (5*(i-1)), math.abs(focused.mode-5),led_maps["mode"][edition])
          g:led(1+(5*(i-1)),1,bank[i].focus_hold == false and led_maps["off"][edition] or led_maps["focus_on"][edition])
          if focused.loop == false then
            g:led(3+(5*(i-1)),4,led_maps["loop_off"][edition])
          elseif focused.loop == true then
            g:led(3+(5*(i-1)),4,led_maps["loop_on"][edition])
          end
          if not arp[i].enabled then
            g:led(3+(5*(i-1)),3,led_maps["off"][edition])
          else
            if arp[i].playing and arp[i].hold then
              g:led(3+(5*(i-1)),3,led_maps["arp_play"][edition])
            elseif arp[i].hold then
              g:led(3+(5*(i-1)),3,led_maps["arp_pause"][edition])
            else
              g:led(3+(5*(i-1)),3,led_maps["arp_on"][edition])
            end
          end

        end
        
        if rec[rec.focus].clear == 0 then
          g:led(16,8-rec.focus,rec[rec.focus].state == 1 and led_maps["live_rec"][edition] or ((rec[rec.focus].queued or rec.transport_queued) and 15 or led_maps["live_pause"][edition]))
        elseif rec[rec.focus].clear == 1 then
          g:led(16,8-rec.focus,(rec[rec.focus].queued or rec.transport_queued) and 9 or led_maps["live_empty"][edition])
        end
      
      elseif grid_page == 1 then
        
        -- if we're on page 2...
        
        for i = 1,3 do

          for j = step_seq[i].start_point,step_seq[i].end_point do
            local xval = j < 9 and (i*5)-2 or (i*5)-1
            local yval = j < 9 and 9 or 17

            g:led(xval,yval-j,led_maps["step_no_data"][edition])

            if grid_loop_mod == 1 then
              g:led(xval,yval-step_seq[i].start_point,led_maps["step_loops"][edition])
              g:led(xval,yval-step_seq[i].end_point,led_maps["step_loops"][edition])
            end

          end

          for j = 1,16 do
            if step_seq[i][j].assigned_to ~= 0 then
              local xval = j < 9 and (i*5)-2 or (i*5)-1
              local yval = j < 9 and 9 or 17
              g:led(xval,yval-j,led_maps["step_yes_data"][edition])
            end
          end

          if step_seq[i].current_step < 9 then
            g:led((i*5)-2,9-step_seq[i].current_step,led_maps["step_current"][edition])
          elseif step_seq[i].current_step >=9 then
            g:led((i*5)-1,9-(step_seq[i].current_step-8),led_maps["step_current"][edition])
          end

          if step_seq[i].held < 9 then
            g:led((i*5)-2,9-step_seq[i].held,led_maps["step_held"][edition])
          elseif step_seq[i].held >= 9 then
            g:led((i*5)-1,9-(step_seq[i].held-8),led_maps["step_held"][edition])
          end

          g:led((i*5)-3, 9-step_seq[i].meta_duration,led_maps["meta_duration"][edition])
          g:led((i*5)-3, 9-step_seq[i].meta_step,led_maps["meta_step_hi"][edition])

          if step_seq[i].held == 0 then
            g:led((i*5), 9-step_seq[i][step_seq[i].current_step].meta_meta_duration,led_maps["meta_duration"][edition])
            g:led((i*5), 9-step_seq[i].meta_meta_step,led_maps["meta_step_hi"][edition])
          else
            g:led((i*5), 9-step_seq[i].meta_meta_step,led_maps["meta_step_lo"][edition])
            g:led((i*5), 9-step_seq[i][step_seq[i].held].meta_meta_duration,led_maps["meta_duration"][edition])
          end
          if step_seq[i].held == 0 then
            g:led(16,8-i,edition == 3 and (15*step_seq[i].active) or ((step_seq[i].active*6)+2))
          else
            g:led(16,8-i,step_seq[i][step_seq[i].held].loop_pattern*4)
          end

        end
        
        for i = 1,11,5 do
          for j = 1,8 do
            local current = math.floor(i/5)+1
            local show = step_seq[current].held == 0 and pattern_saver[current].load_slot or step_seq[current][step_seq[current].held].assigned_to
            g:led(i,j,edition == 3 and (15*pattern_saver[current].saved[9-j]) or ((5*pattern_saver[current].saved[9-j])+2))
            g:led(i,j,j == (9 - show) and 15 or (edition == 3 and (15*pattern_saver[current].saved[9-j]) or ((5*pattern_saver[current].saved[9-j])+2)))
          end
        end
        
        g:led(16,8,grid_alt and led_maps["alt_on"][edition] or led_maps["alt_off"][edition])
        g:led(16,2,grid_loop_mod == 1 and led_maps["loop_mod_hi"][edition] or led_maps["loop_mod_lo"][edition])
      
      elseif grid_page == 2 then
        -- delay page!

        g:led(9,7,params:get("delay L: external input") > 0 and 15 or 0)
        g:led(9,2,params:get("delay R: external input") > 0 and 15 or 0)

        for i = 1,8 do
          local check = {i+8, i}
          for j = 1,2 do
            g:led(i,j,delay[2].selected_bundle == check[j] and 15 or (delay_bundle[2][check[j]].saved == true and led_maps["bundle_saved"][edition] or led_maps["bundle_empty"][edition]))
            g:led(i,j+6,delay[1].selected_bundle == check[j] and 15 or (delay_bundle[1][check[j]].saved == true and led_maps["bundle_saved"][edition] or led_maps["bundle_empty"][edition]))
          end
        end

        -- delay time modifiers
        local time_to_led = {{},{},{},{}}
        local time = {delay[1].modifier, delay[2].modifier}
        for i = 1,2 do
          time_to_led[i] = 0
          time_to_led[i+2] = 0
          if time[i] == 0.5 then
            time_to_led[i+2] = led_maps["time_to_led.5"][edition]
          elseif time[i] == 0.25 then
            time_to_led[i+2] = led_maps["time_to_led.25"][edition]
          elseif time[i] == 0.125 then
            time_to_led[i+2] = led_maps["time_to_led.125"][edition]
          elseif time[i] == 2 then
            time_to_led[i] = led_maps["time_to_led2"][edition]
          elseif time[i] == 4 then
            time_to_led[i] = led_maps["time_to_led4"][edition]
          elseif time[i] == 8 then
            time_to_led[i] = led_maps["time_to_led8"][edition]
          elseif time[i] == 16 then
            time_to_led[i] = led_maps["time_to_led16"][edition]
          end
        end
        g:led(1,3,time_to_led[2])
        g:led(2,3,time_to_led[4])
        g:led(1,6,time_to_led[1])
        g:led(2,6,time_to_led[3])
        g:led(3,3,delay[2].reverse and led_maps["reverse_on"][edition] or led_maps["reverse_off"][edition])
        g:led(3,6,delay[1].reverse and led_maps["reverse_on"][edition] or led_maps["reverse_off"][edition])

        rate_to_led = {{},{},{},{}}
        local rate = {params:get("delay L: rate"), params:get("delay R: rate")}
        for i = 1,2 do
          rate_to_led[i] = 0
          rate_to_led[i+2] = 0
          for j = 1,24 do
            if math.modf(rate[i]) >= j then
              rate_to_led[i] = math.modf(util.linlin(0,24,3,15,j))
            end
          end
          for j = 0.25,1,0.05 do
            if rate[i] >= j then
              rate_to_led[i+2] = math.modf(util.linlin(0.25,1,15,0,j))
            end
          end
          if rate[i] == 1 then
            rate_to_led[i+2] = 3
          end
        end
        g:led(1,4,rate_to_led[2])
        g:led(2,4,rate_to_led[4])
        g:led(3,4,delay[2].wobble_hold and led_maps["wobble_on"][edition] or led_maps["wobble_off"][edition])
        g:led(1,5,rate_to_led[1])
        g:led(2,5,rate_to_led[3])
        g:led(3,5,delay[1].wobble_hold and led_maps["wobble_on"][edition] or led_maps["wobble_off"][edition])
        
        -- delay levels
        local level_to_led = {{},{}}
        local delay_level = {params:get("delay L: global level"), params:get("delay R: global level")}
        for i = 1,2 do
          if delay_level[i] <= 0.125 then
            level_to_led[i] = 0
          elseif delay_level[i] <= 0.375 then
            level_to_led[i] = 1
          elseif delay_level[i] <= 0.625 then
            level_to_led[i] = 2
          elseif delay_level[i] <= 0.875 then
            level_to_led[i] = 3
          elseif delay_level[i] <= 1 then
            level_to_led[i] = 4
          end
        end
        for i = 8,4,-1 do
          g:led(i,6,led_maps["level_lo"][edition])
          g:led(i,3,led_maps["level_lo"][edition])
        end
        for i = 1,2 do
          if not delay[i].level_mute then
            for j = 8,4+(4-level_to_led[i]),-1 do
              g:led(j,i==1 and 6 or 3,led_maps["level_hi"][edition])
            end
          else
            if params:get(i == 1 and "delay L: global level" or "delay R: global level") == 0 then
              for j = 8,4,-1 do
                g:led(j,i==1 and 6 or 3,led_maps["level_hi"][edition])
              end
            end
          end
        end

        -- feedback levels
        local feed_to_led = {{},{}}
        local feedback_level = {params:get("delay L: feedback"), params:get("delay R: feedback")}
        for i = 1,2 do
          if feedback_level[i] <= 12.5 then
            feed_to_led[i] = 0
          elseif feedback_level[i] <= 37.5 then
            feed_to_led[i] = 1
          elseif feedback_level[i] <= 62.5 then
            feed_to_led[i] = 2
          elseif feedback_level[i] <= 87.5 then
            feed_to_led[i] = 3
          elseif feedback_level[i] <= 100 then
            feed_to_led[i] = 4
          end
        end
        for i = 8,4,-1 do
          g:led(i,5,led_maps["level_lo"][edition])
          g:led(i,4,led_maps["level_lo"][edition])
        end
        for i = 1,2 do
          if not delay[i].feedback_mute then
            for j = 8,4+(4-feed_to_led[i]),-1 do
              g:led(j,i==1 and 5 or 4,led_maps["level_hi"][edition])
            end
          else
            if params:get(i == 1 and "delay L: feedback" or "delay R: feedback") == 0 then
              for j = 8,4,-1 do
                g:led(j,i==1 and 5 or 4,led_maps["level_hi"][edition])
              end
            end
          end
        end

        for k = 10,13 do
          for i = 6,3,-1 do
            g:led(k,i,led_maps["square_off"][edition])
          end
        end

        local shifted_x = (selected[delay_grid.bank].x - (5*(delay_grid.bank-1)))+9
        local shifted_y = selected[delay_grid.bank].y - 2
        g:led(shifted_x, shifted_y, led_maps["square_selected"][edition])

        for i = 4,6 do
          g:led(14,i,delay_grid.bank == 7-i and led_maps["selected_bank"][edition] or led_maps["unselected_bank"][edition])
        end

        -- send levels

        local send_to_led = {{},{}}
        local send_level = {bank[delay_grid.bank][bank[delay_grid.bank].id].left_delay_level, bank[delay_grid.bank][bank[delay_grid.bank].id].right_delay_level}
        for i = 1,2 do
          if send_level[i] <= 0.125 then
            send_to_led[i] = 0
          elseif send_level[i] <= 0.375 then
            send_to_led[i] = 1
          elseif send_level[i] <= 0.625 then
            send_to_led[i] = 2
          elseif send_level[i] <= 0.875 then
            send_to_led[i] = 3
          elseif send_level[i] <= 1.0 then
            send_to_led[i] = 4
          end
        end

        for i = 1,2 do
          if not delay[i].send_mute then
            for j = 14,10+(4-send_to_led[i]),-1 do
              g:led(j,i==1 and 8 or 1,led_maps["level_hi"][edition])
            end
          else
            if (i == 1 and bank[delay_grid.bank][bank[delay_grid.bank].id].left_delay_level or bank[delay_grid.bank][bank[delay_grid.bank].id].right_delay_level) == 0 then
              for j = 14,10,-1 do
                g:led(j,i==1 and 8 or 1,led_maps["level_hi"][edition])
              end
            end
          end
        end

        --arp button
        if not arp[delay_grid.bank].enabled then
          g:led(12,2,led_maps["off"][edition])
        else
          if arp[delay_grid.bank].playing and arp[delay_grid.bank].hold then
            g:led(12,2,led_maps["arp_play"][edition])
          elseif arp[delay_grid.bank].hold then
            g:led(12,2,led_maps["arp_pause"][edition])
          else
            g:led(12,2,led_maps["arp_on"][edition])
          end
        end

        if bank[delay_grid.bank][bank[delay_grid.bank].id].loop == false then
          g:led(13,2,led_maps["loop_off"][edition])
        else
          g:led(13,2,led_maps["loop_on"][edition])
        end



        g:led(16,8,(grid_alt and led_maps["alt_on"][edition] or led_maps["alt_off"][edition]))

        for j = 1,4 do
          g:led(15,math.abs(j-7),zilch_leds[4][delay_grid.bank][j] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
        end

      end

      local page_led = {[0] = 0, [1] = 7, [2] = 15}
      if grid_page ~= nil then
        g:led(16,1,led_maps["page_led"][grid_page+1][edition])
      end
      
      g:refresh()

    --64 grid / grid 64
    elseif params:string("grid_size") == "64" then
      g:all(0)
      local edition = params:get("LED_style")

      g:led(8,1,led_maps["square_off"][edition])
      
      if grid_page_64 == 0 then

        for x = 1,3 do
          g:led(x,1,x == bank_64 and 15 or 4)
        end

        --arc recorders
        local a_p; -- this will index the arc encoder recorders
        if arc_param[bank_64] == 1 or arc_param[bank_64] == 2 or arc_param[bank_64] == 3 then
          a_p = 1
        else
          a_p = arc_param[bank_64] - 2
        end
        if arc_pat[bank_64][a_p].rec == 1 then
          g:led(8,3,led_maps["arc_rec_rec"][edition])
        elseif arc_pat[bank_64][a_p].play == 1 then
          g:led(8,3,led_maps["arc_rec_play"][edition])
        elseif arc_pat[bank_64][a_p].count > 0 then
          g:led(8,3,led_maps["arc_rec_pause"][edition])
        else
          g:led(8,3,led_maps["arc_rec_off"][edition])
        end
        
        --main playable grid
        for x = 1,4 do
          for y = 4,7 do
            g:led(x,y,led_maps["square_off"][edition])
          end
        end

        --zilchmos
        for x = 5,8 do
          g:led(x,8,zilch_leds[4][bank_64][x-4] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
        end

        for x = 6,8 do
          g:led(x,7,zilch_leds[3][bank_64][x-5] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
        end

        --pattern rec
        local target = grid_pat[bank_64]
        if target.rec == 1 then
          if edition == 3 then
            g:led(8,5,(15*target.led))
          else
            g:led(8,5,(9*target.led))
          end
        elseif (target.quantize == 0 and target.play == 1) or (target.quantize == 1 and target.tightened_start == 1) then
          if target.overdub == 0 then
            g:led(8,5,9)
          else
            g:led(8,5,15)
          end
        elseif target.count > 0 then
          g:led(8,5,5)
        else
          g:led(8,5,3)
        end
        
        --arc rec
        -- local a_p; -- this will index the arc encoder recorders
        -- if arc_param[bank_64] == 1 or arc_param[bank_64] == 2 or arc_param[bank_64] == 3 then
        --   a_p = 1
        -- else
        --   a_p = arc_param[bank_64] - 2
        -- end
        -- if arc_pat[bank_64][a_p].rec == 1 then
        --   g:led(7,8,led_maps["arc_rec_rec"][edition])
        -- elseif arc_pat[bank_64][a_p].play == 1 then
        --   g:led(7,8,led_maps["arc_rec_play"][edition])
        -- elseif arc_pat[bank_64][a_p].count > 0 then
        --   g:led(7,8,led_maps["arc_rec_pause"][edition])
        -- else
        --   g:led(7,8,led_maps["arc_rec_off"][edition])
        -- end
        
        -- arc control
        if a.device ~= nil then
          g:led(6,2,arc_param[bank_64] == 1 and led_maps["arc_param_show"][edition] or 0)
          g:led(7,2,arc_param[bank_64] == 2 and led_maps["arc_param_show"][edition] or 0)
          g:led(8,2,arc_param[bank_64] == 3 and led_maps["arc_param_show"][edition] or 0)
          if arc_param[bank_64] == 4 then
            for x = 6,8 do
              g:led(x,2,led_maps["arc_param_show"][edition])
            end
          elseif arc_param[bank_64] == 5 then
            g:led(6,2,led_maps["arc_param_show"][edition])
            g:led(7,2,led_maps["arc_param_show"][edition])
          elseif arc_param[bank_64] == 6 then
            g:led(7,2,led_maps["arc_param_show"][edition])
            g:led(8,2,led_maps["arc_param_show"][edition])
          end
        end
        
        --4x4 pads
        if bank[bank_64].focus_hold == false then
          local x_64 = (9-selected[bank_64].y)
          local y_64 = selected[bank_64].x - (5*(bank_64-1))
          g:led(x_64, y_64+3, led_maps["square_selected"][edition])
          if bank[bank_64][bank[bank_64].id].pause == true then
            g:led(8,6,led_maps["pad_pause"][edition])
            g:led(7,6,led_maps["pad_pause"][edition])
          else
            g:led(7,6,zilch_leds[2][bank_64][1] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
            g:led(8,6,zilch_leds[2][bank_64][2] == 1 and led_maps["zilchmo_on"][edition] or led_maps["zilchmo_off"][edition])
          end
        else
          local x_64 = (9-selected[bank_64].y)
          local y_64 = selected[bank_64].x - (5*(bank_64-1))
          local focus_x_64 = bank[bank_64].focus_pad - (4*(math.ceil(bank[bank_64].focus_pad/4)-1))
          local focus_y_64 = math.ceil(bank[bank_64].focus_pad/4)
          g:led(x_64, y_64+3, led_maps["square_dim"][edition])
          g:led(focus_x_64, focus_y_64+3, led_maps["square_selected"][edition])
          if bank[bank_64][bank[bank_64].focus_pad].pause == true then
            g:led(8,6,led_maps["square_selected"][edition])
            g:led(7,6,led_maps["square_selected"][edition])
          else
            g:led(7,6,led_maps["square_off"][edition])
            g:led(8,6,led_maps["square_off"][edition])
          end
        end
        
        -- crow pad execute
        if bank[bank_64].focus_hold then
          g:led(5,7,(10*bank[bank_64][bank[bank_64].focus_pad].crow_pad_execute)+5)
        end
        local alt = bank[bank_64].alt_lock and 1 or 0
        g:led(4,8,15*alt)
        
        -- for i,e in pairs(lit) do
        --   g:led(e.x, e.y,led_maps["zilchmo_on"][edition])
        -- end
        
        --alt
        g:led(1,8,(grid_alt and led_maps["alt_on"][edition] or led_maps["alt_off"][edition]))
          
        local focused = bank[bank_64].focus_hold == false and bank[bank_64][bank[bank_64].id] or bank[bank_64][bank[bank_64].focus_pad]
        --clips + stuff
        g:led(focused.clip+4,4,led_maps["clip"][edition])
        g:led(focused.mode+4,5,led_maps["mode"][edition])
        g:led(8,4,bank[bank_64].focus_hold == false and led_maps["off"][edition] or led_maps["focus_on"][edition])
        if focused.loop == false then
          g:led(5,6,led_maps["loop_off"][edition])
        elseif focused.loop == true then
          g:led(5,6,led_maps["loop_on"][edition])
        end
        if not arp[bank_64].enabled then
          g:led(6,6,led_maps["off"][edition])
        else
          if arp[bank_64].playing and arp[bank_64].hold then
            g:led(6,6,led_maps["arp_play"][edition])
          elseif arp[bank_64].hold then
            g:led(6,6,led_maps["arp_pause"][edition])
          else
            g:led(6,6,led_maps["arp_on"][edition])
          end
        end
        
        -- Live buffers
        if rec[rec.focus].clear == 0 then
          g:led(rec.focus,2,rec[rec.focus].state == 1 and led_maps["live_rec"][edition] or (rec[rec.focus].queued and 15 or led_maps["live_pause"][edition]))
        elseif rec[rec.focus].clear == 1 then
          g:led(rec.focus,2,rec[rec.focus].queued and 9 or led_maps["live_empty"][edition])
        end
      
      elseif grid_page_64 == 1 then

        -- delay page!
        for i = 1,5 do
          g:led(8,i+2,delay[2].selected_bundle == i and 15 or (delay_bundle[2][i].saved == true and led_maps["bundle_saved"][edition] or 0))
          g:led(1,i+2,delay[1].selected_bundle == i and 15 or (delay_bundle[1][i].saved == true and led_maps["bundle_saved"][edition] or 0))
        end

        for i = 1,3 do
          g:led(2,i,bank[i][bank[i].id].left_delay_level > 0 and led_maps["64_bank_send"][edition] or 0)
          g:led(7,i,bank[i][bank[i].id].right_delay_level > 0 and led_maps["64_bank_send"][edition] or 0)
        end

        g:led(2,4,params:get("delay L: external input") > 0 and led_maps["64_bank_send"][edition] or 0)
        g:led(7,4,params:get("delay R: external input") > 0 and led_maps["64_bank_send"][edition] or 0)

        -- delay time modifiers
        local time_to_led = {{},{},{},{}}
        local time = {delay[1].modifier, delay[2].modifier}
        for i = 1,2 do
          time_to_led[i] = 0
          time_to_led[i+2] = 0
          if time[i] == 0.5 then
            time_to_led[i+2] = led_maps["time_to_led.5"][edition]
          elseif time[i] == 0.25 then
            time_to_led[i+2] = led_maps["time_to_led.25"][edition]
          elseif time[i] == 0.125 then
            time_to_led[i+2] = led_maps["time_to_led.125"][edition]
          elseif time[i] == 2 then
            time_to_led[i] = led_maps["time_to_led2"][edition]
          elseif time[i] == 4 then
            time_to_led[i] = led_maps["time_to_led4"][edition]
          elseif time[i] == 8 then
            time_to_led[i] = led_maps["time_to_led8"][edition]
          elseif time[i] == 16 then
            time_to_led[i] = led_maps["time_to_led16"][edition]
          end
        end
        g:led(6,1,time_to_led[2])
        g:led(6,2,time_to_led[4])
        g:led(3,1,time_to_led[1])
        g:led(3,2,time_to_led[3])
        g:led(6,3,delay[2].reverse and led_maps["reverse_on"][edition] or led_maps["reverse_off"][edition])
        g:led(3,3,delay[1].reverse and led_maps["reverse_on"][edition] or led_maps["reverse_off"][edition])

        rate_to_led = {{},{},{},{}}
        local rate = {params:get("delay L: rate"), params:get("delay R: rate")}
        for i = 1,2 do
          rate_to_led[i] = 0
          rate_to_led[i+2] = 0
          for j = 1,24 do
            if math.modf(rate[i]) >= j then
              rate_to_led[i] = math.modf(util.linlin(0,24,3,15,j))
            end
          end
          for j = 0.25,1,0.05 do
            if rate[i] >= j then
              rate_to_led[i+2] = math.modf(util.linlin(0.25,1,15,0,j))
            end
          end
          if rate[i] == 1 then
            rate_to_led[i+2] = 3
          end
        end
        g:led(5,1,rate_to_led[2])
        g:led(5,2,rate_to_led[4])
        g:led(5,3,delay[2].wobble_hold and led_maps["wobble_on"][edition] or led_maps["wobble_off"][edition])
        g:led(4,1,rate_to_led[1])
        g:led(4,2,rate_to_led[3])
        g:led(4,3,delay[1].wobble_hold and led_maps["wobble_on"][edition] or led_maps["wobble_off"][edition])
        
        -- delay levels
        local level_to_led = {{},{}}
        local delay_level = {params:get("delay L: global level"), params:get("delay R: global level")}
        for i = 1,2 do
          if delay_level[i] <= 0.125 then
            level_to_led[i] = 0
          elseif delay_level[i] <= 0.375 then
            level_to_led[i] = 1
          elseif delay_level[i] <= 0.625 then
            level_to_led[i] = 2
          elseif delay_level[i] <= 0.875 then
            level_to_led[i] = 3
          elseif delay_level[i] <= 1 then
            level_to_led[i] = 4
          end
        end
        for i = 8,4,-1 do
          g:led(3,i,led_maps["level_lo"][edition])
          g:led(6,i,led_maps["level_lo"][edition])
        end
        for i = 1,2 do
          if not delay[i].level_mute then
            for j = 8,4+(4-level_to_led[i]),-1 do
              g:led(i==1 and 3 or 6,j,led_maps["level_hi"][edition])
            end
          else
            if params:get(i == 1 and "delay L: global level" or "delay R: global level") == 0 then
              for j = 8,4,-1 do
                g:led(i==1 and 3 or 6,j,led_maps["level_hi"][edition])
              end
            end
          end
        end

        -- feedback levels
        local feed_to_led = {{},{}}
        local feedback_level = {params:get("delay L: feedback"), params:get("delay R: feedback")}
        for i = 1,2 do
          if feedback_level[i] <= 12.5 then
            feed_to_led[i] = 0
          elseif feedback_level[i] <= 37.5 then
            feed_to_led[i] = 1
          elseif feedback_level[i] <= 62.5 then
            feed_to_led[i] = 2
          elseif feedback_level[i] <= 87.5 then
            feed_to_led[i] = 3
          elseif feedback_level[i] <= 100 then
            feed_to_led[i] = 4
          end
        end
        for i = 8,4,-1 do
          g:led(4,i,led_maps["level_lo"][edition])
          g:led(5,i,led_maps["level_lo"][edition])
        end
        for i = 1,2 do
          if not delay[i].feedback_mute then
            for j = 8,4+(4-feed_to_led[i]),-1 do
              g:led(i==1 and 4 or 5,j,led_maps["level_hi"][edition])
            end
          else
            if params:get(i == 1 and "delay L: feedback" or "delay R: feedback") == 0 then
              for j = 8,4,-1 do
                g:led(i==1 and 4 or 5,j,led_maps["level_hi"][edition])
              end
            end
          end
        end
        g:led(1,8,(grid_alt and led_maps["alt_on"][edition] or led_maps["alt_off"][edition]))

      elseif grid_page_64 == 2 then
        for i = 1,8 do
          for j = 1,3 do
            if pattern_saver[j].saved[i] == 1 then
              if params:string("LED_style") == "grayscale" then
                g:led(i,j+1,15)
              else
                g:led(i,j+1,8)
              end
            else
              g:led(i,j+1,4)
            end
            if pattern_saver[j].load_slot == i then
              if params:string("LED_style") == "grayscale" then
                g:led(i,j+1,show_me_grid_blink and 15 or 0)
              else
                g:led(i,j+1,15)
              end
            end
          end
        end
        g:led(1,8,(grid_alt and led_maps["alt_on"][edition] or led_maps["alt_off"][edition]))
        for i = 1,3 do
          g:led(i,6,params:get("bank level "..i) > 0 and 15 or 0)
        end
      end
      
      g:refresh()
    end
  end
end
--/GRID

function grid_pattern_execute(entry)
  if entry ~= nil then
    if entry ~= "pause" then
      local i = entry.i
      local a_p; -- this will index the arc encoder recorders
        if arc_param[i] == 1 or arc_param[i] == 2 or arc_param[i] == 3 then
          a_p = 1
        else
          a_p = arc_param[i] - 2
        end
      if entry.action == "pads" then
        if params:get("zilchmo_patterning") == 2 then
          bank[i][entry.id].rate = entry.rate
        end
        selected[i].id = entry.id
        selected[i].x = entry.x
        selected[i].y = entry.y
        bank[i].id = selected[i].id
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
        if rytm.track[i].k == 0 then
          -- cheat(i,bank[i].id)
          if bank[i].quantize_press == 0 then
            cheat(i, bank[i].id)
          else
            quantize_events[i] = {["bank"] = i, ["pad"] = bank[i].id}
          end
        end
      elseif string.match(entry.action, "zilchmo") then
        if params:get("zilchmo_patterning") == 2 then
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
      bank[id][which_pad].start_point = (entry.start_point + (8*(bank[id][which_pad].clip-1)) + arc_offset)
      bank[id][which_pad].end_point = (entry.end_point + (8*(bank[id][which_pad].clip-1)) + arc_offset)
      if bank[id].id == which_pad then
        softcut.loop_start(id+1, (entry.start_point + (8*(bank[id][which_pad].clip-1))) + arc_offset)
        softcut.loop_end(id+1, (entry.end_point + (8*(bank[id][which_pad].clip-1))) + arc_offset)
      end
    elseif entry.param == 5 then
      bank[id][which_pad].level = (entry.level + arc_offset)
      bank[id].global_level = (entry.global_level + arc_offset)
      if bank[id].id == which_pad then
        softcut.level(id+1, (entry.level + arc_offset)*bank[id].global_level)
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
  lit = {}
  -- grid_redraw()
  grid_dirty = true
  if menu ~= 1 then screen_dirty = true end
end

function pad_copy(destination, source)
  for k,v in pairs(source) do
    if k ~= bank_id and k ~= pad_id then
      destination[k] = v
    end
  end
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

    local duration = bank[i][which_pad].mode == 1 and 8 or clip[bank[i][which_pad].clip].sample_length
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
      local tilt_to_led = slew_counter[i].slewedVal
      if bank[i].focus_hold == true then
        which_pad = bank[i].focus_pad
        tilt_to_led = bank[i][bank[i].focus_pad].tilt
      else
        which_pad = bank[i].id
      end
      if tilt_to_led == nil then
        tilt_to_led = bank[i][which_pad].tilt
        a:led(which_enc,47,5)
        a:led(which_enc,48,10)
        a:led(which_enc,49,15)
        a:led(which_enc,50,10)
        a:led(which_enc,51,5)
      elseif tilt_to_led >= -0.04 and tilt_to_led <=0.20 then
        a:led(which_enc,47,5)
        a:led(which_enc,48,10)
        a:led(which_enc,49,15)
        a:led(which_enc,50,10)
        a:led(which_enc,51,5)
      elseif tilt_to_led < -0.04 then
        a:segment(which_enc, tau*(1/4), util.linlin(-1, 1, (tau*(1/4))+0.1, tau*1.249999, tilt_to_led), 15)
      elseif tilt_to_led > 0.20 then
        a:segment(which_enc, util.linlin(-1, 1, (tau*(1/4)), (tau*1.24)+0.4, tilt_to_led-0.1), tau*(1/4)+0.1, 15)
      end
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
  local dirname = _path.data.."cheat_codes_2/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local file = io.open(_path.data.. "cheat_codes_2/persistent_state.data", "w+")
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
  end
  for i = 1,3 do
    io.write("start_arp_"..i.."_at_launch: "..params:get("start_arp_"..i.."_at_launch").."\n")
  end
  for i = 1,3 do
    io.write(i.."_pad_to_crow_v-8: "..params:get(i.."_pad_to_crow_v-8").."\n")
    io.write(i.."_pad_to_crow_pulse: "..params:get(i.."_pad_to_crow_pulse").."\n")
    io.write(i.."_pad_to_jf_pulse: "..params:get(i.."_pad_to_jf_pulse").."\n")
  end
  io.write("touchosc_echo: "..params:get("touchosc_echo").."\n")
  io.write("arc_size: "..params:get("arc_size").."\n")
  for i = 1,3 do
    io.write("pattern_"..i.."_quantization: "..params:get("pattern_"..i.."_quantization").."\n")
  end
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
  all_loaded = false
  local file = io.open(_path.data .. "cheat_codes_2/persistent_state.data", "r")
  if file then
    io.input(file)
    for i = 1,count_lines_in(_path.data.. "cheat_codes_2/persistent_state.data") do
      local s = io.read()
      local param,val = s:match("(.+): (.+)")
      params:set(param,tonumber(val))
    end
    io.close(file)
  end
  all_loaded = true
  mc.init()
  -- clock.run(
  --   function()
  --     clock.sleep(1)
  --     if (params:string("start_transport_at_launch") == "yes" and params:string("clock_source") == "internal") then
  --       clock.transport.start()
  --     end
  --   end
  -- )
  if params:get("cut_input_adc") == -inf then
    params:set("cut_input_adc",0)
  end
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
  if text ~= nil then
    local name_filepath = _path.data.."cheat_codes_2/names/"
    existing_names = {}
    for i in io.popen("ls "..name_filepath):lines() do
      if string.find(i,"%.cc2$") then table.insert(existing_names,name_filepath..i) end
    end
    local concat = ""
    for word in string.gmatch(text, "%S+") do
      if concat == "" then
        concat = word
      else
        concat = (concat.."-"..word)
      end
    end
    text = concat
    if text ~= 'cancel' and text ~= nil and not tab.contains(existing_names,"/home/we/dust/data/cheat_codes_2/names/"..text..".cc2") then
      print("attempting to save collection '"..text.."'")
      collection_save_clock = clock.run(save_screen,text)
      _norns.key(1,1)
      _norns.key(1,0)
    elseif text == 'cancel' or text == nil then
      print("canceled, nothing saved")
    elseif tab.contains(existing_names,"/home/we/dust/data/cheat_codes_2/names/"..text..".cc2") then
      print(text.." already used, will not overwrite")
      clock.run(save_fail_screen,text)
      _norns.key(1,1)
      _norns.key(1,0)
    end
  end
end

function named_savestate(text)
  save_fail_state = false
  local collection = text
  local dirname = _path.data.."cheat_codes_2/"
  -- local collection = tonumber(string.format("%.0f",params:get("collection")))
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  local dirname = _path.data.."cheat_codes_2/names/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local name_file = io.open(_path.data .. "cheat_codes_2/names/"..collection..".cc2", "w+")
  if name_file then
    io.output(name_file)
    io.write(collection)
    io.close(name_file)
  
    local dirname = _path.data.."cheat_codes_2/collection-"..collection.."/"
    if os.rename(dirname, dirname) == nil then
      os.execute("mkdir " .. dirname)
    end

    local dirnames = {"banks/","params/","arc-rec/","patterns/","step-seq/","arps/","euclid/","rnd/","delays/","rec/","misc/","midi_output_maps/","macros/","cursors/"}
    for i = 1,#dirnames do
      local directory = _path.data.."cheat_codes_2/collection-"..collection.."/"..dirnames[i]
      if os.rename(directory, directory) == nil then
        os.execute("mkdir " .. directory)
      end
    end

    for i = 1,3 do
      tab.save(bank[i],_path.data .. "cheat_codes_2/collection-"..collection.."/banks/"..i..".data")
      tab.save(step_seq[i],_path.data .. "cheat_codes_2/collection-"..collection.."/step-seq/"..i..".data")
      tab.save(arp[i],_path.data .. "cheat_codes_2/collection-"..collection.."/arps/"..i..".data")
      tab.save(rytm.track[i],_path.data .. "cheat_codes_2/collection-"..collection.."/euclid/euclid"..i..".data")
      tab.save(rnd[i],_path.data .. "cheat_codes_2/collection-"..collection.."/rnd/"..i..".data")
      if params:get("collect_live") == 2 then
        collect_samples(i,collection)
      end
    end

    for i = 1,2 do
      tab.save(delay[i],_path.data .. "cheat_codes_2/collection-"..collection.."/delays/delay"..(i == 1 and "L" or "R")..".data")
      tab.save(delay_bundle[i],_path.data .. "cheat_codes_2/collection-"..collection.."/delays/delay_bundle"..(i == 1 and "L" or "R")..".data")
    end
    tab.save(delay_links,_path.data .. "cheat_codes_2/collection-"..collection.."/delays/delay-links.data")
    
    params:write(_path.data.."cheat_codes_2/collection-"..collection.."/params/all.pset")
    
    -- ultimately, i'll want to remember the mappings of specific devices for specific collections...
    -- norns.pmap.rev[dev][ch][cc]
    -- dev = vport ID...
    -- so, see if there are any mappings and if not then ignore that shit...
    -- otherwise, grab the device name
    -- if the device is present, then the mapping can restore
    -- if not, fuck it.
    -- might also need to `norns.pmap.assign(name,m.dev,m.ch,m.cc)`

    mc.write_mappings(collection)

    tab.save(rec,_path.data .. "cheat_codes_2/collection-"..collection.."/rec/rec[rec.focus].data")

    -- GRID pattern save
    if selected_coll ~= collection then
      meta_copy_coll(selected_coll,collection)
    end
    meta_shadow(collection)

    selected_coll = collection
    --/ GRID pattern save

    -- MIDI pattern save
    for i = 1,3 do
      save_midi_pattern(i)
    end
    
    -- local check_file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/midi3.data", "w+")
    local check_file = util.file_exists(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/midi3.data")
    if not check_file then
      save_fail_state = true
      goto failed_save
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
        local file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/arc-rec/encoder-"..i..".data", "r")
        if file then
          io.input(file)
          os.remove(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/arc-rec/encoder-"..i..".data")
          io.close(file)
        end
      end
    end
    --/ ARC rec save

    -- misc save
    local file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/misc/misc.data", "w+")
    if file then
      io.output(file)
      io.write("clock_tempo: "..params:get("clock_tempo").."\n")
      for i = 1,3 do
        io.write("pattern_"..i.."_playmode: "..grid_pat[i].playmode.."\n")
        io.write("pattern_"..i.."_rec_clock_time: "..grid_pat[i].rec_clock_time.."\n")
      end
      io.close(file)
    end

    for i = 1,3 do
      local directory = _path.data.."cheat_codes_2/collection-"..selected_coll.."/midi_output_maps/bank_"..i.."/"
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
        local mc_filepath = _path.data .. "cheat_codes_2/collection-"..selected_coll.."/midi_output_maps/bank_"..i.."/"..mc_tables[j]..".data"
        local file = io.open(mc_filepath, "w+")
        if file then
          io.output(file)
          tab.save(mc[mc_tables[j]][i].entries,mc_filepath)
          io.close(file)
        end
      end
    end

    for i = 1,8 do
      local macro_filepath = _path.data .. "cheat_codes_2/collection-"..selected_coll.."/macros/"..i..".data"
      local file = io.open(macro_filepath, "w+")
      if file then
        io.output(file)
        tab.save(macro[i].params,macro_filepath)
        io.close(file)
      end
    end

    for i = 1,3 do
      local cursor_filepath = _path.data .. "cheat_codes_2/collection-"..selected_coll.."/cursors/"..i..".data"
      local file = io.open(cursor_filepath, "w+")
      if file then
        io.output(file)
        tab.save(cursors[i],cursor_filepath)
        io.close(file)
      end
    end

  else
    -- print("bad name, runnign cannpt save from named_savestate")
    save_fail_state = true
    clock.run(cannot_save_screen,text)
    _norns.key(1,1)
    _norns.key(1,0)
  end
  ::failed_save::
  if save_fail_state then
    -- print("should delete file")
    local name_filepath = _path.data.."cheat_codes_2/names/"
    existing_names = {}
    for i in io.popen("ls "..name_filepath):lines() do
      if string.find(i,"%.cc2$") then table.insert(existing_names,name_filepath..i) end
    end
    if tab.contains(existing_names,'/home/we/dust/data/cheat_codes_2/names/'..text..'.cc2') then
      table.remove(existing_names,tab.key(existing_names,'/home/we/dust/data/cheat_codes_2/names/'..text..'.cc2'))
      if util.file_exists(_path.data .. 'cheat_codes_2/names/'..text..'.cc2') then
        -- print("deleting name file")
        os.remove(_path.data .. 'cheat_codes_2/names/'..text..'.cc2')
      end
      -- print(bad_file)
    end
    local bad_file = util.file_exists(_path.data.."cheat_codes_2/collection-"..text.."/")
    if bad_file then
      print("removing associated collection folder for misformatted name")
      os.remove(_path.data.."cheat_codes_2/collection-"..text.."/")
    end
  end
  --/ midi_output_maps save

end

function fix_all_the_bad_names(path,collection)

  local filename = _path.data.."cheat_codes_2/collection-"..collection.."/params/all.pset"

  local function unquote(s)
    return s:gsub('^"', ''):gsub('"$', ''):gsub('\\"', '"')
  end

  local fd = io.open(filename, "r")
  if fd then
    io.close(fd)
    already_assigned = {}
    for line in io.lines(filename) do
      local id, value = string.match(line, "(\".-\")%s*:%s*(.*)")
      if id and value then
        id = unquote(id)
        local index = params.lookup[id]
        if already_assigned[id] == nil then
          if index and params.params[index] then
            if tonumber(value) ~= nil then
              params.params[index]:set(tonumber(value), silent)
            elseif value == "-inf" then
              params.params[index]:set(-math.huge, silent)
            elseif value == "inf" then
              params.params[index]:set(math.huge, silent)
            elseif value then
              params.params[index]:set(value, silent)
            end
            already_assigned[id] = true
          end
        end
      end
    end
  end

  -- params:read(_path.data.."cheat_codes_2/collection-"..collection.."/params/all.pset")

end

function named_loadstate(path)
  local file = io.open(path, "r")
  if file then
    actively_loading_collection = true
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
    reset_all_banks(bank)
    print(path)
    io.input(file)
    local collection = io.read()
    io.close(file)
    selected_coll = collection
    collection_loaded = true
    if collection == "DEFAULT" then
      clock.run(default_load_screen)
    else
      clock.run(load_screen)
    end
    _norns.key(1,1)
    _norns.key(1,0)
    screen_dirty = true
    -- all_loaded = false
    fix_all_the_bad_names(path,collection)
    -- persistent_state_restore()
    if tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/rec/rec[rec.focus].data") ~= nil then
      rec = tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/rec/rec[rec.focus].data")
      if rec.stopped == nil then rec.stopped = false end
      if rec.play_segment == nil then rec.play_segment = rec.focus end
      softcut.loop_start(1,rec[rec.focus].start_point)
      softcut.loop_end(1,rec[rec.focus].end_point-0.01)
      for i = 1,3 do
        rec[i].last_purged = 0
      end
      if rec[rec.focus].state == 1 then
        rec[rec.focus].state = 0
      end
    end
    for i = 1,3 do
      if tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/banks/"..i..".data") ~= nil then
        bank[i] = tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/banks/"..i..".data")
        if bank[i][bank[i].id].loop then
          softcut.loop(i+1,1)
          cheat(i,bank[i].id)
        end
      end
      if tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/step-seq/"..i..".data") ~= nil then
        step_seq[i] = tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/step-seq/"..i..".data")
      end
      if tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/arps/"..i..".data") ~= nil then
        arp[i] = tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/arps/"..i..".data")
      end
      for j = 1,#rnd[i] do
        rnd[i][j].lattice:destroy()
      end
      if tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/rnd/"..i..".data") ~= nil then
        rnd[i] = tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/rnd/"..i..".data")
        for j = 1,#rnd[i] do
          rnd[i][j].lattice = rnd_lattice:new_sprocket{
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
        if util.file_exists(_path.data .. "cheat_codes_2/collection-"..collection.."/midi_output_maps/bank_"..i.."/"..mc_tables[j]..".data") then
          mc[mc_tables[j]][i].entries = tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/midi_output_maps/bank_"..i.."/"..mc_tables[j]..".data")
        end
      end

      if params:get("collect_live") == 2 then
        reload_collected_samples(_path.dust.."audio/cc2_live-audio/"..collection.."/".."cc2_"..collection.."-"..i..".wav",i)
      end
      
      if util.file_exists(_path.data .. "cheat_codes_2/collection-"..collection.."/euclid/euclid"..i..".data") then
        rytm.track[i] = tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/euclid/euclid"..i..".data")
        if rytm.track[i].runner == nil then rytm.track[i].runner = 0 end
      end
      -- rytm.reset_all_patterns() -- i deactivated this so that a loaded pattern wouldn't auto-start euclid...
      
    end

    arps.restore_collection()
    rytm.restore_collection()

    for i = 1,8 do
      if tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/macros/"..i..".data") ~= nil then
        macro[i].params = tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/macros/"..i..".data")
      end
    end

    for i = 1,2 do
      if tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/delays/delay"..(i == 1 and "L" or "R")..".data") ~= nil then
        delay[i] = tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/delays/delay"..(i == 1 and "L" or "R")..".data")
        if util.file_exists(_path.data .. "cheat_codes_2/collection-"..collection.."/delays/delay_bundle"..(i == 1 and "L" or "R")..".data") then
          delay_bundle[i] = tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/delays/delay_bundle"..(i == 1 and "L" or "R")..".data")
          if delay[i].selected_bundle ~= 0 and delay_bundle[i][delay[i].selected_bundle].saved then
            del.restore_bundle(i,delay[i].selected_bundle)
          end
        end
      end
    end

    if tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/delays/delay-links.data") ~= nil then
      delay_links = tab.load(_path.data .. "cheat_codes_2/collection-"..collection.."/delays/delay-links.data")
    end

    -- GRID pattern restore
    if selected_coll ~= collection then
      meta_shadow(selected_coll)
    elseif selected_coll == collection then
      cleanup("local")
    end
    one_point_two()
    -- / GRID pattern restore

    for i = 1,3 do
      load_arc_pattern(i)
    end

    for i = 1,3 do
      midi_pat[i]:restore_defaults()
      local dirname = _path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/midi"..i..".data"
      if os.rename(dirname, dirname) ~= nil then
        load_midi_pattern(i)
      end
    end

    local file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/misc/misc.data", "r")
    if file then
      io.input(file)
      local number_of_lines = 0
      for lines in file:lines() do
        number_of_lines = number_of_lines+1
      end
      io.close(file)
      file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/misc/misc.data", "r")
      io.input(file)
      if number_of_lines == 1 then
        params:set("clock_tempo", tonumber(string.match(io.read(), ': (.*)')))
      else
        params:set("clock_tempo", tonumber(string.match(io.read(), ': (.*)')))
        for i = 1,3 do
          local playmode = tonumber(string.match(io.read(), ': (.*)'))
          if playmode ~= nil then
            grid_pat[i].playmode = playmode
          end
          local rec_clock_time = tonumber(string.match(io.read(), ': (.*)'))
          if rec_clock_time ~= nil then
            grid_pat[i].rec_clock_time = rec_clock_time
          end
        end
      end
      io.close(file)
      print('loaded')
      actively_loading_collection = false
    end

  else
    _norns.key(1,1)
    _norns.key(1,0)
    collection_loaded = false
    clock.run(load_fail_screen)
  end

  for i = 1,3 do
    local dirname = _path.data .. "cheat_codes_2/collection-"..selected_coll.."/cursors/"..i..".data"
    if os.rename(dirname, dirname) ~= nil then
      cursors[i] = tab.load(dirname)
      if #cursors[i] > 0 then
        params:hide('detect_onsets_'..i)
        params:show('clear_onsets_'..i)
        detecting_onsets_popup = {state = false, percent = nil}
        _menu.rebuild_params()
      end
    end
  end


  ping_midi_devices()
  if file then
    if util.file_exists(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/params/mappings.txt") then
      norns.pmap.rev = tab.load(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/params/mappings.txt")
      print('>>>>'..#norns.pmap.rev)
      if #norns.pmap.rev < 16 then
        print('less than 16')
        for i = #norns.pmap.rev+1,16 do
          norns.pmap.rev[i] = {}
          for j = 1,16 do
            --norns.pmap.rev[dev][ch][cc]
            norns.pmap.rev[i][j] = {}
          end
        end
      end
      norns.pmap.data = tab.load(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/params/map-data.txt")
      print('clearing old mapping files, creating new PMAPs...')
      mc.write_mappings(selected_coll)
      os.execute('rm -r '.._path.data .. "cheat_codes_2/collection-"..selected_coll.."/params/mappings.txt")
      norns.pmap.clear()
      mc.read_mappings(selected_coll)
    else
      print('no prev data file for mapping')
      norns.pmap.clear()
      mc.read_mappings(selected_coll)
    end
  end

  for i = 1,3 do
    clock.run(reset_step_seq,i,4)
  end
    
  if util.file_exists(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/user_script.lua") then
    print("loading user_script.lua")
    local user_script_filepath = (_path.data .. "cheat_codes_2/collection-"..selected_coll.."/user_script.lua")
    user_script = dofile(user_script_filepath)
    if user_script.init then
      user_script.init()
    end
  end

  grid_dirty = true

  -- clock.run(
  --   function()
  --     clock.sleep(1)
  --     if (params:string("start_transport_at_launch") == "yes" and params:string("clock_source") == "internal") then
  --       clock.transport.start()
  --     end
  --   end
  -- )
  -- pre_script_softcut_engine_level = params:get("cut_input_eng")
  audio.level_eng_cut(util.dbamp(-math.huge))
  norns.state.mix.cut_input_eng = -math.huge

end

function reset_step_seq(i,val) -- TODO: funky on some...
  step_seq[i].active = (step_seq[i].active + 1)%2
  step_seq[i].meta_meta_step = 1
  step_seq[i].meta_step = 1
  step_seq[i].current_step = step_seq[i].start_point
  if val~= nil then
    clock.sync(val)
  end
  step_seq[i].active = (step_seq[i].active + 1)%2
  if step_seq[i].active == 1 and step_seq[i][step_seq[i].current_step].assigned_to ~= 0 then
    test_load(step_seq[i][step_seq[i].current_step].assigned_to+(((i)-1)*8),i)
  end
end

function quick_save_pattern(i)
  if (grid_pat[i].count > 0 and grid_pat[i].rec == 0 and grid_pat[i].play == 1) -- if it's playing, then save pattern
  or (grid_pat[i].count > 0 and grid_pat[i].rec == 0 and not arp[i].playing) -- if it's dormant and arp isn't playing, save pattern
  then
    copy_entire_pattern(i)
    save_pattern(i,pattern_saver[i].save_slot+8*(i-1),"pattern")
    pattern_saver[i].saved[pattern_saver[i].save_slot] = 1
    pattern_saver[i].load_slot = pattern_saver[i].save_slot
    if params:string("grid_size") == "128/256" then
      g:led(math.floor((i-1)*5)+1,9-pattern_saver[i].save_slot,15)
    end
    -- g:refresh()
  elseif (#arp[i].notes > 0 and arp[i].playing)
  or (#arp[i].notes > 0 and not arp[i].playing and grid_pat[i].play == 0)
  then
    save_pattern(i,pattern_saver[i].save_slot+8*(i-1),"arp")
    pattern_saver[i].saved[pattern_saver[i].save_slot] = 1
    pattern_saver[i].load_slot = pattern_saver[i].save_slot
    if params:string("grid_size") == "128/256" then
      g:led(math.floor((i-1)*5)+1,9-pattern_saver[i].save_slot,15)
    end
    -- g:refresh()
  else
    print("no pattern data to save")
    if params:string("grid_size") == "128/256" then
      g:led(math.floor((i-1)*5)+1,9-pattern_saver[i].save_slot,0)
    end
    -- g:refresh()
  end
  pattern_saver[i].clock = nil
  grid_dirty = true
end

function quick_delete_pattern(i)
  if pattern_saver[i].saved[pattern_saver[i].save_slot] == 1 then
    delete_pattern(pattern_saver[i].save_slot+8*(i-1))
    pattern_saver[i].saved[pattern_saver[i].save_slot] = 0
    pattern_saver[i].load_slot = 0
  else
    print("no pattern data to delete")
  end
end

function test_save(i)
  clock.sleep(pattern_saver[i].saved[pattern_saver[i].save_slot] == 1 and 0.75 or 0.25)
  pattern_saver[i].active = true
  if pattern_saver[i].active then
    if not grid_alt then
      quick_save_pattern(i)
    else
      quick_delete_pattern(i)
    end
  end
  pattern_saver[i].active = false
end

function test_load(slot,destination,source)
  if pattern_saver[destination].saved[slot-((destination-1)*8)] == 1 then
    if pattern_saver[destination].load_slot ~= slot-((destination-1)*8) then
      pattern_saver[destination].load_slot = slot-((destination-1)*8)
    end

    -- if it isn't a grid press:
    if grid_pat[destination].play == 1 and source ~= "from_grid" then
      grid_pat[destination]:clear()
    elseif arp[destination].playing and source ~= "from_grid" then
      -- arp[destination].pause = true
      -- arp[destination].playing = false
      arps.clear(destination)
    elseif grid_pat[destination].tightened_start == 1 then -- not relevant?
      print("why does this happen? tell dan it happened: 2917107")
      -- grid_pat[destination].tightened_start = 0
      -- grid_pat[destination].step = grid_pat[destination].start_point-1
      -- quantized_grid_pat[destination].current_step = grid_pat[destination].start_point
      -- quantized_grid_pat[destination].sub_step = 1
    end

    if not transport.is_running then
      print("loading while transport is not running")
      load_pattern(slot,destination)
      if type_of_pattern_loaded[destination] == "arp" then
        grid_pat[destination]:clear()
      elseif type_of_pattern_loaded[destination] == "grid" then
        arps.clear(destination)
      end
    else
      -- print("test_load is running...",slot,destination,source,pattern_saver[destination].saved[slot-((destination-1)*8)])
      if source ~= "from_grid" then
        -- print("this hsould load fine...")
        load_pattern(slot,destination)
        if type_of_pattern_loaded[destination] ~= "euclid" then
          start_pattern(grid_pat[destination],"jumpstart")
        end
        -- print("loading "..clock.get_beats())
      elseif params:string("launch_quantization") == "next beat" then
        if source == "from_grid"
        and type_of_pattern_loaded[destination] ~= "arp"
        and type_of_pattern_loaded[destination] ~= "euclid"
        then
          print("going to start grid pattern with delayed load")
          start_pattern(grid_pat[destination],"restart","delayed_load",{slot,destination})
        elseif source == "from_grid" then
          print("dead zone...",type_of_pattern_loaded[destination])
          load_pattern(slot,destination)
          print("starting a pattern!!!", type_of_pattern_loaded[destination])
          if type_of_pattern_loaded[destination] == "grid" then
            if arp[destination].playing then
              arps.toggle("stop",destination)
            end
            grid_pat[destination]:start()
          end
        end
      elseif params:string("launch_quantization") == "free" then
        if grid_pat[destination].play == 1 then
          grid_pat[destination]:clear()
        elseif arp[destination].playing then
          -- arp[destination].pause = true
          -- arp[destination].playing = false
          arps.clear(destination)
        end
        load_pattern(slot,destination)
        start_pattern(grid_pat[destination],"jumpstart")
        goto finish_it_up
      end
      if grid_pat[destination].count > 0 and params:string("launch_quantization") ~= "next bar" then
        if params:string("launch_quantization") == "free" then
          -- print("play it now!!")
          load_pattern(slot,destination)
          start_pattern(grid_pat[destination],"jumpstart")
        end
        -- start_pattern(grid_pat[destination],"restart","delayed_load",{slot,destination})
      elseif params:string("launch_quantization") == "next bar" and source == "from_grid" then
        -- print("loading whatever...")
        start_pattern(grid_pat[destination],"restart","delayed_load",{slot,destination})
      elseif type_of_pattern_loaded[destination] == "arp" then
        print("We've GOT AN ARP")
        if loading_arp_from_grid[destination] ~= nil then
          clock.cancel(loading_arp_from_grid[destination])
        end
        loading_arp_from_grid[destination] = 
        clock.run(
          function()
            clock.sync(1)
            load_pattern(slot,destination)
            if type_of_pattern_loaded[destination] == "arp" then
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
            else
              start_pattern(grid_pat[destination],"jumpstart")
            end
          end
        )
      elseif type_of_pattern_loaded[destination] == "euclid" and source == "from_grid" then
        print("hi euclid!")
        if loading_euclid_from_grid[destination] ~= nil then
          clock.cancel(loading_euclid_from_grid[destination])
        end
        loading_euclid_from_grid[destination] = 
        clock.run(
          function()
            clock.sync(1)
            load_pattern(slot,destination)
            if type_of_pattern_loaded[destination] == "euclid" then
             
            else
              start_pattern(grid_pat[destination],"jumpstart")
            end
          end
        )
      end
    end
  end
  ::finish_it_up::
end

function save_pattern(source,slot,style)

  local dirname = _path.data.."cheat_codes_2/collection-"..selected_coll.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local dirname = _path.data.."cheat_codes_2/collection-"..selected_coll.."/patterns/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  local file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/"..slot..".data", "w+")
  -- local file = io.open(_path.data .. "cheat_codes_2/pattern"..selected_coll.."_"..slot..".data", "w+")
  io.output(file)
  if style == "pattern" then
    io.write("stored pad pattern: collection "..selected_coll.." + slot "..slot.."\n")
    io.write(original_pattern[source].count .. "\n")
    for i = 1,original_pattern[source].count do
      io.write(original_pattern[source].time[i] .. "\n")

      -- new stuff
      if original_pattern[source].event[i] ~= "pause" then
        io.write(original_pattern[source].event[i].id .. "\n")
        io.write(original_pattern[source].event[i].rate .. "\n")
        io.write(tostring(original_pattern[source].event[i].loop) .. "\n")
        if original_pattern[source].event[i].mode ~= nil then
          io.write(original_pattern[source].event[i].mode .. "\n")
        else
          io.write("nil" .. "\n")
        end
        io.write(tostring(original_pattern[source].event[i].pause) .. "\n")
        io.write(original_pattern[source].event[i].start_point .. "\n")
        if original_pattern[source].event[i].clip ~= nil then
          io.write(original_pattern[source].event[i].clip .. "\n")
        else
          io.write("nil" .. "\n")
        end
        io.write(original_pattern[source].event[i].end_point .. "\n")
        if original_pattern[source].event[i].rate_adjusted ~= nil then
          io.write(tostring(original_pattern[source].event[i].rate_adjusted) .. "\n")
        else
          io.write("nil" .. "\n")
        end
        io.write(original_pattern[source].event[i].y .. "\n")
        io.write(original_pattern[source].event[i].x .. "\n")
        io.write(tostring(original_pattern[source].event[i].action) .. "\n")
        io.write(original_pattern[source].event[i].i .. "\n")
        if original_pattern[source].event[i].previous_rate ~= nil then
          io.write(original_pattern[source].event[i].previous_rate .. "\n")
        else
          io.write("nil" .. "\n")
        end
        if original_pattern[source].event[i].row ~=nil then
          io.write(original_pattern[source].event[i].row .. "\n")
        else
          io.write("nil" .. "\n")
        end
        if original_pattern[source].event[i].con ~= nil then
          io.write(original_pattern[source].event[i].con .. "\n")
        else
          io.write("nil" .. "\n")
        end
        if original_pattern[source].event[i].bank ~= nil and #original_pattern[source].event > 0 then
          io.write(original_pattern[source].event[i].bank .. "\n")
        else
          io.write("nil" .. "\n")
        end
      else
        io.write("pause" .. "\n")
      end
    end
    --/new stuff!

    io.write(original_pattern[source].metro.props.time .. "\n")
    io.write(original_pattern[source].prev_time .. "\n")
    io.write("which playmode?" .. "\n")
    io.write(original_pattern[source].playmode .. "\n")
    io.write("start point" .. "\n")
    io.write(original_pattern[source].start_point .. "\n")
    io.write("end point" .. "\n")
    io.write(original_pattern[source].end_point .. "\n")

    --new stuff, quantum and time_beats!
    io.write("cheat codes 2.0" .. "\n")
    for i = 1,original_pattern[source].count do
      io.write(original_pattern[source].quantum[i] .. "\n")
      io.write(original_pattern[source].time_beats[i] .. "\n")
    end
    --/new stuff, quantum and time_beats!

    -- new stuff, quant or unquant + rec_clock_time
    io.write(original_pattern[source].mode.."\n")
    io.write(original_pattern[source].rec_clock_time.."\n")

    io.close(file)
    --GIRAFFE
    --save_external_timing(source,slot)
    --/GIRAFFE
    print("saved pattern "..source.." to slot "..slot)
  elseif style == "arp" then
    arp[source].pad_times = {}
    for i = 1,16 do
      arp[source].pad_times[i] = bank[source][i].arp_time
    end
    tab.save(arp[source],_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/"..slot..".data")
    print("saved arp "..source.." to slot "..slot)
  end
end

function already_saved()
  for i = 1,24 do
    local line_count = 0
    local file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/"..i..".data", "r")
    if file then
      io.input(file)
      for lines in io.lines(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/"..i..".data") do
        line_count = line_count + 1
      end
      if line_count > 0 then
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 1
      else
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 0
        -- print("killing yr file4387")
        os.remove(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/"..i..".data")
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
    local file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/"..i..".data", "r")
    if file then
      io.input(file)
      local current = math.floor((i-1)/8)+1
      io.close(file)
    end
  end
  for i = 1,3 do
    grid_pat[i]:rec_stop()
    grid_pat[i]:stop()
    grid_pat[i].tightened_start = 0
    grid_pat[i]:clear()
    pattern_saver[i].load_slot = 0
  end
end

function clear_zero()
  for i = 1,24 do
    local file = io.open(_path.data .. "cheat_codes_2/collection-0/patterns/"..i..".data", "r")
    if file then
      io.input(file)
      local line_count = 0
      for lines in io.lines(_path.data .. "cheat_codes_2/collection-0/patterns/"..i..".data") do
        line_count = line_count + 1
      end
      if line_count > 0 then
        os.remove(_path.data .. "cheat_codes_2/collection-0/patterns/"..i..".data")
        print("cleared default pattern")
      end
      io.close(file)
    end
  end
end

function delete_pattern(slot)
  local file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/"..slot..".data", "w+")
  io.output(file)
  io.write()
  io.close(file)
  print("deleted pattern from slot "..slot)
end

function copy_pattern_across_coll(read_coll,write_coll,slot)
  print("4610: "..read_coll,write_coll,slot)
  local infile = io.open(_path.data .. "cheat_codes_2/collection-"..read_coll.."/patterns/"..slot..".data", "r")
  local outfile = io.open(_path.data .. "cheat_codes_2/collection-"..write_coll.."/patterns/"..slot..".data", "w+")
  io.output(outfile)
  for line in infile:lines() do
    if line == "stored pad pattern: collection "..read_coll.." + slot "..slot then
      io.write("stored pad pattern: collection "..write_coll.." + slot "..slot.."\n")
    else
      io.write(line.."\n")
    end
  end
  io.close(infile)
  io.close(outfile)
  
end

function shadow_pattern(read_coll,write_coll,slot)
  local infile = io.open(_path.data .. "cheat_codes_2/collection-"..read_coll.."/patterns/"..slot..".data", "r")
  local outfile = io.open(_path.data .. "cheat_codes_2/collection-"..write_coll.."/patterns/shadow-pattern_"..slot..".data", "w+")
  io.output(outfile)
  for line in infile:lines() do
    -- io.write(line.."\n")
    if line == "stored pad pattern: collection "..read_coll.." + slot "..slot then
      io.write("stored pad pattern: collection "..write_coll.." + slot "..slot.."\n")
    else
      io.write(line.."\n")
    end
  end
  io.close(infile)
  io.close(outfile)
end

function meta_shadow(coll)
  for i = 1,3 do
    for j = 1,8 do
      if pattern_saver[i].saved[j] == 1 then
        shadow_pattern(coll,coll,j+(8*(i-1)))
      elseif pattern_saver[i].saved[j] == 0 then
        local file = io.open(_path.data .. "cheat_codes_2/collection-"..coll.."/patterns/shadow-pattern_"..j+(8*(i-1))..".data", "w+")
        if file then
          io.output(file)
          io.write()
          io.close(file)
        end
      end
    end
  end
end

function clear_empty_shadows(coll)
  for i = 1,24 do
    local file = io.open(_path.data .. "cheat_codes_2/collection-"..coll.."/patterns/shadow-pattern_"..i..".data", "r")
    if file then
      io.input(file)
      local line_count = 0
      for lines in io.lines(_path.data .. "cheat_codes_2/collection-"..coll.."/patterns/shadow-pattern_"..i..".data") do
        line_count = line_count + 1
      end
      if line_count > 0 then
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 1
      else
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 0
        os.remove(_path.data .. "cheat_codes_2/collection-"..coll.."/patterns/shadow-pattern_"..i..".data")
      end
      io.close(file)
    else
      local current = math.floor((i-1)/8)+1
      pattern_saver[current].saved[i-(8*(current-1))] = 0
    end
  end
end

function shadow_to_play(coll,slot)
  local infile = io.open(_path.data .. "cheat_codes_2/collection-"..coll.."/patterns/shadow-pattern_"..slot..".data", "r")
  local outfile = io.open(_path.data .. "cheat_codes_2/collection-"..coll.."/patterns/"..slot..".data", "w+")
  io.output(outfile)
  if infile then
    for line in infile:lines() do
      if line == "stored pad pattern: collection "..coll.." + slot "..slot then
        io.write("stored pad pattern: collection "..coll.." + slot "..slot.."\n")
      else
        io.write(line.."\n")
      end
    end
    io.close(infile)
    io.close(outfile)
  end
end

function meta_copy_coll(read_coll,write_coll)
  for i = 1,3 do
    for j = 1,8 do
      if pattern_saver[i].saved[j] == 1 then
        copy_pattern_across_coll(read_coll,write_coll,j+(8*(i-1)))
      elseif pattern_saver[i].saved[j] == 0 then
        local file = io.open(_path.data .. "cheat_codes_2/collection-"..write_coll.."/patterns/"..j+(8*(i-1))..".data", "w+")
        if file then
          io.output(file)
          io.write()
          io.close(file)
        end        
      end
    end
  end
end

function load_pattern(slot,destination,print_also)
  if print_also then
    print(print_also,slot,destination)
  end
  local ignore_external_timing = false
  local file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/"..slot..".data", "r")
  if file then
    io.input(file)
    if io.read() == "stored pad pattern: collection "..selected_coll.." + slot "..slot then
      -- print("loading grid pat")
      type_of_pattern_loaded[destination] = "grid"
      grid_pat[destination].event = {}
      grid_pat[destination].count = tonumber(io.read())
      for i = 1,grid_pat[destination].count do
        grid_pat[destination].time[i] = tonumber(io.read())

        -- new stuff
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
          --grid_pat[destination].event[i].id = tonumber(io.read())
          -- new stuff
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

      --new stuff, quantum and time_beats!
      if io.read() == "cheat codes 2.0" then
        for i = 1,grid_pat[destination].count do
          grid_pat[destination].quantum[i] = tonumber(io.read())
          grid_pat[destination].time_beats[i] = tonumber(io.read())
        end
        grid_pat[destination].mode = io.read()
        grid_pat[destination].rec_clock_time = tonumber(io.read())
        ignore_external_timing = true
      end
      --/new stuff, quantum and time_beats!
    else
      type_of_pattern_loaded[destination] = "arp"
      -- print("it's an arp!")
      arp[destination] = tab.load(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/"..slot..".data")
      if arp[destination].pad_times ~= nil then
        for i = 1,#arp[destination].pad_times do
          bank[destination][i].arp_time = arp[destination].pad_times[i]
        end
      else
        for i = 1,16 do
          bank[destination][i].arp_time = arp[destination].time
        end
      end
      -- arp[destination].pause = true
      -- arp[destination].playing = false
      -- arp[destination] = tab.load(_path.data .. "cheat_codes_2/pattern"..selected_coll.."_"..slot..".data")
      ignore_external_timing = true
    end

    if type_of_pattern_loaded[destination] == "grid" then
      print("loading up a grid pattern")
    elseif type_of_pattern_loaded[destination] == "arp" then
      print("loading up an arp!")
      if grid_pat[destination].play == 1 then
        print("stopping pattern!")
        stop_pattern(grid_pat[destination])
        -- grid_pat[destination]:clear()
      end
    end


    io.close(file)
    if not ignore_external_timing then
      print("see load_external_timing")
      -- load_external_timing(destination,slot)
    end
  else
    print("no grid patterns to load!")
  end
end

function cleanup(is_local)

  if is_local == nil then
    metro[31].time = 0.25
    print("cleaning up")
  end

  for i = 1,3 do
    env_counter[i]:stop()
  end

  clear_zero()
  for i = 1,3 do
    for j = 1,8 do
      shadow_to_play(selected_coll,j+(8*(i-1)))
    end
  end
  
  --need all this to just happen at cleanup after save
  for i = 1,24 do
    local file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/"..i..".data", "r")
    if file then
      io.input(file)
      local line_count = 0
      for lines in io.lines(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/"..i..".data") do
        line_count = line_count + 1
      end
      if line_count > 0 then
          local current = math.floor((i-1)/8)+1
          pattern_saver[current].saved[i-(8*(current-1))] = 1
      else
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 0
        os.remove(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/"..i..".data")
      end
      io.close(file)
    else
      local current = math.floor((i-1)/8)+1
      pattern_saver[current].saved[i-(8*(current-1))] = 0
    end
  end
  clear_empty_shadows(selected_coll)

end

-- arc pattern stuff!

function save_arc_pattern(which)
  local file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/arc-rec/encoder-"..which..".data", "w+")
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
  local file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/arc-rec/encoder-"..which..".data", "r")
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
  local file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/midi"..which..".data", "w+")
  if file then
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
  else
    if which == 3 then
      -- print("BAD FILENAME"..which)
      if not save_fail_state then
        save_fail_state = true
        -- print("running cannot save from midi file creaiton")
        clock.run(cannot_save_screen,text)
        _norns.key(1,1)
        _norns.key(1,0)
      end
    end
  end
end

function load_midi_pattern(which)
  local file = io.open(_path.data .. "cheat_codes_2/collection-"..selected_coll.."/patterns/midi"..which..".data", "r")
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
