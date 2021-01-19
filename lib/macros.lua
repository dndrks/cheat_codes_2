local Macros = {}

-- function Macros:new(args)
--   return args
-- end

-- start with absolute

function Macros:new(args)
  local m = setmetatable({}, { __index = Macros })
  local args = args == nil and {} or args
  m.in_min = args.in_min == nil and 0 or args.in_min
  m.in_max = args.in_max == nil and 127 or args.in_max
  m.mode = args.mode == nil and "range" or args.mode
  m.destructive = args.destructive == nil and false or args.destructive
  m.out_min = args.out_min == nil and 0 or args.out_min
  m.out_max = args.out_max == nil and 127 or args.out_max
  m.focus = args.focus == nil and "none" or args.focus
  return m
end

Macros.ranges =
{
  ["pan"] =
  {
    ["min"] = -100
  , ["max"] = 100
  }
, ["rate"] =
  {
    ["values"] = {-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
  , ["min"] = 1
  , ["max"] = 13
  }
}

Macros.maps =
{
  ["pan"] = {-1,1}
, ["rate"] = {-4,-2,-1,-0.5,-0.25,-0.125,0,0.125,0.25,0.5,1,2,4}
}

function Macros:set_pan(target,val)
  local new_val = util.linlin(self.in_min,self.in_max,self.ranges["pan"]["min"],self.ranges["pan"]["max"],val)/100
  if self.destructive then
    target.pan = new_val
  end
  softcut.pan(target.bank_id+1,new_val)
end

function Macros:set_rate(target,val)
  local new_val = util.round(util.linlin(self.in_min,self.in_max,self.windows["rate"]["min"],self.windows["rate"]["max"],val))
  if self.destructive then
    target.rate = self.windows["rate"]["values"][new_val]
  end
  softcut.rate(target.bank_id+1,self.windows["rate"]["values"][new_val]*target.offset)
end

-- function Macros:update_quantized_rates(pos,val)
--   self.windows["quantized_rates"][pos] = val
--   self.windows["quantized_rates_max"] = #self.windows["quantized_rates"]
-- end

function Macros:get_loop_min(target)
  return target.mode == 1 and live[target.clip].min or clip[target.clip].min
end

function Macros:get_loop_max(target)
  return target.mode == 1 and live[target.clip].max or clip[target.clip].max
end

function Macros:set_loop_start(target,val)
  local lo = self:get_loop_min(target)
  local max = self:get_loop_max(target)
  local save_this = target.start_point
  target.start_point = util.round(util.clamp(util.linlin(self.in_min,self.in_max,lo,max,val),lo,target.end_point-0.1),0.1)
  if save_this ~= target.start_point then
    softcut.loop_start(target.bank_id+1,target.start_point)
  end
  params:set("start point "..target.bank_id,val,"true")
  if menu ~= 1 then screen_dirty = true end
end

return Macros