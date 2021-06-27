local Char = require "char.Char"
local Class = require "modules.hump.class"
local inspect = require "modules.inspect.inspect"

local PunkChar = Class {
  __includes = Char,
  type = "punk",
  name = "punk" -- collision id
}

function PunkChar:init(x, y, animationTag, signal, collision, sheet, grid, width, height)
  width = width or 76
  height = height or 104
  collision = collision
  sheet = sheet
  grid = grid
  animationTag = animationTag or "enemy1"

  Char.init(self, x, y, width, height, 'idle', sheet)

  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.collision = collision

  self:addHitbox("body", 25, 50, 25, 50)
  self:addHitbox("punch_right", 62, 56, 12, 12)
  self:addHitbox("punch_left", 2, 56, 12, 12)
  self:addHitbox("kick_right", 57, 71, 20, 12)
  self:addHitbox("kick_left", -2, 71, 20, 12)

  self.animations:addNewState("idle", grid[animationTag]["idle"], 0.5)
  self.animations:addNewState("walk", grid[animationTag]["walk"], 0.1)
  self.animations:addNewState("punch", grid[animationTag]["punch"], 0.1)
  self.animations:addNewState("kick", grid[animationTag]["kick"], 0.1)
  self.animations:addNewState("death", grid[animationTag]["death"], 0.1, "pauseAtEnd")
  self.animations:addNewState("stun", grid[animationTag]["stun"], 0.1)

  self.collision:add(self, self.x, self.y, self.width, self.height)
end


return PunkChar