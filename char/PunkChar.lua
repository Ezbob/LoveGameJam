local Char = require "char.Char"
local Class = require "modules.hump.class"
local inspect = require "modules.inspect.inspect"
local AnimationSet = require "char.AnimationSet"
local Rectangle = require "rectangle"

local PunkChar = Class {
  __includes = Char,
  name = "punk" -- collision id
}

function PunkChar:init(x, y, animationTag, signal, collision, sheet, grid, width, height)
  width = width or 25
  height = height or 60
  collision = collision
  sheet = sheet
  grid = grid
  animationTag = animationTag or "enemy1"

  Char.init(self, x, y, width, height, AnimationSet(sheet, {width = 76, height = 104}),
      'idle',
      Rectangle(-width, -(height - 15), 0, 0)
  )

  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.collision = collision

  self:addHitbox("punch_right", width + 10, 12, 12, 12)
  self:addHitbox("punch_left", -22, 12, 12, 12)
  self:addHitbox("kick_right", width + 10, 24, 15, 12)
  self:addHitbox("kick_left", -25, 24, 15, 12)


  self.animations:addNewState("idle", grid[animationTag]["idle"], 0.5)
  self.animations:addNewState("walk", grid[animationTag]["walk"], 0.1)
  self.animations:addNewState("punch", grid[animationTag]["punch"], 0.1)
  self.animations:addNewState("kick", grid[animationTag]["kick"], 0.1)
  self.animations:addNewState("death", grid[animationTag]["death"], 0.1, "pauseAtEnd")
  self.animations:addNewState("stun", grid[animationTag]["stun"], 0.1)

  self.collision:add(self, self.x, self.y, self.width, self.height)
end


return PunkChar