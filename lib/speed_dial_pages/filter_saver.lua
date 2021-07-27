local filter_saver = {}

local fs = filter_saver

local filter_types = {"dry","lp","hp","bp"}
local param_names = {}

function fs.init()
  filter_data = {}
  for i = 1,8 do
    filter_data[i] = {["raw"] = {},["dirty"] = false}
  end
  filter_data.save_clock = nil
  filter_data.saver_active = false
  filter_data.save_slot = nil
  filter_data.load_slot = 0
  filter_data.delete_clock = nil
end

function fs.save(slot)
  filter_data.saver_active = true
  clock.sleep(1)
  fs.handle_preset(slot,"save")
  filter_data.saver_active = true
end

function fs.handle_preset(slot,command)
  local target, source;
  if command ~= "delete" then
    if command == "save" then
      filter_data.save_slot = slot
      filter_data.load_slot = slot
      filter_data[slot].dirty = true
      for i = 1,3 do
        filter_data[slot].raw[i] = deep_copy(filter[i])
      end
    elseif command == "load" then -- should this start the pattern??
      filter_data.load_slot = slot
      for i = 1,3 do
        filter[i] = deep_copy(filter_data[slot].raw[i])
      end
    end
  else
    filter_data[slot].raw = {}
    filter_data[slot].dirty = false
    filter_data.save_slot = nil
    filter_data.load_slot = 0
  end
  grid_dirty = true
end

function fs.disk_save_presets(coll)
  local dirname = _path.data.."cheat_codes_yellow/collection-"..coll.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local dirname = _path.data.."cheat_codes_yellow/collection-"..coll.."/filter_presets/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  for i = 1,8 do
    local file = io.open(_path.data .. "cheat_codes_yellow/collection-"..coll.."/filter_presets/"..i..".data", "w+")
    if file then
      os.remove(_path.data .. "cheat_codes_yellow/collection-"..coll.."/filter_presets/"..i..".data")
      io.close(file)
    end
  end

  for i = 1,8 do
    tab.save(filter_data[i],_path.data .. "cheat_codes_yellow/collection-"..coll.."/filter_presets/"..i..".data")
  end

end

return filter_saver