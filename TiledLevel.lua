local Class = require 'modules.hump.class'
local inspect = require 'modules.inspect.inspect'
local json = require 'modules.dkjson.dkjson'
local StringUtils = require 'StringUtils'
local AsepriteMetaParser = require 'AsepriteMetaParser'
local bit = require 'bit'
local rectangle = require "rectangle"

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
  if DEBUG then
    self.debugRects = {}
  end
  parseTiledata(self.mapJSONData.layers, function (layerIndex, gid, x, y, hflipped, vflipped, dflipped)
    local q = self.tileSets.quadIndex[gid]
    local batch = self.tileSets.spriteBatches[q.image]

    local xoffset, yoffset = 0, 0
    local xscale, yscale = 1, 1
    local rotate = 0

    if vflipped and not dflipped then
      yscale = -1
      yoffset = self.tileHeight
    end

    if hflipped and not dflipped then
      xscale = -1
      xoffset = self.tileWidth
    end

    if dflipped and vflipped then
      rotate = (math.pi * 3 / 2)
      xoffset = self.tileWidth
    end

    if dflipped and hflipped then
      rotate = (math.pi / 2)
      yoffset = self.tileHeight
    end

    local xPixel = self.tileWidth * (x - 1)
    local yPixel = self.tileHeight * (y - 1)

    batch:add(q.quad, xPixel, yPixel, rotate, xscale, yscale, xoffset, yoffset)

    self.sortedLayers[layerIndex] = batch

    if self.collisionLookup and self.worldCollision then
      local layer = self.collisionLookup[layerIndex]
      if layer ~= nil then
        local tile = layer[gid]
        if tile then
          for i, collisionObject in ipairs(tile.objectgroup.objects) do
            self.worldCollision:add({ name = collisionObject.name },
              xPixel + collisionObject.x,
              yPixel + collisionObject.y,
              collisionObject.width,
              collisionObject.height
            )
            if DEBUG then
              table.insert(self.debugRects,
                rectangle(
                  xPixel + collisionObject.x,
                  yPixel + collisionObject.y,
                  collisionObject.width,
                  collisionObject.height
                )
              )
            end
          end
        end
      end
    end
  end)
end

function TiledLevel:addExtractCollisions(collision)
  self.collisionLookup = {}
  self.worldCollision = collision
  for tileIndex, tileset in ipairs(self.mapJSONData.tileSets) do
    if tileset.tiles then
      local firstgid = tileset.firstgid
      if not self.collisionLookup[tileIndex] then
        self.collisionLookup[tileIndex] = {}
      end
      for i, tile in ipairs(tileset.tiles) do
        local gid = firstgid + tile.id
        self.collisionLookup[tileIndex][gid] = tile
      end
    end
  end
end

function TiledLevel:draw()
  for i, value in ipairs(self.sortedLayers) do
    love.graphics.draw(value)
  end
  if DEBUG then
    for i, r in ipairs(self.debugRects) do
      --love.graphics.draw("line", r.x, r.y, r.w, r.h)
      --print(inspect(r))
      --print(r.x, r.y, r.width, r.height)
      r:draw()
    end
  end
end

return TiledLevel