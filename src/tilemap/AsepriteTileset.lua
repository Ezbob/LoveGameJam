local Class = require 'modules.hump.class'
local inspect = require 'modules.inspect.inspect'
local AsepriteMetaParser = require 'AsepriteMetaParser'

local AsepriteTileset = Class {}

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

    for i, quadInfo in ipairs(quads) do
      indexedQuads[i + (firstgid - 1)] = {
        gid = i + (firstgid - 1),
        quad = quadInfo.quad,
        frameName = quadInfo.frameName,
        imageName = table.concat({ assetPrefix, value.image }, "/")
      }
    end
  end
  return indexedQuads
end

local function initialImages(indexedQuads)
  local result = {}

  for gid, quadsnshit in ipairs(indexedQuads) do
    if result[quadsnshit.imageName] == nil then
      result[quadsnshit.imageName] = love.graphics.newImage(quadsnshit.imageName)
    end
    indexedQuads[gid].image = result[quadsnshit.imageName]
  end
end

function AsepriteTileset:load(labelSplitter)
  self.tileSetsQuad = loadTileSetQuads(self.tiledData, self.assetPrefix, labelSplitter)

  initialImages(self.tileSetsQuad)
end

function AsepriteTileset:init(TiledJsonTilesetData, assetPrefix)
  self.tiledData = TiledJsonTilesetData
  self.assetPrefix = assetPrefix or ""
end

function AsepriteTileset:getTileInfoForGridId(gid)
  return self.tileSetsQuad[gid]
end

return AsepriteTileset