-- MIKAEL MESSIAS, 2018
-- License information can be found on LICENSE file

-- Attack ----------------------------------------------

-- timers
canShoot = true
canShootTimerMax = 0.2
canShootTimer = canShootTimerMax

bulletImg = nil

-- array of bullets being drawn and updated
leftBullets = {}
rightBullets = {}

-- Aliens ----------------------------------------------

-- timers
createAlienTimerMax = 0.4
createAlienTimer = createAlienTimerMax

alienImg = nil
alienColor = 0

aliens = {} -- array of living aliens

lostAliens = 0 -- used to store the number of aliens that have passed the player

-- Player -----------------------------------------------
score = 0
finalRanking = 0

logo_kaa = nil

-- Will store flags to indicate in which parts of the game the player is.
flags = {}

-- Load assets like images, sounds, fonts, etc.
function love.load(arg)
    -- Use of the flags:
        -- mainScreen = true, gameOver = false: mainScreen
        -- mainScreen = false, gameOver = false: game screen
        -- mainScreen = false, gameOver = true: gameOver screen
    flags = {
        mainScreen = true,
        gameOver = false,
    }

    stdFont = love.graphics.newImageFont("assets/font/8bit-font.png",
    " abcdefghijklmnopqrstuvwxyz" ..
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
    "123456789.,!?-+/():;%&`'*#=[]\"")

    -- stdFont = love.graphics.newFont('assets/font/press-start2p.ttf', 9)
    love.graphics.setFont(stdFont)

    -- logo_kaa = love.graphics.newImage('assets/image/logo.png')

    -- Creates an object for the player that stores all related information.
    player = {
        x = love.graphics:getWidth()/2-50, 
        y = 460, 
        speed = 200, 
        lifeCount = 5,
        isAlive = false,
        img = nil
    }
    
    -- Loads the image that will represent the player.
    player.img = love.graphics.newImage('assets/image/playerPlane.png')

    -- Loads the image that will represent the shot.
    bulletImg = love.graphics.newImage('assets/image/laser_bullet.png')

    -- Loads sound effects
    sfx = {
        shoot = love.audio.newSource("assets/audio/shoots.wav", "static"),
        playerHit = love.audio.newSource("assets/audio/playerHit.wav", "static"),
        enemyHit = love.audio.newSource("assets/audio/enemyHit.wav", "static"),
        lifeUp = love.audio.newSource("assets/audio/lifeUp.wav", "static")
    }

    -- Loads music themes
    music = {
        theme = love.audio.newSource("assets/audio/royal_entrance.mp3", "static"),
        gameOver = love.audio.newSource("assets/audio/jingle-lose.wav", "static")
    }

    music.theme:setLooping(true)
end

-- Update the state of the game every frae 
function love.update(dt)
    -- Quick way to exit the game
    if love.keyboard.isDown('escape') then
        love.event.push('quit')
    end

    if not player.isAlive then
        music.theme:stop()                

        if flags.mainScreen then
            if love.keyboard.isDown('return') then
                flags.gameOver = false
                flags.mainScreen = false
                player.lifeCount = 5
                resetGame(true)
                music.theme:play()
            end
        elseif player.lifeCount >= 0 then
            finalRanking = finalRanking + score
            music.theme:play()
            resetGame(true)
        elseif flags.gameOver then
            if love.keyboard.isDown('q') then
                flags.gameOver = false                
                finalRanking = 0
                flags.mainScreen = true
            elseif love.keyboard.isDown('return') then
                flags.gameOver = false
                finalRanking = 0
                player.lifeCount = 5
                resetGame(true)
                music.theme:play()
            end
        elseif player.lifeCount < 0 then
                finalRanking = finalRanking + score        
                flags.gameOver = true
                music.gameOver:play()
        end
    else 
        -- Handles player movement keys
        if love.keyboard.isDown('left','a') then
            if player.x > 0 then -- binds up to the map
                player.x = player.x - (player.speed*dt)
            end
        elseif love.keyboard.isDown('right','d') then
            if player.x < (love.graphics.getWidth() - player.img:getWidth()) then
                player.x = player.x + (player.speed*dt)
            end
        end
        if love.keyboard.isDown('up','w') then
            if player.y > (love.graphics.getHeight()/2) then
                player.y = player.y - (player.speed * dt)
            end
        elseif love.keyboard.isDown('down','s') then
            if player.y < (love.graphics.getHeight() - 100) then
                player.y = player.y + (player.speed * dt)
            end
        end
    
        -- Time out how far apart shots can be
        canShootTimer = canShootTimer - (1 * dt)
        if canShootTimer < 0 then
            canShoot = true
        end
    
        -- Whenever the player hits 100 aliens, he gains an extra life
        if score == 100 then
            sfx.lifeUp:setVolume(1)
            sfx.lifeUp:play()
            finalRanking = finalRanking + score
            score = 0
            player.lifeCount = player.lifeCount + 1
        end
    
        -- Deals with events related to the fire button
        if love.keyboard.isDown('space', 'rctrl', 'lctrl') and canShoot then
            newLeftBullet = {
                x = player.x + (player.img:getWidth()/2-28), 
                y = player.y, 
                img = bulletImg
            }
    
            newRightBullet = {
                x = player.x + (player.img:getWidth()/2+18), 
                y = player.y, 
                img = bulletImg            
            }
    
            -- Insert both new objects into the respective bullets table
            table.insert(leftBullets, newLeftBullet)
            table.insert(rightBullets, newRightBullet)
    
            playSoundEffect(sfx.shoot)
    
            canShoot = false
            canShootTimer = canShootTimerMax
        end
    
        -- Updates bullet position on screen
        for i, bullet in ipairs(leftBullets) do
            bullet.y = bullet.y - (250 * dt) 
    
            if bullet.y < 0 then -- remove bullets when they pass off the screen
                table.remove(leftBullets, i)
            end
        end
    
        for i, bullet in ipairs(rightBullets) do
            bullet.y = bullet.y - (250 * dt) 
    
            if bullet.y < 0 then -- remove bullets when they pass off the screen
                table.remove(rightBullets, i)
            end
        end

        createAlienTimer = createAlienTimer - (1 * dt)
        if createAlienTimer < 0 then
            createAlienTimer = createAlienTimerMax
    
            randomNumber = math.random(10, love.graphics.getWidth() - 10)
    
            alienColor = math.random(0,140)
    
            if alienColor <= 10 or alienColor > 50 and alienColor <= 60 then
                alienImg = love.graphics.newImage('assets/image/aliens/yellowAlien.png')
            elseif alienColor > 10 and alienColor <= 20 or alienColor > 100 and alienColor <= 110 then
                alienImg = love.graphics.newImage('assets/image/aliens/greenAlien.png')
            elseif alienColor > 30 and alienColor <= 40 or alienColor > 90 and alienColor <= 100 then
                alienImg = love.graphics.newImage('assets/image/aliens/pinkAlien.png')
            elseif alienColor > 40 and alienColor <= 50 or alienColor > 70 and alienColor <= 80 then
                alienImg = love.graphics.newImage('assets/image/aliens/blueAlien.png')
            elseif alienColor > 60 and alienColor <= 70 or alienColor > 110 and alienColor <= 120 then
                alienImg = love.graphics.newImage('assets/image/aliens/orangeAlien.png')       
            elseif alienColor > 80 and alienColor <= 90 or alienColor > 120 and alienColor <= 130 then
                alienImg = love.graphics.newImage('assets/image/aliens/grayAlien.png')  
            elseif alienColor > 20 and alienColor <= 30 or alienColor > 130 then
                alienImg = love.graphics.newImage('assets/image/aliens/redAlien.png')         
            end
    
            newAlien = {x = randomNumber, y = -10, img = alienImg}

            table.insert(aliens, newAlien)
        end
    
        -- update the positions of aliens
        for i, alien in ipairs(aliens) do
            alien.y = alien.y + (180 * dt)
    
            if alien.y > love.graphics:getHeight()+110 then -- remove aliens when they pass of the screen
                table.remove(aliens, i)
                lostAliens = lostAliens + 1
            end
        end

        -- Colllision detection: 
        -- Loop aliens and bullets tables to verify wether are collision or not
        for i, alien in ipairs(aliens) do
            for j, bullet in ipairs(leftBullets) do
                if CheckCollision(alien.x, alien.y, alien.img:getWidth(), alien.img:getHeight(), bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) then
                    playSoundEffect(sfx.enemyHit)        
                    table.remove(leftBullets, j)
                    table.remove(aliens, i)
                    score = score + 1
                end
            end
        end

        -- Colllision detection: 
        -- Loop aliens and bullets tables to verify wether are collision or not
        for i, alien in ipairs(aliens) do
            for j, bullet in ipairs(rightBullets) do
                if CheckCollision(alien.x, alien.y, alien.img:getWidth(), alien.img:getHeight(), bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) then
                    playSoundEffect(sfx.enemyHit)        
                    table.remove(rightBullets, j)
                    table.remove(aliens, i)
                    score = score + 1
                end
            end
        end
        
        -- Colllision detection: 
        -- Verify collision between aliens and the player
        for i, alien in ipairs(aliens) do
            if CheckCollision(alien.x, alien.y, alien.img:getWidth(), alien.img:getHeight(), player.x, player.y, player.img:getWidth(), player.img:getHeight()) then
                playSoundEffect(sfx.playerHit)
                player.isAlive = false
                player.lifeCount = player.lifeCount - 1          
            end
        end
        
        if lostAliens > 50 then
            player.isAlive = false
            player.lifeCount = player.lifeCount - 1
        end
    end
end

function love.draw(dt)
    message = nil
    screenWidth = love.graphics:getWidth()
    color = love.graphics.setColor

    if player.isAlive then
        love.graphics.setBackgroundColor(0, 0, 18)
        
        love.graphics.draw(player.img, player.x, player.y)

        for i, bullet in ipairs(leftBullets) do
            love.graphics.draw(bullet.img, bullet.x, bullet.y)
        end
        
        for i, bullet in ipairs(rightBullets) do
            love.graphics.draw(bullet.img, bullet.x, bullet.y)
        end
        
        for i, alien in ipairs(aliens) do
            love.graphics.draw(alien.img, alien.x, alien.y)
        end

        if lostAliens >= 25 and lostAliens < 30 then
            message = "CAUTION!\nAliens are almost dominating the perimeter"
            love.graphics.printf(message, 0, 200, screenWidth, "center")
            music.theme:setPitch(0.5)
        else
            music.theme:setPitch(1)        
        end
        
        message = "SCORE: " .. tostring(score) ..
        "    LIFES: " .. tostring(player.lifeCount) ..
        "    LOST ALIENS: " .. tostring(lostAliens)        
        
        if player.lifeCount == 0 or lostAliens >= 45 then
            -- The player is almost losing
            color(255, 60, 0)
            love.graphics.printf(message, 0, 20, screenWidth, "center")
        else
            color(255, 200, 0)
            love.graphics.printf(message, 0, 20, screenWidth, "center")
        end
        
        color(255, 255, 255)
    else
        love.graphics.setBackgroundColor(0,0,0)
        
        screenHeight = love.graphics:getHeight()/2-10;        

        if flags.mainScreen then           
            -- love.graphics.draw(logo_kaa, 40, 30)           

            message = "Press 'ENTER' to start"
            love.graphics.printf(message, 0, 280, screenWidth, "center")

            message = "CONTROLS:\n\nA: move left\nD: move right\nW: move up\n" ..
                    "S: move down\nSPACE: shoot"
            love.graphics.printf(message, 20, screenHeight+80, screenWidth-20, "left")
        elseif flags.gameOver then
            color(255, 0, 0)
            love.graphics.setNewFont('assets/font/press-start2p.ttf', 15)

            love.graphics.printf("GAME OVER", 0, screenHeight-30, screenWidth, "center")

            color(255, 255, 255)
            love.graphics.setFont(stdFont)

            message = "Final Ranking: " .. tostring(finalRanking) .. "\n\n" .. 
                    "ENTER: restart\nQ: main screen\nESC: leave"
            love.graphics.printf(message, 0, screenHeight+20, screenWidth, "center")
        end
    end
end

-- Receives a source object, does the default routine and plays the effect.
    -- sound: the source object.
function playSoundEffect(sound)
    -- Generate a pitchMod value (sound frequency) between 0.8 and 1.2.
    pitchMod = 0.6 + love.math.random(0, 10)/25
    -- Set the pitchMod and play the sound effect.
    sound:setPitch(pitchMod)
    sound:setVolume(0.8)
    sound:play()
end

-- Remove and/or reset bullets, aliens and player variables, and set the state of the player (alive or not).
    -- status: the state of the player.
function resetGame(status)
    -- remove all bullets and aliens from screen
    bullets = {}
    aliens = {}
    
    -- reset timers
    canShootTimer = canShootTimerMax
    createAlienTimer = createAlienTimerMax
    
    --reset player to the default position
    player.x = love.graphics:getWidth()/2-50
    player.y = 460
    
    -- reset game state
    score = 0
    player.isAlive = status
    lostAliens = 0    
end

-- Collision detection taken function from http://love2d.org/wiki/BoundingBox.lua
    -- Returns true if two boxes overlap, false if they don't
    -- x1,y1 are the left-top coords of the first box, while w1,h1 are its width and height
    -- x2,y2,w2 & h2 are the same, but for the second box
function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
    return x1 < x2+w2 and
           x2 < x1+w1 and
           y1 < y2+h2 and
           y2 < y1+h1
end