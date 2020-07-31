local allowed = weaponCraftConfig.allowedPlayers
local can = true
local deliveryState = false
local deliveryVanPlate = nil
local deliveryRewards = {
    components = 0,
    metal = 0
}

-- Le joueur est-il autorisé à fabriquer des armes et à utiliser les points relatifs au script
function isAllowed(src)
    local isAllowed = false
    for k,v in pairs(allowed) do
        local license = getIdentifiers(src).license
        if v == license then
            isAllowed = true
        end
    end
    return isAllowed,getIdentifiers(src).license
end

-- Obtenir les identifiants du joueur
function getIdentifiers(src)
    local identifiers = {
        steam = "",
        ip = "",
        discord = "",
        license = "",
        xbl = "",
        live = ""
    }
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.find(id, "steam") then
            identifiers.steam = id
        elseif string.find(id, "ip") then
            identifiers.ip = id
        elseif string.find(id, "discord") then
            identifiers.discord = id
        elseif string.find(id, "license") then
            identifiers.license = id
        elseif string.find(id, "xbl") then
            identifiers.xbl = id
        elseif string.find(id, "live") then
            identifiers.live = id
        end
    end
    return identifiers
end

-- Callback de la possibilité du joueur à utiliser les points relatif au script
RegisterServerEvent(weaponCraftConfig.prefix.."isAllowed")
AddEventHandler(weaponCraftConfig.prefix.."isAllowed", function()
    local _src = source
    local can,license = isAllowed(source)
    Citizen.Wait(50)
    if can then print("[RedSide Armes] "..GetPlayerName(_src).." is allowed to craft weapons") end
    TriggerClientEvent(weaponCraftConfig.prefix.."setAllowedState", _src, can, license)
end)

RegisterServerEvent(weaponCraftConfig.prefix.."setVehPlate")
AddEventHandler(weaponCraftConfig.prefix.."setVehPlate", function(plate)
    deliveryVanPlate = plate
end)


RegisterServerEvent(weaponCraftConfig.prefix.."initDelivery")
AddEventHandler(weaponCraftConfig.prefix.."initDelivery", function(this)
    deliveryState = true
    deliveryRewards = {
        components = this.components,
        metal = this.metal
    }
end)

RegisterServerEvent(weaponCraftConfig.prefix.."setOnCoolDown")
AddEventHandler(weaponCraftConfig.prefix.."setOnCoolDown", function()
    can = false
    Citizen.SetTimeout(((1000)*60)*weaponCraftConfig.cooldown, function()
        can = true
    end)
end)

RegisterServerEvent(weaponCraftConfig.prefix.."requestDeliveryState")
AddEventHandler(weaponCraftConfig.prefix.."requestDeliveryState", function()
    local _src = source 
    TriggerClientEvent(weaponCraftConfig.prefix.."setCandelivery", _src, can)
end)

