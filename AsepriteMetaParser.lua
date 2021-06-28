local inspect = require "modules.inspect.inspect"
local json = require "modules.dkjson.dkjson"

local AsepriteMetaParser = {}

local function loadJson(filename)
  local file = io.open(filename, "r")
  local str = "";
  for line in file:lines() do
    str = str .. line
  end
  file:close()
  return json.decode(str)
end

-- splitting string using gmatch separator
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

-- ordering pairs iterator
local function spairs(t, order)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[#keys+1] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys 
  if order then
      table.sort(keys, function(a,b) return order(t, a, b) end)
  else
      table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
      i = i + 1
      if keys[i] then
          return keys[i], t[keys[i]]
      end
  end
end

local function parse(filepath, outputHandler, labelSplitter)
  local json_data_ = loadJson(filepath)
  labelSplitter = labelSplitter or defaultLabelSplitter

  local imageSizes = {width = 0, height = 0}
  local frames = {}

  for i, entry in ipairs(json_data_['meta']['frameTags']) do
    frames[entry['name']] = {
      stateName = entry['name'],
      fromIndex = tonumber(entry['from']),
      toIndex = tonumber(entry['to'])
    }
  end

  imageSizes.width = json_data_['meta'].size.w
  imageSizes.height = json_data_['meta'].size.h

  for key, value in spairs(json_data_["frames"], function (t, a, b)
    local _, frameIndex1 = labelSplitter(a)
    local _, frameIndex2 = labelSplitter(b)
    return tonumber(frameIndex1) < tonumber(frameIndex2)
  end) do

    local entityName, frameIndex = labelSplitter(key)

    frameIndex = tonumber(frameIndex)
    for frameName, frameEntry in pairs(frames) do
      if frameEntry['fromIndex'] <= frameIndex and frameIndex <= frameEntry['toIndex'] then
        outputHandler(entityName, frameName, frameIndex, value, key, imageSizes)
      end
    end
  end

end

-- Getting ordering animation grids from aseprite JSON
-- The default label splitter uses {title}-{layer}-{frame} item filename
-- This can be customized with by parsing a function that returns layer name and frame index
function AsepriteMetaParser.getGridsFromJSON(filepath, labelSplitter)
  local result = {}

  parse(filepath, function (entityName, frameName, frameIndex, value)

    local column = (value["frame"]["x"] / value["sourceSize"]["w"]) + 1
    local row = (value["frame"]["y"] / value["sourceSize"]["h"]) + 1

    if result[entityName] == nil then
      result[entityName] = {}
    end
    if result[entityName][frameName] == nil then
      result[entityName][frameName] = {}
    end
    table.insert(result[entityName][frameName], column)
    table.insert(result[entityName][frameName], row)
  end, labelSplitter)

  return result
end

function AsepriteMetaParser.getQuadsFromJSON(filepath, labelSplitter)
  local result = {}

  parse(filepath, function (entityName, frameName, frameIndex, value, key, imageSizes)

    local column = value["frame"]["x"]
    local row = value["frame"]["y"]
    local width = value["frame"]["w"]
    local height = value["frame"]["h"]

    if result[entityName] == nil then
      result[entityName] = {}
    end
    if entityName ~= frameName then
      if result[entityName][frameName] == nil then
        result[entityName][frameName] = {}
      end
      table.insert(result[entityName][frameName], love.graphics.newQuad(column, row, width, height, imageSizes.width, imageSizes.height))
    else
      result[entityName] = love.graphics.newQuad(column, row, width, height, imageSizes.width, imageSizes.height)
    end

  end, labelSplitter)

  return result
end

return AsepriteMetaParser