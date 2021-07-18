local Class = require "modules.hump.class"
local bump = require "modules.bump.bump"
local Signal = require "modules.hump.signal"
local inspect = require "modules.inspect.inspect"
local AsepriteMetaParser = require "AsepriteMetaParser"
local Camera = require "modules.hump.camera"
local PlayerChar = require "char.PlayerChar"
local PunkChar = require "char.PunkChar"
local TiledLevel = require "tilemap.TiledLevel"
local rectangle  = require "rectangle"
local CameraPath = require "camera.CameraPath"
local CameraHold = require "camera.CameraHold"
local Timer = require "modules.hump.timer"
local CameraStateMachine = require "camera.CameraStateMachine"

local Mainstate = Class {}

local DEBUG_FONT_SIZE = 16

function Mainstate:init()
  self.entities = nil
  self.signal = nil
  self.world = nil
  self.timer = nil
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
    obstacles = {},
  }
  self.drawings = {}

  local function insertDrawableEntity(key, entry)
    table.insert(self.entities[key], entry)
    table.insert(self.drawings, entry)
  end

  local Obstacles = Class{__includes=rectangle}

  function Obstacles:init(tileInfo, transform)
    self.image = tileInfo.image
    self.quad = tileInfo.quad
    self.transform = transform

    local _, _, w, h = self.quad:getViewport()
    rectangle.init(self, self.transform.x, self.transform.y, w, h)
  end

  function Obstacles:draw()
    love.graphics.draw(self.image, self.quad, self.transform.x, self.transform.y, self.transform.r, self.transform.sx, self.transform.sy, self.transform.ox, self.transform.oy)
    if DEBUG then
      rectangle.draw(self)
    end
  end

  self.world = bump.newWorld()
  self.signal = Signal()
  self.camera = Camera(0, 0)
  self.timer = Timer()

  self.tileMap = TiledLevel('Assets/level1.json')
  self.tileMap:loadTileSets('aseprite')
  self.tileMap:extractCollisions(self.world)
  self.tileMap:populateLayers(function(layerIndex, layerName, transform, tileSetInfo)

    if layerName == "background" then
      if not self.background then
        self.background = love.graphics.newSpriteBatch(tileSetInfo.image)
      end
      self.background:add(tileSetInfo.quad, transform.x, transform.y, transform.r, transform.sx, transform.sy, transform.ox, transform.oy)
    elseif layerName == "obstacles" then
      local obs = Obstacles(tileSetInfo, transform)
      insertDrawableEntity("obstacles", obs)
    end

  end)

  love.graphics.setFont(self.font)

  self.camera:zoom(2)

  local p1 = newPlayer(self, 1, 100, SCREEN_VALUES.height * 0.45)
  local p2 = newPlayer(self, 2, 100, SCREEN_VALUES.height * 0.35)

  local e1 = newPunk(self, 705, SCREEN_VALUES.height * 0.5)
  local e2 = newPunk(self, 705, SCREEN_VALUES.height * 0.42)

  insertDrawableEntity("players", p1)
  insertDrawableEntity("players", p2)

  insertDrawableEntity("enemies", e1)
  insertDrawableEntity("enemies", e2)

  for _, p in ipairs(self.entities.enemies) do
    table.insert(self.entities.characters, p)
  end
  for _, p in ipairs(self.entities.players) do
    table.insert(self.entities.characters, p)
  end

  self.cameraStates = CameraStateMachine()
  self.cameraStates:addCameraState("player1follow", CameraHold(self.camera, p1, Camera.smooth.damped(10)))
  self.cameraStates:addCameraState("player2follow", CameraHold(self.camera, p2, Camera.smooth.damped(10)))
  self.cameraStates:addCameraState("enemyPan", CameraPath(self.camera, {e1, e2, p1}, Camera.smooth.damped(3), 6))
  self.cameraStates:setCurrentState("enemyPan")

  local w, h = self.tileMap:levelPixelDimensions()
  self.upperBoundary = { x = 0, y = self.tileMap.tileWidth * 2, name = "upperBoundary", width = w, height = 2 }
  self.lowerBoundary = { x = 0, y = h - (self.tileMap.tileWidth * 2), name = "lowerBoundary", width = w, height = 2}

  self.world:add(self.upperBoundary, self.upperBoundary.x, self.upperBoundary.y, self.upperBoundary.width, self.upperBoundary.height)
  self.world:add(self.lowerBoundary, self.lowerBoundary.x, self.lowerBoundary.y, self.lowerBoundary.width, self.lowerBoundary.height)

  self.camera:lookAt(p1:midPoint())

  self.signal:register("punch", function(player, hitbox)
    hitbox:setActive(true)
    self.timer:after(0.1, function ()
      hitbox:setActive(false)
    end)
  end)

  self.signal:register("kick", function(player, hitbox)
    hitbox:setActive(true)
    self.timer:after(0.1, function ()
      hitbox:setActive(false)
    end)
  end)
end


function Mainstate:update(dt)
  for _, char in ipairs(self.entities.characters) do
    char:update(dt)
  end

  if self.cameraStates:isCurrentPathFinished() then
    self.cameraStates:setCurrentState('player1follow')
  end

  self.cameraStates:update(dt)
  self.timer:update(dt)
end


function Mainstate:draw()
  self.camera:attach()
  love.graphics.draw(self.background)

  table.sort(self.drawings, function (a, b)
    return math.floor(a.y) < math.floor(b.y)
  end)

  for _, drawable in ipairs(self.drawings) do
    drawable:draw()
  end

  if DEBUG then
    self.tileMap:debugDraw()
    love.graphics.line(self.upperBoundary.x, self.upperBoundary.y, self.upperBoundary.x + self.upperBoundary.width, self.upperBoundary.y + self.upperBoundary.height)
    love.graphics.line(self.lowerBoundary.x, self.lowerBoundary.y, self.lowerBoundary.x + self.lowerBoundary.width, self.lowerBoundary.y + self.lowerBoundary.height)
  end
  self.camera:detach()

end

return Mainstate