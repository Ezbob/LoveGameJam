local Class = require "modules.hump.class"
local bump = require "modules.bump.bump"
local Signal = require "modules.hump.signal"
local Rectangle = require "rectangle"
local inspect = require "modules.inspect.inspect"
local AsepriteAnim8Adaptor = require "char.AsepriteAnim8Adaptor"
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
end

local function setup_background(streetSprites, streetImage)

  local sw = streetImage:getWidth()
  local sh = streetImage:getHeight()
  local backgroundQuads = {
    ASPHALT = love.graphics.newQuad(0, 0, 64, 64, sw, sh),
    PLANK_AND_SIDEWALK = love.graphics.newQuad(64, 0, 64, 64, sw, sh),
    PLANK = love.graphics.newQuad(128, 0, 64, 64, sw, sh),
    PLANK_TOP = love.graphics.newQuad(192, 0, 64, 64, sw, sh),
    GUTTER = love.graphics.newQuad(192 + 64, 0, 64, 64, sw, sh),
    SIDEWALK = love.graphics.newQuad(192 + 64 * 2, 0, 64, 64, sw, sh),
    STREET_LINES = love.graphics.newQuad(192 + 64 * 3, 0, 64, 64, sw, sh)
  }

  local tileSideLength = 64
  for i = 0, 30, 1 do
    streetSprites:add(backgroundQuads.PLANK_TOP, i * tileSideLength, 0)
    streetSprites:add(backgroundQuads.PLANK, i * tileSideLength, tileSideLength)
    streetSprites:add(backgroundQuads.PLANK, i * tileSideLength, tileSideLength * 2)
    streetSprites:add(backgroundQuads.PLANK_AND_SIDEWALK, i * tileSideLength, tileSideLength * 3)
    streetSprites:add(backgroundQuads.SIDEWALK, i * tileSideLength, tileSideLength * 4)
    streetSprites:add(backgroundQuads.GUTTER, i * tileSideLength, tileSideLength * 5)
    streetSprites:add(backgroundQuads.ASPHALT, i * tileSideLength, tileSideLength * 6)
    streetSprites:add(backgroundQuads.ASPHALT, i * tileSideLength, tileSideLength * 7)
    streetSprites:add(backgroundQuads.STREET_LINES, i * tileSideLength, tileSideLength * 8)
    streetSprites:add(backgroundQuads.ASPHALT, i * tileSideLength, tileSideLength * 9)
    streetSprites:add(backgroundQuads.ASPHALT, i * tileSideLength, tileSideLength * 10)
    streetSprites:add(backgroundQuads.GUTTER, i * tileSideLength, tileSideLength * 11, math.pi, 1, 1, 64, 64)
    streetSprites:add(backgroundQuads.SIDEWALK, i * tileSideLength, tileSideLength * 12, math.pi, 1, 1, 64, 64)
  end

end

local function intialize_world(entities, collision_world, screen)
--[[
  for i, c in ipairs(entities.characters) do
      c.name = ("%s%i"):format(c.type, i)
      collision_world:add(c, c.x, c.y, c.width, c.height)
  end
--]]
  collision_world:add( { name = "left bounding box" }, 5, 0, 1, screen.height)
  collision_world:add( { name = "top bounding box" }, 5, screen.height * (2/5), screen.width * 10, 1)
  collision_world:add( { name = "bottom bounding box" }, 5, screen.height * 0.9, screen.width * 10, 1)
  collision_world:add( { name = "right bounding box" }, screen.width * 10, 0, 1, screen.height)

  --[[

  for i = 0, 11, 1 do
    table.insert(entities.road.barricades, Rectangle( 5, 372 + (64 * i), 64, 64 ))
  end

  for i = 0, 11, 1 do
    table.insert(entities.road.barricades, Rectangle( screen.width * 10 - (5 + 64), 372 + (64 * i), 64, 64 ))
  end

  for i, rect in ipairs(entities.road.barricades) do
    collision_world:add( { name = string.format("%d barricade", i) }, rect.x, rect.y, rect.width, rect.height)
  end

  --]]

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
    players = {}
  }
  self.world = bump.newWorld()
  self.signal = Signal()
  self.assets = {
    character = {
      sheet = love.graphics.newImage("Assets/miniplayer.png"),
      grids = AsepriteAnim8Adaptor.getGridsFromJSON("Assets/miniplayer.json")
    },
    asphalt = {
      sheet = love.graphics.newImage("Assets/asphalt.png")
    }
  }
  self.streetSprites = love.graphics.newSpriteBatch(self.assets.asphalt.sheet)
  self.camera = Camera(0, 0)

  love.graphics.setFont(self.font)

  setup_background(self.streetSprites, self.assets.asphalt.sheet)

  self.camera:zoom(2)

  local p1 = newPlayer(self, 1, 100, SCREEN_VALUES.height * 0.65)
  local p2 = newPlayer(self, 2, 100, SCREEN_VALUES.height * 0.55)

  local e1 = newPunk(self, 700, SCREEN_VALUES.height * 0.7)
  local e2 = newPunk(self, 700, SCREEN_VALUES.height * 0.62)

  intialize_world(self.entities, self.world, SCREEN_VALUES)

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
  for _, char in ipairs(self.entities.characters) do
    char:draw()
  end
  self.camera:detach()
end

return Mainstate