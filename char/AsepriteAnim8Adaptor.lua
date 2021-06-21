--local inspect = require "modules.inspect.inspect"
local json = require "modules.dkjson.dkjson"

local AsepriteAnim8Adaptor = {}

local function loadJson(filename)
  local file = io.open(filename, "r")
  local str = "";
  for line in file:lines() do
    str = str .. line
  end
  file:close()
  return json.decode(str)
end

local function split(inputstr, sep)
  if sep == nil then
          sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
          table.insert(t, str)
  end
  return t
end

-- Default label splitter. Returns layer name and frame index from aseprite JSON frame
-- "frame" entries. This is needed to associate the frame data with the meta data.
local function defaultLabelSplitter(label)
  local splitit = split(label, "-")
  return splitit[2], splitit[3]
end

function AsepriteAnim8Adaptor.getGridsFromJSON(filepath, labelSplitter)
  local json_data_ = loadJson(filepath)

  labelSplitter = labelSplitter or defaultLabelSplitter

  local frames = {}

  for i, entry in ipairs(json_data_['meta']['frameTags']) do
    frames[entry['name']] = {
      stateName = entry['name'],
      fromIndex = tonumber(entry['from']),
      toIndex = tonumber(entry['to'])
    }
  end

  local result = {}
  for key, value in pairs(json_data_["frames"]) do

    local entityName, frameIndex = labelSplitter(key)

    local column = (value["frame"]["x"] / value["sourceSize"]["w"]) + 1
    local row = (value["frame"]["y"] / value["sourceSize"]["h"]) + 1


    if result[entityName] == nil then
      result[entityName] = {}
    end

    frameIndex = tonumber(frameIndex)
    for frameName, frameEntry in pairs(frames) do
      if frameEntry['fromIndex'] <= frameIndex and frameIndex <= frameEntry['toIndex'] then
        if result[entityName][frameName] == nil then
          result[entityName][frameName] = {}
        end
        table.insert(result[entityName][frameName], column)
        table.insert(result[entityName][frameName], row)
      end
    end
  end

  return result
end



return AsepriteAnim8Adaptor