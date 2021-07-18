local Class = require "modules.hump.class"

local Rectangle = Class {}

function Rectangle:init(x, y, w, h)
  self.x = x
  self.y = y
  self.width = w
  self.height = h
end

function Rectangle:isIntersectingRectangles(other)
  local self_left = self.x
  local self_right = self.x + self.width
  local self_top = self.y
  local self_bottom = self.y + self.height

  local other_left = other.x
  local other_right = other.x + other.width
  local other_top = other.y
  local other_bottom = other.y + other.height

  if self_right >= other_left and
  self_left <= other_right and
  self_bottom >= other_top and
  self_top <= other_bottom then
      return true
  else
      return false
  end
end

function Rectangle:setPosition(x, y)
  if (x) then self.x = x end
  if (y) then self.y = y end
end

function Rectangle:getPosition()
  return self.x, self.y
end

function Rectangle:getDimensions()
  return self.width, self.height
end

function Rectangle:setDimensions(width, height)
  self.width = width
  self.height = height
end

function Rectangle:draw(style)
  love.graphics.rectangle(style or "line", self.x, self.y, self.width, self.height)
end

function Rectangle:midPoint()
  return self.x + (self.width / 2), self.y + (self.height / 2)
end

function Rectangle:midPointVector()
  local x, y = self:midPoint()
  return {x = x, y = y}
end

return Rectangle