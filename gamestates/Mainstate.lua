local Class = require "modules.hump.class"
local bump = require "modules.bump.bump"
local Signal = require "modules.hump.signal"
local inspect = require "modules.inspect.inspect"
local AsepriteMetaParser = require "AsepriteMetaParser"
local Camera = require "modules.hump.camera"
local PlayerChar = require "char.PlayerChar"
local PunkChar = require "char.PunkChar"
local TiledLevel = require "TiledLevel"

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
  self.streetSprites = love.graphics.newSpriteBatch(self.assets.ground.sheet)
  self.obstaclesSprites = love.graphics.newSpriteBatch(self.assets.obstacles.sheet)

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
  self.streetSprites:clear()
  self.camera = Camera(0, 0)

  self.tileMap = TiledLevel('Assets/level1.json')
  self.tileMap:loadTilesFromAseprite()
  self.tileMap:extractCollisions(self.world)
  self.tileMap:populateLayers()

  love.graphics.setFont(self.font)

  --setup_background(self.assets, self.streetSprites, self.obstaclesSprites, SCREEN_VALUES, self.world)

  self.camera:zoom(2)

  local p1 = newPlayer(self, 1, 100, SCREEN_VALUES.height * 0.65)
  local p2 = newPlayer(self, 2, 100, SCREEN_VALUES.height * 0.55)

  local e1 = newPunk(self, 700, SCREEN_VALUES.height * 0.7)
  local e2 = newPunk(self, 700, SCREEN_VALUES.height * 0.62)

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

  self.camera:detach()
end

return Mainstate