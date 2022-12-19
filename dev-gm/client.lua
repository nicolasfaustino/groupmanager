local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

local vRP = Proxy.getInterface("vRP")
local GMServer = Tunnel.getInterface("dev_gm")

local improvements = {}
local org_name, group, organization_members, is_mod, is_owner, user_id, money
local UIOpened = false

CreateThread(function()
    while not GMServer do Wait(500) end
    improvements = config.organizations
    for org, improvement in pairs(improvements) do
        for map, state in pairs(improvement) do
            if state then
                RequestIpl(map)
            else
                RemoveIpl(map) 
            end
        end
        GMServer.SyncIpls()
    end
end)

RegisterNetEvent('gm:setipl', function(iplname, state, org)
    if state then
        RequestIpl(iplname)
    else
        RemoveIpl(iplname) 
    end
    improvements[org][iplname] = state
end)

RegisterNetEvent("gm:openUI", function(_org_name, _group, _organization_members, _is_mod, _is_owner, _user_id, _money,chestKg, logs, mapinfos, logsmoney)
    org_name, group, organization_members, is_mod, is_owner,  user_id, money = _org_name, _group, _organization_members, _is_mod, _is_owner,  _user_id, _money
    UIOpened = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        'openUI',
        {
            org_name = org_name,
            group = group,
            organization_members = organization_members,
            is_mod = is_mod,
            config = config,
            groups = config.organizations[org_name].groups,
            is_owner = is_owner,
            user_id = user_id,
            improvements = improvements,
            money = money,
            maxMembers = config.organizations[org_name].maxMembers,
            maxChest = config.organizations[org_name].maxChest,
            chestKg = chestKg,
            logs = logs,
            mapinfos = mapinfos,
            logsmoney = logsmoney
        }
    })
end)

RegisterNUICallback('updade', function(data, cb)
    local success = GMServer.updade(_org_name, _group, _organization_members, _is_mod, _is_owner, _user_id, _money,maxMembers,service)
    org_name, group, organization_members, is_mod, is_owner,  user_id, money = _org_name, _group, _organization_members, _is_mod, _is_owner,  _user_id, _money

    cb({org_name = org_name,
    group = group,
    organization_members = organization_members,
    is_mod = is_mod,
    config = config,
    groups = GlobalState.GMGroups,
    is_owner = is_owner,
    user_id = user_id,
    improvements = improvements,
    money = money,
    maxMembers = maxMembers,
    service = service})
end)


RegisterNetEvent("gm:closeUI", function()
    SetNuiFocus(false, false)
    SendNUIMessage({
        'closeUI'
    })
end)

RegisterNUICallback("close", function(data, cb)
    if data.closeServer then
        TriggerServerEvent('gm:closeUI')
    end
    UIOpened = false
    level, xp, current_missions = nil, nil, nil
    SetNuiFocus(false, false)
    TransitionFromBlurred(1000)
    cb(true)
end)

RegisterNUICallback('invite-member', function(data, cb)
    if data.group ~= "-" then
        local success = GMServer.inviteMember(data.user_id, data.group)
        cb({success = true})
    end
    -- if success then 
    --     cb({success = success or false})
    -- end
end)

RegisterNUICallback("donate-money", function(data,cb)
    local success = GMServer.donateMoney(data.value)
    cb({success = success or false})
end)

RegisterNUICallback("retrieve-money", function(data,cb)
    local success = GMServer.retrieveMoney(data.value)
    cb({success = success or false})
end)

RegisterNUICallback('promote', function(data,cb)
    local success, gName = GMServer.promote(data.user_id)
    cb { success = success or false, gName = gName }
end)

RegisterNUICallback('unpromote', function(data,cb)
    local success, gName = GMServer.unpromote(data.user_id)
    cb { success = success or false, gName = gName }
end)

RegisterNUICallback('demitido', function(data,cb)
    local success, gName = GMServer.demitido(data.user_id)
    cb { success = success or false, gName = gName }
end)

RegisterNUICallback('upgrademap', function(data,cb)
    print(data.id)
    local success = GMServer.buyMap(data.id)
    cb { success = success or false }
end)

local chestlocal = false
local orgname

RegisterNUICallback('chestlocal', function(data,cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local distance = #(coords - config.organizations[data.orgname].center)
    if distance <= config.organizations[data.orgname].maxdistance.chest then
        orgname = data.orgname
        chestlocal = true
        SetNuiFocus(false, false)
        SendNUIMessage({
            'closeUI'
        })
    else
        TriggerEvent('Notify','negado','Você não está longe da sua facção!!', 8000)
    end
end)

Citizen.CreateThread(function()
    while true do
        local idle = 1000
        if chestlocal then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local distance = #(coords - config.organizations[orgname].center)
            if distance <= config.organizations[orgname].maxdistance.chest then
                DrawMarker(23,coords.x, coords.y, coords.z - 0.96,0,0,0,0,0,0,1.0,1.0,1.0,223, 128, 255,155,0,0,0,0)
				DrawText3D(coords.x, coords.y, coords.z+0.2,'~w~Pressione ~g~[E]~w~ para colocar')
                idle = 5
                if IsControlJustPressed(1,38) then
                    GMServer.ChestLocaltion(coords)
                    chestlocal = false
                end
            else
                chestlocal = false
                TriggerEvent('Notify','negado','Você se afastou do local permitido!!', 8000)
            end 
        end
        Citizen.Wait(idle)
    end
end)

RegisterNUICallback("chest-upgrade", function(data,cb)
    local success = GMServer.donateUpgradeChest(data.value)
    cb({success = success or false})
end)

function DrawText3D(x,y,z,text)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)
	SetTextFont(4)
	SetTextScale(0.35,0.35)
	SetTextColour(255,255,255,100)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text)) / 400
	DrawRect(_x,_y+0.0125,0.01+factor,0.03,0,0,0,100)
end
