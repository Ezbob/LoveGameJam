local Class = require "modules.hump.class"
local veclight = require "modules.hump.vector-light"
local CameraState = require "camera.CameraState"

local CameraPath = Class {
  __includes = CameraState
}

function CameraPath:init(camera, points, smoother, switchLimit)
  self.camera = camera
  self.points = points
  self.smoother = smoother
  self.currentPoint = 1
  self.switchLimit = switchLimit or 4
  self.done = false
end

function CameraPath:update()
  local point = self.points[self.currentPoint]
  if point ~= nil then
    self.camera.smoother = self.smoother
    self.camera:lockPosition(point.x, point.y)

    local cx, cy = self.camera:position()
    if veclight.dist(cx, cy, point.x, point.y) < self.switchLimit then
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