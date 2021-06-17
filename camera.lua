local rect = require("rectangle")

local Camera = rect:new()

function Camera:update(player, screen)
  local w, h = player:getBboxDimensions()

  self:setPosition(
    player.x - (screen.width / 4),
    (screen.height / 4) + (player.y / 4) + h
  )
end

return Camera