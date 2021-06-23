local Rectangle = require "rectangle"

local Char = Rectangle:new {
  health = 100,
  movement_speed = 0,
  effects = {
    stunned = false
  },
  animations = nil
}

function Char:update(dt)
  self.animations:getCurrentAnimation():update(dt)
end

function Char:draw()
  self.animations:getCurrentAnimation():drawAt(self.x, self.y)
end

function Char:flipHorizontal()
  self.animations:getCurrentAnimation():flipH()
end

function Char:flipVertical()
  self.animations:getCurrentAnimation():flipV()
end

function Char:drawDebug(style)
  Rectangle.draw(self, style)
end


return Char