local transport = {}

local tp = transport

transport.vars = {["midi_transport_out"] = {}, ["midi_transport_in"] = {}}
for i = 1,16 do
  tp.vars.midi_transport_in[i] = false
end
transport.cycle = 0
transport.pending = false

function tp.init()
  local vports = {}
  local function refresh_params_vports()
    for i = 1,#midi.vports do
      vports[i] = midi.vports[i].name ~= "none" and (util.trim_string_to_width(midi.vports[i].name,90)) or tostring(i)..": [device]"
    end
  end
  refresh_params_vports()
  params:add_group("transport settings",39)
  params:add_separator("auto-start")
  params:add_option("start_transport_at_launch", "start at launch?",{"no","yes"},1)
  params:set_action("start_transport_at_launch", function()
    if all_loaded then
      persistent_state_save()
    end
  end)
  local banks = {"a","b","c"}
  for i = 1,3 do
    params:add_option("start_arp_"..i.."_at_launch", "auto-start arp "..banks[i].."?",{"no","yes"},2)
  end
  params:add_separator("send MIDI transport?")
  for i = 1,16 do
    params:add_option("port_"..i.."_start_stop_out", vports[i],{"no","yes"},1)
    params:set_action("port_"..i.."_start_stop_out", function(x)
      if x == 2 then
        if all_loaded then
          persistent_state_save()
        end
        table.insert(tp.vars.midi_transport_out,i)
      end
    end)
  end
  params:add_separator("receive MIDI transport?")
  for i = 1,16 do
    params:add_option("port_"..i.."_start_stop_in", vports[i],{"no","yes"},1)
    params:set_action("port_"..i.."_start_stop_in", function(x)
      if x == 2 then
        if all_loaded then
          persistent_state_save()
        end
        tp.vars.midi_transport_in[i] = true
      end
    end)
  end

  tp.status_icon = UI.PlaybackIcon.new(32, 32, 15, 1)

  tp.is_running = false -- will want this initialized as false eventually

end

function tp.start()
  -- set stuff to 1 and start them
  clock.sync(4)
  print("starting at "..clock.get_beats())
  -- tp.lattice:start()
  tp.is_running = true
  transport.status_icon.status = 4
  for i = 1,3 do
    if #arp[i].notes > 0 and params:string("start_arp_"..i.."_at_launch") == "yes" then
      arps.toggle("start",i)
    end
    if #grid_pat[i].event > 0 then
      grid_pat[i]:start()
    end
    -- rytm.toggle("start",i)
    print(clock.get_beats())
  end
  rytm.toggle("start")
  tp.start_midi()-- midi_dev[4]:start()
  grid_dirty = true
  tp.start_clock = nil
  tp.pending = false
end

function tp.start_midi()
  if params:string("clock_source") ~= "midi" then
    for k,v in pairs(tp.vars.midi_transport_out) do
      midi_dev[v]:start()
    end
  end
end

function tp.stop_midi()
  if params:string("clock_source") ~= "midi" then
    for k,v in pairs(tp.vars.midi_transport_out) do
      midi_dev[v]:stop()
    end
  end
end

function tp.stop()
  -- kill stuff
  print("stopping at "..clock.get_beats())
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

--one option is to just start `clock.internal.start(-4)`
-- if the clock source is midi, it'll automatically try to do clock.transport.start() and ...stop()

function clock.transport.start()
  if params:string("start_transport_at_launch") == "yes" or tp.cycle > 0 then
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
  elseif n == 2 and z == 0 then
    menu = 1
  end
end

function tp.enc(n,d)
  if n == 1 then
    params:delta("clock_tempo",d)
  end
end

function tp.status_icon_redraw(x_pos,y_pos,new_size)
  tp.status_icon.x = x_pos
  tp.status_icon.y = y_pos
  tp.status_icon.size = new_size
  tp.status_icon:redraw()
end

function tp.UI()
  screen.level(15)
  screen.rect(0, 0, 128, 7)
  screen.fill()
  screen.move(2,6)
  screen.level(0)
  screen.text("TRANSPORT")
  screen.font_size(8)
  metronome(115,6,0,0)
  screen.move(0,25)
  screen.level(15)
  screen.font_size(18)
  screen.text("E1: "..params:get("clock_tempo").." bpm")
  screen.move(0,45)
  screen.text("K3: ")
  tp.status_icon_redraw(32, 32, 15)
  if transport.pending then
    screen.move(60,60)
    screen.font_size(8)
    screen.text_center("(waiting for 1...)")
  end
end

function tp.tap_UI()

end

return transport