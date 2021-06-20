local inspect = require "modules.inspect.inspect"
local json = require "modules.dkjson.dkjson"

local AsepriteAdapter = {
  json_data_ = nil
}

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


function AsepriteAdapter:new()
  local o = {}
  setmetatable(o, AsepriteAdapter)
  self.__index = self
  return o
end

function AsepriteAdapter:load(filepath)
  self.json_data_ = loadJson(filepath)

  self.frames = {}

  for i, entry in ipairs(self.json_data_['meta']['frameTags']) do

    local f = {
      stateName = entry['name'],
      fromIndex = tonumber(entry['from']),
      toIndex = tonumber(entry['to'])
    }
    self.frames[entry['name']] = f
  end

  self.sheetSizes = {
    h = self.json_data_['meta']['size']['h'],
    w = self.json_data_['meta']['size']['w']
  }

  local p = {}
  for key, value in pairs(self.json_data_["frames"]) do

    local fname, entityName, frameIndex = unpack(split(key, "-"))

    local column = (value["frame"]["x"] / value["sourceSize"]["w"]) + 1
    local row = (value["frame"]["y"] / value["sourceSize"]["h"]) + 1


    if p[entityName] == nil then
      p[entityName] = {}
    end

    frameIndex = tonumber(frameIndex)
    for frameName, frameEntry in pairs(self.frames) do
      if frameEntry['fromIndex'] <= frameIndex and frameIndex <= frameEntry['toIndex'] then
        if p[entityName][frameName] == nil then
          p[entityName][frameName] = {}
        end
        table.insert(p[entityName][frameName], {column, row})
      end
    end
  end

  print(inspect(p))
end


local adapter = AsepriteAdapter:new()

adapter:load('Assets/miniplayer.json')


return AsepriteAdapter