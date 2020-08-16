--- Music utility module.
-- Utility methods for working with notes, scales and chords.
--
-- @module MusicUtil
-- @release v1.1.1
-- @author Mark Eats

local MusicUtil = {}

MusicUtil.SCALES = {
    {name = "octave + fifth", intervals = {-12,-5,0,7,12}},
    {name = "ionian", intervals = {0, 2, 4, 5, 7, 9, 11, 12}},
    {name = "aeolian", intervals = {0, 2, 3, 5, 7, 8, 10, 12}},
    {name = "dorian", intervals = {0, 2, 3, 5, 7, 9, 10, 12}},
    {name = "phrygian", intervals = {0, 1, 3, 5, 7, 8, 10, 12}},
    {name = "lydian", intervals = {0, 2, 4, 6, 7, 9, 11, 12}},
    {name = "mixolydian", intervals = {0, 2, 4, 5, 7, 9, 10, 12}},
    {name = "locrian", intervals = {0, 1, 3, 5, 6, 8, 10, 12}},
    {name = "maj pent", intervals = {0, 2, 4, 7, 9, 12}},
    {name = "min pent", intervals = {0, 3, 5, 7, 10, 12}},
    {name = "maj", intervals = {0, 4, 7}},
    {name = "maj6", intervals = {0, 4, 7, 9}},
    {name = "maj7", intervals = {0, 4, 7, 11}},
    {name = "maj9", intervals = {0, 4, 7, 11, 14}},
    {name = "maj11", intervals = {0, 4, 7, 11, 14, 17}},
    {name = "Major 13", intervals = {0, 4, 7, 11, 14, 17, 21}},
    {name = "Dominant 7", intervals = {0, 4, 7, 10}},
    {name = "Ninth", intervals = {0, 4, 7, 10, 14}},
    {name = "Eleventh", intervals = {0, 4, 7, 10, 14, 17}},
    {name = "Thirteenth", intervals = {0, 4, 7, 10, 14, 17, 21}},
    {name = "Augmented", intervals = {0, 4, 8}},
    {name = "Augmented 7", intervals = {0, 4, 8, 10}},
    {name = "Sus4", intervals = {0, 5, 7}},
    {name = "Seventh sus4", intervals = {0, 5, 7, 10}},
    {name = "Minor Major 7", intervals = {0, 3, 7, 11}},
    {name = "Minor", intervals = {0, 3, 7}},
    {name = "Minor 6", intervals = {0, 3, 7, 9}},
    {name = "Minor 7", intervals = {0, 3, 7, 10}},
    {name = "Minor 69", intervals = {0, 3, 7, 9, 14}},
    {name = "Minor 9", intervals = {0, 3, 7, 10, 14}},
    {name = "Minor 11", intervals = {0, 3, 7, 10, 14, 17}},
    {name = "Minor 13", intervals = {0, 3, 7, 10, 14, 17, 21}},
    {name = "Diminished", intervals = {0, 3, 6}},
    {name = "Diminished 7", intervals = {0, 3, 6, 9}},
    {name = "Half Diminished 7", intervals = {0, 3, 6, 10}}
}

local function lookup_data(lookup_table, search)
  
  if type(search) == "string" then 
    search = string.lower(search)
    for i = 1, #lookup_table do
      if string.lower(lookup_table[i].name) == search then
        search = i
        break
      elseif lookup_table[i].alt_names then
        local found = false
        for j = 1, #lookup_table[i].alt_names do
          if string.lower(lookup_table[i].alt_names[j]) == search then
            search = i
            found = true
            break
          end
        end
        if found then break end
      end
    end
  end
  
  return lookup_table[search]
end

local function generate_scale_array(root_num, scale_data, length)
  local out_array = {}
  local scale_len = #scale_data.intervals
  local note_num
  local i = 0
  while #out_array < length do
    if i > 0 and i % scale_len == 0 then
      root_num = root_num + scale_data.intervals[scale_len]
    else
      note_num = root_num + scale_data.intervals[i % scale_len + 1]
      if note_num > 127 then break
      else table.insert(out_array, note_num) end
    end
    i = i + 1
  end
  return out_array
end

--- Generate scale from a root note.
-- @tparam integer root_num MIDI note number (0-127) where scale will begin.
-- @tparam string scale_type String defining scale type (eg, "major", "aeolian" or "neapolitan major"), see class for full list.
-- @tparam[opt] integer octaves Number of octaves to return, defaults to 1.
-- @treturn {integer...} Array of MIDI note numbers.
function MusicUtil.generate_scale(root_num, scale_type, octaves)
  if type(root_num) ~= "number" or root_num < 0 or root_num > 127 then return nil end
  scale_type = scale_type or 1
  octaves = octaves or 1
  
  local scale_data = lookup_data(MusicUtil.SCALES, scale_type)
  if not scale_data then return nil end
  local length = octaves * #scale_data.intervals - (util.round(octaves) - 1)
  
  return generate_scale_array(root_num, scale_data, length)
end

return MusicUtil