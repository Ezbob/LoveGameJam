local Class = require 'modules.hump.class'
local inspect = require 'modules.inspect.inspect'
local json = require 'modules.dkjson.dkjson'
local StringUtils = require 'StringUtils'
local AsepriteMetaParser = require 'AsepriteMetaParser'
local bit = require 'bit'

local TiledLevel = Class {}

local function loadJsonFile(filename)
  local file = love.filesystem.newFile(filename)
  file:open("r")
  local str = "";
  for line in file:lines() do
    str = str .. line
  end
  file:close()
  return json.decode(str)
end

local function getPrefix(filepath)
  local splitting = StringUtils.split(filepath, "/")
  splitting[#splitting] = nil
  return table.concat(splitting, "/")
end

local function loadJSON(self, filename)
  local loadedJson = loadJsonFile(filename)
  self.tileWidth = loadedJson.tilewidth
  self.tileHeight = loadedJson.tileheight
  self.mapWidth = loadedJson.width
  self.mapHeight = loadedJson.height
  self.mapJSONData = {
    layers = loadedJson.layers,
    tileSets = loadedJson.tilesets
  }
  self.assetPrefix = getPrefix(filename)
end

function TiledLevel:init(filename)
  self.tileSets = nil
  self.sortedLayers = {}
  loadJSON(self, filename)
end

local function parseTiledata(layers, callback)
  local FLIPPED_HORIZONTALLY_FLAG = 0x80000000
  local FLIPPED_VERTICALLY_FLAG = 0x40000000
  local FLIPPED_DIAGONALLY_FLAG   = 0x20000000

  local inverse = bit.bnot(
      bit.bor(bit.bor(FLIPPED_HORIZONTALLY_FLAG, FLIPPED_VERTICALLY_FLAG), FLIPPED_DIAGONALLY_FLAG))

  for layerIndex, layer in ipairs(layers) do
    local w, h = layer.width, layer.height
    local data = layer.data

    for y = 1, h do
      for x = 1, w do
        local tileId = data[w * (y - 1) + x]

        if tileId > 0 then
          local is_flipped_horizontal = (bit.band(tileId, FLIPPED_HORIZONTALLY_FLAG) ~= 0)
          local is_flipped_vertically = (bit.band(tileId,  FLIPPED_VERTICALLY_FLAG) ~= 0)
          local is_flipped_diagonally = (bit.band(tileId,  FLIPPED_DIAGONALLY_FLAG) ~= 0)

          tileId = bit.band(tileId, inverse)

          callback(layerIndex, tileId, x, y, is_flipped_horizontal, is_flipped_vertically, is_flipped_diagonally)
        end
      end
    end
  end
end

local function replaceExtensionWithJson(file)
  local r = ""
  for char in file:gmatch("[^.]+$") do
    r = file:gsub("." .. char, ".json")
  end
  return r
end

local function loadTileSetQuads(tileSets, assetPrefix, labelSplitter)
  local indexedQuads = {}

  for _, value in ipairs(tileSets) do
    local jsonFilepath = table.concat({assetPrefix, replaceExtensionWithJson(value.image)}, "/")
    local quads = AsepriteMetaParser.getIndexedQuadsFromJSON(jsonFilepath, labelSplitter)
    local firstgid = value.firstgid

    for i, quad in ipairs(quads) do
      indexedQuads[i + (firstgid - 1)] = {
        quad = quad,
        image = table.concat({ assetPrefix, value.image }, "/")
      }
    end
  end
  return indexedQuads
end

local function initialSpriteBatches(indexedQuads)
  local result = {}

  for gid, quadsnshit in ipairs(indexedQuads) do
    local img = love.graphics.newImage(quadsnshit.image)
    result[quadsnshit.image] = love.graphics.newSpriteBatch(img)
  end

  return result
end

function TiledLevel:loadTilesFromAseprite(labelSplitter, prefix)
  prefix = prefix or self.assetPrefix

  local indexedQuads = loadTileSetQuads(self.mapJSONData.tileSets, prefix, labelSplitter)

  local spriteBatches = initialSpriteBatches(indexedQuads)

  self.tileSets = {
    quadIndex = indexedQuads,
    spriteBatches = spriteBatches
  }
end

function TiledLevel:populateLayers()
  parseTiledata(self.mapJSONData.layers, function (layerIndex, gid, x, y, hflipped, vflipped)
    local q = self.tileSets.quadIndex[gid]
    local batch = self.tileSets.spriteBatches[q.image]

    local xoffset, yoffset = 0, 0
    local xscale, yscale = 1, 1

    if vflipped then
      yscale = -1
      yoffset = self.tileHeight
    end

    if hflipped then
      xscale = -1
      xoffset = self.tileWidth
    end

    batch:add(q.quad, self.tileWidth * (x - 1), self.tileHeight * (y - 1), 0, xscale, yscale, xoffset, yoffset)

    self.sortedLayers[layerIndex] = batch
  end)
end

function TiledLevel:draw()
  for i, value in ipairs(self.sortedLayers) do
    love.graphics.draw(value)
  end
end

return TiledLevel