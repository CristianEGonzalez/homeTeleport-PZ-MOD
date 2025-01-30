-- Tabla global para almacenar la ubicación "home" y el último uso del teletransportador
local playerHome = {}
local lastTeleportUsage = {}

-- Cargar datos almacenados
local function loadTeleportData()
    local data = ModData.getOrCreate("PezWorldHomeTeleport")
    playerHome = data.playerHome or {}
    lastTeleportUsage = data.lastTeleportUsage or {}
end

-- Guardar datos
local function saveTeleportData()
    local data = ModData.getOrCreate("PezWorldHomeTeleport")
    data.playerHome = playerHome
    data.lastTeleportUsage = lastTeleportUsage
    ModData.transmit("PezWorldHomeTeleport")  -- Sincronizar en servidores
end

-- Función para establecer la ubicación "home"
local function setHome(player)
    local x, y, z = player:getX(), player:getY(), player:getZ()
    playerHome[player:getOnlineID()] = {x = x, y = y, z = z}
    saveTeleportData()

    player:setHaloNote("Home set at: X=" .. math.floor(x) .. " Y=" .. math.floor(y) .. " Z=" .. math.floor(z))
end

-- Función para teletransportar al jugador a una ubicación específica
local function teleportPlayer(player, x,y,z)
    player:setX(x)
    player:setY(y)
    player:setZ(z)
    player:setLx(x)
    player:setLy(y)
    player:setLz(z)
end

-- Función para verificar el cooldown
local function canUseTeleporter(player)
    -- Hora actual del juego en horas
    local currentTime = getGameTime():getWorldAgeHours()
    -- Última vez que se usó el teletransportador
    local lastUsageTime = lastTeleportUsage[player:getOnlineID()] or 0
    -- Duración del cooldown en horas del juego (tomado desde las sandbox options)
    local CooldownTime = SandboxVars.PezWorldHomeTeleport.CooldownTime

    if (currentTime - lastUsageTime) < CooldownTime then
        local remainingTime = math.ceil(CooldownTime - (currentTime - lastUsageTime))
        player:setHaloNote("Teleporter on cooldown! Try again in " .. remainingTime .. " in-game hours.")
        return false
    end
    return true
end

-- Función para teletransportarse a la ubicación "home"
local function teleportToHome(player)
    local home = playerHome[player:getOnlineID()]
    if not canUseTeleporter(player) then return end
    if not home then
        player:setHaloNote("No home location set!")
        return
    end

    teleportPlayer(player, home.x, home.y, home.z)
    lastTeleportUsage[player:getOnlineID()] = getGameTime():getWorldAgeHours()
    saveTeleportData()

    player:setHaloNote("Teleported to Home!")
end

-- Menú contextual para el ítem
local function DoTeleporterMenu(playerId, context, items)
    print("DoTeleporterMenu triggered!") -- Depuración

    if #items > 1 then
        print("Multiple items selected. No menu displayed.")
        return
    end

    local item = items[1]
    if not instanceof(item, "InventoryItem") then
        item = item.items[1]
    end

    print("Item type: " .. tostring(item:getFullType()))
    if item:getFullType() ~= "Base.Teleporter" then
        print("Item is not a teleporter. No menu displayed.")
        return
    end

    local player = getPlayer()

    -- Si el ítem no está en el inventario
    if not player:getInventory():containsRecursive(item) then
        print("Item not found in inventory. No menu displayed.")
        return
    end

    context:addOption("Set Home", player, setHome)
    context:addOption("Teleport to Home", player, teleportToHome)

    --context:addOption("Clear Teleport Data", clearTeleportData)   -- Para depuración y pruebas (descomentar para usar)

end

-- Limpiar datos ----------------------------------------
local function clearTeleportData()
    ModData.get("PezWorldHomeTeleportData")[player:getOnlineID()] = nil
    ModData.sync("PezWorldHomeTeleportData")
    print("Teleport data cleared for player " .. tostring(player:getOnlineID()))
end
---------------------------------------------------------

-- Conectar el evento
Events.OnFillInventoryObjectContextMenu.Add(DoTeleporterMenu)

-- Cargar datos almacenados
Events.OnGameStart.Add(loadTeleportData)