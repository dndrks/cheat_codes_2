local transport = {}

local tp = transport

transport.vars = {["midi_transport_out"] = {}}

function tp.init()
  local vports = {}
  local function refresh_params_vports()
    for i = 1,#midi.vports do
      vports[i] = midi.vports[i].name ~= "none" and (util.trim_string_to_width(midi.vports[i].name,90)) or tostring(i)..": [device]"
    end
  end
  refresh_params_vports()
  params:add_group("transport settings",17)
  params:add_separator("send MIDI transport?")
  for i = 1,16 do
    params:add_option("port_"..i.."_start_stop_out", vports[i],{"no","yes"},1)
    params:set_action("port_"..i.."_start_stop_out", function(x)
      if x == 2 then
        table.insert(tp.vars.midi_transport_out,i)
      end
    end)
  end

  tp.is_running = false -- will want this initialized as false eventually

end

function tp.start()
  -- set stuff to 1 and start them
  clock.sync(4)
  print("starting at "..clock.get_beats())
  -- tp.lattice:start()
  tp.is_running = true
  for i = 1,3 do
    if #arp[i].notes > 0 then
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
end

function tp.start_midi()
  for k,v in pairs(tp.vars.midi_transport_out) do
    midi_dev[v]:start()
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
  midi_dev[4]:stop()
  tp.is_running = false
  grid_dirty = true
end

--one option is to just start `clock.internal.start(-4)`

function clock.transport.start()
  -- tp.start()
  if tp.start_clock == nil then
    tp.start_clock = clock.run(tp.start)
  end
end

function clock.transport.stop()
  tp.stop()
end

return transport