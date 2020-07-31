weaponCraftConfig = {
    prefix = "rs_weapondealer:",

    allowedPlayers = {
        "license:d67dec9ddd7c3d7f4e160f675224b06eb5a2d008", -- Pablo
        "license:73368238ecbb5c69a2768471824aea691c9f16fe", -- San
        "license:e7d37d444efb3b10fa535b0dbbc7d2bc80f9c0fe", --dicta
        "license:9538d5219739f68e9879c05566e5acb879498b0c",
        "license:016a0ad3cde0ceddc5320ecea0891a554e91afbb",
        "license:ff2e47bbde8a056d84fd2aee4e0912ad1b29bed3",
        "license:726d2b40f0e32cb0ef64fcffdacc7b320431fb3c",
        "license:5429cdd9891fdb5c1a03357d0441d9064964c980",
        "license:2f388238adb939cc2ae000b012d9b6e36694ee27",
    },

    timeBeforeCops = 40, -- in second

    cooldown = 45, -- in minutes

    Rewards = {
        components = function() 
            return math.random(10,20)
        end,

        metal = function() 
            return math.random(10,30)
        end,
    },

    Locations = {
        enum = {
            vector3(1219.08, 2390.71, 65.57),
            vector3(1614.672, 3776.244, 34.61634),
            vector3(1967.714, 3821.214, 32.39694),
            vector3(1272.34, 3621.52, 33.04606),
            vector3(462.0386, 3547.162, 33.23856),
            vector3(-1583.228, 5156.266, 19.70824),
            vector3(-252.9264, 6358.004, 31.4809),
            vector3(531.14, 3097.172, 40.46516),
            vector3(222.0184, 2580.536, 45.81386),
            vector3(-283.8974, 2534.916, 74.67138),
            vector3(733.946, 4192.536, 40.71852),
        },

        randomize = function()
            return weaponCraftConfig.Locations.enum[math.random(1,#weaponCraftConfig.Locations.enum)]
        end,
    },

    Craft = {
        {item = CRAFT_ID.UZI, label = "Uzi"},
        {item = CRAFT_ID.PISTOL50, label = "Cal .50"},
        {item = CRAFT_ID.SCORPION, label = "Scorpion"},
        {item = CRAFT_ID.SMG, label = "Smg"},
        {item = CRAFT_ID.AKU, label = "AKU"},
        {item = CRAFT_ID.AK47, label = "AK-47"},
        {item = CRAFT_ID.GUSENBERG, label = "Gusenberg"},
        {item = CRAFT_ID.CANONSCIE, label = "Canon scié"},
        {item = CRAFT_ID.FLARE, label = "flare"},
        {item = CRAFT_ID.CMOLOTOV, label = "cocktail molotov"}
    },

    Zones = {
        {
            drawDistance = 15.0,
            interactionDistance = 1.0,
            pos = vector3(-1121.63, 4884.38, 218.48),
            draw = function()
                DrawMarker(22, weaponCraftConfig.Zones[1].pos.x, weaponCraftConfig.Zones[1].pos.y,weaponCraftConfig.Zones[1].pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255, 0, 0, 255, 55555, false, true, 2, false, false, false, false)
            end,
            interact = function()
                if not RageUI.Visible(RMenu:Get(weaponCraftConfig.prefix,'main')) then
                    last_interaction = 0
                    RageUI.Text({message = "Appuyez sur ~b~[E]~s~ pour intéragir avec l'ordinateur",time_display = 1})
                end
                if IsControlJustPressed(0, 51) then
                    TriggerServerEvent(weaponCraftConfig.prefix.."requestDeliveryState")
                    Citizen.Wait(100)
                    alterMenuVisibility()
                end

            end,
        },

        {
            drawDistance = 25.0,
            interactionDistance = 1.5,
            pos = vector3(-1093.66, 4950.01, 218.35),
            draw = function()
                DrawMarker(22, weaponCraftConfig.Zones[2].pos.x, weaponCraftConfig.Zones[2].pos.y,weaponCraftConfig.Zones[2].pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255, 0, 0, 255, 55555, false, true, 2, false, false, false, false)
            end,
            interact = function()
                if IsPedInAnyVehicle(PlayerPedId(), false) and not pedInvestigate then
                    last_interaction = 1
                    RageUI.Text({message = "Appuyez sur ~b~[E]~s~ pour déverouiller l'arrière du véhicule",time_display = 1})
                    if IsControlJustPressed(0, 51) then
                        pre_delivery()
                    end
                end
                

            end,
        },

        {
            drawDistance = 15.0,
            interactionDistance = 1.0,
            pos = vector3(-1107.37, 4955.82, 218.46),
            draw = function()
                DrawMarker(22, weaponCraftConfig.Zones[3].pos.x, weaponCraftConfig.Zones[3].pos.y,weaponCraftConfig.Zones[3].pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255, 0, 0, 255, 55555, false, true, 2, false, false, false, false)
            end,
            interact = function()
                if not RageUI.Visible(RMenu:Get(weaponCraftConfig.prefix,'main')) then
                    last_interaction = 2
                    RageUI.Text({message = "Appuyez sur ~b~[E]~s~ pour fabriquer des armes",time_display = 1})
                end
                if IsControlJustPressed(0, 51) then
                    Citizen.Wait(100)
                    alterMenuVisibility()
                end
                

            end,
        },
    }
}