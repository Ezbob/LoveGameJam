local rect = require("rectangle")

local Camera = rect:new()

function Camera:update(player, screen)
  local w, h = player:getBboxDimensions()

  self:setPosition(
    player.position.x - (screen.width / 4),
    (screen.height / 4) + (player.position.y / 4) + h
  )
end

return Camera