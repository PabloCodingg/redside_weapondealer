last_interaction = 0

local allowedStateSynchronized = false
local isAllowed = false

local computerBlip = nil
local deliveryBlip = nil
local craftBlip = nil

local mission_ped = nil
local mission_ped_ready = false

local canDoDelivery = false
local pedInvestigate = false
local pedInvestigationSpeech = ""

local missionData = {}
local vanLocation = nil

local missionBlip = nil
local timer = 0
local vehPlate = nil
local menuDeliveringDesc = {
    [true] = "Effectuer une livraison de matériaux nécéssaire à la fabrication des armes",
    [false] = "Vous ne pouvez pas effectuer de livraison car vous en avez déjà fait une récemment ou vous avez une livraison en cours."
}
local menuDeliveringStyle = {
    [true] = {RightLabel = "→→"},
    [false] = {RightBadge = 5}
}

local componentsVan = nil

-- Fonctions diverses
function Popup(txt)
    ClearPrints()
    SetNotificationBackgroundColor(140)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(txt)
    DrawNotification(false, true)
end

function ShowHelp(text, n)
    BeginTextCommandDisplayHelp(text)
    EndTextCommandDisplayHelp(n or 0, false, true, -1)
end

function ShowFloatingHelp(text, pos)
    SetFloatingHelpTextWorldPosition(1, pos)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    ShowHelp(text, 2)
end

function DrawAdvancedNotification(sender, subject, msg, textureDict, iconType)
    SetAudioFlag("LoadMPData", 1)
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", 1)
	AddTextEntry('AutoEventAdvNotif', msg)
	BeginTextCommandThefeedPost('AutoEventAdvNotif')
	EndTextCommandThefeedPostMessagetext(textureDict, textureDict, false, iconType, sender, subject)
	--EndTextCommandThefeedPostTicker(flash or false, saveToBrief)
end


-- La définition de la possibilité du joueur à intéragir avec le système d'armes illégal est oui ou non est définie dès la connexion de celui-ci
Citizen.CreateThread(function()
    TriggerServerEvent(weaponCraftConfig.prefix.."isAllowed")
    while not allowedStateSynchronized do Citizen.Wait(10) end
    if isAllowed == false then return end
    createMenuThread()
    createComputerBlip()
    createMissionPed()
    createDeliveryBlip()
    createCraftBlip()
    -- Adding menu
    RMenu.Add(weaponCraftConfig.prefix, 'main', RageUI.CreateMenu("Marché d'armes","Marché illégal d'armes"))
    local wait = 0
    local closeToZone = nil

    while true do
        local pCoords = GetEntityCoords(PlayerPedId())
        for k,v in pairs(weaponCraftConfig.Zones) do
            local dst = GetDistanceBetweenCoords(pCoords, v.pos, true)
            if dst <= v.drawDistance then
                closeToZone = true
                v.draw()
                if dst <= v.interactionDistance then
                    v.interact()
                end
            else
                if closeToZone ~= true then closeToZone = false end

            end
        end
        if not closeToZone then wait = 1000 else wait = 5 end
        Citizen.Wait(wait)
    end
end)

function createMenuThread()
    Citizen.CreateThread(function()
        while true do
            RageUI.IsVisible(RMenu:Get(weaponCraftConfig.prefix,'main'),true,true,true,function()
                if last_interaction == 0 then
                RageUI.ButtonWithStyle("Effectuer une livraison",menuDeliveringDesc[canDoDelivery], menuDeliveringStyle[canDoDelivery], canDoDelivery, function(Hovered,Active,Selected)
                    if Selected then
                        RageUI.Visible(RMenu:Get(weaponCraftConfig.prefix,'main'), false)
                        TriggerServerEvent(weaponCraftConfig.prefix.."setOnCoolDown")
                        local componentsReward = weaponCraftConfig.Rewards.components()
                        local metalReward = weaponCraftConfig.Rewards.metal()
                        PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0)
                        DrawAdvancedNotification("Red Saïd", "~r~Vol de marchandise", "~y~Mission: ~s~Voles cette camionnette et ramène-là moi!~n~~g~Récompense: ~o~"..componentsReward.." composants ~s~/ ~o~"..metalReward.." métaux","CHAR_MP_ROBERTO",9)
                        TriggerServerEvent(weaponCraftConfig.prefix.."initDelivery", {components = componentsReward, metal = metalReward})
                        missionData = {components = componentsReward, metal = metalReward}
                        createMissionThread()
                        --createCopCallThread() Sera disponible à la version 1.1
                    end
                end)
                elseif last_interaction == 2 then 
                    for k,v in pairs(weaponCraftConfig.Craft) do 
                        RageUI.ButtonWithStyle("Fabriquer "..v.label,"Cliquez pour fabriquer cette arme", {RightLabel = "→→"}, true, function(Hovered,Active,Selected)
                            if Selected then
                                RageUI.Visible(RMenu:Get(weaponCraftConfig.prefix,'main'), false)
                                craftItem(v.item)
                            end
                        end)
                    end
                end
            end, function()    
            end, 1)

            Citizen.Wait(0)

        end
    end)
end

function createCopCallThread()
    Citizen.SetTimeout(1000*weaponCraftConfig.timeBeforeCops, function()
        PlaySoundFrontend(-1, "FIRST_PLACE", "HUD_MINI_GAME_SOUNDSET", 1)
        DrawAdvancedNotification("911 Tracker", "~r~Appel reçu", "Un civil a apperçu un ~b~van suspect~s~ et a appellé ~r~la police~s~!","CHAR_CALL911",9)
        -- TODO -> Faire la boucle pour les policiers et le marker
    end)
end

function createMissionThread()
    Citizen.CreateThread(function()
        vanLocation = weaponCraftConfig.Locations.randomize()
        missionBlip = AddBlipForCoord(vanLocation.x,vanLocation.y,vanLocation.z)
	    SetBlipSprite(missionBlip, 1)
	    SetBlipDisplay(missionBlip, 4)
	    SetBlipScale(missionBlip, 1.0)
	    SetBlipColour(missionBlip, 5)
	    SetBlipAsShortRange(missionBlip, true)
	    BeginTextCommandSetBlipName("STRING")
	    AddTextComponentString("Localisation de la marchandise")
	    EndTextCommandSetBlipName(missionBlip)
        SetBlipRoute(missionBlip, true)
        updateBlipsName()
        local van = GetHashKey("burrito")
        --RequestModel(van)
        --while not HasModelLoaded(van) do Citizen.Wait(100) end

        rUtils.SpawnVehicle(van, vector3(vanLocation.x,vanLocation.y,vanLocation.z), 90.0, _, function(veh)
            vehPlate = GetVehicleNumberPlateText(veh)
            SetEntityAsMissionEntity(veh,true,true)
        end)
        --TriggerServerEvent(weaponCraftConfig.prefix.."setVehPlate", vehPlate)

        local vanFound = false

        while not vanFound do
            local playerLoc = GetEntityCoords(PlayerPedId())
            local dst = GetDistanceBetweenCoords(playerLoc, vanLocation, true)
            if dst <= 10 then
                vanFound = true
            end
            Citizen.Wait(500)
        end

        RemoveBlip(missionBlip)
        DrawAdvancedNotification("Red Saïd", "~r~Vol de marchandise", "Trouve le véhicule, et ramène-le à la base pour que je fasse sauter le cadenas!","CHAR_MP_ROBERTO",9)
        -- Suite 
    end)
end

function getButtonAccessibility()
    local val = nil
    if isDelivering == 1 or isDelivering == 2 then
        return false 
    else
        return true
    end
end



function alterMenuVisibility()
    RageUI.Visible(RMenu:Get(weaponCraftConfig.prefix,'main'), not RageUI.Visible(RMenu:Get(weaponCraftConfig.prefix,'main')))
end



function createComputerBlip() 
    computerBlip = AddBlipForCoord(weaponCraftConfig.Zones[1].pos)
    SetBlipAsShortRange(computerBlip, true)
    SetBlipScale(computerBlip, 1.0)
    SetBlipSprite(computerBlip, 521)
    SetBlipColour(computerBlip, 59)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Ordinateur de livraison")
    EndTextCommandSetBlipName(computerBlip)
end

function createDeliveryBlip() 
    deliveryBlip = AddBlipForCoord(weaponCraftConfig.Zones[2].pos)
    SetBlipAsShortRange(deliveryBlip, true)
    SetBlipScale(deliveryBlip, 1.0)
    SetBlipSprite(deliveryBlip, 478)
    SetBlipColour(deliveryBlip, 59)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Livraison de cargaison")
    EndTextCommandSetBlipName(deliveryBlip)
end

function createCraftBlip() 
    craftBlip = AddBlipForCoord(weaponCraftConfig.Zones[3].pos)
    SetBlipAsShortRange(craftBlip, true)
    SetBlipScale(craftBlip, 1.0)
    SetBlipSprite(craftBlip, 643)
    SetBlipColour(craftBlip, 59)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Fabrique d'arme")
    EndTextCommandSetBlipName(craftBlip)
end

function updateBlipsName()
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Ordinateur de livraison")
    EndTextCommandSetBlipName(computerBlip)

    --

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Livraison de cargaison")
    EndTextCommandSetBlipName(deliveryBlip)

    --

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Fabrique d'arme")
    EndTextCommandSetBlipName(craftBlip)
end

function createMissionPed()
    local model = GetHashKey("s_m_y_robber_01")
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(100) end
    mission_ped = CreatePed_(9, model, -1097.99, 4949.87, 218.35, 245.0, false, true)
    Citizen.Wait(1500)
    TaskStartScenarioInPlace(mission_ped, "WORLD_HUMAN_GUARD_STAND", 0, true)
    FreezeEntityPosition(mission_ped,true)
    SetBlockingOfNonTemporaryEvents(mission_ped, true)
    SetEntityInvincible(mission_ped,true)
    mission_ped_ready = true
end

function pre_delivery()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    local vehPlateb = GetVehicleNumberPlateText(veh)
    Citizen.Wait(100)
    if vehPlate == nil then
    else
        if vehPlate ~= vehPlateb then 
            DrawAdvancedNotification("Red Saïd", "~r~Vol de marchandise", "Tu pensais pouvoir m'avoir aussi facilement? Non.","CHAR_MP_ROBERTO",9)
        else
            delivery()
        end
    end
end

function delivery()
    pedInvestigate = true
    vehPlate = nil
    createPedDialog()
    pedInvestigationSpeech = ""
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    SetVehicleUndriveable(veh,true)
    TaskLeaveVehicle(PlayerPedId(), veh, 1)
    if mission_ped == nil then
        mission_ped_ready = false
        createMissionPed()
    end
    while not mission_ped_ready do Citizen.Wait(100) end
    while IsPedInAnyVehicle(PlayerPedId(), false) do Citizen.Wait(100) end


    TaskStartScenarioInPlace(mission_ped, "WORLD_HUMAN_HAMMERING", 0, true)
    pedInvestigationSpeech = "~y~Sous-traitant: ~s~Eh ben! Je n'y croyais plus, vous voilà enfin.."
    ClearPedTasksImmediately(mission_ped)
    Citizen.Wait(1000)
    FreezeEntityPosition(mission_ped,false)
    -- Ped action

    Citizen.Wait(2000)
    pedInvestigationSpeech = "~y~Sous-traitant: ~s~Bon, voyons voir.."

    --TaskEnterVehicle(mission_ped, veh, 20000,-1, 1.5, 1, 0)

    --while not IsPedInAnyVehicle(mission_ped, false) do Citizen.Wait(100) end
    local x,y,z = GetEntityCoords(veh)
    local vehBoneIndex = GetEntityBoneIndexByName(veh,"wheel_lr")
    local pos = GetWorldPositionOfEntityBone(veh, vehBoneIndex)
    TaskStartScenarioAtPosition(mission_ped, "WORLD_HUMAN_HAMMERING", pos.x, pos.y, pos.z, 245.0, -1, false,false)
    Citizen.Wait(4000)
    pedInvestigationSpeech = "~y~Sous-traitant: ~s~Cela ne me prendra que quelques secondes.."
    Citizen.Wait(14500)
    pedInvestigationSpeech = "~y~Sous-traitant: ~s~Nous y sommes presques!"
    for i = 0,5 do
        if i > 1 then
            SetVehicleDoorBroken(veh, i, false)
        else
            SetVehicleDoorOpen(veh, i, false,false)
        end
        Citizen.Wait(4500)
    end
    pedInvestigationSpeech = "~y~Sous-traitant: ~s~Voilà! Cargaison déchargée et livrée."
    TaskLeaveVehicle(mission_ped, veh, 0)
    while IsPedInAnyVehicle(mission_ped, false) do Citizen.Wait(100) end
    Citizen.Wait(2000)
    SetVehicleDoorsLocked(veh,2)
    
    pedInvestigationSpeech = "~y~Sous-traitant: ~s~Le boss sera fière de vous. Je vais noter tout ça.."
    TaskStartScenarioAtPosition(mission_ped, "CODE_HUMAN_MEDIC_TIME_OF_DEATH", -1097.99, 4949.87, 218.35, 245.0, -1, false,false)
    Citizen.Wait(10000)
    pedInvestigationSpeech = "~y~Sous-traitant: ~s~Tout est bon, merci encore, le boss vous recontactera bientôt."
    Citizen.Wait(8000)
    PlaySoundFrontend(-1, "Event_Message_Purple", "GTAO_FM_Events_Soundset", 0)
    DrawAdvancedNotification("Red Saïd", "~r~Vol de marchandise", "J'ai eu echo de ton exploit, félicitations.. Continue comme ça et le marché de l'armement sera à notre merci.","CHAR_MP_ROBERTO",9)
    FreezeEntityPosition(mission_ped,true)
    
    giveItem(ITEM_ID.WEAPON_COMPONENTS, missionData.components)
    giveItem(ITEM_ID.WEAPON_METAL, missionData.metal)
    missionData = {}
    pedInvestigate = false
    vanLocation = nil
    missionBlip = nil
    Citizen.Wait(40000)
    DeleteEntity(veh)
    ClearPedTasksImmediately(mission_ped)
    TaskStartScenarioInPlace(mission_ped, "WORLD_HUMAN_GUARD_STAND", 0, true)
end

function createPedDialog()
    Citizen.CreateThread(function()
        while pedInvestigate do 
            Citizen.Wait(1)
            RageUI.Text({message = pedInvestigationSpeech,time_display = 1})
        end
    end) 
end

-- Renvoie de la requête faite au serveur (Possibilité de fabriquer des armes, bol) + Double check license
RegisterNetEvent(weaponCraftConfig.prefix.."setAllowedState")
AddEventHandler(weaponCraftConfig.prefix.."setAllowedState", function(bol,license) 
    local can = false
    for k,v in pairs(weaponCraftConfig.allowedPlayers) do
        if v == license then
            can = true
        end
    end
    if can == true and bol == true then 
        isAllowed = true
        allowedStateSynchronized = true
    else
        isAllowed = false
    end
end)

RegisterNetEvent(weaponCraftConfig.prefix.."setCandelivery")
AddEventHandler(weaponCraftConfig.prefix.."setCandelivery", function(bol)
    canDoDelivery = bol
end)

--[[


    ## Pour Dictateurfou ##


]]

function craftItem(craftId)
    -- Craft une arme, nécéssite de check les composants nécéssaires à la fabrication de celle-ci
    TriggerServerEvent("inventory:transform",craftId)
end

function giveItem(itemId, ammount)
    -- Permet de donner l'item au joueur
    TriggerServerEvent("inventory:farm", itemId, ammount)
end









