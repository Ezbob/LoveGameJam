local Class = require "modules.hump.class"
local bump = require "modules.bump.bump"
local Signal = require "modules.hump.signal"
local inspect = require "modules.inspect.inspect"
local AsepriteMetaParser = require "AsepriteMetaParser"
local Camera = require "modules.hump.camera"
local PlayerChar = require "char.PlayerChar"
local PunkChar = require "char.PunkChar"
local TiledLevel = require "tilemap.TiledLevel"

local Mainstate = Class {}

local DEBUG_FONT_SIZE = 16

function Mainstate:init()
  self.entities = nil
  self.signal = nil
  self.world = nil
  self.font = love.graphics.newFont("Assets/PressStart2P.ttf", DEBUG_FONT_SIZE)
  self.assets = {
    character = {
      sheet = love.graphics.newImage("Assets/miniplayer.png"),
      grids = AsepriteMetaParser.getGridsFromJSON("Assets/miniplayer.json")
    },
    ground = {
      sheet = love.graphics.newImage("Assets/asphalt.png"),
      quads = AsepriteMetaParser.getQuadsFromJSON("Assets/asphalt.json")
    },
    obstacles = {
      sheet = love.graphics.newImage("Assets/obstacles_small.png"),
      quads = AsepriteMetaParser.getQuadsFromJSON("Assets/obstacles_small.json")
    }
  }
end

local function newPlayer(self, id, x, y)
  local aniTag = "player1"
  if id > 1 then
    aniTag = "player2"
  end
  return PlayerChar(
    id,
    x,
    y,
    aniTag,
    self.signal,
    self.world,
    self.assets['character'].sheet,
    self.assets['character'].grids
  )
end

local function newPunk(self, x, y)
  local res = PunkChar(
    x,
    y,
    "enemy1",
    self.signal,
    self.world,
    self.assets['character'].sheet,
    self.assets['character'].grids
  )
  res:faceLeft()
  return res
end


function Mainstate:enter()
  self.entities = {
    characters = {},
    enemies = {},
    players = {},
    obstacles = {}
  }
  self.world = bump.newWorld()
  self.signal = Signal()
  self.camera = Camera(0, 0)

  self.tileMap = TiledLevel('Assets/level1.json')
  self.tileMap:loadTilesFromAseprite()
  self.tileMap:extractCollisions(self.world)
  self.tileMap:populateLayers()

  love.graphics.setFont(self.font)

  self.camera:zoom(2)

  local p1 = newPlayer(self, 1, 100, SCREEN_VALUES.height * 0.45)
  local p2 = newPlayer(self, 2, 100, SCREEN_VALUES.height * 0.35)

  local e1 = newPunk(self, 705, SCREEN_VALUES.height * 0.5)
  local e2 = newPunk(self, 705, SCREEN_VALUES.height * 0.42)

  table.insert(self.entities.players, p1)
  table.insert(self.entities.players, p2)

  table.insert(self.entities.enemies, e1)
  table.insert(self.entities.enemies, e2)

  for _, p in ipairs(self.entities.enemies) do
    table.insert(self.entities.characters, p)
  end
  for _, p in ipairs(self.entities.players) do
    table.insert(self.entities.characters, p)
  end

  local CharacterLayer = {
    sprites = self.entities.characters
  }

  function CharacterLayer:draw()
    for _, char in ipairs(self.sprites) do
      char:draw()

      if DEBUG then
        char:drawDebug()
      end
    end
  end

  local w, h = self.tileMap:levelPixelDimensions()
  self.upperBoundary = { x = 0, y = self.tileMap.tileWidth * 2, name = "upperBoundary", width = w, height = 2 }
  self.lowerBoundary = { x = 0, y = h - (self.tileMap.tileWidth * 2), name = "lowerBoundary", width = w, height = 2}

  self.world:add(self.upperBoundary, self.upperBoundary.x, self.upperBoundary.y, self.upperBoundary.width, self.upperBoundary.height)
  self.world:add(self.lowerBoundary, self.lowerBoundary.x, self.lowerBoundary.y, self.lowerBoundary.width, self.lowerBoundary.height)


  -- this adds the characters infront of the background tiles but behind the obstacles
  self.tileMap:addLayer(CharacterLayer, 2)
end


function Mainstate:update(dt)
  for _, char in ipairs(self.entities.characters) do
    char:update(dt)
  end

  local p1 = self.entities.players[1]
  self.camera:lookAt(p1.x + (p1.width / 2), p1.y + (p1.height / 2))
end


function Mainstate:draw()
  self.camera:attach()

  self.tileMap:draw()
  if DEBUG then
    love.graphics.line(self.upperBoundary.x, self.upperBoundary.y, self.upperBoundary.x + self.upperBoundary.width, self.upperBoundary.y + self.upperBoundary.height)
    love.graphics.line(self.lowerBoundary.x, self.lowerBoundary.y, self.lowerBoundary.x + self.lowerBoundary.width, self.lowerBoundary.y + self.lowerBoundary.height)
  end
  self.camera:detach()


end

return Mainstate