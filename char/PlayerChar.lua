local Char = require "char.Char"
local AnimationSet = require "char.AnimationSet"

local PlayerChar = Char:new()

function PlayerChar:new(o)
  local r = o or {}
  r.type = "player"
  setmetatable(r, self)
  self.__index = self

  r:addHitbox("body", 25, 50, 25, 50)
  r:addHitbox("punch_right", 55, 54, 24, 20)
  r:addHitbox("punch_left", -3, 54, 24, 20)
  r:addHitbox("kick_right", 55, 77, 28, 20)
  r:addHitbox("kick_left", -7, 77, 28, 20)
  return r
end

function PlayerChar:die()
  Char.die(self)
  self:setCurrentAnimation('death')
end

function PlayerChar:setupAnimations(sheet, grids, entity)
  self.animations = AnimationSet:new(sheet, {width = self.width, height = self.height})
  self.animations:addNewState("idle", grids[entity]["idle"], 0.5)
  self.animations:addNewState("walk", grids[entity]["walk"], 0.1)
  self.animations:addNewState("punch", grids[entity]["punch"], 0.1)
  self.animations:addNewState("kick", grids[entity]["kick"], 0.1)
  self.animations:addNewState("death", grids[entity]["death"], 0.1, "pauseAtEnd")
  self.animations:addNewState("stun", grids[entity]["stun"], 0.1)
end

-- Shorthand for creating a new player
function PlayerChar:newPlayer(x, y, animationTag, width, height, sheet, grid)
  width = width or 76
  height = height or 104
  sheet = sheet or ASSETS["character"].sheet
  grid = grid or ASSETS["character"].grids
  animationTag = animationTag or "player1"

  local newChar = PlayerChar:new {
    width = width,
    height = height,
    x = x,
    y = y
  }

  newChar:setupAnimations(sheet, grid, animationTag)
  return newChar
end

return PlayerChar