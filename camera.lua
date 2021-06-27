local rect = require("rectangle")
local Class = require "modules.hump.class"

local Camera = Class { __includes = rect }

function Camera:init(x, y, w, h)
  rect.init(self, x, y, w, h)
end

function Camera:update(player, screen)
  local w, h = player:getBboxDimensions()

  self:setPosition(
    player.x - (screen.width / 4),
    (screen.height / 4) + (player.y / 4) + h
  )
end

return Camera