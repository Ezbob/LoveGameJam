local Class = require "modules.hump.class"
local bump = require "modules.bump.bump"
local Signal = require "modules.hump.signal"
local Rectangle = require "rectangle"
local inspect = require "modules.inspect.inspect"
local AsepriteMetaParser = require "AsepriteMetaParser"
local Camera = require "modules.hump.camera"
local PlayerChar = require "char.PlayerChar"
local PunkChar = require "char.PunkChar"

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

local function setup_background(assets, streetSprites, obstaclesSprites, screen, collision_world)

  local tileSideLength = 64
  local lastRow = screen.width * 2
  local spriteCount = (lastRow / tileSideLength) - 1
  for i = 0, spriteCount, 1 do
    local column = i * tileSideLength
    streetSprites:add(assets.ground.quads.plank_top, column, tileSideLength * 3)
    streetSprites:add(assets.ground.quads.planks, column, tileSideLength * 4)
    streetSprites:add(assets.ground.quads.planks, column, tileSideLength * 5)
    streetSprites:add(assets.ground.quads.plank_sidewalk, column, tileSideLength * 6)
    streetSprites:add(assets.ground.quads.sidewalk, column, tileSideLength * 7)
    streetSprites:add(assets.ground.quads.gutter, column, tileSideLength * 8)
    streetSprites:add(assets.ground.quads.asphalt, column, tileSideLength * 9)
    streetSprites:add(assets.ground.quads.asphalt, column, tileSideLength * 10)
    streetSprites:add(assets.ground.quads.road_stripe,  column, tileSideLength * 11)
    streetSprites:add(assets.ground.quads.asphalt, column, tileSideLength * 12)
    streetSprites:add(assets.ground.quads.asphalt, column, tileSideLength * 13)
    streetSprites:add(assets.ground.quads.gutter, column, tileSideLength * 14, math.pi, 1, 1, tileSideLength, tileSideLength)
    streetSprites:add(assets.ground.quads.sidewalk, column, tileSideLength * 15, math.pi, 1, 1, tileSideLength, tileSideLength)
  end

  for i = 0, 9, 1 do
    local y = 376 + (tileSideLength * i)
    local xRight = lastRow - (5 + tileSideLength)
    local xLeft = 5
    obstaclesSprites:add(assets.obstacles.quads.barricade, xRight, y)
    obstaclesSprites:add(assets.obstacles.quads.barricade, xLeft, y)

    collision_world:add( { name = string.format("%d barricade right", i) }, xRight, y, tileSideLength, tileSideLength)
    collision_world:add( { name = string.format("%d barricade left", i) }, xLeft, y, tileSideLength, tileSideLength)
  end

  collision_world:add( { name = "left bounding box" }, 5, 0, 1, screen.height)
  collision_world:add( { name = "top bounding box" }, 5, screen.height * (2/5) - tileSideLength / 2, screen.width * 10, 1)
  collision_world:add( { name = "bottom bounding box" }, 5, screen.height, screen.width * 10, 1)
  collision_world:add( { name = "right bounding box" }, screen.width * 10, 0, 1, screen.height)

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

  love.graphics.setFont(self.font)

  setup_background(self.assets, self.streetSprites, self.obstaclesSprites, SCREEN_VALUES, self.world)

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
  love.graphics.draw(self.streetSprites)
  love.graphics.draw(self.obstaclesSprites)
  for _, char in ipairs(self.entities.characters) do
    char:draw()

    if DEBUG then
      char:drawDebug()
    end
  end

  self.camera:detach()
end

return Mainstate