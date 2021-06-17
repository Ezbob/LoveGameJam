local rectangle = require "rectangle"
AI = {
	enemy_dead_zone_y = 15,
	enemy_dead_zone_x = 15
}

function AI:attack(currentEnemy, timer)
	local choice = math.random(0, 3)
	if choice <= 2 then
		currentEnemy:punch(timer)
	else
		currentEnemy:kick(timer)
	end
end


function AI:update(dt, scoreTable, timer)

	for i, currentEnemy in ipairs(ENTITIES.enemies) do

		currentEnemy.animation:update(dt)

		if currentEnemy:isAlive() then
			for index, player in ipairs(ENTITIES.players) do

				local w, h = player:getBboxDimensions()
				local currentEnemyX, currentEnemyY = currentEnemy:getPosition()
				local playerX, playerY = player:getPosition()

				if currentEnemyX <= playerX + DETECTION_ZONE_WIDTH and
					currentEnemyX >= playerX + w - DETECTION_ZONE_WIDTH and player:isAlive() then
					currentEnemy.triggered = true
				else
					currentEnemy.triggered = false
				end

				if currentEnemy.triggered then

					if not (
						currentEnemyX > playerX + w + self.enemy_dead_zone_x or
						currentEnemyX < playerX - w - self.enemy_dead_zone_x or
						currentEnemyY > playerY + self.enemy_dead_zone_y or
						currentEnemyY < playerY - self.enemy_dead_zone_y
						) then
						-- current enemy within "striking distance"

						if currentEnemyX > playerX + (w / 2) then
							-- if the enemy is on the right of the player, face left
							currentEnemy:faceLeft()
						else
							-- else face right
							currentEnemy:faceRight()
						end

						self:attack(currentEnemy, timer)

						-- change this to something useful
						currentEnemy:checkCollision(
							player,
							function(me, other)
								other:looseHealth(me.attack_damage * 0.1)
								--other:stun()
							end,
							function(me, other)
								other:looseHealth(me.attack_damage * 0.2)
								--other:stun()
							end
						)

					else
						-- else we move to get to the striking distance

						--- Horizontal movement
						if currentEnemyX > playerX + w + self.enemy_dead_zone_x then

							currentEnemy:move(-currentEnemy.movement_speed * dt, 0)

							currentEnemy:setAniState('walk')
							currentEnemy:faceLeft()

						elseif currentEnemyX < playerX - w - self.enemy_dead_zone_x then

							currentEnemy:move(currentEnemy.movement_speed * dt, 0)

							currentEnemy:setAniState('walk')
							currentEnemy:faceRight()
						end

						--- Vertical movement
						if currentEnemyY > playerY + self.enemy_dead_zone_y then
							-- enemy top to down

							currentEnemy:move(0, -currentEnemy.movement_speed * dt)
							currentEnemy:setAniState('walk')

						elseif currentEnemyY < playerY - self.enemy_dead_zone_y then
							-- enemy down to top

							currentEnemy:move(0, currentEnemy.movement_speed * dt)
							currentEnemy:setAniState('walk')
						end
					end

				elseif not (currentEnemy.triggered or currentEnemy.effects.stunned) then
					-- not triggered
					currentEnemy:goToState('idle')
				end

				player:checkCollision(
					currentEnemy,
					function(me, other)
						other:looseHealth(me.attack_damage * 0.15)
					   -- other:stun()
					end,
					function(me, other)
						other:looseHealth(me.attack_damage * 0.2)
						other:stun()
					end
				)

			end
			currentEnemy:handleAttackBoxes()
		else
			currentEnemy:death()
		end
	end
end
