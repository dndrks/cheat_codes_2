start_up = {}

function start_up.init()
  
  softcut.buffer_clear()
  softcut.pan(1, 0.0)
  
  for i = 1, 4 do
    softcut.level(i,0.0)
    softcut.level_input_cut(1, i, 1.0)
    softcut.level_input_cut(2, i, 1.0)
    softcut.buffer(i, 1)
    audio.level_adc_cut(1)
    softcut.fade_time(i, 0.01)
    softcut.play(i, 1)
    softcut.rate(i, 1)
    softcut.loop_start(i, 1)
    softcut.loop_end(i, 9)
    softcut.loop_end(1,8.99)
    softcut.loop(i, 1)
    softcut.rec_level(1, 1)
    -- softcut.pre_level(1, 0.25)
    softcut.pre_level(1, 1)
    softcut.position(i, 1)
    softcut.phase_quant(i, 0.01)
    -- softcut.phase_quant(i, 1/15)
    -- softcut.rec_offset(i, -0.0003)
    softcut.enable(i, 1)
    softcut.rate_slew_time(4,0.2)
  end

  clock.run(function()
    clock.sleep(0.25)
    softcut.rec(1, 1)
  end)
  
  softcut.event_phase(phase)
  softcut.poll_start_phase()
  softcut.event_render(on_render)
  
  softcut.level(5,1)
  softcut.pan(5,-1)
  softcut.buffer(5,1)
  softcut.play(5, 1)
  softcut.rate(5, 1)
  softcut.loop_start(5, 41)
  softcut.loop_end(5, 41.5)
  softcut.loop(5, 1)
  softcut.rec(5, 1)
  softcut.rec_level(5, 1)
  softcut.pre_level(5, 0.5)
  softcut.recpre_slew_time(5,0.01)
  softcut.position(5, 41)
  -- softcut.rec_offset(5, -0.0003)
  softcut.enable(5, 1)
  
  softcut.level(6,1)
  softcut.pan(6,1)
  softcut.level_cut_cut(2,6,0.3)
  softcut.level_cut_cut(3,6,0.7)
  softcut.level_cut_cut(4,6,1)
  softcut.buffer(6,1)
  softcut.play(6, 1)
  softcut.rate(6, 1)
  softcut.loop_start(6, 71)
  softcut.loop_end(6, 71.5)
  softcut.loop(6, 1)
  softcut.rec(6, 1)
  softcut.rec_level(6, 1)
  softcut.pre_level(6, 0.5)
  softcut.recpre_slew_time(6,0.01)
  softcut.position(6, 71)
  -- softcut.rec_offset(6, -0.0003)
  softcut.enable(6, 1)
  
  --params:add_separator()
  
  params:add_group("loops + buffers", 29)

  params:add_separator("clips")
  
  for i = 1,3 do
    params:add_file("clip "..i.." sample", "clip "..i.." sample")
    params:set_action("clip "..i.." sample", function(file) load_sample(file,i) end)
  end

  for i = 1,3 do
    params:add{type = "trigger", id = "save_buffer"..i, name = "save live buffer "..i.." [K3]", action = function() save_sample(i) end}	
  end

  params:add_separator("live")

  for i = 1,3 do
    -- params:add_option("rec_loop_"..i, "live "..i.." rec behavior", {"loop","1-shot","SOS"}, 1)
    params:add_option("rec_loop_"..i, "live "..i.." rec behavior", {"loop","1-shot"}, 1)
    params:set_action("rec_loop_"..i,
      function(x)
        if x < 3 then
          rec[i].loop = 2-x
          if rec[i].loop == 0 then rec.stopped = true end
          if rec.focus == i then
            softcut.loop(1,rec[rec.focus].loop)
            softcut.position(1,rec[rec.focus].start_point)
            softcut.rec_level(1,rec[rec.focus].state)
            if rec[rec.focus].state == 1 then
              if x == 2 then
                --rec_state_watcher:start()
                run_one_shot_rec_clock()
                softcut.pre_level(1,params:get("live_rec_feedback_"..rec.focus))
              elseif x == 1 then
                softcut.pre_level(1,params:get("live_rec_feedback_"..rec.focus))
              end
            end
          end
        end
      end
    )
  end

  params:add_option("one_shot_clock_div","--> 1-shot sync",{"next beat","next bar","free","threshold"},1)
  params:set_action("one_shot_clock_div",
    function(x)
      if x ~= 4 then
        params:hide("one_shot_threshold")
        _menu.rebuild_params()
      else
        params:show("one_shot_threshold")
        _menu.rebuild_params()
      end
    end
  )
  params:add_control("one_shot_threshold","----> thresh",controlspec.new(1,1000,'exp',1,85,'amp/10k'))
  params:add_control("one_shot_latency_offset","--> latency offset",controlspec.new(0,1,'lin',0.01,0,'s'))

  params:add_option("rec_loop_enc_resolution", "rec loop enc resolution", {"0.1","0.01","1/16","1/8","1/4","1/2","1 bar"}, 1)
  params:set_action("rec_loop_enc_resolution", function(x)
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
      -- rec[rec.focus].start_point = 1+(8*(rec.focus-1))
      -- local lbr = {1,2,4}
      -- rec[rec.focus].end_point = (1+(8*(rec.focus-1) + (1/rec_loop_enc_resolution))/lbr[params:get("live_buff_rate")])
      local lbr = {1,2,4}
      for i = 1,3 do
        rec[i].start_point = 1+(8*(i-1))
        rec[i].end_point = (1+(8*(i-1) + (1/rec_loop_enc_resolution))/lbr[params:get("live_buff_rate")])
      end
      softcut.loop_start(1,rec[rec.focus].start_point)
      softcut.loop_end(1,rec[rec.focus].end_point)
    end
  end)

  for i = 1,3 do
    params:add{id="live_rec_feedback_"..i, name="live "..i.." rec feedback", type="control", 
    controlspec=controlspec.new(0,1.0,'lin',0,0.25,""),
    action=function(x)
      if rec.focus == i and rec[rec.focus].state == 1 then
        softcut.pre_level(1,x)
      end
    end}
  end
  
  params:add_option("live_buff_rate", "live buffer max", {"8 sec", "16 sec", "32 sec"}, 1)
  params:set_action("live_buff_rate", function(x)
    local buff_rates = {1,0.5,0.25}
    softcut.rate(1,buff_rates[x])
    compare_rec_resolution(params:get("rec_loop_enc_resolution"))
    local rate_offset = {0,-12,-24}
    params:set("offset",rate_offset[x])
  end)
  
  for i = 1,3 do
    params:add_control("random_rec_clock_prob_"..i, "rand rec "..i.." probability", controlspec.new(0, 100, 'lin', 1, 0, "%"))
  end

  params:add_separator("global")

  params:add_control("offset", "global pitch offset", controlspec.new(-24, 24, 'lin', 1, 0, "st"))
  params:set_action("offset",
    function(value)
      for i=1,3 do
        for j = 1,16 do
          bank[i][j].offset = math.pow(0.5, -value / 12)
        end
        if bank[i][bank[i].id].pause == false then
          softcut.rate(i+1, bank[i][bank[i].id].rate*bank[i][bank[i].id].offset)
        end
      end
    end
  )
  
  loop_enc_resolution = {}
  local banks = {"(a)","(b)","(c)"}
  for i = 1,3 do
    params:add_option("loop_enc_resolution_"..i, "loops enc resolution "..banks[i], {"0.1","0.01","1/16","1/8","1/4","1/2","1 bar"}, 1)
    params:set_action("loop_enc_resolution_"..i, function(x)
      local resolutions =
      { [1] = 10
      , [2] = 100
      , [3] = 1/(clock.get_beat_sec()/4)
      , [4] = 1/(clock.get_beat_sec()/2)
      , [5] = 1/(clock.get_beat_sec())
      , [6] = (1/(clock.get_beat_sec()))/2
      , [7] = (1/(clock.get_beat_sec()))/4
      }
      loop_enc_resolution[i] = resolutions[x]
      for j = 1,16 do
        local pad = bank[i][j]
        if x > 2 then
          pad.end_point = pad.start_point + (((1/loop_enc_resolution[pad.bank_id])))
          if menu ~= 1 then screen_dirty = true end
        end
      end
      softcut.loop_start(i+1,bank[i][bank[i].id].start_point)
      softcut.loop_end(i+1,bank[i][bank[i].id].end_point)
      if all_loaded then
        mc.mft_redraw(bank[i][bank[i].id],"all")
      end
    end)
  end

  params:add_option("preview_clip_change", "preview clip changes?", {"yes","no"},1)
  params:set_action("preview_clip_change", function() if all_loaded then persistent_state_save() end end)
  params:add_option("visual_metro", "visual metronome?", {"yes","no"},2)
  params:set_action("visual_metro", function() if all_loaded then persistent_state_save() end end)
  
  --params:add_option("zilchmo_bind_rand","bind random zilchmo?", {"no","yes"}, 1)
  
  params:add_group("timing + patterns + arps",27)
  params:add_separator("quantization")
  for i = 1,3 do
    params:add_option("pattern_"..i.."_quantization", "live-quantize pads "..banks[i].."?", {"no", "yes"})
    params:set_action("pattern_"..i.."_quantization", function(x)
      -- grid_pat[i]:quant(x == 1 and 0 or 1)
      -- if midi_pat ~= nil then -- TODO FIXME
      --   midi_pat[i]:quant(x == 1 and 0 or 1)
      -- end
      if x == 2 then
        bank[i].quantize_press = 1
      else
        bank[i].quantize_press = 0
      end
      if all_loaded then
        persistent_state_save()
      end
    end
    )
  end
  params:add_option("launch_quantization", "patterns launch at:", {"next beat", "next bar"})
  -- params:hide("launch_quantization")
  params:add_separator("patterns")
  params:add_option("zilchmo_patterning", "grid pat style", { "classic", "rad sauce" })
  params:set_action("zilchmo_patterning", function() if all_loaded then persistent_state_save() end end)
  params:add_option("arc_patterning", "arc pat style", { "passive", "active" })
  params:set_action("arc_patterning", function() if all_loaded then persistent_state_save() end end)
  for i = 1,3 do
    params:add_option("sync_clock_to_pattern_"..i, "sync bpm to free pat "..i.."?", { "no", "yes" })
    params:set_action("sync_clock_to_pattern_"..i, function() if all_loaded then persistent_state_save() end end)
  end
  params:add_separator("random patterns")
  for i = 1,3 do
    params:add_option("random_patterning_"..i,"rand pat "..i.." style", 
      { "rand"
      , "horizontal"
      , "h.snake"
      , "vertical"
      , "v.snake"
      , "top-in"
      , "bottom-in"
      , "zig-zag"
      , "wrap"
    })
    params:set_action("random_patterning_"..i, function(x)
      if x > 1 then
        grid_pat[i].playmode = 2
        if midi_pat ~= nil then -- TODO FIXME
          midi_pat[i].playmode = 2
        end
      end
    end)
  end

  for i = 1,3 do
    params:add_option("rand_pattern_"..i.."_note_length", "rand pat "..i.." note length", {"1/16", "1/8", "1/4", "1/2", "1", "rand"},6)
  end

  params:add_separator("arps (grid only)")
  for i = 1,3 do
    params:add_option("arp_"..i.."_hold_style", "arp "..i.." hold style", {"last pressed","additive"},1)
  end

  params:add_trigger("arp_panic","arp reset (K3)")
  params:set_action("arp_panic",
    function (x)
      if all_loaded == true then
        print("here")
        for i = 1,3 do
          clock.cancel(arp_clock[i])
          arp_clock[i] = nil
          arp_clock[i] = clock.run(arps.arpeggiate,i)
        end
      end
    end
  )

  params:add_separator("metronome")
  params:add_option("metronome_audio_state","metronome audio",{"off","on"})
  params:add_number("metronome_one_beat_pitch","1-beat pitch",30,1200,600)
  params:add_number("metronome_alt_beat_pitch","alt pitch",30,1200,300)

  params:add_group("pattern management",28)
  local banks = {"(a)", "(b)", "(c)"}
  params:add_separator("save")
  for i = 1,3 do
    params:add_number("pattern_save_slot_"..i, "save slot "..banks[i],1,8,1)
    params:set_action("pattern_save_slot_"..i,
      function(x)
        pattern_saver[i].save_slot = x
      end
    )
    params:add_trigger("pattern_save_"..i, "save (K3)")
    params:set_action("pattern_save_"..i,
      function()
        quick_save_pattern(i)
      end
    )
  end
  params:add_separator("manual load")
  for i = 1,3 do
    params:add_number("pattern_load_slot_"..i, "load slot "..banks[i],1,8,1)
    params:add_trigger("pattern_load_"..i, "load (K3)")
    params:set_action("pattern_load_"..i,
      function()
        test_load(params:get("pattern_load_slot_"..i)+(8*(i-1)),i)
      end
    )
  end
  params:add_separator("iterative load")
  for i = 1,3 do
    params:add_trigger("pattern_load_next"..i, "load next "..banks[i].." pattern (K3)")
    params:set_action("pattern_load_next"..i,
      function()
        local saved_pool = {}
        for j = 1,8 do
          if pattern_saver[i].saved[j] == 1 then
            table.insert(saved_pool,j)
          end
        end
        local current_pattern;
        if tab.count(saved_pool) > 0 and pattern_saver[i].load_slot == 0 then
          current_pattern = saved_pool[1]
        else
          current_pattern = tab.key(saved_pool,pattern_saver[i].load_slot)
        end
        if current_pattern ~= nil then
          local slick;
          if tab.count(saved_pool) > 0 and pattern_saver[i].load_slot == 0 then
            slick = saved_pool[1]
          else
            slick = saved_pool[util.wrap(current_pattern+1,1,#saved_pool)]
          end
          params:set("pattern_load_slot_"..i,slick)
          pattern_saver[i].load_slot = slick
          test_load(slick,i)
        end
      end
    )
    params:add_trigger("pattern_load_prev"..i, "load prev "..banks[i].." pattern (K3)")
    params:set_action("pattern_load_prev"..i,
      function()
        local saved_pool = {}
        for j = 1,8 do
          if pattern_saver[i].saved[j] == 1 then
            table.insert(saved_pool,j)
          end
        end
        local current_pattern;
        if tab.count(saved_pool) > 0 and pattern_saver[i].load_slot == 0 then
          current_pattern = saved_pool[1]
        else
          current_pattern = tab.key(saved_pool,pattern_saver[i].load_slot)
        end
        if current_pattern ~= nil then
          local slick;
          if tab.count(saved_pool) > 0 and pattern_saver[i].load_slot == 0 then
            slick = saved_pool[1]
          else
            slick = saved_pool[util.wrap(current_pattern-1,1,#saved_pool)]
          end
          params:set("pattern_load_slot_"..i,slick)
          pattern_saver[i].load_slot = slick
          test_load(slick,i)
        end
      end
    )
  end
  params:add_separator("delete")
  for i = 1,3 do
    params:add_number("pattern_del_slot_"..i, "delete slot "..banks[i],1,8,1)
    params:set_action("pattern_del_slot_"..i,
      function(x)
        pattern_saver[i].save_slot = x
      end
    )
    params:add_trigger("pattern_del_"..i, "delete (K3)")
    params:set_action("pattern_del_"..i,
      function()
        quick_delete_pattern(i)
      end
    )
  end

  params:add_group("mappable control",99)

  params:add_separator("save MIDI mappings")

  params:add{type='binary',name="save mappings",id='save_mappings',behavior='momentary', allow_pmap=false,
  action=function(x)
    if all_loaded and x == 1 then
      norns.pmap.write()
    end
  end
  }

params:add_separator("ALT key")

  params:add{type='binary',name="ALT key",id='alt_key',behavior='momentary',
  action=function(x)
    if all_loaded then
      grid_alt = x == 1 and true or false
      grid_dirty = true
    end
  end
  }
  -- params:hide("manual control")

  params:add_separator("arc encoders")
  for i = 1,3 do
    params:add_option("enc_"..i.."_param", "enc "..i.." param", {"loop window", "loop start", "loop end", "filter tilt", "level", "pan"})
    params:set_action("enc_"..i.."_param", function(x)
      arc_param[i] = x
    end)
  end

  params:add_separator("pattern trigs")

  for i = 1,3 do
    params:add{type='binary',name="midi pat "..i.." rec",id='midi_pat_'..i..' rec',behavior='trigger',
      action=function()
        if all_loaded then
            if midi_pat[i].rec == 0 then
              if midi_pat[i].count == 0 and not grid_alt then
                midi_pattern_recording(i,"start")
                print("recording midi pattern")
              elseif midi_pat[i].count ~= 0 and not grid_alt then
                toggle_midi_pattern_overdub(i)
                print("overdubbing midi pattern")
              elseif grid_alt then
                print("erasing midi pattern")
                if midi_pat[i].count > 0 then
                  midi_pat[i]:rec_stop()
                  if midi_pat[i].clock ~= nil then
                    print("clearing clock: "..midi_pat[i].clock)
                    clock.cancel(midi_pat[i].clock)
                  end
                  midi_pat[i]:clear()
                end
              end
            elseif midi_pat[i].rec == 1 then
              if not grid_alt then
                midi_pattern_recording(i,"stop")
              end
            end
          -- end
        end
      end
    }
  end

  for i = 1,3 do
    params:add{type='binary',name="random pattern "..i,id='random_pat_'..i,behavior='trigger',
      action=function()
        if all_loaded then
          -- if g.device ~= nil then
          if get_grid_connected() then
            random_grid_pat(i,3)
          else
            random_midi_pat(i)
          end
          -- end
        end
      end
    }
  end

  for i = 1,3 do
    params:add{type='binary',name="shuffle pattern "..i,id='shuffle_pat_'..i,behavior='trigger',
      action=function(x)
        if all_loaded then
          if x == 1 then
            -- if g.device ~= nil then
            if get_grid_connected() then
              random_grid_pat(id,2)
            else
              shuffle_midi_pat(id)
            end
          end
        end
      end
    }
  end

  params:add_separator("live recording trigs")

  for i = 1,3 do
    params:add{type='binary',name="rec live "..i,id='rec_live_'..i,behavior='trigger',
      action=function()
        if all_loaded then
          if not grid_alt then
            toggle_buffer(i)
          else
            buff_flush()
          end
        end
      end
    }
  end

  params:add_separator("zilchmos: global mods")

  local global_zilches =
  {
    {"0.5x rate","0.5x_rate"}
  , {"2x rate","2x_rate"}
  , {"reverse rate","reverse_rate"}
  , {"reverse pan","reverse_pan"}
  , {"random pan","random_pan"}
  , {"pause","pause"}
  , {"random start","random_start"}
  , {"random end","random_end"}
  , {"random window","random_window"}
  }

  for i = 1,#global_zilches do
    params:add{type='binary',name=global_zilches[i][1],id=global_zilches[i][2],behavior='momentary',
      action=function(x)
        if all_loaded then
          mc.midi_mod_table[global_zilches[i][1]] = x == 1 and true or false
        end
      end
    }
  end

  params:add_separator("zilchmos: local mods")

  local local_zilches =
  {
    {"a: 0.5x rate","a_0.5x_rate"}
  , {"b: 0.5x rate","b_0.5x_rate"}
  , {"c: 0.5x rate","c_0.5x_rate"}
  , {"a: 2x rate","a_2x_rate"}
  , {"b: 2x rate","b_2x_rate"}
  , {"c: 2x rate","c_2x_rate"}
  , {"a: reverse rate","a_reverse_rate"}
  , {"b: reverse rate","b_reverse_rate"}
  , {"c: reverse rate","c_reverse_rate"}
  , {"a: random pan","a_random_pan"}
  , {"b: random pan","b_random_pan"}
  , {"c: random pan","c_random_pan"}
  , {"a: pause","a_pause"}
  , {"b: pause","b_pause"}
  , {"c: pause","c_pause"}
  , {"a: random start","a_random_start"}
  , {"b: random start","b_random_start"}
  , {"c: random start","c_random_start"}
  , {"a: random end","a_random_end"}
  , {"b: random end","b_random_end"}
  , {"c: random end","c_random_end"}
  , {"a: random window","a_random_window"}
  , {"b: random window","b_random_window"}
  , {"c: random window","c_random_window"}
  }

  for i = 1,#local_zilches do
    params:add{type='binary',name=local_zilches[i][1],id=local_zilches[i][2],behavior='momentary',
      action=function(x)
        if all_loaded then
          mc.midi_mod_table[local_zilches[i][1]] = x == 1 and true or false
        end
      end
    }
  end

  local last_start_value = {}
  local last_end_value = {}
  
  for i = 1,3 do
    local banks = {"(a)","(b)","(c)"}
    params:add_separator(banks[i].." values")
    -- params:add_control("current pad "..i, "current pad "..banks[i], controlspec.new(1,16,'lin',1,1))
    params:add_number("current pad "..i, "current pad "..banks[i], 1, 16, 1)
    params:set_action("current pad "..i, function(x)
      if bank[i].id ~= util.clamp(1,16,util.round(x)) then
        bank[i].id = util.clamp(1,16,util.round(x))
        selected[i].x = (math.ceil(bank[i].id/4)+(5*(i-1)))
        selected[i].y = 8-((bank[i].id-1)%4)
        cheat(i,bank[i].id)
        screen_dirty = true
        grid_dirty = true
      end
    end)
    local rates = {-4,-2,-1,-0.5,-0.25,-0.125,0.125,0.25,0.5,1,2,4}
    params:add_option("rate "..i, "rate "..banks[i], macros.pad_rates, tab.key(macros.pad_rates,macros.default_pad_rate))
    params:set_action("rate "..i, function(x)
      x = util.clamp(1,#macros.pad_rates,util.round(x))
      for p = (grid_alt and 1 or bank[i].id),(grid_alt and 16 or bank[i].id) do
        bank[i][p].rate = macros.pad_rates[x]
      end
      if bank[i][bank[i].id].pause == false then
        softcut.rate(i+1, bank[i][bank[i].id].rate*bank[i][bank[i].id].offset)
      end
    end)
    params:add_control("rate slew time "..i, "rate slew time "..banks[i], controlspec.new(0,3,'lin',0.01,0))
    params:set_action("rate slew time "..i, function(x) softcut.rate_slew_time(i+1,x) end)
    params:add_control("pan "..i, "pan "..banks[i], controlspec.new(-1,1,'lin',0.01,0))
    params:set_action("pan "..i, function(x)
      softcut.pan(i+1,x)
      for p = (grid_alt and 1 or bank[i].id),(grid_alt and 16 or bank[i].id) do
        bank[i][p].pan = x
      end
      screen_dirty = true
    end)
    params:add_control("pan slew "..i,"pan slew "..banks[i], controlspec.new(0.,200.,'lin',0.1,5.0))
    params:set_action("pan slew "..i, function(x) softcut.pan_slew_time(i+1,x) end)
    params:add_control("level "..i, "pad level "..banks[i], controlspec.new(0,127,'lin',1,64))
    params:set_action("level "..i, function(x)
      for p = (grid_alt and 1 or bank[i].id),(grid_alt and 16 or bank[i].id) do
        mc.adjust_pad_level(bank[i][p],x)
      end
      if all_loaded then mc.redraw(bank[i][bank[i].id]) end
      end)
    params:add_control("bank level "..i, "bank level "..banks[i], controlspec.new(0,127,'lin',1,64))
    params:set_action("bank level "..i, function(x)
      mc.adjust_bank_level(bank[i][bank[i].id],x)
      if all_loaded then mc.redraw(bank[i][bank[i].id]) end
      end)
    params:add_control("start point "..i, "start point "..banks[i], controlspec.new(0,127,'lin',1,0))
    params:set_action("start point "..i, function(x)
      mc.move_start(bank[i][bank[i].id],x)
      if all_loaded then mc.redraw(bank[i][bank[i].id]) end
      end)
    
    last_start_value[i] = 0

    params:add_number("start (delta) "..i, "start (delta) "..banks[i],0,127,64)
    params:set_action("start (delta) "..i, function(x)
      if all_loaded then
        local returned = 0
        if last_start_value[i] > math.floor(x) then
          -- negative delta
          returned = -1
        elseif last_start_value[i] < math.floor(x) then
          -- positive delta
          returned = 1
        end
        if last_start_value[i] ~= math.floor(x) then
          local resolution = loop_enc_resolution[i]
          encoder_actions.move_start(bank[i][bank[i].id],returned/resolution)
          encoder_actions.sc.move_start(i)
        end
        last_start_value[i] = math.floor(x)
      end
    end)
    
    params:add_control("end point "..i, "end point "..banks[i], controlspec.new(0,127,'lin',1,8))
    params:set_action("end point "..i, function(x)
      mc.move_end(bank[i][bank[i].id],x)
      if all_loaded then mc.redraw(bank[i][bank[i].id]) end
      end)

    last_end_value[i] = 0

    params:add_number("end (delta) "..i, "end (delta) "..banks[i],0,127,64)
    params:set_action("end (delta) "..i, function(x)
      if all_loaded then
        local returned = 0
        if last_end_value[i] > x then
          -- negative delta
          returned = -1
        elseif last_end_value[i] < x then
          -- positive delta
          returned = 1
        end
        if last_end_value[i] ~= x then
          local resolution = loop_enc_resolution[i]
          encoder_actions.move_end(bank[i][bank[i].id],returned/resolution)
          encoder_actions.sc.move_end(i)
        end
        last_end_value[i] = x
      end
    end)

    
    params:add{type='binary',name="toggle loop "..banks[i],id="loop_"..i,behavior='momentary',
      action=function(x)
        if x == 1 then
          grid_actions.toggle_pad_loop(i)
          if osc_communication == true then
            osc_redraw(i)
          end
        end
      end
    }
    params:add_control("filter tilt "..i, "filter tilt "..banks[i], controlspec.new(-1,1,'lin',0.01,0))
    params:set_action("filter tilt "..i, function(x)
      for j = 1,16 do
        local target = bank[i][j]
        if slew_counter[i] ~= nil then
          slew_counter[i].prev_tilt = target.tilt
        end
        target.tilt = x
      end
    slew_filter(i,slew_counter[i].prev_tilt,bank[i][bank[i].id].tilt,bank[i][bank[i].id].q,bank[i][bank[i].id].q,bank[i][bank[i].id].tilt_ease_time)
    end)
  end
  
  params:add_group("delays",65)

  params:add_separator("manage delay audio")
  params:add{type = "trigger", id = "save_left_delay", name = "** save L delay", action = function() del.save_delay(1) end}
  params:add{type = "trigger", id = "save_right_delay", name = "save R delay **", action = function() del.save_delay(2) end}
  params:add{type = "trigger", id = "save_both_delays", name = "** save both delays **", action = function() for i = 1,2 do del.save_delay(i) end end}
  params:add_file("load_left_delay", "--> load L delay")
  params:set_action("load_left_delay", function(file) del.load_delay(file,1) end)
  params:add_file("load_right_delay", "load R delay <--")
  params:set_action("load_right_delay", function(file) del.load_delay(file,2) end)
  
  
  for i = 4,5 do
    local sides = {"L","R"}
    params:add_separator("delay output "..sides[i-3])
    params:add_control("delay "..sides[i-3]..": global level", "delay "..sides[i-3]..": global level", controlspec.new(0,1,'lin',0,0,""))
    params:set_action("delay "..sides[i-3]..": global level", function(x) softcut.level(i+1,x) screen_dirty = true encoder_actions.check_delay_links(sides[i-3], sides[i-3] == "L" and "R" or "L","global level") end)
    params:add_option("delay "..sides[i-3]..": mode", "delay "..sides[i-3]..": mode", {"clocked", "free"},1)
    params:set_action("delay "..sides[i-3]..": mode", function(x)
      if x == 1 then
        delay[i-3].mode = "clocked"
        softcut.loop_end(i+1,delay[i-3].end_point)
      else
        delay[i-3].mode = "free"
        softcut.loop_end(i+1,delay[i-3].free_end_point)
      end
      encoder_actions.check_delay_links(sides[i-3], sides[i-3] == "L" and "R" or "L","mode")
      screen_dirty = true
    end)
    params:add_option("delay "..sides[i-3]..": div/mult", "--> clocked div/mult: ",
    {"x16"   ,"x15 3/4"   ,"x15 2/3"   ,"x15 1/2"   ,"x15 1/3"   ,"x15 1/4"
    , "x15"   ,"x14 3/4"   ,"x14 2/3"   ,"x14 1/2"   ,"x14 1/3"   ,"x14 1/4"
    , "x14"   ,"x13 3/4"   ,"x13 2/3"   ,"x13 1/2"   ,"x13 1/3"   ,"x13 1/4"
    , "x13"   ,"x12 3/4"   ,"x12 2/3"   ,"x12 1/2"   ,"x12 1/3"   ,"x12 1/4"
    , "x12"   ,"x11 3/4"   ,"x11 2/3"   ,"x11 1/2"   ,"x11 1/3"   ,"x11 1/4"
    , "x11"   ,"x10 3/4"   ,"x10 2/3"   ,"x10 1/2"   ,"x10 1/3"   ,"x10 1/4"
    , "x10"   ,"x9 3/4"   ,"x9 2/3"   ,"x9 1/2"   ,"x9 1/3"   ,"x9 1/4"
    , "x9"    ,"x8 3/4"   ,"x8 2/3"   ,"x8 1/2"   ,"x8 1/3"   ,"x8 1/4"
    , "x8"    ,"x7 3/4"   ,"x7 2/3"   ,"x7 1/2"   ,"x7 1/3"   ,"x7 1/4"
    , "x7"    ,"x6 3/4"   ,"x6 2/3"   ,"x6 1/2"   ,"x6 1/3"   ,"x6 1/4"
    , "x6"    ,"x5 3/4"   ,"x5 2/3"   ,"x5 1/2"   ,"x5 1/3"   ,"x5 1/4"
    , "x5"    ,"x4 3/4"   ,"x4 2/3"   ,"x4 1/2"   ,"x4 1/3"   ,"x4 1/4"
    , "x4"    ,"x3 3/4"   ,"x3 2/3"   ,"x3 1/2"   ,"x3 1/3"   ,"x3 1/4"
    , "x3"    ,"x2 3/4"   ,"x2 2/3"   ,"x2 1/2"   ,"x2 1/3"   ,"x2 1/4"
    , "x2"    ,"x1 3/4"   ,"x1 2/3"   ,"x1 1/2"   ,"x1 1/3"   ,"x1 1/4"
    , "x1"    ,"/1 1/4"   ,"/1 1/3"   ,"/1 1/2"   ,"/1 2/3"   ,"/1 3/4"   ,"/2"   ,"/4"
    },91)
    params:set_action("delay "..sides[i-3]..": div/mult", function(x)
      delay[i-3].clocked_length = clocked_delays[x]
      delay[i-3].id = x
      local delay_rate_to_time = clock.get_beat_sec() * clocked_delays[x] * delay[i-3].modifier
      local delay_time = delay_rate_to_time + (41 + (30*(i-4)))
      delay[i-3].end_point = delay_time
      softcut.loop_end(i+1,delay[i-3].end_point)
      encoder_actions.check_delay_links(sides[i-3], sides[i-3] == "L" and "R" or "L","div/mult")
      screen_dirty = true
    end)

    --params:add_control("delay "..sides[i-3]..": free length", "--> free length: ", controlspec.new(0.01,30,'lin',0.01,0.01,""))
    params:add{
      type='control',
      id="delay "..sides[i-3]..": fade time",
      name="delay "..sides[i-3]..": fade time",
      controlspec=controlspec.def{
        min=0.000,
        max=2.000,
        warp='lin',
        step=0.001,
        default=0.01,
        quantum=0.001,
        wrap=false,
      },
    }
    params:set_action("delay "..sides[i-3]..": fade time", function(x)
      softcut.fade_time(i+1,x)
      encoder_actions.check_delay_links(sides[i-3], sides[i-3] == "L" and "R" or "L","fade time")
    end)
    params:add{
      type='control',
      id="delay "..sides[i-3]..": rate",
      name="delay "..sides[i-3]..": rate",
      controlspec=controlspec.def{
        min=0.25,
        max=24.000,
        warp='lin',
        step=0.01,
        default=1,
        quantum=1/(23.75*100),
        wrap=false,
      },
    }
    params:set_action("delay "..sides[i-3]..": rate", function(x)
      delay[i-3].rate = x
      softcut.rate(i+1,x*(delay[i-3].reverse and -1 or 1))
      encoder_actions.check_delay_links(sides[i-3], sides[i-3] == "L" and "R" or "L","rate")
    end)
    params:add_option("delay "..sides[i-3]..": rate bump", "delay "..sides[i-3]..": rate bump", {"fifth","detune"}, 1)
    params:add_control("delay "..sides[i-3]..": rate slew time", "delay "..sides[i-3]..": rate slew time", controlspec.new(0,3,'lin',0.01,0.01))
    params:set_action("delay "..sides[i-3]..": rate slew time", function(x) softcut.rate_slew_time(i+1,x) end)
    params:add_control("delay "..sides[i-3]..": feedback", "delay "..sides[i-3]..": feedback", controlspec.new(0,100,'lin',0,50,"%"))
    params:set_action("delay "..sides[i-3]..": feedback",
    function(x)
      softcut.pre_level(i+1,(x/100))
      screen_dirty = true
      encoder_actions.check_delay_links(sides[i-3], sides[i-3] == "L" and "R" or "L","feedback")
    end)
    params:add_control("delay "..sides[i-3]..": pan", "delay "..sides[i-3]..": pan", controlspec.new(-1,1,'lin',0.01,(i == 4 and -1 or 1)))
    params:set_action("delay "..sides[i-3]..": pan", function(x)
      softcut.pan(i+1,x)
    end)
    params:add{type = "trigger", id = "save_delay_"..sides[i-3], name = "***** save delay "..sides[i-3].." ***** [K3]", action = function() del.save_delay(i-3) end}	

    params:add{
      type='control',
      id='delay '..sides[i-3]..': free length',
      name='--> free length: ',
      controlspec=controlspec.def{
        min=0.00,
        max=30.0,
        warp='lin',
        step=0.0001,
        default=1,
        quantum=0.0001,
        wrap=false,
      },
    }
    params:hide("delay "..sides[i-3]..": free length")
    params:set_action("delay "..sides[i-3]..": free length", function(x)
      if delay[i-3].mode == "free" then
        delay[i-3].free_end_point = delay[i-3].start_point + x
        softcut.loop_end(i+1,delay[i-3].free_end_point)
        encoder_actions.check_delay_links(sides[i-3], sides[i-3] == "L" and "R" or "L","free length")
      end
    end)

    -- this is dumb, but it works:

    params:add_control("delay pan "..i-3, "delay pan "..i-3, controlspec.new(-1,1,'lin',0.01,(i == 4 and -1 or 1)))
    params:hide("delay pan "..i-3)
    params:set_action("delay pan "..i-3, function(x)
      if all_loaded then
        params:set("delay "..sides[i-3]..": pan",x)
      end
    end)

    params:add{
      type='control',
      id='delay free time '..i-3,
      name='delay free time '..i-3,
      controlspec=controlspec.def{
        min=0.00,
        max=30.0,
        warp='lin',
        step=0.0001,
        default=1,
        quantum=0.0001,
        wrap=false,
      },
    }
    params:hide('delay free time '..i-3)
    params:set_action('delay free time '..i-3, function(x)
      if all_loaded then
        params:set("delay "..sides[i-3]..": free length",x)
      end
    end)
    params:add_option("delay div/mult "..i-3, "delay div/mult "..i-3,
    {"x16"   ,"x15.75"   ,"x15.66"   ,"x15.5"   ,"x15.33"   ,"x15.25"
    , "x15"   ,"x14.75"   ,"x14.66"   ,"x14.5"   ,"x14.33"   ,"x14.25"
    , "x14"   ,"x13.75"   ,"x13.66"   ,"x13.5"   ,"x13.33"   ,"x13.25"
    , "x13"   ,"x12.75"   ,"x12.66"   ,"x12.5"   ,"x12.33"   ,"x12.25"
    , "x12"   ,"x11.75"   ,"x11.66"   ,"x11.5"   ,"x11.33"   ,"x11.25"
    , "x11"   ,"x10.75"   ,"x10.66"   ,"x10.5"   ,"x10.33"   ,"x10.25"
    , "x10"   ,"x9.75"   ,"x9.66"   ,"x9.5"   ,"x9.33"   ,"x9.25"
    , "x9"    ,"x8.75"   ,"x8.66"   ,"x8.5"   ,"x8.33"   ,"x8.25"
    , "x8"    ,"x7.75"   ,"x7.66"   ,"x7.5"   ,"x7.33"   ,"x7.25"
    , "x7"    ,"x6.75"   ,"x6.66"   ,"x6.5"   ,"x6.33"   ,"x6.25"
    , "x6"    ,"x5.75"   ,"x5.66"   ,"x5.5"   ,"x5.33"   ,"x5.25"
    , "x5"    ,"x4.75"   ,"x4.66"   ,"x4.5"   ,"x4.33"   ,"x4.25"
    , "x4"    ,"x3.75"   ,"x3.66"   ,"x3.5"   ,"x3.33"   ,"x3.25"
    , "x3"    ,"x2.75"   ,"x2.66"   ,"x2.5"   ,"x2.33"   ,"x2.25"
    , "x2"    ,"x1.75"   ,"x1.66"   ,"x1.5"   ,"x1.33"   ,"x1.25"
    , "x1"    ,"/1.25"   ,"/1.33"   ,"/1.5"   ,"/1.66"   ,"/1.75"   ,"/2"   ,"/4"
    },91)
    params:hide('delay div/mult '..i-3)
    params:set_action('delay div/mult '..i-3, function(x)
      if all_loaded then
        params:set("delay "..sides[i-3]..": div/mult",x)
      end
    end)

    params:add_option("delay rate "..i-3, "delay rate "..i-3, macros.delay_rates)
    params:hide('delay rate '..i-3)
    params:set_action("delay rate "..i-3, function(x)
      if all_loaded then
        params:set("delay "..sides[i-3]..": rate", macros.delay_rates[x])
      end
    end)
    ---/
  end

  params:add_separator("delay input")

  for i = 1,3 do
    local banks = {"a","b","c"}
    params:add_control("delay L: ("..banks[i]..") send", "delay L: ("..banks[i]..") send", controlspec.new(0,1,'lin',0.1,0,""))
    params:set_action("delay L: ("..banks[i]..") send", function(x)
      if bank[i][bank[i].id].enveloped == false then
        softcut.level_cut_cut(i+1,5,(x*bank[i][bank[i].id].level)*bank[i].global_level)
      end
      for j = 1,16 do
        bank[i][j].left_delay_level = x
      end
      grid_dirty = true
    end)
    params:add_control("delay R: ("..banks[i]..") send", "delay R: ("..banks[i]..") send", controlspec.new(0,1,'lin',0.1,0,""))
    params:set_action("delay R: ("..banks[i]..") send", function(x)
      if bank[i][bank[i].id].enveloped == false then
        softcut.level_cut_cut(i+1,6,(x*bank[i][bank[i].id].level)*bank[i].global_level)
      end
      for j = 1,16 do
        bank[i][j].right_delay_level = x
      end
      grid_dirty = true
    end)
  end

  for i = 1,2 do
    local sides = {"L","R"}
    params:add_control("delay "..sides[i]..": external input", "delay "..sides[i]..": external input", controlspec.new(0,1,'lin',0.1,0,""))
    params:set_action("delay "..sides[i]..": external input", function(x)
      softcut.level_input_cut(1,i+4,x)
      softcut.level_input_cut(2,i+4,x)
    end)
  end
  
  --params:add_separator()
  
  for i = 4,5 do
    local sides = {"L","R"}
    params:add_separator("delay filters "..sides[i-3])
    params:add_option("delay "..sides[i-3]..": curve", "delay "..sides[i-3]..": curve", easingFunctions.easingNames,1)
    params:add_control("delay "..sides[i-3]..": filter cut", "delay "..sides[i-3]..": filter cut", controlspec.new(10,12000,'exp',1,12000,"Hz"))
    params:set_action("delay "..sides[i-3]..": filter cut",
    function(x)
      local modified_freq = nil
      if i == 4 then
        modified_freq = easingFunctions[params:string("delay "..sides[i-3]..": curve")](x/12000,10,11990,1)
      elseif i == 5 then
        modified_freq = easingFunctions[params:string("delay "..sides[i-3]..": curve")](x/12000,10,11990,1)
      end
      softcut.post_filter_fc(i+1,modified_freq)
      encoder_actions.check_delay_links(sides[i-3], sides[i-3] == "L" and "R" or "L","filter cut")
    end)
    params:add_control("delay "..sides[i-3]..": filter q", "delay "..sides[i-3]..": filter q", controlspec.new(0.001, 8.0, 'exp', 0, 1.0, ""))
    params:set_action("delay "..sides[i-3]..": filter q",
    function(x)
      softcut.post_filter_rq(i+1,x)
      encoder_actions.check_delay_links(sides[i-3], sides[i-3] == "L" and "R" or "L","filter q")
    end)
    params:add_control("delay "..sides[i-3]..": filter lp", "delay "..sides[i-3]..": filter lp", controlspec.new(0, 1, 'lin', 0, 1, ""))
    params:set_action("delay "..sides[i-3]..": filter lp",
    function(x)
      softcut.post_filter_lp(i+1,x)
      encoder_actions.check_delay_links(sides[i-3], sides[i-3] == "L" and "R" or "L","filter lp")
    end)
    params:add_control("delay "..sides[i-3]..": filter hp", "delay "..sides[i-3]..": filter hp", controlspec.new(0, 1, 'lin', 0, 0, ""))
    params:set_action("delay "..sides[i-3]..": filter hp",
    function(x)
      softcut.post_filter_hp(i+1,x)
      encoder_actions.check_delay_links(sides[i-3], sides[i-3] == "L" and "R" or "L","filter hp")
    end)
    params:add_control("delay "..sides[i-3]..": filter bp", "delay "..sides[i-3]..": filter bp", controlspec.new(0, 1, 'lin', 0, 0, ""))
    params:set_action("delay "..sides[i-3]..": filter bp",
    function(x)
      softcut.post_filter_bp(i+1,x)
      encoder_actions.check_delay_links(sides[i-3], sides[i-3] == "L" and "R" or "L","filter bp")
    end)
    params:add_control("delay "..sides[i-3]..": filter dry", "delay "..sides[i-3]..": filter dry", controlspec.new(0, 1, 'lin', 0, 0, ""))
    params:set_action("delay "..sides[i-3]..": filter dry",
    function(x)
      softcut.post_filter_dry(i+1,x)
      encoder_actions.check_delay_links(sides[i-3], sides[i-3] == "L" and "R" or "L","filter dry")
    end)
    
    --this is dumb:
    params:add_control("delay filter cut "..i-3, "delay filter cut "..i-3, controlspec.new(10,12000,'exp',1,12000,"Hz"))
    params:hide("delay filter cut "..i-3)
    params:set_action("delay filter cut "..i-3,function(x)
      if all_loaded then
        params:set("delay "..sides[i-3]..": filter cut",x)
      end
    end)
    --/
  end
  
  --params:add_separator()
  
  params:add_group("ignore",18)
  params:hide("ignore")
  
  --params:add{type = "trigger", id = "ignore", name = "ignore, data only:"}
  
  for i = 1,3 do
    local banks = {"(a)", "(b)", "(c)"}
    params:add_control("filter "..i.." cutoff", "filter "..banks[i].." cutoff", controlspec.new(10,12000,'lin',1,12000,"Hz"))
    params:set_action("filter "..i.." cutoff", function(x) softcut.post_filter_fc(i+1,x) bank[i][bank[i].id].fc = x end)
    params:add_control("filter "..i.." q", "filter "..banks[i].." q", controlspec.new(0.0005, 2.0, 'exp', 0, 0.32, ""))
    params:set_action("filter "..i.." q", function(x)
      softcut.post_filter_rq(i+1,x)
      for j = 1,16 do
        bank[i][j].q = x
      end
    end)
    params:add_control("filter "..i.." lp", "filter "..banks[i].." lp", controlspec.new(0, 1, 'lin', 0, 1, ""))
    params:set_action("filter "..i.." lp", function(x) softcut.post_filter_lp(i+1,x) bank[i][bank[i].id].lp = x end)
    params:add_control("filter "..i.." hp", "filter "..banks[i].." hp", controlspec.new(0, 1, 'lin', 0, 0, ""))
    params:set_action("filter "..i.." hp", function(x) softcut.post_filter_hp(i+1,x) bank[i][bank[i].id].hp = x end)
    params:add_control("filter "..i.." bp", "filter "..banks[i].." bp", controlspec.new(0, 1, 'lin', 0, 0, ""))
    params:set_action("filter "..i.." bp", function(x) softcut.post_filter_bp(i+1,x) bank[i][bank[i].id].bp = x end)
    params:add_control("filter "..i.." dry", "filter "..banks[i].." dry", controlspec.new(0, 1, 'lin', 0, 0, ""))
    params:set_action("filter "..i.." dry", function(x) softcut.post_filter_dry(i+1,x) bank[i][bank[i].id].fd = x end)
  end
  
end

return start_up