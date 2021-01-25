local Container = {}
local Macro = {}

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

function Macro:delta_curve(id,d)
  local lookup = tab.key(easingFunctions.easingNames,self.params[id].curve)
  local max = #easingFunctions.easingNames
  self.params[id].curve = easingFunctions.easingNames[util.clamp(lookup + d,1,max)]
end

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
  , enabled = true
  , destructive = true
  , min = 1
  , max = 16
  , target = 1
  , curve = "linear"
  }
, ["rate"] =
  {
    params_name = "rate"
  , enabled = true
  , destructive = true
  , min = 1
  , max = 12
  , target = 1
  , curve = "linear"
  }
, ["pan"] =
  {
    params_name = "pan"
  , enabled = true
  , destructive = true
  , min = -1
  , max = 1
  , target = 1
  , curve = "linear"
  }
, ["filter tilt"] =
  {
    params_name = "filter tilt"
  , enabled = true
  , destructive = true
  , min = -1
  , max = 1
  , target = 1
  , curve = "linear"
  }
, ["start point"] =
  {
    params_name = "start point"
  , enabled = true
  , destructive = true
  , min = 1
  , max = 127
  , target = 1
  , curve = "linear"
  }
, ["end point"] =
  {
    params_name = "end point"
  , enabled = true
  , destructive = true
  , min = 1
  , max = 127
  , target = 1
  , curve = "linear"
  }
, ["delay free time"] =
  {
    params_name = "delay free time"
  , enabled = true
  , destructive = true
  , min = 1
  , max = 30
  , target = 1
  , curve = "linear"
  }
, ["macro"] =
  {
    params_name = "macro"
  , enabled = true
  , destructive = true
  , min = 1
  , max = 127
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
  m.focus = "none" -- what is this???
  m.control_source = "PARAMS"
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
      if m[i].enabled == true then
        local target = m[i].target
        local name = m[i].params_name..(m[i].destructive and (" ".. target) or (" non-destructive "..target))
        local id = params.lookup[m[i].params_name.." "..target]
        local min = m[i].min
        local max = m[i].max
        local eased_val = easingFunctions[m[i].curve](val/self.in_max,self.in_min,self.in_max,1)
        -- local eased_val = easingFunctions[m[i].curve](val/127,0,127,1)
        local new_val = util.linlin(self.in_min,self.in_max,min,max,eased_val)
        --easingFunctions[self.curve](x/12000,10,11990,1)
        if m[i].destructive then
          params:set(name,new_val)
        else
          params:set(name.." non-destructive")
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
, "delay free time"
, "macro"
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
    local div = current.params_name == "pan" and 10 or (current.params_name == "filter tilt" and 10 or 1)
    macro[p.selected_macro]:delta_min(p.param_sel[p.selected_macro],d,div)
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
    if p.section == 1 then
      p.param_sel[p.selected_macro] = util.clamp(p.param_sel[p.selected_macro] + d,1,8)
      p.edit_focus[p.selected_macro] = 1
    elseif p.section == 2 then
      if macro[p.selected_macro].params[p.param_sel[p.selected_macro]].params_name ~= "none" then
        p.edit_focus[p.selected_macro] = util.clamp(p.edit_focus[p.selected_macro] + d,1,5)
      end
    elseif p.section == 3 then
      local sources = {["PARAMS"] = 1, ["crow in 1"] = 2, ["crow in 2"] = 3}
      local current = sources[macro[p.selected_macro].control_source]
      sources = tab.invert(sources)
      macro[p.selected_macro].control_source = sources[util.clamp(current+d,1,3)]
    end
  elseif n == 3 then
    if page.macros.mode == "perform" then
      params:delta("macro "..p.selected_macro,d)
    elseif page.macros.mode == "setup" then
      if p.section == 2 then
        macro[p.selected_macro]:cycle_entry(d,current_line)
      end
    end
  end
end

function Container.key(n,z)
  local p = page.macros
  if n == 1 then
    key1_hold = z == 1 and true or false
    if z == 1 then
      page.macros.mode = page.macros.mode == "setup" and "perform" or "setup"
    end
  elseif n == 3 and z == 1 then
    if page.macros.mode == "setup" then
      p.section = util.wrap(p.section+1,1,3)
    elseif page.macros.mode == "perform" then
      params:set("macro "..p.selected_macro,math.random(macro[p.selected_macro].in_min,macro[p.selected_macro].in_max))
    end
  elseif n == 2 and z == 1 then
    menu = 1
    key1_hold = false
  end
end

function Container:add_params()
  params:add_group("macros",8)
  for i = 1,8 do
    params:add_number("macro "..i, "macro "..i, 0,127,0)
    params:set_action("macro "..i, function(x) if all_loaded then macro[i]:pass_value(x) end end)
  end
end

function Container:convert(prm,trg,indx,controlspec_type)
  -- prm = macro[x].params[y]
  local lookup_name = prm.params_name
  if lookup_name ~= "none" then
    local id = params.lookup[lookup_name.." "..trg]
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
        return tonumber(string.format("%.2g",util.round(prm.min,0.1)))
      elseif controlspec_type == "maxval" then
        return prm.max
      end
    end
  else
    return "-"
  end
end

local bank_names = {"bank a", "bank b", "bank c"}

function get_target_display_name(prm,trg)
  if prm == "none" then
    return "-"
  elseif prm == "macro" then
    return "macro "..trg
  elseif prm == "delay free time" then
    if trg == 1 then
      return "L"
    else
      return "R"
    end
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
    screen.text("macro "..p.selected_macro.." source: "..macro[p.selected_macro].control_source)

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
    screen.text_center(params:get("macro "..p.selected_macro))
  end

end


return Container