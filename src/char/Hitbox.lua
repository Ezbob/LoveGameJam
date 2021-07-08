local Rectangle = require "rectangle"
local Class = require "modules.hump.class"

local Hitbox = Class {__includes = Rectangle}

function Hitbox:init(tag, x, y, offset_x, offset_y, w, h)
  Rectangle.init(self, 0, 0, w, h)
  self.name = tag
  self.active = false
  self.x = x
  self.y = y
  self.offset_x = offset_x or 0
  self.offset_y = offset_y or 0
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