QBCore = exports['qb-core']:GetCoreObject()
VehicleStatus = {}

local ClosestPlate = nil
local PlayerJob = {}
local onDuty = false
local effectTimer = 0
local openingDoor = false

-- zone check
local isInsideDutyZone = false
local isInsideStashZone = false
local isInsideGarageZone = false
local isInsideVehiclePlateZone = false
local plateZones = {}
local plateTargetBoxID = 'plateTarget_'
local dutyTargetBoxID = 'dutyTarget'
local stashTargetBoxID = 'stashTarget'

local buildingList_table = {}
local dynamicSpawner_state = false

-- Exports

local function GetVehicleStatusList(plate)
    local retval = nil
    if VehicleStatus[plate] ~= nil then
        retval = VehicleStatus[plate]
    end
    return retval
end

local function GetVehicleStatus(plate, part)
    local retval = nil
    if VehicleStatus[plate] ~= nil then
        retval = VehicleStatus[plate][part]
    end
    return retval
end

local function SetVehicleStatus(plate, part, level)
    TriggerServerEvent("vehiclemod:server:updatePart", plate, part, level)
end

exports('GetVehicleStatusList', GetVehicleStatusList)
exports('GetVehicleStatus', GetVehicleStatus)
exports('SetVehicleStatus', SetVehicleStatus)

-- Spawner

function CheckJob()
    print('---')
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        return Player.PlayerData.job.grade.name == 'Engineer'
    end
    return false
end

RegisterNetEvent('qb-mechanicjob:build:garage', function()
    TriggerEvent("qb-mechanicjob:client:spawn", 'garage')
end)

RegisterNetEvent('qb-mechanicjob:build:guardpost', function()
    TriggerEvent("qb-mechanicjob:client:spawn", 'guardpost')
end)

RegisterNetEvent('qb-mechanicjob:build:hospital', function()
    TriggerEvent("qb-mechanicjob:client:spawn", 'hospital')
end)

RegisterNetEvent('qb-mechanicjob:build:radarcenter', function()
    TriggerEvent("qb-mechanicjob:client:spawn", 'radar')
end)

RegisterNetEvent('qb-mechanicjob:build:crafttable', function()
    TriggerEvent("qb-mechanicjob:client:spawn", 'craft')
end)

RegisterNetEvent('qb-mechanicjob:build:weapon', function()
    TriggerEvent("qb-mechanicjob:client:spawn", 'weapon')
end)

RegisterNetEvent('qb-mechanicjob:build:ammo', function()
    TriggerEvent("qb-mechanicjob:client:spawn", 'ammo')
end)

RegisterNetEvent('qb-mechanicjob:build:radar', function()
    TriggerEvent("qb-mechanicjob:client:spawn", 'radar')
end)


RegisterNetEvent('qb-mechanicjob:build:ladder', function()
    TriggerEvent("qb-mechanicjob:client:spawn", 'ladder')
end)

RegisterNetEvent('qb-mechanicjob:build:recycle', function()
    TriggerEvent("qb-mechanicjob:client:spawn", 'recycle')
end)

RegisterNetEvent('qb-mechanicjob:build:builddismiss', function()
    TriggerEvent("qb-mechanicjob:client:spawn", 'radar')
end)


RegisterNetEvent('qb-mechanicjob:build:remove', function(building)
    QBCore.Functions.Notify("You have 5 seconds to run before the blast", "success")
    Wait(5000)
    print(dump(building))
    table.remove(buildingList_table,building.d)
    local coord = json.decode(building.coordinate)
    local ObjectCoords = vector3(coord.x, coord.y, coord.z)
    AddExplosion(ObjectCoords, 5, 100.0, true, false, true)
    DeleteEntity(building.entity)
end)

----
--- This function will be triggered once the hack is done
--- @param success boolean
--- @param bank number | string
--- @return nil
function Config.OnHackDone(success)
    local dist, building = getClosestBuilding(nil)
    TriggerEvent('mhacking:hide')
    if not success then return end
    TriggerEvent('qb-mechanicjob:build:remove', building)
end

--- This is triggered once the hack at a small bank is done
--- @param success boolean
--- @return nil
local function OnHackDone(success)
    Config.OnHackDone(success)
end

RegisterNetEvent('qb-mechanicjob:build:hack', function()
    local ped = PlayerPedId()
    if QBCore.Functions.GetPlayerData().job.grade.name ~= 'Engineer' then
        QBCore.Functions.Notify("You are not an Engineer", "error")
        return 
    end
    local hasItem = QBCore.Functions.HasItem('thermite')
    if hasItem then
        print("IM hacking now")
        
        local pos = GetEntityCoords(ped)
        loadAnimDict("anim@gangops@facility@servers@")
        TaskPlayAnim(ped, 'anim@gangops@facility@servers@', 'hotwire', 3.0, 3.0, -1, 1, 0, false, false, false)
        QBCore.Functions.Progressbar("hack_gate", "Uploading the destroying code", math.random(5000, 10000), false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done
            StopAnimTask(ped, "anim@gangops@facility@servers@", "hotwire", 1.0)
            TriggerServerEvent('qb-mechanicjob:server:removeThermite')
            TriggerEvent("mhacking:show")
            TriggerEvent("mhacking:start", math.random(6, 7), math.random(22, 25), OnHackDone)
            TriggerServerEvent("qb-bankrobbery:server:callCops", "small", closestBank, pos)
            copsCalled = true
        end, function() -- Cancel
            StopAnimTask(ped, "anim@gangops@facility@servers@", "hotwire", 1.0)
            QBCore.Functions.Notify(Lang:t("error.cancel_message"), "error")
        end)
    else
        QBCore.Functions.Notify("You need a Thermite", "error")
    end
    
end)

function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end

function getClosestBuilding(buildingName)
    local closestBuildingIndex = 1
    local closestDistance = 1000000
    for _, building in pairs(buildingList_table) do
        if buildingName == nil or buildingName == building.type then
            print(4)
            local pedCoord = GetEntityCoords(PlayerPedId())
            local c = json.decode(building.coordinate)
            local distance = #((vector3(c.x, c.y, c.z)) - pedCoord)
            if closestDistance > distance then
                closestDistance = distance
                closestBuildingIndex = _
            end
        end
    end
    return closestDistance, buildingList_table[closestBuildingIndex]
end

RegisterNetEvent('qb-mechanicjob:client:validBuilding',function(buildingName, grantrole)
    local closestMargin = 5
    print(2)
    
    if buildingList_table ~= nil then
        local distance, closestBuilding = getClosestBuilding(buildingName)
        local mygang = QBCore.Functions.GetPlayerData().gang
        local myrole = QBCore.Functions.GetPlayerData().job.grade.name
        print("Job Name>", myrole )
        print('2>', distance, " - ", mygang, " - ", closestBuilding.teamname)
        if grantrole == myrole or myrole == "Leader" then
            if distance < closestMargin and mygang == closestBuilding.teamname then
                TriggerEvent("inventory:client:proceedaction", buildingName)
            else
                QBCore.Functions.Notify("Accessible only for " .. grantrole, "error")
            end      
        else
            QBCore.Functions.Notify("This property isn't belongs to your team", "error")
        end   
    end
    
end)


RegisterNetEvent('qb-mechanicjob:client:spawn', function(buildingName)
    local itemModel = getModelType(buildingName) 
    local coords,head = ChooseSpawnLocation(itemModel)
    print('my>', PlayerPedId())
    print('my>', source)
    if coords ~= nil then
        local coordinate = '{ "x":' .. coords.x .. ', "y":' .. coords.y .. ', "z":' .. coords.z .. '}'
        local mygang = QBCore.Functions.GetPlayerData().gang
        TriggerServerEvent("qb-mechanicjob:server:trackBuildingLocation",buildingName,mygang,coordinate,head)
        
        loadBuildingData()  
    end
end)


function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function getModelType(buildingName)
    local modeltype = nil
    if buildingName == 'garage' then
        modeltype = Config.GarageObject
    elseif buildingName == 'guardpost' then
        modeltype ='prop_air_stair_04a'
    elseif buildingName == 'weapon' then
        modeltype = Config.WeaponCraft
    elseif buildingName == 'hospital' then
        modeltype = Config.MedicalCamp
    elseif buildingName == 'radar' then
        modeltype = Config.Radar 
    elseif buildingName == 'craft' then
        modeltype = Config.CraftingObject
    elseif buildingName == 'ammo' then
        modeltype = Config.AmmoCraft
    elseif buildingName == 'recycle' then
        modeltype = Config.Recycle
    elseif buildingName == 'ladder' then
        modeltype = Config.Ladder
    end  
    return modeltype
end

---

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
         return
    end
    Wait(500)
    print('resource started')
    loadBuildingData()
end)


function Flush_Entities()
    for _, building in pairs(buildingList_table) do
         if building.entity then
              DeleteObject(building.entity)
         end
         RemoveBlip(building.blip_handle)
    end
    dynamicSpawner_state = false
    Wait(5)
    buildingList_table = {}
end

function addBuildingToList(s_res, id,teamname)
    if buildingList_table[id] ~= nil then
         return
    end
    buildingList_table[id] = {}
    buildingList_table[id] = s_res
    buildingList_table[id].entity = nil
    if buildingList_table[id].teamname == teamname then
        local blip_settings = Config.Buildings.CraftingTable.blip
        blip_settings.type = 'teamName_'
        blip_settings.id = id
        blip_settings.name = '(' ..teamname .. ') ' .. Config.Buildings.CraftingTable.name
        local c = json.decode(buildingList_table[id].coordinate)
        print(dump(c))
        buildingList_table[id].blip_handle = createCustom(vector3(c.x, c.y, c.z), blip_settings)
   end
end

function createCustom(coord, o)
    local blip = AddBlipForCoord(
         coord.x,
         coord.y,
         coord.z
    )
    SetBlipSprite(blip, o.sprite)
    SetBlipColour(blip, o.colour)
    if o.range == 'short' then
         SetBlipAsShortRange(blip, true)
    else
         SetBlipAsShortRange(blip, false)
    end
    BeginTextCommandSetBlipName("STRING")
    -- AddTextComponentString(replaceString(o))
    AddTextComponentString(o.name)
    EndTextCommandSetBlipName(blip)
    return blip
end

function replaceString(o)
    local s = o.name
    if o.id ~= nil then
         --  oilwells
         local building = getById(o.id)
         s = s:gsub("OILWELLNAME", building.name)
         s = s:gsub("OILWELL_HASH", building.oilrig_hash)
         s = s:gsub("DB_ID_RAW", o.id)
         s = s:gsub("TYPE", o.type)

    else
         s = s:gsub("TYPE", o.type)
    end
    return s
end

function getById(id)
    for key, value in pairs(buildingList_table) do
         if value.id == id then
              return value
         end
    end
    return false
end

function loadBuildingData()
    Flush_Entities()
    local teamName = QBCore.Functions.GetPlayerData().gang
    QBCore.Functions.TriggerCallback('qb-mechanicjob:server:getBuildingLocations', function(result)
        -- local Player = QBCore.Functions.GetPlayer(source)
        -- Player.PlayerData.job.gang
          for key, value in pairs(result) do
               addBuildingToList(value, key,teamName)
          end
          DynamicSpawner()
    end)
end

function DynamicSpawner()
    dynamicSpawner_state = true
    local object_spawn_distance = 25.0

    CreateThread(function()
        Wait(50)
        while dynamicSpawner_state do
            local pedCoord = GetEntityCoords(PlayerPedId())
            for index, value in pairs(buildingList_table) do
                local itemModel = getModelType(value.type);
                local c = json.decode(value.coordinate)
                local distance = #((vector3(c.x, c.y, c.z)) - pedCoord)
                if distance < object_spawn_distance and buildingList_table[index].entity == nil then
                    buildingList_table[index].entity = spawnObjects(itemModel, c, value.heading)
                elseif distance > object_spawn_distance and buildingList_table[index].entity ~= nil then
                    DeleteEntity(buildingList_table[index].entity)
                    buildingList_table[index].entity = nil
                end  
                isDestroyedProp(index)          
            end
            Wait(1250)
        end
        
    
    end)
end

function isDestroyedProp(index)
    if buildingList_table[index].entity ~= nil then
        local health = GetEntityHealth(buildingList_table[index].entity)
        if health < 1 then
            local coord = json.decode(buildingList_table[index].coordinate)
            local ObjectCoords = vector3(coord.x, coord.y, coord.z)
            AddExplosion(ObjectCoords, 5, 100.0, true, false, true)
            DeleteEntity(buildingList_table[index].entity)
            table.remove(buildingList_table,index)
            buildingList_table[index].entity = nil
            TriggerServerEvent("qb-mechanicjob:server:destroyBuilding",buildingList_table[index].id)
        end 
    end
end

function spawnObjects(model, position, heading)
    ClearAreaOfObjects(position.x, position.y, position.z, 5.0, 1)
    -- every oilwell exist only on client side!
    newentity = CreateObject(model, position.x, position.y, position.z, true)
    PlaceObjectOnGroundProperly(newentity)
    SetEntityHeading(newentity, heading-0.00001)
    return newentity
end

----

local function Draw2DText(content, font, colour, scale, x, y)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(colour[1], colour[2], colour[3], 255)
    SetTextEntry("STRING")
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    AddTextComponentString(content)
    DrawText(x, y)
end

local function RotationToDirection(rotation)
    local adjustedRotation = {
         x = (math.pi / 180) * rotation.x,
         y = (math.pi / 180) * rotation.y,
         z = (math.pi / 180) * rotation.z
    }
    local direction = {
         x = -math.sin(adjustedRotation.z) *
             math.abs(math.cos(adjustedRotation.x)),
         y = math.cos(adjustedRotation.z) *
             math.abs(math.cos(adjustedRotation.x)),
         z = math.sin(adjustedRotation.x)
    }
    return direction
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = {
         x = cameraCoord.x + direction.x * distance,
         y = cameraCoord.y + direction.y * distance,
         z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(
         StartShapeTestRay(cameraCoord.x, cameraCoord.y,
              cameraCoord.z, destination.x,
              destination.y, destination.z,
              -1, PlayerPedId(), 0))
    return c, e
end

RegisterNetEvent('qb-mechanicjob:client:test', function()
    -- local coord = json.decode(buildingList_table[1].coordinate)
    -- local ObjectCoords = vector3(coord.x, coord.y, coord.z)
    -- AddExplosion(ObjectCoords, 5, 100.0, true, false, true)
    print('ssss')
    print('>',dump(buildingList_table))
end)

function ChooseSpawnLocation(spawnObj)
    local plyped = PlayerPedId()
    local pedCoord = GetEntityCoords(plyped)
    local activeLaser = true
    local obj = CreateObject(GetHashKey(spawnObj), pedCoord.x, pedCoord.y, pedCoord.z, 1, 1, 0)
   
    SetEntityAlpha(obj, 150, true)

    while activeLaser do
         Wait(0)
         local color = {
              r = 2,
              g = 241,
              b = 181,
              a = 200
         }
         local position = GetEntityCoords(plyped)
         local coords, entity = RayCastGamePlayCamera(1000.0)
        
         Draw2DText('Press ~g~E~w~ To Place Building Stucture \n Press ~g~F~w~ To Ignore the Selection', 4, { 255, 255, 255 }, 0.4, 0.43,
              0.888 + 0.025)
    
        local heading = GetEntityHeading(PlayerPedId())
        SetEntityHeading(obj, heading )
         if IsControlJustReleased(0, 38) then
              activeLaser = false
              DeleteEntity(obj)
              return coords,heading
         elseif IsControlJustReleased(0, 23) then
            activeLaser = false
            DeleteEntity(obj)
            return nil
         end
        
         DrawLine(position.x, position.y, position.z, coords.x, coords.y,
              coords.z, color.r, color.g, color.b, color.a)
         SetEntityCollision(obj, false, false)
         SetEntityCoords(obj, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0)
    end
end

-- Functions

local function DeleteTarget(id)
    if Config.UseTarget then
        exports['qb-target']:RemoveZone(id)
    else
        if Config.Targets[id] and Config.Targets[id].zone then
            Config.Targets[id].zone:destroy();
        end
    end

    Config.Targets[id] = nil
end

local function RegisterDutyTarget()
    local coords = Config.Locations['duty']
    local boxData = Config.Targets[dutyTargetBoxID] or {}

    if boxData and boxData.created then
        return
    end

    if PlayerJob.type ~= 'Engineer' then
        return
    end

    local label = Lang:t('labels.sign_in')
    if onDuty then
        label = Lang:t('labels.sign_off')
    end

    if Config.UseTarget then
        exports['qb-target']:AddBoxZone(dutyTargetBoxID, coords, 1.5, 1.5, {
            name = dutyTargetBoxID,
            heading = 0,
            debugPoly = false,
            minZ = coords.z - 1.0,
            maxZ = coords.z + 1.0,
        }, {
            options = {{
                type = "server",
                event = "QBCore:ToggleDuty",
                label = label,
            }},
            distance = 2.0
        })

        Config.Targets[dutyTargetBoxID] = {created = true}
    else
        local zone = BoxZone:Create(coords, 1.5, 1.5, {
            name = dutyTargetBoxID,
            heading = 0,
            debugPoly = false,
            minZ = coords.z - 1.0,
            maxZ = coords.z + 1.0,
        })
        zone:onPlayerInOut(function (isPointInside)
            if isPointInside then
                exports['qb-core']:DrawText("[E] " .. label, 'left')
            else
                exports['qb-core']:HideText()
            end

            isInsideDutyZone = isPointInside
        end)

        Config.Targets[dutyTargetBoxID] = {created = true, zone = zone}
    end
end

local function RegisterStashTarget()
    local coords = Config.Locations['stash']
    local boxData = Config.Targets[stashTargetBoxID] or {}

    if boxData and boxData.created then
        return
    end

    if PlayerJob.type ~= 'Engineer' then
        return
    end

    if Config.UseTarget then
        exports['qb-target']:AddBoxZone(stashTargetBoxID, coords, 1.5, 1.5, {
            name = stashTargetBoxID,
            heading = 0,
            debugPoly = false,
            minZ = coords.z - 1.0,
            maxZ = coords.z + 1.0,
        }, {
            options = {{
                type = "client",
                event = "qb-mechanicjob:client:target:OpenStash",
                label = Lang:t('labels.o_stash'),
            }},
            distance = 2.0
        })

        Config.Targets[stashTargetBoxID] = {created = true}
    else
        local zone = BoxZone:Create(coords, 1.5, 1.5, {
            name = stashTargetBoxID,
            heading = 0,
            debugPoly = false,
            minZ = coords.z - 1.0,
            maxZ = coords.z + 1.0,
        })
        zone:onPlayerInOut(function (isPointInside)
            if isPointInside then
                exports['qb-core']:DrawText(Lang:t('labels.o_stash'), 'left')
            else
                exports['qb-core']:HideText()
            end

            isInsideStashZone = isPointInside
        end)

        Config.Targets[stashTargetBoxID] = {created = true, zone = zone}
    end
end

local function RegisterGarageZone()
    local coords = Config.Locations['vehicle']
    local vehicleZone = BoxZone:Create(vector3(coords.x, coords.y, coords.z), 5, 15, {
        name = 'vehicleZone',
        heading = 340.0,
        minZ = coords.z - 1.0,
        maxZ = coords.z + 5.0,
        debugPoly = false
    })

    vehicleZone:onPlayerInOut(function (isPointInside)
        if isPointInside and onDuty then
            local inVehicle = IsPedInAnyVehicle(PlayerPedId())
            if inVehicle then
                exports['qb-core']:DrawText(Lang:t('labels.h_vehicle'), 'left')
            else
                exports['qb-core']:DrawText(Lang:t('labels.g_vehicle'), 'left')
            end
        else
            exports['qb-core']:HideText()
        end

        isInsideGarageZone = isPointInside
    end)
end

function DestroyVehiclePlateZone(id)
    if plateZones[id] then
        plateZones[id]:destroy()
        plateZones[id] = nil
    end
end

function RegisterVehiclePlateZone(id, plate)
    local coords = plate.coords
    local boxData = plate.boxData
    local plateZone = BoxZone:Create(vector3(coords.x, coords.y, coords.z), boxData.length, boxData.width, {
        name = plateTargetBoxID .. id,
        heading = boxData.heading,
        minZ = coords.z - 1.0,
        maxZ = coords.z + 3.0,
        debugPoly = boxData.debugPoly
    })

    plateZones[id] = plateZone

    plateZone:onPlayerInOut(function (isPointInside)
        if isPointInside and onDuty then
            if plate.AttachedVehicle then
                exports['qb-core']:DrawText(Lang:t('labels.o_menu'), 'left')
            else
                if IsPedInAnyVehicle(PlayerPedId()) then
                    exports['qb-core']:DrawText(Lang:t('labels.work_v'), 'left')
                end
            end
        else
            exports['qb-core']:HideText()
        end

        isInsideVehiclePlateZone = isPointInside
    end)
end

local function SetVehiclePlateZones()
    if Config.Plates and next(Config.Plates) then
        for id, plate in pairs(Config.Plates) do
            RegisterVehiclePlateZone(id, plate)
        end
    else
        print('No vehicle plates configured')
    end
end

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function SetClosestPlate()
    local pos = GetEntityCoords(PlayerPedId(), true)
    local current = nil
    local dist = nil
    for id,_ in pairs(Config.Plates) do
        if current ~= nil then
            if #(pos - vector3(Config.Plates[id].coords.x, Config.Plates[id].coords.y, Config.Plates[id].coords.z)) < dist then
                current = id
                dist = #(pos - vector3(Config.Plates[id].coords.x, Config.Plates[id].coords.y, Config.Plates[id].coords.z))
            end
        else
            dist = #(pos - vector3(Config.Plates[id].coords.x, Config.Plates[id].coords.y, Config.Plates[id].coords.z))
            current = id
        end
    end
    ClosestPlate = current
end

local function ScrapAnim(time)
    time = time / 1000
    loadAnimDict("mp_car_bomb")
    TaskPlayAnim(PlayerPedId(), "mp_car_bomb", "car_bomb_mechanic" ,3.0, 3.0, -1, 16, 0, false, false, false)
    openingDoor = true
    CreateThread(function()
        while openingDoor do
            TaskPlayAnim(PlayerPedId(), "mp_car_bomb", "car_bomb_mechanic", 3.0, 3.0, -1, 16, 0, 0, 0, 0)
            Wait(2000)
            time = time - 2
            if time <= 0 then
                openingDoor = false
                StopAnimTask(PlayerPedId(), "mp_car_bomb", "car_bomb_mechanic", 1.0)
            end
        end
    end)
end

local function ApplyEffects(vehicle)
    local plate = QBCore.Functions.GetPlate(vehicle)
    if GetVehicleClass(vehicle) ~= 13 and GetVehicleClass(vehicle) ~= 21 and GetVehicleClass(vehicle) ~= 16 and GetVehicleClass(vehicle) ~= 15 and GetVehicleClass(vehicle) ~= 14 then
        if VehicleStatus[plate] ~= nil then
            local chance = math.random(1, 100)
            if VehicleStatus[plate]["radiator"] <= 80 and (chance >= 1 and chance <= 20) then
                local engineHealth = GetVehicleEngineHealth(vehicle)
                if VehicleStatus[plate]["radiator"] <= 80 and VehicleStatus[plate]["radiator"] >= 60 then
                    SetVehicleEngineHealth(vehicle, engineHealth - math.random(10, 15))
                elseif VehicleStatus[plate]["radiator"] <= 59 and VehicleStatus[plate]["radiator"] >= 40 then
                    SetVehicleEngineHealth(vehicle, engineHealth - math.random(15, 20))
                elseif VehicleStatus[plate]["radiator"] <= 39 and VehicleStatus[plate]["radiator"] >= 20 then
                    SetVehicleEngineHealth(vehicle, engineHealth - math.random(20, 30))
                elseif VehicleStatus[plate]["radiator"] <= 19 and VehicleStatus[plate]["radiator"] >= 6 then
                    SetVehicleEngineHealth(vehicle, engineHealth - math.random(30, 40))
                else
                    SetVehicleEngineHealth(vehicle, engineHealth - math.random(40, 50))
                end
            end

            if VehicleStatus[plate]["axle"] <= 80 and (chance >= 21 and chance <= 40) then
                if VehicleStatus[plate]["axle"] <= 80 and VehicleStatus[plate]["axle"] >= 60 then
                    for i=0,360 do
                        SetVehicleSteeringScale(vehicle,i)
                        Wait(5)
                    end
                elseif VehicleStatus[plate]["axle"] <= 59 and VehicleStatus[plate]["axle"] >= 40 then
                    for i=0,360 do
                        Wait(10)
                        SetVehicleSteeringScale(vehicle,i)
                    end
                elseif VehicleStatus[plate]["axle"] <= 39 and VehicleStatus[plate]["axle"] >= 20 then
                    for i=0,360 do
                        Wait(15)
                        SetVehicleSteeringScale(vehicle,i)
                    end
                elseif VehicleStatus[plate]["axle"] <= 19 and VehicleStatus[plate]["axle"] >= 6 then
                    for i=0,360 do
                        Wait(20)
                        SetVehicleSteeringScale(vehicle,i)
                    end
                else
                    for i=0,360 do
                        Wait(25)
                        SetVehicleSteeringScale(vehicle,i)
                    end
                end
            end

            if VehicleStatus[plate]["brakes"] <= 80 and (chance >= 41 and chance <= 60) then
                if VehicleStatus[plate]["brakes"] <= 80 and VehicleStatus[plate]["brakes"] >= 60 then
                    SetVehicleHandbrake(vehicle, true)
                    Wait(1000)
                    SetVehicleHandbrake(vehicle, false)
                elseif VehicleStatus[plate]["brakes"] <= 59 and VehicleStatus[plate]["brakes"] >= 40 then
                    SetVehicleHandbrake(vehicle, true)
                    Wait(3000)
                    SetVehicleHandbrake(vehicle, false)
                elseif VehicleStatus[plate]["brakes"] <= 39 and VehicleStatus[plate]["brakes"] >= 20 then
                    SetVehicleHandbrake(vehicle, true)
                    Wait(5000)
                    SetVehicleHandbrake(vehicle, false)
                elseif VehicleStatus[plate]["brakes"] <= 19 and VehicleStatus[plate]["brakes"] >= 6 then
                    SetVehicleHandbrake(vehicle, true)
                    Wait(7000)
                    SetVehicleHandbrake(vehicle, false)
                else
                    SetVehicleHandbrake(vehicle, true)
                    Wait(9000)
                    SetVehicleHandbrake(vehicle, false)
                end
            end

            if VehicleStatus[plate]["clutch"] <= 80 and (chance >= 61 and chance <= 80) then
                if VehicleStatus[plate]["clutch"] <= 80 and VehicleStatus[plate]["clutch"] >= 60 then
                    SetVehicleHandbrake(vehicle, true)
                    SetVehicleEngineOn(vehicle,0,0,1)
                    SetVehicleUndriveable(vehicle,true)
                    Wait(50)
                    SetVehicleEngineOn(vehicle,1,0,1)
                    SetVehicleUndriveable(vehicle,false)
                    for i=1,360 do
                        SetVehicleSteeringScale(vehicle, i)
                        Wait(5)
                    end
                    Wait(500)
                    SetVehicleHandbrake(vehicle, false)
                elseif VehicleStatus[plate]["clutch"] <= 59 and VehicleStatus[plate]["clutch"] >= 40 then
                    SetVehicleHandbrake(vehicle, true)
                    SetVehicleEngineOn(vehicle,0,0,1)
                    SetVehicleUndriveable(vehicle,true)
                    Wait(100)
                    SetVehicleEngineOn(vehicle,1,0,1)
                    SetVehicleUndriveable(vehicle,false)
                    for i=1,360 do
                        SetVehicleSteeringScale(vehicle, i)
                        Wait(5)
                    end
                    Wait(750)
                    SetVehicleHandbrake(vehicle, false)
                elseif VehicleStatus[plate]["clutch"] <= 39 and VehicleStatus[plate]["clutch"] >= 20 then
                    SetVehicleHandbrake(vehicle, true)
                    SetVehicleEngineOn(vehicle,0,0,1)
                    SetVehicleUndriveable(vehicle,true)
                    Wait(150)
                    SetVehicleEngineOn(vehicle,1,0,1)
                    SetVehicleUndriveable(vehicle,false)
                    for i=1,360 do
                        SetVehicleSteeringScale(vehicle, i)
                        Wait(5)
                    end
                    Wait(1000)
                    SetVehicleHandbrake(vehicle, false)
                elseif VehicleStatus[plate]["clutch"] <= 19 and VehicleStatus[plate]["clutch"] >= 6 then
                    SetVehicleHandbrake(vehicle, true)
                    SetVehicleEngineOn(vehicle,0,0,1)
                    SetVehicleUndriveable(vehicle,true)
                    Wait(200)
                    SetVehicleEngineOn(vehicle,1,0,1)
                    SetVehicleUndriveable(vehicle,false)
                    for i=1,360 do
                        SetVehicleSteeringScale(vehicle, i)
                        Wait(5)
                    end
                    Wait(1250)
                    SetVehicleHandbrake(vehicle, false)
                else
                    SetVehicleHandbrake(vehicle, true)
                    SetVehicleEngineOn(vehicle,0,0,1)
                    SetVehicleUndriveable(vehicle,true)
                    Wait(250)
                    SetVehicleEngineOn(vehicle,1,0,1)
                    SetVehicleUndriveable(vehicle,false)
                    for i=1,360 do
                        SetVehicleSteeringScale(vehicle, i)
                        Wait(5)
                    end
                    Wait(1500)
                    SetVehicleHandbrake(vehicle, false)
                end
            end

            if VehicleStatus[plate]["fuel"] <= 80 and (chance >= 81 and chance <= 100) then
                local fuel = exports['LegacyFuel']:GetFuel(vehicle)
                if VehicleStatus[plate]["fuel"] <= 80 and VehicleStatus[plate]["fuel"] >= 60 then
                    exports['LegacyFuel']:SetFuel(vehicle, fuel - 2.0)
                elseif VehicleStatus[plate]["fuel"] <= 59 and VehicleStatus[plate]["fuel"] >= 40 then
                    exports['LegacyFuel']:SetFuel(vehicle, fuel - 4.0)
                elseif VehicleStatus[plate]["fuel"] <= 39 and VehicleStatus[plate]["fuel"] >= 20 then
                    exports['LegacyFuel']:SetFuel(vehicle, fuel - 6.0)
                elseif VehicleStatus[plate]["fuel"] <= 19 and VehicleStatus[plate]["fuel"] >= 6 then
                    exports['LegacyFuel']:SetFuel(vehicle, fuel - 8.0)
                else
                    exports['LegacyFuel']:SetFuel(vehicle, fuel - 10.0)
                end
            end
        end
    end
end

local function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 1) .. "f", num))
end

local function SendStatusMessage(statusList)
    if statusList ~= nil then
        TriggerEvent('chat:addMessage', {
            template = '<div class="chat-message normal"><div class="chat-message-body"><strong>{0}:</strong><br><br> <strong>'.. Config.ValuesLabels["engine"] ..' (engine):</strong> {1} <br><strong>'.. Config.ValuesLabels["body"] ..' (body):</strong> {2} <br><strong>'.. Config.ValuesLabels["radiator"] ..' (radiator):</strong> {3} <br><strong>'.. Config.ValuesLabels["axle"] ..' (axle):</strong> {4}<br><strong>'.. Config.ValuesLabels["brakes"] ..' (brakes):</strong> {5}<br><strong>'.. Config.ValuesLabels["clutch"] ..' (clutch):</strong> {6}<br><strong>'.. Config.ValuesLabels["fuel"] ..' (fuel):</strong> {7}</div></div>',
            args = {Lang:t('labels.veh_status'), round(statusList["engine"]) .. "/" .. Config.MaxStatusValues["engine"] .. " ("..QBCore.Shared.Items["advancedrepairkit"]["label"]..")", round(statusList["body"]) .. "/" .. Config.MaxStatusValues["body"] .. " ("..QBCore.Shared.Items[Config.RepairCost["body"]]["label"]..")", round(statusList["radiator"]) .. "/" .. Config.MaxStatusValues["radiator"] .. ".0 ("..QBCore.Shared.Items[Config.RepairCost["radiator"]]["label"]..")", round(statusList["axle"]) .. "/" .. Config.MaxStatusValues["axle"] .. ".0 ("..QBCore.Shared.Items[Config.RepairCost["axle"]]["label"]..")", round(statusList["brakes"]) .. "/" .. Config.MaxStatusValues["brakes"] .. ".0 ("..QBCore.Shared.Items[Config.RepairCost["brakes"]]["label"]..")", round(statusList["clutch"]) .. "/" .. Config.MaxStatusValues["clutch"] .. ".0 ("..QBCore.Shared.Items[Config.RepairCost["clutch"]]["label"]..")", round(statusList["fuel"]) .. "/" .. Config.MaxStatusValues["fuel"] .. ".0 ("..QBCore.Shared.Items[Config.RepairCost["fuel"]]["label"]..")"}
        })
    end
end

local function OpenMenu()
    local openMenu = {
        {
            header = Lang:t('lift_menu.header_menu'),
            isMenuHeader = true
        }, {
            header = Lang:t('lift_menu.header_vehdc'),
            txt = Lang:t('lift_menu.desc_vehdc'),
            params = {
                event = "qb-mechanicjob:client:UnattachVehicle",
            }
        }, {
            header = Lang:t('lift_menu.header_stats'),
            txt = Lang:t('lift_menu.desc_stats'),
            params = {
                event = "qb-mechanicjob:client:CheckStatus",
                args = {
                    number = 1,
                }
            }
        }, {
            header = Lang:t('lift_menu.header_parts'),
            txt = Lang:t('lift_menu.desc_parts'),
            params = {
                event = "qb-mechanicjob:client:PartsMenu",
                args = {
                    number = 1,
                }
            }
        }, {
            header = Lang:t('lift_menu.c_menu'),
            txt = "",
            params = {
                event = "qb-mechanicjob:client:target:CloseMenu",
            }
        },
    }
    exports['qb-menu']:openMenu(openMenu)
end

local function PartsMenu()
    local plate = QBCore.Functions.GetPlate(Config.Plates[ClosestPlate].AttachedVehicle)
    if VehicleStatus[plate] ~= nil then
        local vehicleMenu = {
            {
                header = "Status",
                isMenuHeader = true
            }
        }
        for k,v in pairs(Config.ValuesLabels) do
            if math.ceil(VehicleStatus[plate][k]) ~= Config.MaxStatusValues[k] then
                local percentage = math.ceil(VehicleStatus[plate][k])
                if percentage > 100 then
                    percentage = math.ceil(VehicleStatus[plate][k]) / 10
                end
                vehicleMenu[#vehicleMenu+1] = {
                    header = v,
                    txt = "Status: " .. percentage .. ".0% / 100.0%",
                    params = {
                        event = "qb-mechanicjob:client:PartMenu",
                        args = {
                            name = v,
                            parts = k
                        }
                    }
                }
            else
                local percentage = math.ceil(Config.MaxStatusValues[k])
                if percentage > 100 then
                    percentage = math.ceil(Config.MaxStatusValues[k]) / 10
                end
                vehicleMenu[#vehicleMenu+1] = {
                    header = v,
                    txt = Lang:t('parts_menu.status') .. percentage .. ".0% / 100.0%",
                    params = {
                        event = "qb-mechanicjob:client:NoDamage",
                    }
                }
            end
        end
        vehicleMenu[#vehicleMenu+1] = {
            header = Lang:t('lift_menu.c_menu'),
            txt = "",
            params = {
                event = "qb-menu:client:closeMenu"
            }
        }
        exports['qb-menu']:openMenu(vehicleMenu)
    end

end

local function PartMenu(data)
    local partName = data.name
    local part = data.parts
    local TestMenu1 = {
        {
            header = Lang:t('parts_menu.menu_header'),
            isMenuHeader = true
        },
        {
            header = ""..partName.."",
            txt = Lang:t('parts_menu.repair_op')..QBCore.Shared.Items[Config.RepairCostAmount[part].item]["label"].." "..Config.RepairCostAmount[part].costs.."x",
            params = {
                event = "qb-mechanicjob:client:RepairPart",
                args = {
                    part = part,
                }
            }
        },
        {
            header = Lang:t('parts_menu.b_menu'),
            txt = Lang:t('parts_menu.d_menu'),
            params = {
                event = "qb-mechanicjob:client:PartsMenu",
            }
        },
        {
            header = Lang:t('parts_menu.c_menu'),
            txt = "",
            params = {
                event = "qb-menu:client:closeMenu",
            }
        },
    }

    exports['qb-menu']:openMenu(TestMenu1)
end

local function NoDamage()
    local noDamage = {
        {
            header = Lang:t('nodamage_menu.header'),
            isMenuHeader = true
        },
        {
            header = Lang:t('nodamage_menu.bh_menu'),
            txt = Lang:t('nodamage_menu.bd_menu'),
            params = {
                event = "qb-mechanicjob:client:PartsMenu",
            }
        },
        {
            header = Lang:t('nodamage_menu.c_menu'),
            txt = "",
            params = {
                event = "qb-menu:client:closeMenu",
            }
        },
    }
    exports['qb-menu']:openMenu(noDamage)
end

local function UnattachVehicle()
    DoScreenFadeOut(150)
    Wait(150)
    FreezeEntityPosition(Config.Plates[ClosestPlate].AttachedVehicle, false)
    SetEntityCoords(Config.Plates[ClosestPlate].AttachedVehicle, Config.Plates[ClosestPlate].coords.x, Config.Plates[ClosestPlate].coords.y, Config.Plates[ClosestPlate].coords.z)
    SetEntityHeading(Config.Plates[ClosestPlate].AttachedVehicle, Config.Plates[ClosestPlate].coords.w)
    TaskWarpPedIntoVehicle(PlayerPedId(), Config.Plates[ClosestPlate].AttachedVehicle, -1)
    Wait(500)
    DoScreenFadeIn(250)
    Config.Plates[ClosestPlate].AttachedVehicle = nil
    TriggerServerEvent('qb-vehicletuning:server:SetAttachedVehicle', false, ClosestPlate)

    DestroyVehiclePlateZone(ClosestPlate)
    RegisterVehiclePlateZone(ClosestPlate, Config.Plates[ClosestPlate])

end

local function SpawnListVehicle(model)
    local coords = {
        x = Config.Locations["vehicle"].x,
        y = Config.Locations["vehicle"].y,
        z = Config.Locations["vehicle"].z,
        w = Config.Locations["vehicle"].w,
    }

    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
        SetVehicleNumberPlateText(veh, "ACBV"..tostring(math.random(1000, 9999)))
        SetEntityHeading(veh, coords.w)
        exports['LegacyFuel']:SetFuel(veh, 100.0)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        SetVehicleEngineOn(veh, true, true)
    end, model, coords, true)
end

local function VehicleList()
    local vehicleMenu = {
        {
            header = "Vehicle List",
            isMenuHeader = true
        }
    }
    for k,v in pairs(Config.Vehicles) do
        vehicleMenu[#vehicleMenu+1] = {
            header = v,
            txt = "Vehicle: "..v.."",
            params = {
                event = "qb-mechanicjob:client:SpawnListVehicle",
                args = {
                    headername = v,
                    spawnName = k
                }
            }
        }
    end
    vehicleMenu[#vehicleMenu+1] = {
        header = "⬅ Close Menu",
        txt = "",
        params = {
            event = "qb-menu:client:closeMenu"
        }

    }
    exports['qb-menu']:openMenu(vehicleMenu)
end

local function CheckStatus()
    local plate = QBCore.Functions.GetPlate(Config.Plates[ClosestPlate].AttachedVehicle)
    SendStatusMessage(VehicleStatus[plate])
end

local function RepairPart(part)
    local PartData = Config.RepairCostAmount[part]
    local hasitem = false
    local indx = 0
    local countitem = 0
    QBCore.Functions.TriggerCallback('qb-inventory:server:GetStashItems', function(StashItems)
        for k,v in pairs(StashItems) do
            if v.name == PartData.item then
                hasitem = true
                if v.amount >= PartData.costs then
                    countitem = v.amount
                    indx = k
                end
            end
        end
        if hasitem and countitem >= PartData.costs then
            TriggerEvent('animations:client:EmoteCommandStart', {"mechanic"})
            QBCore.Functions.Progressbar("repair_part", Lang:t('labels.progress_bar') ..Config.ValuesLabels[part], math.random(5000, 10000), false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function() -- Done
                TriggerEvent('animations:client:EmoteCommandStart', {"c"})
                if (countitem - PartData.costs) <= 0 then
                    StashItems[indx] = nil
                else
                    countitem = (countitem - PartData.costs)
                    StashItems[indx].amount = countitem
                end
                TriggerEvent('qb-vehicletuning:client:RepaireeePart', part)
                TriggerServerEvent('qb-inventory:server:SaveStashItems', "mechanicstash", StashItems)
                SetTimeout(250, function()
                    PartsMenu()
                end)
            end, function()
                QBCore.Functions.Notify(Lang:t('notifications.rep_canceled'), "error")
            end)
        else
            QBCore.Functions.Notify(Lang:t('notifications.not_materials'), 'error')
        end
    end, "mechanicstash")
end


-- Events

RegisterNetEvent("qb-mechanicjob:client:UnattachVehicle",function()
    UnattachVehicle()
end)

RegisterNetEvent("qb-mechanicjob:client:PartsMenu",function()
    PartsMenu()
end)

RegisterNetEvent("qb-mechanicjob:client:PartMenu",function(data)
    PartMenu(data)
end)

RegisterNetEvent("qb-mechanicjob:client:NoDamage",function()
    NoDamage()
end)

RegisterNetEvent("qb-mechanicjob:client:CheckStatus",function()
    CheckStatus()
end)

RegisterNetEvent("qb-mechanicjob:client:SpawnListVehicle",function(data)
    local vehicleSpawnName = data.spawnName
    SpawnListVehicle(vehicleSpawnName)
end)

RegisterNetEvent("qb-mechanicjob:client:RepairPart",function(data)
    local partData = data.part
    RepairPart(partData)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(3000)
    loadBuildingData()
    -- QBCore.Functions.GetPlayerData(function(PlayerData)
    --     PlayerJob = PlayerData.job
    --     if PlayerData.job.onduty then
    --         if PlayerJob.type == 'mechanic' then
    --             TriggerServerEvent("QBCore:ToggleDuty")
    --         end
    --     end
    -- end)
    QBCore.Functions.TriggerCallback('qb-vehicletuning:server:GetAttachedVehicle', function(plates)
        for k, v in pairs(plates) do
            Config.Plates[k].AttachedVehicle = v.AttachedVehicle
        end
    end)

    QBCore.Functions.TriggerCallback('qb-vehicletuning:server:GetDrivingDistances', function(retval)
        DrivingDistance = retval
    end)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    onDuty = PlayerJob.onduty

    DeleteTarget(dutyTargetBoxID)
    DeleteTarget(stashTargetBoxID)
    RegisterDutyTarget()

    if onDuty then
        RegisterStashTarget()
    end
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    onDuty = duty

    DeleteTarget(dutyTargetBoxID)
    DeleteTarget(stashTargetBoxID)
    RegisterDutyTarget()

    if onDuty then
        RegisterStashTarget()
    end
end)

RegisterNetEvent('qb-vehicletuning:client:SetAttachedVehicle', function(veh, key)
    if veh ~= false then
        Config.Plates[key].AttachedVehicle = veh
    else
        Config.Plates[key].AttachedVehicle = nil
    end
end)

RegisterNetEvent('qb-vehicletuning:client:RepaireeePart', function(part)
    local veh = Config.Plates[ClosestPlate].AttachedVehicle
    local plate = QBCore.Functions.GetPlate(veh)
    if part == "engine" then
        SetVehicleEngineHealth(veh, Config.MaxStatusValues[part])
        TriggerServerEvent("vehiclemod:server:updatePart", plate, "engine", Config.MaxStatusValues[part])
    elseif part == "body" then
        local enhealth = GetVehicleEngineHealth(veh)
        local realFuel = GetVehicleFuelLevel(veh)
        SetVehicleBodyHealth(veh, Config.MaxStatusValues[part])
        TriggerServerEvent("vehiclemod:server:updatePart", plate, "body", Config.MaxStatusValues[part])
        SetVehicleFixed(veh)
        SetVehicleEngineHealth(veh, enhealth)
        if GetVehicleFuelLevel(veh) ~= realFuel then
            SetVehicleFuelLevel(veh, realFuel)
        end
    else
        TriggerServerEvent("vehiclemod:server:updatePart", plate, part, Config.MaxStatusValues[part])
    end
    QBCore.Functions.Notify(Lang:t('notifications.partrep', {value = Config.ValuesLabels[part]}))
end)
RegisterNetEvent('vehiclemod:client:setVehicleStatus', function(plate, status)
    VehicleStatus[plate] = status
end)

RegisterNetEvent('vehiclemod:client:getVehicleStatus', function()
    if not (IsPedInAnyVehicle(PlayerPedId(), false)) then
        local veh = GetVehiclePedIsIn(PlayerPedId(), true)
        if veh ~= nil and veh ~= 0 then
            local vehpos = GetEntityCoords(veh)
            local pos = GetEntityCoords(PlayerPedId())
            if #(pos - vehpos) < 5.0 then
                if not IsThisModelABicycle(GetEntityModel(veh)) then
                    local plate = QBCore.Functions.GetPlate(veh)
                    if VehicleStatus[plate] ~= nil then
                        SendStatusMessage(VehicleStatus[plate])
                    else
                        QBCore.Functions.Notify(Lang:t('notifications.uknown'), "error")
                    end
                else
                    QBCore.Functions.Notify(Lang:t('notifications.not_valid'), "error")
                end
            else
                QBCore.Functions.Notify(Lang:t('notifications.not_close'), "error")
            end
        else
            QBCore.Functions.Notify(Lang:t('notifications.veh_first'), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t('notifications.outside'), "error")
    end
end)

RegisterNetEvent('vehiclemod:client:fixEverything', function()
    if (IsPedInAnyVehicle(PlayerPedId(), false)) then
        local veh = GetVehiclePedIsIn(PlayerPedId(),false)
        if not IsThisModelABicycle(GetEntityModel(veh)) and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
            local plate = QBCore.Functions.GetPlate(veh)
            TriggerServerEvent("vehiclemod:server:fixEverything", plate)
        else
            QBCore.Functions.Notify(Lang:t('notifications.wrong_seat'), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t('notifications.not_vehicle'), "error")
    end
end)

RegisterNetEvent('vehiclemod:client:setPartLevel', function(part, level)
    if (IsPedInAnyVehicle(PlayerPedId(), false)) then
        local veh = GetVehiclePedIsIn(PlayerPedId(),false)
        if not IsThisModelABicycle(GetEntityModel(veh)) and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
            local plate = QBCore.Functions.GetPlate(veh)
            if part == "engine" then
                SetVehicleEngineHealth(veh, level)
                TriggerServerEvent("vehiclemod:server:updatePart", plate, "engine", GetVehicleEngineHealth(veh))
            elseif part == "body" then
                SetVehicleBodyHealth(veh, level)
                TriggerServerEvent("vehiclemod:server:updatePart", plate, "body", GetVehicleBodyHealth(veh))
            else
                TriggerServerEvent("vehiclemod:server:updatePart", plate, part, level)
            end
        else
            QBCore.Functions.Notify(Lang:t('notifications.wrong_seat'), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t('notifications.wrong_seat'), "error")
    end
end)

RegisterNetEvent('vehiclemod:client:repairPart', function(part, level, needAmount)
    if not IsPedInAnyVehicle(PlayerPedId(), false) then
        local veh = GetVehiclePedIsIn(PlayerPedId(), true)
        if veh ~= nil and veh ~= 0 then
            local vehpos = GetEntityCoords(veh)
            local pos = GetEntityCoords(PlayerPedId())
            if #(pos - vehpos) < 5.0 then
                if not IsThisModelABicycle(GetEntityModel(veh)) then
                    local plate = QBCore.Functions.GetPlate(veh)
                    if VehicleStatus[plate] ~= nil and VehicleStatus[plate][part] ~= nil then
                        local lockpickTime = (1000 * level)
                        if part == "body" then
                            lockpickTime = lockpickTime / 10
                        end
                        ScrapAnim(lockpickTime)
                        QBCore.Functions.Progressbar("repair_advanced", Lang:t('notifications.progress_bar'), lockpickTime, false, true, {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        }, {
                            animDict = "mp_car_bomb",
                            anim = "car_bomb_mechanic",
                            flags = 16,
                        }, {}, {}, function() -- Done
                            openingDoor = false
                            ClearPedTasks(PlayerPedId())
                            if part == "body" then
                                local enhealth = GetVehicleEngineHealth(veh)
                                SetVehicleBodyHealth(veh, GetVehicleBodyHealth(veh) + level)
                                SetVehicleFixed(veh)
                                SetVehicleEngineHealth(veh, enhealth)
                                TriggerServerEvent("vehiclemod:server:updatePart", plate, part, GetVehicleBodyHealth(veh))
                                TriggerServerEvent("qb-mechanicjob:server:removePart", part, needAmount)
                                TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items[Config.RepairCost[part]], "remove")
                            elseif part ~= "engine" then
                                TriggerServerEvent("vehiclemod:server:updatePart", plate, part, GetVehicleStatus(plate, part) + level)
                                TriggerServerEvent("qb-mechanicjob:server:removePart", part, level)
                                TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items[Config.RepairCost[part]], "remove")
                            end
                        end, function() -- Cancel
                            openingDoor = false
                            ClearPedTasks(PlayerPedId())
                            QBCore.Functions.Notify(Lang:t('notifications.process_canceled'), "error")
                        end)
                    else
                        QBCore.Functions.Notify(Lang:t('notifications.not_part'), "error")
                    end
                else
                    QBCore.Functions.Notify(Lang:t('notifications.not_valid'), "error")
                end
            else
                QBCore.Functions.Notify(Lang:t('notifications.not_close'), "error")
            end
        else
            QBCore.Functions.Notify(Lang:t('notifications.veh_first'), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t('notifications.not_vehicle'), "error")
    end
end)

RegisterNetEvent('qb-mechanicjob:client:target:OpenStash', function ()
    TriggerEvent("inventory:client:SetCurrentStash", "mechanicstash")
    TriggerServerEvent("inventory:server:OpenInventory", "stash", "mechanicstash", {
        maxweight = 4000000,
        slots = 500,
    })
end)

RegisterNetEvent('qb-mechanicjob:client:target:CloseMenu', function()
    DestroyVehiclePlateZone(ClosestPlate)
    RegisterVehiclePlateZone(ClosestPlate, Config.Plates[ClosestPlate])

    TriggerEvent('qb-menu:client:closeMenu')
end)


-- Threads

CreateThread(function()
    local wait = 500
    while not LocalPlayer.state.isLoggedIn do
        -- do nothing
        Wait(wait)
    end

    local Blip = AddBlipForCoord(Config.Locations["exit"].x, Config.Locations["exit"].y, Config.Locations["exit"].z)
    SetBlipSprite (Blip, 446)
    SetBlipDisplay(Blip, 4)
    SetBlipScale  (Blip, 0.7)
    SetBlipAsShortRange(Blip, true)
    SetBlipColour(Blip, 0)
    SetBlipAlpha(Blip, 0.7)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(Lang:t('labels.job_blip'))
    EndTextCommandSetBlipName(Blip)

    RegisterGarageZone()
    RegisterDutyTarget()
    RegisterStashTarget()
    SetVehiclePlateZones()

    while true do
        wait = 500
        SetClosestPlate()

        if PlayerJob.type == 'mechanic' then

            if isInsideDutyZone then
                wait = 0
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent("QBCore:ToggleDuty")
                end
            end

            if onDuty then
                if isInsideStashZone then
                    wait = 0
                    if IsControlJustPressed(0, 38) then
                        TriggerEvent("qb-mechanicjob:client:target:OpenStash")
                    end
                end

                if isInsideGarageZone then
                    wait = 0
                    local inVehicle = IsPedInAnyVehicle(PlayerPedId())
                    if IsControlJustPressed(0, 38) then
                        if inVehicle then
                            DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
                            exports['qb-core']:HideText()
                        else
                            VehicleList()
                            exports['qb-core']:HideText()
                        end
                    end
                end

                if isInsideVehiclePlateZone then
                    wait = 0
                    local attachedVehicle = Config.Plates[ClosestPlate].AttachedVehicle
                    local coords = Config.Plates[ClosestPlate].coords
                    if attachedVehicle then
                        if IsControlJustPressed(0, 38) then
                            exports['qb-core']:HideText()
                            OpenMenu()
                        end
                    else
                        if IsControlJustPressed(0, 38) and IsPedInAnyVehicle(PlayerPedId()) then
                            local veh = GetVehiclePedIsIn(PlayerPedId())
                            DoScreenFadeOut(150)
                            Wait(150)
                            Config.Plates[ClosestPlate].AttachedVehicle = veh
                            SetEntityCoords(veh, coords)
                            SetEntityHeading(veh, coords.w)
                            FreezeEntityPosition(veh, true)
                            Wait(500)
                            DoScreenFadeIn(150)
                            TriggerServerEvent('qb-vehicletuning:server:SetAttachedVehicle', veh, ClosestPlate)

                            DestroyVehiclePlateZone(ClosestPlate)
                            RegisterVehiclePlateZone(ClosestPlate, Config.Plates[ClosestPlate])
                        end
                    end
                end
            end
        end
        Wait(wait)
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if (IsPedInAnyVehicle(PlayerPedId(), false)) then
            local veh = GetVehiclePedIsIn(PlayerPedId(),false)
            if not IsThisModelABicycle(GetEntityModel(veh)) and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
                local engineHealth = GetVehicleEngineHealth(veh)
                local bodyHealth = GetVehicleBodyHealth(veh)
                local plate = QBCore.Functions.GetPlate(veh)
                if VehicleStatus[plate] == nil then
                    TriggerServerEvent("vehiclemod:server:setupVehicleStatus", plate, engineHealth, bodyHealth)
                else
                    TriggerServerEvent("vehiclemod:server:updatePart", plate, "engine", engineHealth)
                    TriggerServerEvent("vehiclemod:server:updatePart", plate, "body", bodyHealth)
                    effectTimer = effectTimer + 1
                    if effectTimer >= math.random(10, 15) then
                        ApplyEffects(veh)
                        effectTimer = 0
                    end
                end
            else
                effectTimer = 0
                Wait(1000)
            end
        else
            effectTimer = 0
            Wait(2000)
        end
    end
end)
