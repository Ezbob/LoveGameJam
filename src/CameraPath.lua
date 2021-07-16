local Class = require "modules.hump.class"
local veclight = require "modules.hump.vector-light"

local CameraPath = Class {}

function CameraPath:init(camera, points, smoother)
  self.camera = camera
  self.points = points
  self.smoother = smoother
  self.currentPoint = 1
  self.done = false
end

function CameraPath:update()
  local point = self.points[self.currentPoint]
  if point ~= nil then
    self.camera.smoother = self.smoother
    self.camera:lockPosition(point.x, point.y)

    local cx, cy = self.camera:position()
    if veclight.dist(cx, cy, point.x, point.y) < 4 then
      self.currentPoint = self.currentPoint + 1
    end
  else
    self.done = true
  end
end

function CameraPath:isFinished()
  return self.done
end

function CameraPath:reset()
  if self:isFinished() then
    self.currentPoint = 1
    self.done = false
  end
end

return CameraPath