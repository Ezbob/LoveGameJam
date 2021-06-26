local Char = require "char.Char"
local AnimationSet = require "char.AnimationSet"

local PunkChar = Char:new()

function PunkChar:new(o)
  local r = o or {}
  r.type = "punk"
  setmetatable(r, self)
  self.__index = self

  r:addHitbox("body", 25, 50, 25, 50)
  r:addHitbox("punch_right", 55, 54, 24, 20)
  r:addHitbox("punch_left", -3, 54, 24, 20)
  r:addHitbox("kick_right", 55, 77, 28, 20)
  r:addHitbox("kick_left", -7, 77, 28, 20)

  return r
end

function PunkChar:setupAnimations(sheet, grids, entity)
  self.animations = AnimationSet:new(sheet, {width = self.width, height = self.height})
  self.animations:addNewState("idle", grids[entity]["idle"], 0.5)
  self.animations:addNewState("walk", grids[entity]["walk"], 0.1)
  self.animations:addNewState("punch", grids[entity]["punch"], 0.1)
  self.animations:addNewState("kick", grids[entity]["kick"], 0.1)
  self.animations:addNewState("death", grids[entity]["death"], 0.1, "pauseAtEnd")
  self.animations:addNewState("stun", grids[entity]["stun"], 0.1)
end

return PunkChar