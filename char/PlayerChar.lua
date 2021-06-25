local Char = require "char.Char"

local PlayerChar = Char:new()

function PlayerChar:new(o)
  local r = o or {}
  r.type = "player"
  setmetatable(r, self)
  self.__index = self
  return r
end


return PlayerChar