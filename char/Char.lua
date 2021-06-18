local Rectangle = require("rectangle")
local CharEffects = require "char.CharEffects"


local Char = Rectangle:new {
  health = 100,
  movement_speed = 0,
  effects = CharEffects:new()
}

return Char