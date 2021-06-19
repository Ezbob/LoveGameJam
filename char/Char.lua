local Rectangle = require("rectangle")
local CharEffects = require "char.CharEffects"
local Animation = require "char.animation"

local Char = Rectangle:new {
  health = 100,
  movement_speed = 0,
  effects = CharEffects:new(),
  animations = Animation.AnimationStates:new()
}

function Char:updateAnimation(dt)
  self.animations:getCurrentAnimation():update(dt)
end

function Char:drawAnimation()
  self.animations:getCurrentAnimation():drawAt(self.x, self.y)
end

return Char