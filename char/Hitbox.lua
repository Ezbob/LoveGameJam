local Rectangle = require "rectangle"

local Hitbox = Rectangle:new()

function Hitbox:new(o)
  local r = o or {}
  setmetatable(r, self)
  self.__index = self
  r.active = r.active or false
  r.type = r.type or nil
  r.offset_x = r.offset_x or 0
  r.offset_y = r.offset_y or 0
  return r
end

function Hitbox:isActive()
  return self.active
end

function Hitbox:setActive(active)
  self.active = active
  return self.active
end

function Hitbox:drawDebug()
  if self.active then
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
  else
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
  end
end

-- Active intersection test
-- returns -1 iff two hitboxes are intersecting and the this rectangle is active
-- return 1 iff two hitboxes are intersecting and the other rectangle is actve
-- return 3 iff two hitboxes are intersecting and the both rectangle is actve
-- return 0 otherwise
function Hitbox:activeIntersectTest(otherHitbox)
  if not self.isIntersectingRectangles(otherHitbox) then
    return 0
  else
    if self.active and otherHitbox.active then
      return 3
    elseif self.active then
      return -1
    elseif otherHitbox.active then
      return 1
    else
      return 0
    end
  end
end

return Hitbox