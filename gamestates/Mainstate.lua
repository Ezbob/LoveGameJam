local Class = require "modules.hump.class"
local bump = require "modules.bump.bump"
local Signal = require "modules.hump.signal"
local Rectangle = require "rectangle"
local inspect = require "modules.inspect.inspect"
local AsepriteMetaParser = require "char.AsepriteMetaParser"
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
    asphalt = {
      sheet = love.graphics.newImage("Assets/asphalt.png"),
      quads = AsepriteMetaParser.getQuadsFromJSON("Assets/asphalt.json")
    }
  }
  self.streetSprites = love.graphics.newSpriteBatch(self.assets.asphalt.sheet)
end

local function setup_background(assets, streetSprites)

  local tileSideLength = 64
  for i = 0, 30, 1 do
    streetSprites:add(assets.asphalt.quads.plank_top, i * tileSideLength, 0)
    streetSprites:add(assets.asphalt.quads.planks, i * tileSideLength, tileSideLength)
    streetSprites:add(assets.asphalt.quads.planks, i * tileSideLength, tileSideLength * 2)
    streetSprites:add(assets.asphalt.quads.plank_sidewalk, i * tileSideLength, tileSideLength * 3)
    streetSprites:add(assets.asphalt.quads.sidewalk, i * tileSideLength, tileSideLength * 4)
    streetSprites:add(assets.asphalt.quads.gutter, i * tileSideLength, tileSideLength * 5)
    streetSprites:add(assets.asphalt.quads.asphalt, i * tileSideLength, tileSideLength * 6)
    streetSprites:add(assets.asphalt.quads.asphalt, i * tileSideLength, tileSideLength * 7)
    streetSprites:add(assets.asphalt.quads.road_stripe, i * tileSideLength, tileSideLength * 8)
    streetSprites:add(assets.asphalt.quads.asphalt, i * tileSideLength, tileSideLength * 9)
    streetSprites:add(assets.asphalt.quads.asphalt, i * tileSideLength, tileSideLength * 10)
    streetSprites:add(assets.asphalt.quads.gutter, i * tileSideLength, tileSideLength * 11, math.pi, 1, 1, tileSideLength, tileSideLength)
    streetSprites:add(assets.asphalt.quads.sidewalk, i * tileSideLength, tileSideLength * 12, math.pi, 1, 1, tileSideLength, tileSideLength)
  end

end

local function intialize_world(entities, collision_world, screen)

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
  self.streetSprites:clear()
  self.camera = Camera(0, 0)

  love.graphics.setFont(self.font)

  setup_background(self.assets, self.streetSprites)

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

    if DEBUG then
      char:drawDebug()
    end
  end

  self.camera:detach()
end

return Mainstate