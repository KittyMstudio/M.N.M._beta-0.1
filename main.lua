-- ======================
-- BMB / M.N.M FPS DEMO (VERSIUNE FINALĂ CURĂȚATĂ)
-- ======================

-- CONFIG
TILE = 64
FOV = math.pi / 3
RAYS = 160
MAX_DIST = 800

spawnTimer = 30 
pigImage = nil 
treeImage = nil
player = nil
map = nil
trees = nil
weapons = nil
currentWeapon = nil
shootTimer = nil
enemies = nil
dead = false


function love.load()
    -- Setează filtrul implicit la "nearest" pentru a evita orice blur pixelat
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- IMAGINI (Asigură-te că ai pig.png și tree.png în folder)
    pigImage = love.graphics.newImage("pig.png")
    treeImage = love.graphics.newImage("tree.png") 
    
    player = { x = 3, y = 3, angle = 0, speed = 2.5, hp = 100 }
    dead = false
    
    -- Harta (1 = perete, 0 = liber)
    map = {
        {1,1,1,1,1,1,1,1},
        {1,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,1},
        {1,1,1,1,1,1,1,1},
    }

    -- Copaci random (fără coliziune)
    trees = {
        {x = 2.5, y = 2.5},
        {x = 5.2, y = 1.8},
        {x = 6.0, y = 3.5}
    }

    weapons = {
        ak = { damage = 40, cooldown = 0.4 },
        m4 = { damage = 25, cooldown = 0.2 }
    }
    currentWeapon = "ak"
    shootTimer = 0
    enemies = { { x = 5, y = 3, hp = 100 } }
end

function love.keypressed(key)
    if key == "1" then currentWeapon = "ak" end
    if key == "2" then currentWeapon = "m4a1" end
    if key == "3" then currentWeapon = "akm" end
end

function love.update(dt)
    if dead then return end

    spawnTimer = spawnTimer - dt
    if spawnTimer <= 0 then
        table.insert(enemies, { x = 2, y = 2, hp = 100 }) 
        spawnTimer = 30 
    end

    -- Mișcare cu coliziune simplă (verifică doar celula map)
    if love.keyboard.isDown("a") then player.angle = player.angle - 1.6 * dt end
    if love.keyboard.isDown("d") then player.angle = player.angle + 1.6 * dt end
    
    local moveX = math.cos(player.angle) * player.speed * dt
    local moveY = math.sin(player.angle) * player.speed * dt
    
    if love.keyboard.isDown("w") then
        if map[math.floor(player.y)][math.floor(player.x + moveX)] == 0 then player.x = player.x + moveX end
        if map[math.floor(player.y + moveY)][math.floor(player.x)] == 0 then player.y = player.y + moveY end
    end
    if love.keyboard.isDown("s") then
        if map[math.floor(player.y)][math.floor(player.x - moveX)] == 0 then player.x = player.x - moveX end
        if map[math.floor(player.y - moveY)][math.floor(player.x)] == 0 then player.y = player.y - moveY end
    end

    -- Logica inamici
    shootTimer = shootTimer - dt
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        local dx, dy = player.x - e.x, player.y - e.y
        local dist = math.sqrt(dx*dx + dy*dy)

        if dist > 0.6 then
            e.x = e.x + (dx/dist) * dt * 0.8
            e.y = e.y + (dy/dist) * dt * 0.8
        else
            player.hp = player.hp - 20 * dt
        end

        if love.keyboard.isDown("space") and shootTimer <= 0 then
            if dist < 2 then e.hp = e.hp - weapons[currentWeapon].damage end
        end
        if e.hp <= 0 then table.remove(enemies, i) end
    end
    
    if love.keyboard.isDown("space") and shootTimer <= 0 then 
        shootTimer = weapons[currentWeapon].cooldown 
    end
    if player.hp <= 0 then dead = true end
end

function castRay(angle)
    for d = 0, MAX_DIST, 2 do
        local x = player.x + math.cos(angle) * d / TILE
        local y = player.y + math.sin(angle) * d / TILE
        if map[math.floor(y)] and map[math.floor(y)][math.floor(x)] == 1 then return d end
    end
    return MAX_DIST
end

-- Funcție utilitară pentru desenare sprites (Inamici și Copaci)
function drawSprite(sx, sy, img, w, h)
    local dx, dy = sx - player.x, sy - player.y
    local dist = math.sqrt(dx*dx + dy*dy)
    local angle = math.atan2(dy, dx) - player.angle
    -- Corecție unghi
    while angle > math.pi do angle = angle - 2*math.pi end
    while angle < -math.pi do angle = angle + 2*math.pi end

    -- Randare doar dacă este în unghiul vizual și distanța e mai mare de 0.5 unități (preveniți vederea prin obiecte)
    if math.abs(angle) < FOV and dist > 0.5 then 
        -- Corecție perspectivă
        local screenX = (0.5 * (angle / (FOV/2)) + 0.5) * w
        local spriteH = (TILE * h) / (dist * math.cos(angle - player.angle))
        love.graphics.setColor(1,1,1)
        love.graphics.draw(img, screenX, h/2, 0, spriteH/img:getWidth(), spriteH/img:getHeight(), img:getWidth()/2, img:getHeight()/2)
    end
end


function love.draw()
    local w, h = love.graphics.getDimensions()

    -- 1. FUNDAL (Cer și Podea Verde)
    love.graphics.setColor(0.4, 0.6, 1) -- Albastru deschis
    love.graphics.rectangle("fill", 0, 0, w, h/2)
    love.graphics.setColor(0.2, 0.5, 0.2) -- Verde închis
    love.graphics.rectangle("fill", 0, h/2, w, h/2)

    -- 2. PEREȚI (Raycasting cu corecție fisheye)
    for i = 1, RAYS do
        local angle = player.angle - FOV/2 + (i/RAYS)*FOV
        local dist = castRay(angle)
        -- Aplică corecția fisheye folosind cosinusul unghiului relativ
        local height = (TILE * h) / (dist * math.cos(angle - player.angle))
        local shade = 1 - dist / MAX_DIST
        love.graphics.setColor(shade, shade, shade)
        love.graphics.rectangle("fill", (i-1)*(w/RAYS), (h-height)/2, w/RAYS+1, height)
    end

    -- 3. SPRITES (Copaci și Porci) - Trebuie sortate după distanță pentru randare corectă
    -- Notă: Fără sortare, obiectele îndepărtate pot apărea deasupra celor apropiate
    for _, t in ipairs(trees) do drawSprite(t.x, t.y, treeImage, w, h) end
    for _, e in ipairs(enemies) do drawSprite(e.x, e.y, pigImage, w, h) end


    -- 4. HUD
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: "..math.floor(player.hp), 20, 20)
    love.graphics.print("Weapon: "..currentWeapon, 20, 40)
    love.graphics.print("Next Pig in: "..math.ceil(spawnTimer).."s", 20, 60) 
    
    -- Cătarea (Crosshair)
    love.graphics.line(w/2 - 10, h/2, w/2 + 10, h/2)
    love.graphics.line(w/2, h/2 - 10, w/2, h/2 + 10)

    if dead then
        love.graphics.setColor(1,0,0)
        love.graphics.printf("YOU DIED", 0, h/2, w, "center", 0, 2, 2)
    end
end
