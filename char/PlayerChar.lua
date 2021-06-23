local Char = require "char.Char"
local Hitbox = require "char.Hitbox"
local Rectangle = require "rectangle"

local PlayerChar = Char:new()

function PlayerChar:new(o)
  local r = o or {}
  if not r.bodyHitbox  then
    r.bodyHitbox = Hitbox:new()
  end
  r.bodyHitbox.x = r.x + (r.bodyHitbox.offset_x or 0)
  r.bodyHitbox.y = r.y + (r.bodyHitbox.offset_y or 0)
  setmetatable(r, self)
  self.__index = self
  return r
end

function PlayerChar:update(dt)
  Char.update(self, dt)
  self.bodyHitbox.x = self.x + self.bodyHitbox.offset_x
  self.bodyHitbox.y = self.y + self.bodyHitbox.offset_y
end

function PlayerChar:drawDebug(style)
  Rectangle.draw(self, style)
  self.bodyHitbox:drawDebug()
end

return PlayerChar