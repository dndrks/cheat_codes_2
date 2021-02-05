local transport = {}

local tp = transport

transport.vars = {["midi_transport_out"] = {}, ["midi_transport_in"] = {}}
for i = 1,16 do
  tp.vars.midi_transport_out[i] = false
  tp.vars.midi_transport_in[i] = false
end
transport.cycle = 0
transport.pending = false
transport.tap_tempo_index = 1
transport.tap_tempo_table = {}

function tp.init()
  local vports = {}
  local function refresh_params_vports()
    for i = 1,#midi.vports do
      vports[i] = midi.vports[i].name ~= "none" and (util.trim_string_to_width(midi.vports[i].name,90)) or tostring(i)..": [device]"
    end
  end
  refresh_params_vports()
  params:add_group("transport settings",42)
  params:add_separator("auto-start")
  params:add_option("start_transport_at_launch", "start at launch?",{"no","yes"},2)
  -- params:set_action("start_transport_at_launch", function()
  --   if all_loaded then
  --     persistent_state_save()
  --   end
  -- end)
  local banks = {"a","b","c"}
  for i = 1,3 do
    params:add_option("start_arp_"..i.."_at_launch", "auto-start arp "..banks[i].."?",{"no","yes"},2)
  end
  for i = 1,3 do
    params:add_option("start_pat_"..i.."_at_launch", "auto-start pat "..banks[i].."?",{"no","yes"},2)
  end
  params:add_separator("send MIDI transport?")
  for i = 1,16 do
    params:add_option("port_"..i.."_start_stop_out", vports[i],{"no","yes"},1)
    params:set_action("port_"..i.."_start_stop_out", function(x)
      -- if all_loaded then
      --   persistent_state_save()
      -- end
      -- table.insert(tp.vars.midi_transport_out,i)
      if x == 1 then
        tp.vars.midi_transport_out[i] = false
      else
        tp.vars.midi_transport_out[i] = true
      end
      if x == 2 and params:get("port_"..i.."_start_stop_in") == 2 then
        params:set("port_"..i.."_start_stop_in", 1)
      end
    end)
  end
  params:add_separator("receive MIDI transport?")
  for i = 1,16 do
    params:add_option("port_"..i.."_start_stop_in", vports[i],{"no","yes"},1)
    params:set_action("port_"..i.."_start_stop_in", function(x)
      -- if all_loaded then
      --   persistent_state_save()
      -- end
      if x == 1 then
        tp.vars.midi_transport_in[i] = false
      else
        tp.vars.midi_transport_in[i] = true
      end
      if x == 2 and params:get("port_"..i.."_start_stop_out") == 2 then
        params:set("port_"..i.."_start_stop_out", 1)
      end
    end)
  end

  tp.status_icon = UI.PlaybackIcon.new(32, 32, 15, 1)

  tp.is_running = false -- will want this initialized as false eventually

end

function tp.start()
  -- set stuff to 1 and start them
  clock.sync(4)
  -- print("starting at "..clock.get_beats())
  tp.is_running = true
  transport.status_icon.status = 4
  for i = 1,3 do
    if #arp[i].notes > 0 and params:string("start_arp_"..i.."_at_launch") == "yes" then
      arps.toggle("start",i)
    end
    if #grid_pat[i].event > 0 and params:string("start_pat_"..i.."_at_launch") == "yes" then
      grid_pat[i]:start()
    end
    toggle_meta("start",i)
    -- print(clock.get_beats())
  end
  rytm.toggle("start")
  tp.start_midi()
  grid_dirty = true
  tp.start_clock = nil
  tp.pending = false
end

function tp.start_from_midi_message()
  -- print("starting at "..clock.get_beats())
  tp.is_running = true
  transport.status_icon.status = 4
  for i = 1,3 do
    if #arp[i].notes > 0 and params:string("start_arp_"..i.."_at_launch") == "yes" then
      arps.toggle("start",i)
    end
    if #grid_pat[i].event > 0 then
      grid_pat[i]:start()
    end
    toggle_meta("stop",i)
    -- print(clock.get_beats())
  end
  rytm.toggle("start")
  grid_dirty = true
  tp.start_clock = nil
  tp.pending = false
end

function tp.start_midi()
  if params:string("clock_source") ~= "midi" then
    for k,v in pairs(tp.vars.midi_transport_out) do
      if v == true then
        midi_dev[k]:start()
      end
    end
  end
end

function tp.stop_midi()
  if params:string("clock_source") ~= "midi" then
    for k,v in pairs(tp.vars.midi_transport_out) do
      if v == true then
        midi_dev[k]:stop()
      end
    end
  end
end

function tp.stop()
  -- kill stuff
  -- print("stopping at "..clock.get_beats())
  for i = 1,3 do
    if #arp[i].notes > 0 then
      arps.toggle("stop",i)
    end
    if #grid_pat[i].event > 0 then
      grid_pat[i]:stop()
    end
    -- rytm.toggle("stop",i)
  end
  rytm.toggle("stop")
  tp.stop_midi()
  tp.is_running = false
  transport.status_icon.status = 1
  grid_dirty = true
end

function tp.stop_from_midi_message()
  -- print("stopping at "..clock.get_beats())
  for i = 1,3 do
    if #arp[i].notes > 0 then
      arps.toggle("stop",i)
    end
    if #grid_pat[i].event > 0 then
      grid_pat[i]:stop()
    end
    -- rytm.toggle("stop",i)
  end
  rytm.toggle("stop")
  tp.is_running = false
  transport.status_icon.status = 1
  grid_dirty = true
end

--one option is to just start `clock.internal.start(-4)`
-- if the clock source is midi, it'll automatically try to do clock.transport.start() and ...stop()

function clock.transport.start()
  -- print("starting clock...", tp.cycle)
  if all_loaded and tp.cycle > 0 then
    -- print("for real..")
    if tp.start_clock == nil then
      tp.start_clock = clock.run(tp.start)
      tp.pending = true
    end
  end
  tp.cycle = tp.cycle + 1
end

function clock.transport.stop()
  tp.stop()
end

function tp.key(n,z)
  if n == 3 and z == 1 then
    if page.transport.focus == "TRANSPORT" then
      if tp.is_running then
        clock.transport.stop()
      else
        if params:string("clock_source") == "internal" then
          -- clock.internal.start(3.9)
          clock.internal.start(-0.1)
        -- elseif params:string("clock_source") == "link" then
        else
          tp.cycle = 1
          clock.transport.start()
        end
        tp.pending = true
        -- clock.transport.start()
      end
    elseif page.transport.focus == "TAP-TEMPO" then
      tp.tap_tempo()
    end
  elseif n == 2 and z == 0 then
    menu = 1
    transport.tap_tempo_table = {}
    transport.tap_tempo_index = 1
    sum_tempo = 0
  end
end

function tp.enc(n,d)
  if n == 1 then
    local which = tab.key(page.transport.foci, page.transport.focus)
    if page.transport.focus ~= page.transport.foci[util.clamp(which+d,1,#page.transport.foci)] then
      page.transport.focus = page.transport.foci[util.clamp(which+d,1,#page.transport.foci)]
    end
  elseif n == 2 then
    params:delta("clock_tempo",d)
  elseif n == 3 then
    params:delta("clock_tempo",d/10)
  end
end

function tp.status_icon_redraw(x_pos,y_pos,new_size)
  tp.status_icon.x = x_pos
  tp.status_icon.y = y_pos
  tp.status_icon.size = new_size
  tp.status_icon:redraw()
end

function tp.UI()
  screen.level(page.transport.focus == "TRANSPORT" and 15 or 0)
  screen.rect(0, 0, screen.text_extents("TRANSPORT") + 4, 7)
  screen.fill()
  screen.move(2,6)
  screen.level(page.transport.focus == "TRANSPORT" and 0 or 15)
  screen.text("TRANSPORT")

  screen.level(page.transport.focus == "TRANSPORT" and 0 or 15)
  screen.rect(50,0, screen.text_extents("TAP-TEMPO") + 4, 7)
  screen.fill()
  screen.move(52,6)
  screen.level(page.transport.focus == "TRANSPORT" and 15 or 0)
  screen.text("TAP-TEMPO")

  screen.font_size(8)
  metronome(115,6,15,3)
  screen.move(0,30)
  screen.level(15)
  screen.font_size(18)
  screen.text(params:get("clock_tempo").." bpm")
  screen.move(0,50)
  screen.text("K3: ")
  if page.transport.focus == "TRANSPORT" then
    screen.text(tostring(transport.is_running) == "true" and "stop" or "play")
  elseif page.transport.focus == "TAP-TEMPO" then
    if #transport.tap_tempo_table == 0 then
      screen.text("tap")
    else
      for i = 1,#transport.tap_tempo_table do
        screen.rect(30+(10*i),42,5,5)
        screen.fill()
      end
    end
  end
  if transport.pending then
    screen.move(90,50)
    screen.font_size(15)
    screen.text_center("...")
  end
end

function tp.tap_UI()
  screen.level(15)
  screen.rect(0, 0, 128, 7)
  screen.fill()
  screen.move(2,6)
  screen.level(0)
  screen.text("TAP-TEMPO")
  screen.font_size(8)
  metronome(115,6,0,0)
end

tap = 0
deltatap = 1
local sum_tempo = 0

function tp.tap_tempo()
  local last = params:get("clock_tempo")
  local tap1 = util.time()
  deltatap = tap1 - tap
  tap = tap1
  local t_t = 60/deltatap
  -- if t_t >= 1 and deltatap <=3 then
    transport.tap_tempo_table[transport.tap_tempo_index] = math.floor(t_t+0.5)
    transport.tap_tempo_index = transport.tap_tempo_index + 1
  -- end
  if #transport.tap_tempo_table == 4 then
    for i = 2,4 do
      sum_tempo = sum_tempo + transport.tap_tempo_table[i]
    end
    params:set("clock_tempo",util.round(sum_tempo/3,0.1))
    transport.tap_tempo_table = {}
    transport.tap_tempo_index = 1
    sum_tempo = 0
  end
end

return transport