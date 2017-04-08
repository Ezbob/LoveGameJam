
AI = {
	enemy_dead_zone_y = 15,
    enemy_dead_zone_x = 15
}


function AI:update(dt, enemies, score_table)

	for i, current_enemy in ipairs(enemies) do

        current_enemy.animation:update(dt)
        local en_pos_x = current_enemy.position.x
        local en_pos_y = current_enemy.position.y

        for index, player in ipairs(entities.players) do

            local w, h = player:getBboxDimensions() 

            if en_pos_x <= player.position.x + detection_zone_width or en_pos_x <= player.position.x - detection_zone_width then
                current_enemy.triggered = true
            else
                current_enemy.triggered = false
            end

            if current_enemy.triggered then
            	--- Horizontal movement
                if en_pos_x > player.position.x + w + self.enemy_dead_zone_x then
                    local intendedX = current_enemy.position.x - current_enemy.movement_speed * dt
                    local intendedY = current_enemy.position.y
                    local actualX, actualY, col, len = world:move(current_enemy, intendedX, intendedY)
                    current_enemy.position.x = actualX
                    current_enemy.position.y = actualY
                    current_enemy:setAniState('walk')
                    
                    current_enemy:faceLeft()

                elseif en_pos_x < player.position.x then

                    local intendedX = current_enemy.position.x + current_enemy.movement_speed * dt
                    local intendedY = current_enemy.position.y
                    local actualX, actualY, col, len = world:move(current_enemy, intendedX, intendedY)
                    current_enemy.position.x = actualX
                    current_enemy.position.y = actualY
                    
                    current_enemy:faceRight()
                end

                --- Vertical movement
                if en_pos_y > player.position.y + self.enemy_dead_zone_y then
                    -- enemy top to down

                    local intendedX = current_enemy.position.x
                    local intendedY = current_enemy.position.y - current_enemy.movement_speed * dt
                    local actualX, actualY, col, len = world:move(current_enemy, intendedX, intendedY)
                    current_enemy.position.x = actualX
                    current_enemy.position.y = actualY
                    current_enemy:setAniState('walk')

                elseif en_pos_y < player.position.y - self.enemy_dead_zone_y then
                    -- enemy down to top
                    local intendedX = current_enemy.position.x
                    local intendedY = current_enemy.position.y + current_enemy.movement_speed * dt
                    local actualX, actualY, col, len = world:move(current_enemy, intendedX, intendedY)
                    current_enemy.position.x = actualX
                    current_enemy.position.y = actualY
                    current_enemy:setAniState('walk')
                end

                if not (en_pos_x > player.position.x + w + self.enemy_dead_zone_y or en_pos_x < player.position.x
                    or en_pos_y > player.position.y + self.enemy_dead_zone_y or
                    en_pos_y < player.position.y - self.enemy_dead_zone_y) then
                    current_enemy:setAniState('idle')
                end

            else
                current_enemy:setAniState('idle')
            end

            if player.punch_box.isActive then

                if check_collision({ position = { x = player.punch_box.x, y = player.punch_box.y}, width = player.punch_box.width, height = player.punch_box.height}, current_enemy) then

                    score_table:pushScore(100)

                    if player:isFacingLeft() then
                        local intendedX = current_enemy.position.x - 100
                        local intendedY = current_enemy.position.y
                        local actualX, actualY, col, len = world:move(current_enemy, intendedX, intendedY)
                        current_enemy.position.x = actualX; current_enemy.position.y = actualY
                    else 
                        local intendedX = current_enemy.position.x + 100
                        local intendedY = current_enemy.position.y
                        local actualX, actualY, col, len = world:move(current_enemy, intendedX, intendedY)
                        current_enemy.position.x = actualX; current_enemy.position.y = actualY
                    end 
                end
            end

            if player.kick_box.isActive then

                if check_collision({ position = { x = player.kick_box.x, y = player.kick_box.y}, width = player.kick_box.width, height = player.kick_box.height}, current_enemy) then
                    
                    score_table:pushScore(200)

                    if player.facingLeft then
                        current_enemy:move(-300, 0)
                    else 
                        current_enemy:move(300, 0)
                    end 
                end
            end
        end
        current_enemy:handleAttackBoxes()
    end
end
