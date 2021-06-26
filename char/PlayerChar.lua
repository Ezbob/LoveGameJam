local Char = require "char.Char"

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


return PlayerChar