local Container = {}
local Macro = {}

-- user-replaceable tables!
Container.delay_rates = {0.25,0.5,1,2,4,8,16}
Container.pad_rates = {-4,-2,-1,-0.5,-0.25,-0.125,0.125,0.25,0.5,1,2,4}
Container.default_pad_rate = 1
--/ user-replaceable tables!

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
, ["bank level"] =
  {
    params_name = "bank level"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 127
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
, ["delay output"] =
  {
    params_name = "delay output"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 1
  , target = 1
  , curve = "linear"
  }
, ["delay input a"] =
  {
    params_name = "delay input a"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 1
  , target = 1
  , curve = "linear"
  }
, ["delay input b"] =
  {
    params_name = "delay input b"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 1
  , target = 1
  , curve = "linear"
  }
, ["delay input c"] =
  {
    params_name = "delay input c"
  , enabled = false
  , destructive = true
  , min = 0
  , max = 1
  , target = 1
  , curve = "linear"
  }
, ["delay input ext"] =
  {
    params_name = "delay input ext"
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
          if string.find(m[i].params_name, "w/") == nil then
            name = m[i].params_name..(m[i].destructive and (" ".. target) or (" non-destructive "..target))
          else
            name = m[i].params_name
          end
          local min = m[i].min
          local max = m[i].max
          local eased_val = easingFunctions[m[i].curve](val/self.in_max,self.in_min,self.in_max,1)
          local new_val = util.linlin(self.in_min,self.in_max,min,max,eased_val)
          if m[i].destructive then
            params:set(name,new_val)
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
  if menu == "macro_config" then
    screen_dirty = true
  end
end

local parameter_names = 
{
  "none"
, "current pad"
, "rate"
, "pan"
, "bank level"
, "filter tilt"
, "start point"
, "end point"
, "start (delta)"
, "end (delta)"
, "delay div/mult"
, "delay free time"
, "delay rate"
, "delay pan"
, "delay input a"
, "delay input b"
, "delay input c"
, "delay input ext"
, "delay output"
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
    local params_with_fine = {"pan","filter tilt","delay pan"}
    local div = tab.contains(params_with_fine,current.params_name) and 10 or 1
    macro[p.selected_macro]:delta_min(p.param_sel[p.selected_macro],d,div)
  elseif id ==  4 then
    local current = macro[p.selected_macro].params[p.param_sel[p.selected_macro]]
    local params_with_fine = {"pan","filter tilt","delay pan"}
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
      if p.section == 1 then
        p.param_sel[p.selected_macro] = util.clamp(p.param_sel[p.selected_macro] + d,1,8)
        p.edit_focus[p.selected_macro] = 1
      elseif p.section == 2 then
        if macro[p.selected_macro].params[p.param_sel[p.selected_macro]].params_name ~= "none" then
          p.edit_focus[p.selected_macro] = util.clamp(p.edit_focus[p.selected_macro] + d,1,5)
        end
      elseif p.section == 3 then
        macro[p.selected_macro].params[p.param_sel[p.selected_macro]].enabled = d > 0 and true or false
      end
    end
  elseif n == 3 then
    if page.macros.mode == "perform" then
      params:delta("macro "..p.selected_macro,d)
    elseif page.macros.mode == "setup" then
      if p.section == 1 then
        p.param_sel[p.selected_macro] = util.clamp(p.param_sel[p.selected_macro] + d,1,8)
        p.edit_focus[p.selected_macro] = 1
      elseif p.section == 2 then
        macro[p.selected_macro]:cycle_entry(d,current_line)
      elseif p.section == 3 then
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
    if z == 1 then
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
      page.macros.mode = page.macros.mode == "setup" and "perform" or "setup"
    else
      if p.mode == "setup" then
        p.section = util.wrap(p.section+1,1,2)
      elseif p.mode == "perform" then
        params:set("macro "..p.selected_macro,math.random(macro[p.selected_macro].in_min,macro[p.selected_macro].in_max))
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
  params:add_group("macros",8)
  for i = 1,8 do
    params:add_number("macro "..i, "macro "..i, 0,127,0)
    params:set_action("macro "..i, 
    function(x)
      if all_loaded then
        macro[i]:pass_value(x)
      end
    end)
    _lfos:register("macro "..i, 'macro LFOs')
  end
  _lfos:add_params('macro LFOs')
end

function Container:convert(prm,trg,indx,controlspec_type)
  -- prm = macro[x].params[y]
  local lookup_name = prm.params_name
  if lookup_name ~= "none" then
    local id;
    if string.find(lookup_name,"w/") == nil then
      id = params.lookup[lookup_name.." "..trg]
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
  else
    return bank_names[trg]
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

    screen.level(p.section == 1 and 15 or 3)
    screen.font_size(40)
    screen.move(0,42)
    screen.text(p.param_sel[p.selected_macro])
    local current = macro[p.selected_macro].params[p.param_sel[p.selected_macro]]
    local edit_focus = p.edit_focus[p.selected_macro] -- this is key!
    screen.font_size(8)
    screen.level(p.section == 3 and 15 or 3)
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
    screen.level(p.section == 2 and (edit_focus == 1 and 15 or 3) or 3)
    screen.text("param: "..current.params_name)

    screen.move(30,31)
    screen.level(p.section == 2 and (edit_focus == 2 and 15 or 3) or 3)
    -- screen.text("target: "..(current.params_name == "macro" and "macro "..current.target or (current.params_name == "none" and "-" or bank_names[current.target])))
    -- screen.text("target: "..current.target)
    screen.text("target: "..get_target_display_name(current.params_name,current.target))

    screen.move(30,41)
    screen.level(p.section == 2 and (edit_focus == 3 and 15 or 3) or 3)
    screen.text("min: "..Container:convert(current,current.target,current.min,"minval"))
    screen.move_rel(5,0)
    screen.level(p.section == 2 and (edit_focus == 4 and 15 or 3) or 3)
    screen.text("max: "..Container:convert(current,current.target,current.max,"maxval"))

    screen.move(30,51)
    screen.level(p.section == 2 and (edit_focus == 5 and 15 or 3) or 3)
    screen.text("curve: "..current.curve)
  
  elseif p.mode == "perform" then
    screen.rect(0,18,128,13)
    screen.fill()
    screen.level(0)
    screen.move(60,30)
    screen.font_size(18)
    screen.text_center("current val")
    screen.level(15)
    screen.move(60,60)
    screen.font_size(40)
    screen.text_center(util.round(params:get("macro "..p.selected_macro)))
  end

end


return Container