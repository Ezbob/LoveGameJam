local Class = require 'modules.hump.class'
local inspect = require 'modules.inspect.inspect'
local json = require 'modules.dkjson.dkjson'
local StringUtils = require 'StringUtils'
local bit = require 'bit'
local rectangle = require "rectangle"
local AsepriteTileset = require "tilemap.AsepriteTileset"

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
  self.mapJSONData = loadJsonFile(filename)
  self.tileWidth = self.mapJSONData.tilewidth
  self.tileHeight = self.mapJSONData.tileheight
  self.mapWidth = self.mapJSONData.width
  self.mapHeight = self.mapJSONData.height
  self.assetPrefix = getPrefix(filename)
end

function TiledLevel:init(filename)
  loadJSON(self, filename)
end

function TiledLevel:loadTileSets(types)
  if types == "aseprite" then
    self.tileSets = AsepriteTileset(self.mapJSONData.tilesets, self.assetPrefix)
  else
    self.tileSets = AsepriteTileset(self.mapJSONData.tilesets, self.assetPrefix)
  end

  self.tileSets:load()
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

function TiledLevel:populateLayers(layerInitializer)
  layerInitializer = layerInitializer or function () end

  parseTiledata(self.mapJSONData.layers, function (layerIndex, gid, x, y, hflipped, vflipped, dflipped)
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

    local tileSetInfo = self.tileSets:getTileInfoForGridId(gid)

    local transform = {x=xPixel, y=yPixel, r=rotate, sx=xscale, sy=yscale, ox=xoffset, oy=yoffset}

    local layerName = self.mapJSONData.layers[layerIndex].name

    layerInitializer(layerIndex, layerName, transform, tileSetInfo)

  end)
end

function TiledLevel:extractCollisions(collision)
  self.collisionLookup = {}
  self.worldCollision = collision
  for tileIndex, tileset in ipairs(self.mapJSONData.tilesets) do
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

  if DEBUG then
    self.debugRects = {}
  end

  parseTiledata(self.mapJSONData.layers, function (layerIndex, gid, x, y)
    local xPixel = self.tileWidth * (x - 1)
    local yPixel = self.tileHeight * (y - 1)

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

-- get the pixel width and height
function TiledLevel:levelPixelDimensions()
  local pixelWidth = self.tileWidth * self.mapWidth
  local pixelHeight = self.tileHeight * self.mapHeight
  return pixelWidth, pixelHeight
end

function TiledLevel:debugDraw()
  if DEBUG then

    for key, value in pairs(self.debugRects) do
      value:draw()
    end
  end

end

return TiledLevel