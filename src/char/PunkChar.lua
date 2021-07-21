local Char = require "char.Char"
local Class = require "modules.hump.class"
local inspect = require "modules.inspect.inspect"
local AnimationSet = require "char.AnimationSet"

local PunkChar = Class {
  __includes = Char,
  name = "punk" -- collision id
}

function PunkChar:init(x, y, animationTag, signal, collision, sheet, grid, width, height)
  width = width or 25
  height = height or 45
  collision = collision
  sheet = sheet
  grid = grid
  animationTag = animationTag or "enemy1"

  Char.init(self, x, y, width, height, AnimationSet(sheet, {width = 76, height = 104}),
      'idle',
      {x = -width, y =  -(height + 10)}
  )

  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.collision = collision

  self.vx = 150
  self.vy = 150

  self:addHitbox("body", 0, 5, width, width + 10)
  self:addHitbox("punch_right", width + 10, 8, 12, 12)
  self:addHitbox("punch_left", -22, 8, 12, 12)
  self:addHitbox("kick_right", width + 10, 20, 15, 12)
  self:addHitbox("kick_left", -25, 20, 15, 12)

  self.animations:addNewState("idle", grid[animationTag]["idle"], 0.5)
  self.animations:addNewState("walk", grid[animationTag]["walk"], 0.1)
  self.animations:addNewState("punch", grid[animationTag]["punch"], 0.1, function ()
    self.isPunching = false
  end)
  self.animations:addNewState("kick", grid[animationTag]["kick"], 0.1, function ()
    self.isKicking = false
  end)
  self.animations:addNewState("death", grid[animationTag]["death"], 0.4, "pauseAtEnd")
  self.animations:addNewState("stun", grid[animationTag]["stun"], 0.2, function ()
    self:setCurrentAnimation("idle")
    self.stunned = false
  end)

  self.collision:add(self, self.x, self.y, self.width, self.height)
end

local function playerCollisionFilter(me, other)
  if other.name == "punk" or other.name == "heavy" or other.name == "player" then
      return "cross"
  end
  return "slide"
end

function PunkChar:move(relative_x, relative_y)
  self:setCurrentAnimation('walk')

  local actualX, actualY, col, len = self.collision:move(self,
      self.x + relative_x, self.y + relative_y,
      playerCollisionFilter)

  if self.x < actualX then
    self:faceRight()
  elseif self.x > actualX then
    self:faceLeft()
  end

  self.x = actualX
  self.y = actualY
end

function PunkChar:stop()
  self:setCurrentAnimation('idle')
end

return PunkChar