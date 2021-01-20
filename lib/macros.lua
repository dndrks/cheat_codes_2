local Container = {}
local Macro = {}

-- function Macros:new(args)
--   return args
-- end

-- start with absolute

-- function Macros:init(args)
--   local m = setmetatable({}, { __index = Macros })
--   local args = args == nil and {} or args
--   m.in_min = args.in_min == nil and 0 or args.in_min
--   m.in_max = args.in_max == nil and 127 or args.in_max
--   m.mode = args.mode == nil and "range" or args.mode
--   m.destructive = args.destructive == nil and false or args.destructive
--   m.out_min = args.out_min == nil and 0 or args.out_min
--   m.out_max = args.out_max == nil and 127 or args.out_max
--   m.focus = args.focus == nil and "none" or args.focus
--   m.params =
--   {
--     {
--       param_name = "current pad"
--     , enabled = false
--     , destructive = true
--     , min = 1
--     , max = 16
--     , target = 1
--     -- , thresholds = {} -- this should be able to be changed, so you can stack a ton of functions in a small range
--     , thresholds = Macros:default_thresholds() -- this should be able to be changed, so you can stack a ton of functions in a small range
--     }
--   }
--   return m
-- end

-- function Macros:default_thresholds(target)
--   local thresholds = {}
--   for i = 1, 16 do
--     thresholds[i] = util.round(util.linlin(1,16,0,127,i))
--   end
--   return thresholds
-- end

-- function Macros:create_param()
-- end

-- Macros.ranges =
-- {
--   ["pan"] =
--   {
--     ["min"] = -100
--   , ["max"] = 100
--   }
-- , ["rate"] =
--   {
--     ["values"] = {-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
--   , ["min"] = 1
--   , ["max"] = 13
--   }
-- }

-- Macros.maps =
-- {
--   ["pan"] = {-1,1}
-- , ["rate"] = {-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
-- }

-- function Macros:set_pan(target,val)
--   local new_val = util.linlin(self.in_min,self.in_max,self.ranges["pan"]["min"],self.ranges["pan"]["max"],val)/100
--   if self.destructive then
--     target.pan = new_val
--   end
--   softcut.pan(target.bank_id+1,new_val)
-- end

-- function Macros:set_rate(target,val)
--   local new_val = util.round(util.linlin(self.in_min,self.in_max,self.windows["rate"]["min"],self.windows["rate"]["max"],val))
--   if self.destructive then
--     target.rate = self.windows["rate"]["values"][new_val]
--   end
--   softcut.rate(target.bank_id+1,self.windows["rate"]["values"][new_val]*target.offset)
-- end

-- -- function Macros:update_quantized_rates(pos,val)
-- --   self.windows["quantized_rates"][pos] = val
-- --   self.windows["quantized_rates_max"] = #self.windows["quantized_rates"]
-- -- end

-- function Macros:get_loop_min(target)
--   return target.mode == 1 and live[target.clip].min or clip[target.clip].min
-- end

-- function Macros:get_loop_max(target)
--   return target.mode == 1 and live[target.clip].max or clip[target.clip].max
-- end

-- function Macros:set_loop_start(target,val)
--   local lo = self:get_loop_min(target)
--   local max = self:get_loop_max(target)
--   local save_this = target.start_point
--   target.start_point = util.round(util.clamp(util.linlin(self.in_min,self.in_max,lo,max,val),lo,target.end_point-0.1),0.1)
--   if save_this ~= target.start_point then
--     softcut.loop_start(target.bank_id+1,target.start_point)
--   end
--   params:set("start point "..target.bank_id,val,"true")
--   if menu ~= 1 then screen_dirty = true end
-- end

-- -- params.lookup["rate 1"] = 186
-- -- params.params[186].selected = 10
-- -- params.params[186].options[10] = "1x"
-- -- params.params[186].count = 12
-- -- t = 2?

-- -- params.lookup["pan 1"] = 188
-- -- params.params[188].raw = 0.5
-- -- params.params[188].controlspec.minval = -1
-- -- params.params[188].controlspec.maxval = 1
-- -- t = 3?

-- Macros.param_names =
-- {
--   "none"
-- , "current pad"
-- , "rate"
-- , "pan"
-- , "level"
-- , "bank level"
-- , "filter tilt"
-- , "start point"
-- , "end point"
-- , "macro"
-- }

function Container:new_macro(args)
  local ind = Macro:new()
  return ind
end

local parameter_names = 
{
  "none"
, "current pad"
, "rate"
, "pan"
, "level"
, "bank level"
, "filter tilt"
, "start point"
, "end point"
, "macro"
}

function Macro:set_param(id,prm)
  self.params[id].params_name = prm
end

local default_vals =
{
  params_name = "none"
, enabled = false
, destructive = true
, min = "-"
, max = "-"
, target = "-"
}


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
  { default_vals,default_vals,default_vals,default_vals,default_vals,default_vals,default_vals,default_vals,}
  return m
end

function Macro:pass_value(val)
  local m = self.params
  for i = 1,#m do
    if m[i].param_name ~= "none" then
      if m[i].enabled == true then
        local target = m[i].target
        local name = m[i].param_name..(m[i].destructive and (" ".. target) or (" non-destructive "..target))
        local id = params.lookup[m[i].param_name.." "..target]
        -- local t = nil
        -- if params.params[id].t == 3 then
        --   t = "controlspec"
        -- elseif params.params[id].t == 2 then
        --   t = "options"
        -- end
        local min = m[i].min
        local max = m[i].max
        local new_val = util.linlin(self.in_min,self.in_max,min,max,val)
        if m[i].destructive then
          params:set(name,new_val)
        else
          params:set(name.." non-destructive")
        end
      end
    end
  end
end

function Container.enc(n,d)
  local p = page.macros
  if n == 1 then
    p.selected_macro = util.clamp(p.selected_macro+d,1,8)
  elseif n == 2 then
    if p.section == 1 then
      p.param_sel[p.selected_macro] = util.clamp(p.param_sel[p.selected_macro] + d,1,8)
    elseif p.section == 2 then
      local current = macro[p.selected_macro].params[p.param_sel[p.selected_macro]]
      local now_val = tab.key(parameter_names,current.params_name)
      now_val = util.clamp(now_val+d,1,#parameter_names)
      macro[p.selected_macro]:set_param(p.selected_macro,parameter_names[now_val])
    end
  elseif n == 3 then
    if p.section == 1 then
      local sources = {["PARAMS"] = 1, ["crow in 1"] = 2, ["crow in 2"] = 3}
      local current = sources[macro[p.selected_macro].control_source]
      sources = tab.invert(sources)
      macro[p.selected_macro].control_source = sources[util.clamp(current+d,1,3)]
    end
  end
end

function Container.key(n,z)
  local p = page.macros
  if n == 3 and z == 1 then
    p.section = util.wrap(p.section+1,1,2)
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
  
  screen.level(3)
  screen.move(0,20)
  screen.level(3)

  screen.level(p.section == 1 and 15 or 3)
  screen.font_size(40)
  screen.move(0,42)
  screen.text(p.param_sel[p.selected_macro])
  local current = macro[p.selected_macro].params[p.param_sel[p.selected_macro]]
  local edit_line = p.edit_line[p.selected_macro] -- this is key!
  screen.font_size(8)
  screen.level(p.section == 1 and 15 or 3)
  screen.rect(0,54,128,7)
  screen.fill()
  screen.level(0)
  screen.move(2,60)
  -- screen.text(tostring(current.enabled) == "true" and "active" or "")
  screen.text("macro "..p.selected_macro.." source: "..macro[p.selected_macro].control_source)

  screen.level(3)
  screen.move(0,20)
  screen.font_size(8)
  screen.move(30,22)
  screen.level(p.section == 2 and (edit_line == 1 and 15 or 3) or 3)
  screen.text("param: "..current.params_name)

  screen.move(30,32)
  screen.level(p.section == 2 and (edit_line == 2 and 15 or 3) or 3)
  screen.text("target: "..current.target)

  screen.move(30,42)
  screen.level(p.section == 2 and ((edit_line == 3 or edit_line == 4) and 15 or 3) or 3)
  screen.text("min: "..current.min)
  screen.move_rel(5,0)
  screen.text("max: "..current.max)

  screen.level(p.section == 2 and (edit_line == 3 and 15 or 3) or 3)
  screen.move(30,52)
  -- screen.text(current.num)
  screen.move_rel(1,0)
  screen.level(p.section == 2 and ((edit_line == 3 or edit_line == 4) and 15 or 3) or 3)
  -- screen.text("/")
  screen.level(p.section == 2 and (edit_line == 4 and 15 or 3) or 3)
  screen.move_rel(1,0)
  -- screen.text(current.denom)
  -- local params_to_mins =
  -- { ["pan"] = {"min: "..(current.pan_min < 0 and "L " or "R ")..math.abs(current.pan_min)}
  -- , ["rate"] = {"min: "..current.rate_min}
  -- , ["rate slew"] = {"min: "..string.format("%.1f",current.rate_slew_min)}
  -- , ["delay send"] = {""}
  -- , ["loop"] = {""}
  -- , ["semitone offset"] = {current.offset_scale:lower()}
  -- , ["filter tilt"] = {"min: "..string.format("%.2f",current.filter_min)}
  -- }
  -- local params_to_maxs = 
  -- { ["pan"] = {"max: "..(current.pan_max > 0 and "R " or "L ")..math.abs(current.pan_max)}
  -- , ["rate"] = {"max: "..current.rate_max}
  -- , ["rate slew"] = {"max: "..string.format("%.1f",current.rate_slew_max)}
  -- , ["delay send"] = {""}
  -- , ["loop"] = {""}
  -- , ["semitone offset"] = {""}
  -- , ["filter tilt"] = {"max: "..string.format("%.2f",current.filter_max)}
  -- }
  screen.level(p.section == 2 and (edit_line == 5 and 15 or 3) or 3)
  screen.move(30,60)
  -- screen.text(params_to_mins[current.param][1])
  screen.move_rel(5,0)
  screen.level(p.section == 2 and (edit_line == 6 and 15 or 3) or 3)
  -- screen.text(params_to_maxs[current.param][1])
end


return Container