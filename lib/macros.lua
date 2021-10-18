local Container = {}
local Macro = {}

-- user-replaceable tables!
Container.delay_rates = {0.25,0.5,1,2,4,8,16}
Container.pad_rates = {-4,-2,-1,-0.5,-0.25,-0.125,0.125,0.25,0.5,1,2,4}
Container.default_pad_rate = 1
--/ user-replaceable tables!
Container.lfos = {"macro 1","macro 2","macro 3","macro 4","macro 5","macro 6","macro 7","macro 8"}
Container.NUM_LFOS = 8
Container.LFO_MIN_TIME = 1 -- Secs
Container.LFO_MAX_TIME = 60 * 60 * 24
Container.LFO_UPDATE_FREQ = 128
Container.LFO_RESOLUTION = 128 -- MIDI CC resolution
Container.lfo_freqs = {}
Container.lfo_progress = {}
Container.lfo_values = {}

local lfo_rates = {1/4,5/16,1/3,3/8,1/2,3/4,1,1.5,2,3,4,6,8,16,32,64,128,256,512,1024}

function Container.update_freqs()
  for i = 1, Container.NUM_LFOS do
    Container.lfo_freqs[i] = 1 / util.linexp(1, Container.NUM_LFOS, 1, 1, i)
  end
end

function Container.reset_phase(which)
  if which == nil then
    for i = 1, Container.NUM_LFOS do
      Container.lfo_progress[i] = math.pi * 1.5
    end
  else
    Container.lfo_progress[which] = math.pi * 1.5
  end
end

function Container.lfo_update()
  local delta = (1 / Container.LFO_UPDATE_FREQ) * 2 * math.pi
  for i = 1, Container.NUM_LFOS do
    Container.lfo_progress[i] = Container.lfo_progress[i] + delta * Container.lfo_freqs[i]
    local value = util.round(util.linlin(-1, 1, 0, Container.LFO_RESOLUTION - 1, math.sin(Container.lfo_progress[i])))
    if value ~= Container.lfo_values[i] then
      Container.lfo_values[i] = value
      if params:string("lfo_macro "..i) == "on" then
        if params:string("lfo_shape_macro "..i) == "sine" then
          params:set("macro "..i, value)
        elseif params:string("lfo_shape_macro "..i) == "square" then
          params:set("macro "..i, value >= 63 and 127 or 0)
        elseif params:string("lfo_shape_macro "..i) == "random" then
          local comparator = value >= 63 and 127 or 0
          if value == 0 or value == 127 then
            params:set("macro "..i, math.random(0,127))
          end
        end
      end
    end
  end
  screen_dirty = true
end


function Container:new_macro(args)
  local ind = Macro:new()
  return ind
end

function Macro:set_param(id,prm)
  self.params[id].params_name = prm
end

function Macro:delta_target(id,d)
  local max = self.params[id].params_name == "macro" and 8 or (self.params[id].params_name:find("delay") and 2 or 3)
  self.params[id].target = util.clamp(self.params[id].target + d,1,max)
end

function Macro:delta_min(id,d,divisor)
  local min = default_vals[self.params[id].params_name].min
  local max = default_vals[self.params[id].params_name].max
  self.params[id].min = util.clamp(self.params[id].min + (d/divisor),min,max)
end

function Macro:delta_max(id,d,divisor)
  local min = default_vals[self.params[id].params_name].min
  local max = default_vals[self.params[id].params_name].max
  self.params[id].max = util.clamp(self.params[id].max + (d/divisor),min,max)
end

function Macro:delta_curve(id,d)
  local lookup = tab.key(easingFunctions.easingNames,self.params[id].curve)
  local max = #easingFunctions.easingNames
  self.params[id].curve = easingFunctions.easingNames[util.clamp(lookup + d,1,max)]
end

-- ideally, a move_start parameter would have min/max that matches the min/max of the clip the pad's pointed to...
-- in a generic case, we'd just want to have "delta min/max" and every time it passes a new value, it sends a delta of +/-1 to the param
-- just a sweet spot of values that send the delta -- so min: 60, max: 64 will send +/- 1 delta to parameter only when macro is between
---- those positions.

default_vals =
{
  ["none"] =
  {
    params_name = "none"
  , enabled = false
  , destructive = true
  , min = "-"
  , max = "-"
  , target = "-"
  , curve = "-"
  }
, ["current pad"] =
  {
    params_name = "current pad"
  , enabled = false
  , destructive = true
  , min = 1
  , max = 16
  , target = 1
  , curve = "linear"
  }
, ["rate"] =
  {
    params_name = "rate"
  , enabled = false
  , destructive = true
  , min = 1
  , max = #Container.pad_rates
  , target = 1
  , curve = "linear"
  }
, ["pan"] =
  {
    params_name = "pan"
  , enabled = false
  , destructive = true
  , min = -1
  , max = 1
  , target = 1
  , curve = "linear"
  }
, ["filter tilt"] =
  {
    params_name = "filter tilt"
  , enabled = false
  , destructive = true
  , min = -1
  , max = 1
  , target = 1
  , curve = "linear"
  }
, ["start point"] =
  {
    params_name = "start point"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 127
  , target = 1
  , curve = "linear"
  }
, ["end point"] =
  {
    params_name = "end point"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 127
  , target = 1
  , curve = "linear"
  }
, ["start (delta)"] =
  {
    params_name = "start (delta)"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 127
  , target = 1
  , curve = "linear"
  , last_val = 0
  }
, ["end (delta)"] =
  {
    params_name = "end (delta)"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 127
  , target = 1
  , curve = "linear"
  , last_val = 0
  }
, ["delay div/mult"] =
  {
    params_name = "delay div/mult"
  , enabled = false
  , destructive = true
  , min = 1
  , max = 98
  , target = 1
  , curve = "linear"
  }
, ["delay free time"] =
  {
    params_name = "delay free time"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 30
  , target = 1
  , curve = "linear"
  }
, ["delay rate"] =
  {
    params_name = "delay rate"
  , enabled = false
  , destructive = true
  , min = 1
  , max = #Container.delay_rates
  , target = 1
  , curve = "linear"
  }
, ["delay pan"] =
  {
    params_name = "delay pan"
  , enabled = false
  , destructive = true
  , min = -1
  , max = 1
  , target = 1
  , curve = "linear"
  }
, ["rec_live_"] =
  {
    params_name = "rec_live_"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 1
  , target = 1
  , curve = "linear"
  }
, ["macro"] =
  {
    params_name = "macro"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 127
  , target = 1
  , curve = "linear"
  }
, ["w/curve"] =
  {
    params_name = "w/curve"
  , enabled = false
  , destructive = true
  , min = -5
  , max = 5
  , target = 1
  , curve = "linear"
  }
, ["w/ramp"] =
  {
    params_name = "w/ramp"
  , enabled = false
  , destructive = true
  , min = -5
  , max = 5
  , target = 1
  , curve = "linear"
  }
, ["w/fm index"] =
  {
    params_name = "w/fm index"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 5
  , target = 1
  , curve = "linear"
  }
, ["w/fm env"] =
  {
    params_name = "w/fm env"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 5
  , target = 1
  , curve = "linear"
  }
, ["w/fm num"] =
  {
    params_name = "w/fm num"
  , enabled = false
  , destructive = true
  , min = 1
  , max = 20
  , target = 1
  , curve = "linear"
  }
, ["w/fm den"] =
  {
    params_name = "w/fm den"
  , enabled = false
  , destructive = true
  , min = 1
  , max = 20
  , target = 1
  , curve = "linear"
  }
, ["w/lpg time"] =
  {
    params_name = "w/lpg time"
  , enabled = false
  , destructive = true
  , min = -5
  , max = 5
  , target = 1
  , curve = "linear"
  }
, ["w/lpg symm"] =
  {
    params_name = "w/lpg symm"
  , enabled = false
  , destructive = true
  , min = -5
  , max = 5
  , target = 1
  , curve = "linear"
  }
}

function Macro:generate_default_params()
  return {
    params_name = "none"
  , enabled = false
  , destructive = true
  , min = "-"
  , max = "-"
  , target = "-"
  , curve = "-"
  }
end

--- "private" method to instantiate a new pattern, only called by Container:new_macro()
function Macro:new()
  local m = setmetatable({}, { __index = Macro })
  m.in_min = 0
  m.in_max = 127
  m.mode = "range"
  m.destructive = false
  m.out_min = 0
  m.out_max = 127
  m.last_val = 0
  m.focus = "none" -- what is this???
  m.control_source = "PARAMS"
  m.enabled = false
  m.params =
  { 
    self:generate_default_params()
  , self:generate_default_params()
  , self:generate_default_params()
  , self:generate_default_params()
  , self:generate_default_params()
  , self:generate_default_params()
  , self:generate_default_params()
  , self:generate_default_params()
  }
  return m
end

function Macro:pass_value(val)
  local m = self.params
  for i = 1,#m do
    if m[i].params_name ~= "none" then
      if string.find(m[i].params_name, "delta") == nil then
        if m[i].enabled == true then
          local target = m[i].target
          -- local name = m[i].params_name..(m[i].destructive and (" ".. target) or (" non-destructive "..target))
          local name;
          if string.find(m[i].params_name, "w/") ~= nil then
            name = m[i].params_name
          elseif string.find(m[i].params_name, "rec_live_") ~= nil then
            name = m[i].params_name..target
          elseif string.find(m[i].params_name, "pan_lfo_rate_") ~= nil then
            name = m[i].params_name..target
          elseif string.find(m[i].params_name, "level_lfo_rate_") ~= nil then
            name = m[i].params_name..target
          else
            name = m[i].params_name..(m[i].destructive and (" ".. target) or (" non-destructive "..target))
          end
          local min = m[i].min
          local max = m[i].max
          local eased_val = easingFunctions[m[i].curve](val/self.in_max,self.in_min,self.in_max,1)
          local new_val = util.linlin(self.in_min,self.in_max,min,max,eased_val)
          if m[i].destructive then
            if m[i].params_name ~= "filter dynamic freq" then
              params:set(name,new_val)
              if menu == 5 then screen_dirty = true end
            else
              params:set(name,eased_val > 64 and 1 or 0)
            end
          else
            params:set(name.." non-destructive")
          end
        end
      elseif string.find(m[i].params_name, "delta") ~= nil then
        if m[i].enabled == true then
          if (val >= m[i].min and val <= m[i].max) or (val <= m[i].min and val >= m[i].max) then
            local target = m[i].target
            local name = m[i].params_name..(m[i].destructive and (" ".. target) or (" non-destructive "..target))
            local min = 0
            local max = 127
            local eased_val = easingFunctions[m[i].curve](val/self.in_max,self.in_min,self.in_max,1)
            local new_val = util.linlin(self.in_min,self.in_max,min,max,eased_val)
            if m[i].destructive then
              -- params:set(name,math.floor(new_val))
              if val == m[i].min then
                params:set(name,64)
              else
                -- params:delta(name,val - m[i].last_val)
                params:delta(name,(val >= m[i].min and val <= m[i].max) and (val - m[i].last_val) or (m[i].last_val - val))
              end
            else
              params:set(name.." non-destructive")
            end
          end
          m[i].last_val = val
        end
      end
    end
  end
end

local parameter_names = 
{
  "none"
, "current pad"
, "rate"
, "pan"
, "filter tilt"
, "start point"
, "end point"
, "start (delta)"
, "end (delta)"
, "delay div/mult"
, "delay free time"
, "delay rate"
, "delay pan"
, "rec_live_"
, "macro"
, "w/curve"
, "w/ramp"
, "w/fm index"
, "w/fm env"
, "w/fm num"
, "w/fm den"
, "w/lpg time"
, "w/lpg symm"
}

function Macro:cycle_entry(d,id)
  local p = page.macros
  if id == 1 then
    local current = macro[p.selected_macro].params[p.param_sel[p.selected_macro]]
    local now_val = tab.key(parameter_names,current.params_name)
    now_val = util.clamp(now_val+d,1,#parameter_names)
    macro[p.selected_macro]:set_param(p.param_sel[p.selected_macro],parameter_names[now_val])
    for k,v in pairs(default_vals[parameter_names[now_val]]) do
      macro[p.selected_macro].params[p.param_sel[p.selected_macro]][k] = v
    end
  elseif id == 2 then
    macro[p.selected_macro]:delta_target(p.param_sel[p.selected_macro],d)
  elseif id == 3 then
    local current = macro[p.selected_macro].params[p.param_sel[p.selected_macro]]
    local params_with_fine = {"pan","filter tilt","delay pan","delay free time"}
    local div = tab.contains(params_with_fine,current.params_name) and 10 or 1
    macro[p.selected_macro]:delta_min(p.param_sel[p.selected_macro],d,div)
  elseif id ==  4 then
    local current = macro[p.selected_macro].params[p.param_sel[p.selected_macro]]
    local params_with_fine = {"pan","filter tilt","delay pan","delay free time"}
    local div = tab.contains(params_with_fine,current.params_name) and 10 or 1
    macro[p.selected_macro]:delta_max(p.param_sel[p.selected_macro],d,div)
  elseif id == 5 then
    macro[p.selected_macro]:delta_curve(p.param_sel[p.selected_macro],d)
    -- easingFunctions.easingNames
  end
end

function Container.enc(n,d)
  local p = page.macros
  local current_line = p.edit_focus[p.selected_macro]
  if n == 1 then
    p.selected_macro = util.clamp(p.selected_macro+d,1,8)
  elseif n == 2 then
    if page.macros.mode == "setup" then
      local reasonable_max = macro[p.selected_macro].params[p.param_sel[p.selected_macro]].params_name ~= "none" and 7 or 2
      p.edit_focus[p.selected_macro] = util.clamp(p.edit_focus[p.selected_macro] + d,1,reasonable_max)
    elseif page.macros.mode == "perform" then
      p.perform_focus[p.selected_macro] = util.clamp(p.perform_focus[p.selected_macro] + d,1,5)
    end
  elseif n == 3 then
    if page.macros.mode == "perform" then
      if p.perform_focus[p.selected_macro] == 1 then
        params:delta("macro "..p.selected_macro,d)
      else
        local f = p.perform_focus[p.selected_macro]-1
        local params_to_adjust =
        {
          "lfo_macro "..p.selected_macro,
          "lfo_shape_macro "..p.selected_macro,
          "lfo_mode_macro "..p.selected_macro,
          "lfo_rate_macro "..p.selected_macro,
        }
        if params:string("lfo_mode_macro "..p.selected_macro) == "beats" then
          params_to_adjust[4] = "lfo_beats_macro "..p.selected_macro
        else
          params_to_adjust[4] = "lfo_free_macro "..p.selected_macro
        end
        params:delta(params_to_adjust[f],d)
      end
    elseif page.macros.mode == "setup" then
      if p.edit_focus[p.selected_macro] == 1 then
        p.param_sel[p.selected_macro] = util.clamp(p.param_sel[p.selected_macro] + d,1,8)
        p.edit_focus[p.selected_macro] = 1
      elseif p.edit_focus[p.selected_macro] > 1 and p.edit_focus[p.selected_macro] < 7  then
        macro[p.selected_macro]:cycle_entry(d,p.edit_focus[p.selected_macro]-1)
      elseif p.edit_focus[p.selected_macro] == 7  then
        macro[p.selected_macro].params[p.param_sel[p.selected_macro]].enabled = d > 0 and true or false
      end
    end
  end
end

local last_section = 1

function Container.key(n,z)
  local p = page.macros
  if n == 1 then
    key1_hold = z == 1 and true or false
    -- page.macros.alt_menu = z == 1 and true or false
    if z == 1 then
      page.macros.mode = page.macros.mode == "setup" and "perform" or "setup"
      if p.mode == "setup" then
        last_section = p.section
        p.section = 3
      end
    elseif z == 0 then
      if p.mode == "setup" then
        p.section = last_section
      end
    end
  elseif n == 3 and z == 1 then
    if key1_hold then
      -- page.macros.mode = page.macros.mode == "setup" and "perform" or "setup"
    else
      if p.mode == "setup" then
        -- p.section = wrap(p.section+1,1,2)
      elseif p.mode == "perform" then
        if p.perform_focus[p.selected_macro] == 1 then
          params:set("macro "..p.selected_macro,math.random(macro[p.selected_macro].in_min,macro[p.selected_macro].in_max))
        end
      end
    end
  elseif n == 2 and z == 1 then
    if key1_hold then
      if p.mode == "setup" then
        local current_state = macro[p.selected_macro].params[p.param_sel[p.selected_macro]].enabled
        for i = 1,8 do
          if macro[p.selected_macro].params[i].params_name ~= "none" then
            macro[p.selected_macro].params[i].enabled = not current_state
          end
        end
      end
    else
      menu = 1
      key1_hold = false
    end
  end
end

function Container:add_params()
  params:add_group("macros",8*8)
  for i = 1,8 do
    params:add_separator("macro "..i)
    params:add_number("macro "..i, "macro "..i.." current value", 0,127,0)
    params:set_action("macro "..i, function(x) if all_loaded then macro[i]:pass_value(x) end end)
    params:add_option("lfo_macro "..i,"macro "..i.." lfo",{"off","on"},1)
    params:set_action("lfo_macro "..i,function(x)
      -- self:refresh_params()
    end)
    params:add_option("lfo_mode_macro "..i, "lfo mode", {"beats","free"},1)
    params:set_action("lfo_mode_macro "..i,
      function(x)
        if x == 1 then
          params:hide("lfo_free_macro "..i)
          params:show("lfo_beats_macro "..i)
        elseif x == 2 then
          params:hide("lfo_beats_macro "..i)
          params:show("lfo_free_macro "..i)
        end
        _menu.rebuild_params()
      end
      )
    params:add_option("lfo_beats_macro "..i, "lfo rate", {"1/4","5/16","1/3","3/8","1/2","3/4","1","1.5","2","3","4","6","8","16","32","64","128","256","512","1024"},7)
    params:set_action("lfo_beats_macro "..i,
      function(x)
        if params:string("lfo_mode_macro "..i) == "beats" then
          Container.lfo_freqs[i] = 1/(clock.get_beat_sec() * lfo_rates[x])
        end
      end
    )
    params:add {
      type='control',
      id="lfo_free_macro "..i,
      name="lfo rate",
      controlspec=controlspec.new(0.001,1,'lin',0.001,0.05,'hz',0.01)
    }
    params:set_action("lfo_free_macro "..i,
      function(x)
        if params:string("lfo_mode_macro "..i) == "free" then
          Container.lfo_freqs[i] = x
        end
      end
    )
    params:add_option("lfo_shape_macro "..i, "lfo shape", {"sine","square","random"},1)
    params:add_trigger("lfo_reset_macro "..i, "reset lfo")
    params:set_action("lfo_reset_macro "..i, function(x) Container.reset_phase(i) end)
    params:hide("lfo_free_macro "..i)
  end
  macros.reset_phase()
  macros.update_freqs()
  macros.lfo_update()
  metro.init(macros.lfo_update, 1 / macros.LFO_UPDATE_FREQ):start()
end

function Container:convert(prm,trg,indx,controlspec_type)
  -- prm = macro[x].params[y]
  local lookup_name = prm.params_name
  if lookup_name ~= "none" then
    local id;
    if string.find(lookup_name,"w/") == nil then
      if string.find(lookup_name,"rec_live") == nil and string.find(lookup_name,"pan_lfo_rate_") == nil and string.find(lookup_name,"level_lfo_rate_") == nil then
        id = params.lookup[lookup_name.." "..trg]
      else
        id = params.lookup[lookup_name..trg]
      end
    else
      id = params.lookup[lookup_name]
    end
    -- params types
    -- 1 = number
    -- 2 = options
    -- 3 = controlspec
    if params.params[id].t == 1 then
      return tonumber(string.format("%.0f",indx))
    elseif params.params[id].t == 2 then
      return params.params[id].options[indx]
    elseif params.params[id].t == 3 then
      if controlspec_type == "minval" then
        return tonumber(string.format("%.4g",util.round(prm.min,0.1)))
      elseif controlspec_type == "maxval" then
        -- return prm.max
        return tonumber(string.format("%.4g",util.round(prm.max,0.1)))
      end
    elseif params.params[id].t == 9 then
      if controlspec_type == "minval" then
        return 0
      elseif controlspec_type == "maxval" then
        return 1
      end
    end
  elseif lookup_name == "none" then
    return "-"
  end
end

local bank_names = {"bank a", "bank b", "bank c"}

function get_target_display_name(prm,trg)
  if prm == "none" then
    return "-"
  elseif prm == "macro" then
    return "macro "..trg
  elseif string.find(prm,"delay")~= nil then
    if trg == 1 then
      return "L"
    else
      return "R"
    end
  elseif string.find(prm,"w/")~= nil then
    return "w/synth"
  elseif string.find(prm,"rec_live_")~= nil then
    return "live "..trg
  else
    return bank_names[trg]
  end
end

function Container.UI_init()
  page.macros = {}
  page.macros.selected_macro = 1
  page.macros.section = 1
  page.macros.param_sel = {}
  page.macros.edit_focus = {}
  page.macros.perform_focus = {}
  page.macros.mode = "setup"
  for i = 1,8 do
    page.macros.param_sel[i] = 1
    page.macros.edit_focus[i] = 1
    page.macros.perform_focus[i] = 1
  end
end

function Container.UI()
  local p = page.macros
  screen.move(0,10)
  screen.level(3)
  screen.text("macros")

  local header = {"1","2","3","4","5","6","7","8"}
  for i = 1,8 do
    screen.level(p.selected_macro == i and 15 or 3)
    screen.move(40+(i*10),10)
    screen.text(header[i])
  end

  screen.level(p.selected_macro == p.selected_macro and 15 or 3)
  screen.move(40+(p.selected_macro*10),13)
  screen.text("_")
  
  if p.mode == "setup" then
  
    screen.level(3)
    screen.move(0,20)
    screen.level(3)

    local current = macro[p.selected_macro].params[p.param_sel[p.selected_macro]]
    local edit_focus = p.edit_focus[p.selected_macro] -- this is key!
    screen.level(edit_focus == 1 and 15 or 3)
    screen.font_size(40)
    screen.move(0,42)
    screen.text(p.param_sel[p.selected_macro])

    screen.font_size(8)
    screen.level(edit_focus == 7 and 15 or 3)
    screen.rect(0,54,128,7)
    screen.fill()
    screen.level(0)
    screen.move(2,60)
    local on = macro[p.selected_macro].params[p.param_sel[p.selected_macro]].enabled == true and "active" or "inactive"
    screen.text("macro["..p.selected_macro.."]["..p.param_sel[p.selected_macro].."]: "..on)
    -- screen.text("macro "..p.selected_macro.." source: "..macro[p.selected_macro].control_source)

    screen.level(3)
    screen.font_size(8)
    screen.move(30,21)
    screen.level(edit_focus == 2 and 15 or 3)
    local special_cases =
      {
        ["rec_live_"] = "live rec toggle",
        ["pan_lfo_rate_"] = "pan LFO rate",
        ["level_lfo_rate_"] = "level LFO rate",
        ["filter dynamic freq"] = "filter dyn freq"
      }
    local display_name = special_cases[current.params_name] ~= nil and special_cases[current.params_name] or current.params_name
    -- local display_name = current.params_name ~= "rec_live_" and current.params_name or "live rec toggle"
    screen.text("param: "..display_name)

    screen.move(30,31)
    screen.level(edit_focus == 3 and 15 or 3)
    -- screen.text("target: "..(current.params_name == "macro" and "macro "..current.target or (current.params_name == "none" and "-" or bank_names[current.target])))
    -- screen.text("target: "..current.target)
    screen.text("target: "..get_target_display_name(current.params_name,current.target))

    screen.move(30,41)
    screen.level(edit_focus == 4 and 15 or 3)
    screen.text("min: "..Container:convert(current,current.target,current.min,"minval"))
    screen.move_rel(5,0)
    screen.level(edit_focus == 5 and 15 or 3)
    screen.text("max: "..Container:convert(current,current.target,current.max,"maxval"))

    screen.move(30,51)
    screen.level(edit_focus == 6 and 15 or 3)
    screen.text("curve: "..current.curve)
  
  elseif p.mode == "perform" then
    local current = macro[p.selected_macro].params[p.param_sel[p.selected_macro]]
    local edit_focus = p.perform_focus[p.selected_macro]
    screen.level(edit_focus == 1 and 15 or 3)
    screen.rect(0,18,66,13)
    screen.fill()
    screen.level(edit_focus == 1 and 0 or 10)
    screen.move(33,30)
    screen.font_size(18)
    screen.text_center("value")
    screen.level(edit_focus == 1 and 15 or 3)
    screen.move(33,60)
    screen.font_size(40)
    screen.text_center(util.round(params:get("macro "..p.selected_macro)))
    local lfo_section =
    {
      "LFO: "..(params:string("lfo_macro "..p.selected_macro)),
      "SHP: "..(params:string("lfo_shape_macro "..p.selected_macro)),
      -- "DPTH: "..macro[p.selected_macro].lfo.depth,
      "MODE: "..(params:string("lfo_mode_macro "..p.selected_macro)),
      "RATE: "..(
        params:string("lfo_mode_macro "..p.selected_macro) == "beats" and 
          params:get("lfo_beats_macro "..p.selected_macro) or
          params:get("lfo_free_macro "..p.selected_macro)
        )
    }
    screen.font_size(8)
    for i = 1,#lfo_section do
      screen.level(edit_focus == i + 1 and 15 or 3)
      screen.move(75,15+(10*i))
      screen.text(lfo_section[i])
    end
  end

end

return Container