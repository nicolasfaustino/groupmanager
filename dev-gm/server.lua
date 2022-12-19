-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Proxy = module("vrp","lib/Proxy")
local Tunnel = module("vrp","lib/Tunnel")
vRP = Proxy.getInterface("vRP")
vRP_groups = module("vrp", "cfg/groups").groups

-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
dev = {}
Tunnel.bindInterface("dev_gm", dev)

vRP.prepare("donate/get","SELECT * FROM groups_donates WHERE user_id = @user_id AND groupname = @groupname")
vRP.prepare('donate/update','REPLACE INTO groups_donates(user_id,groupname,donate) VALUES(@user_id,@groupname,@donate)')
vRP.prepare('control/get_money','SELECT money FROM groups_control WHERE name = @name')

-- vRP.prepare('control/get_logs','SELECT chestlogs FROM groups_control WHERE name = @name')
vRP._prepare("control/get_logs", "SELECT * FROM groups_chest WHERE grupo = @grupo AND data > DATE_SUB(NOW(), INTERVAL 1 DAY) ORDER BY data DESC")
vRP._prepare("control/get_logsbank", "SELECT * FROM groups_bank WHERE grupo = @grupo AND data > DATE_SUB(NOW(), INTERVAL 1 DAY) ORDER BY data DESC")
vRP.prepare('control/insetBankLogs','INSERT INTO groups_bank(user_id,nome,tipo,quantidade,grupo) VALUES (@user_id,@nome,@tipo,@quantidade,@grupo)')


vRP.prepare('control/getMaps','SELECT * FROM groups_maps')
vRP.prepare('control/getMapsOrg','SELECT * FROM groups_maps WHERE name = @name')
vRP.prepare('control/insertMap','INSERT INTO groups_maps(name,maps) VALUES (@name,@maps)')
vRP.prepare('control/updateMap','UPDATE groups_maps SET maps = @maps WHERE name = @name')

vRP.prepare('control/update_money','UPDATE groups_control SET money = @money WHERE name = @name')
vRP.prepare('control/Create','INSERT INTO groups_control(name,money) VALUES (@name,@money)')


vRP._prepare("control/getAllDataTables","SELECT * FROM vrp_user_data WHERE dkey = 'vRP:datatable'")
open = {}
local orgmembers = {}


vRP._prepare("blacklist/removeBlackListUsers", "DELETE FROM groups_blacklist WHERE time + "..config.blacklist.." * 24 * 60 * 60 <= @time")

vRP._prepare("blacklist/removeBlackListUser", "DELETE FROM groups_blacklist WHERE user_id = @user_id")

function removeBlackListUsers()
    vRP.execute("blacklist/removeBlackListUsers", { time = parseInt(os.time())} )
end

RegisterCommand("rbl", function(source, args, rawCommand)
	local source = source
	local user_id = vRP.getUserId(source)
	
	if vRP.hasPermission(user_id, config.adminperm) then
		local nuser_id = parseInt(args[1])
		if nuser_id then
			vRP.execute("blacklist/removeBlackListUser", { user_id = nuser_id} )
			TriggerClientEvent("Notify",source,"sucesso","Blacklist do id "..nuser_id.." retirada com sucesso!")
		end
	end
end)

Citizen.CreateThread(function()
    for org in pairs(config.organizations) do
        orgmembers[org] = {}
    end
    local dataTables = vRP.query("control/getAllDataTables")
    for i, t in ipairs(dataTables) do
        local dataTable = json.decode(t.dvalue or nil)
        if dataTable and dataTable.groups then
            local userOrg, userGroup = getUserInfo(dataTable.groups)
            if userOrg and userGroup then
                table.insert(orgmembers[userOrg], { user_id = t.user_id,  group = userGroup or "none" })
            end
        end
    end
	removeBlackListUsers()
end)

RegisterServerEvent("gm:tabletadd")
AddEventHandler("gm:tabletadd",function(id, group)
	for org, t in pairs(config.organizations) do
		for i, v in pairs (t.groups) do
			if group == v.onService or group == v.offService then
				table.insert(orgmembers[org], { user_id = id, group = v.onService or "none" })
			end
		end
	end
end)

RegisterServerEvent("gm:tabletrem")
AddEventHandler("gm:tabletrem",function(id, group)
	for org, t in pairs(config.organizations) do
		for i, v in pairs (t.groups) do
			if group == v.onService or group == v.offService then
				for z, y in pairs (orgmembers[org]) do
					if id == y.user_id then
						orgmembers[org][z] = nil
					end
				end
			end
		end
	end
end)

function getUserInfo(userGroups)
	for org, t in pairs(config.organizations) do
		for i, v in pairs (t.groups) do
			if hasUserGroup(userGroups, v.onService) then
				return org, v.onService
			elseif hasUserGroup(userGroups, v.offService) then
				return org, v.offService
			end
		end
	end
end

function hasUserGroup(userGroups,group)
    if userGroups[group] then return true end
    return false
end

RegisterCommand('paineladm', function(source,args,rawCommand)
	local user_id = vRP.getUserId(source)
	if vRP.hasGroup(user_id, config.adminperm) then
		local fac = vRP.prompt(source, 'NOME DA FACÇÃO', '')
		if fac ~= nil and fac ~= "" and config.organizations[fac] then
			-- for k,v in pairs(config.organizations) do
			-- 	print(k, fac)
			-- 	if fac == k then
			-- 		print("quebrou")
			-- 		break
			-- 	elseif not fac == k then
			-- 		TriggerClientEvent('Notify',source,'negado','Você digitou um nome de facção invalido!')
			-- 		return
			-- 	end
			-- end
			open[user_id] = fac
			if open[user_id] then
				local group_members = {}
				local members_list = {}
				local num_members = {}
				local members_get = {}
				local org_money = vRP.query('control/get_money', {name = open[user_id]})
				local chestlogs = vRP.query('control/get_logs', {grupo = open[user_id]})
				local banklogs = vRP.query('control/get_logsbank', {grupo = open[user_id]})
				local logs = {}
				local logsmoney = {}
				local mapsinfo = config.organizations[open[user_id]].mapImprovements
				local money = 0
				if org_money[1] then
					money = org_money[1].money
				end
					for l,w in pairs(orgmembers[open[user_id]]) do
						local allname = vRP.getUserIdentity(w.user_id)
						local donates = vRP.query("donate/get",{user_id = w.user_id, groupname = open[user_id]}) or {}
						local stats = vRP.getUserSource(w.user_id)
						local status = 1
						if stats then
							status = 0
						end
						local d_value = 0
						if donates[1] then
							d_value = donates[1].donate
						end
						local temp_tbl = {
							name = allname.name..' '..allname.firstname,
							user_id = w.user_id,
							org_group = getUserGroup(w.user_id),
							last_login = "Indisponível",
							donated_money = d_value,
							status = status
						}
						table.insert(members_list,temp_tbl)		
					end

					for k,v in pairs(chestlogs) do
						if k <= 30 then
							logstemp = {
								id = v.user_id,
								nome = v.nome,
								item = v.item,
								quantidade = v.quantidade,
								tipo = v.tipo,
								data = v.data
							}
							table.insert(logs, logstemp)
						end
					end

					for k,v in pairs(banklogs) do
						if k <= 30 then
							logsmoneytemp = {
								id = v.user_id,
								nome = v.nome,
								quantidade = v.quantidade,
								tipo = v.tipo,
								data = v.data
							}
							table.insert(logsmoney, logsmoneytemp)
						end
					end
				--end
				local is_mod = false
				for k,v in pairs(config.organizations[open[user_id]].modGroups) do
					if mygroup == v then
						is_mod = true
					end
				end
				
				local is_owner = false
				if config.organizations[open[user_id]].ownerGroup == mygroup then
					is_owner = true
				end

				local weightchest = 0
				local query = exports.oxmysql:query_async("SELECT weight FROM `chests` WHERE `name` = @name",{ name = open[user_id]})
				if query[1] then
					weightchest = query[1].weight
				end
				TriggerClientEvent("gm:openUI", source, open[user_id], mygroup, members_list, is_mod, is_owner, user_id, money, weightchest, logs, mapsinfo, logsmoney)
			else
				TriggerClientEvent('Notify',source,'negado','Você não faz parte de uma organização')
			end
		else
			TriggerClientEvent('Notify',source,'negado','Você o nome de uma organização inexistente!')
		end
	end
end)

RegisterCommand('painel', function(source,args,rawCommand)
	local user_id = vRP.getUserId(source)
	local mygroup = nil
	for k,v in pairs(config.organizations) do
		for l,w in pairs(v.groups) do
			if vRP.hasGroup(user_id,w.onService) then
				open[user_id] = k
				mygroup = w.onService
			elseif vRP.hasGroup(user_id,w.offService) then
				open[user_id] = k
				mygroup = w.onService
			end
		end
	end
	if open[user_id] then
		local group_members = {}
		local members_list = {}
		local num_members = {}
		local members_get = {}
		local org_money = vRP.query('control/get_money', {name = open[user_id]})
		local chestlogs = vRP.query('control/get_logs', {grupo = open[user_id]})
		local banklogs = vRP.query('control/get_logsbank', {grupo = open[user_id]})
		local logs = {}
		local logsmoney = {}
		local mapsinfo = config.organizations[open[user_id]].mapImprovements
		local money = 0
		if org_money[1] then
			money = org_money[1].money
		end
			for l,w in pairs(orgmembers[open[user_id]]) do
				local allname = vRP.getUserIdentity(w.user_id)
				local donates = vRP.query("donate/get",{user_id = w.user_id, groupname = open[user_id]}) or {}
				local stats = vRP.getUserSource(w.user_id)
				local status = 1
				if stats then
					status = 0
				end
				local d_value = 0
				if donates[1] then
					d_value = donates[1].donate
				end
				local temp_tbl = {
					name = allname.name..' '..allname.firstname,
					user_id = w.user_id,
					org_group = getUserGroup(w.user_id),
					last_login = "Indisponível",
					donated_money = d_value,
					status = status
				}
				table.insert(members_list,temp_tbl)		
			end

			for k,v in pairs(chestlogs) do
				if k <= 30 then
					logstemp = {
						id = v.user_id,
						nome = v.nome,
						item = v.item,
						quantidade = v.quantidade,
						tipo = v.tipo,
						data = v.data
					}
					table.insert(logs, logstemp)
				end
			end

			for k,v in pairs(banklogs) do
				if k <= 30 then
					logsmoneytemp = {
						id = v.user_id,
						nome = v.nome,
						quantidade = v.quantidade,
						tipo = v.tipo,
						data = v.data
					}
					table.insert(logsmoney, logsmoneytemp)
				end
			end
		--end
		local is_mod = false
		for k,v in pairs(config.organizations[open[user_id]].modGroups) do
			if mygroup == v then
				is_mod = true
			end
		end
		
		local is_owner = false
		if config.organizations[open[user_id]].ownerGroup == mygroup then
			is_owner = true
		end

		local weightchest = 0
		local query = exports.oxmysql:query_async("SELECT weight FROM `chests` WHERE `name` = @name",{ name = open[user_id]})
		if query[1] then
			weightchest = query[1].weight
		end
		TriggerClientEvent("gm:openUI", source, open[user_id], mygroup, members_list, is_mod, is_owner, user_id, money, weightchest, logs, mapsinfo, logsmoney)
	else
		TriggerClientEvent('Notify',source,'negado','Você não faz parte de uma organização')
	end
end)


function dev.SyncIpls()
	local source = source
	local maps = vRP.query('control/getMaps', {})
	if maps[1] then
		for k,v in pairs(maps) do
			local ipls = json.decode(v.maps)
			for l,w in pairs(ipls) do
				TriggerClientEvent("gm:setipl", source, l, w, v.name)
			end
		end
	end
end

function dev.buyMap(id)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		local mapinfos = config.organizations[open[user_id]].mapImprovements[id]
		local org_money = vRP.query('control/get_money', { name = open[user_id]})
		if org_money[1] and (org_money[1].money >= mapinfos.price) then
			local new = org_money[1].money - mapinfos.price
			local maps = vRP.query('control/getMapsOrg', { name = open[user_id] })
			if maps[1] then
				local info = json.decode(maps[1].maps)
				if not info[mapinfos.ipl] then
					info[mapinfos.ipl] = true
					vRP.execute('control/updateMap', {maps = json.encode(info), name = open[user_id]})
				else
					TriggerClientEvent('Notify',source,'negado','A organização já possui esse upgrade!')
					return false
				end
			else
				local info = {}
				info[mapinfos.ipl] = true
				vRP.execute('control/insertMap', {maps = json.encode(info), name = open[user_id]})
			end
			TriggerClientEvent('Notify',source,'sucesso','Você comprou com sucesso o upgrade '..config.organizations[open[user_id]].mapImprovements[id].name..'!')
			vRP.execute('control/update_money', {money = new, name = open[user_id]})
			TriggerClientEvent("gm:setipl", -1, mapinfos.ipl, true, open[user_id])
			return true
		else
			TriggerClientEvent('Notify',source,'negado','A organização não possui fundos o suficiente para isso!')
			return false
		end
		return false
	end
end


function dev.inviteMember(id,id_group)
	local source = source
	local user_id = vRP.getUserId(source)
	local nsource = vRP.getUserSource(parseInt(id))
	if nsource then
		local query = exports.oxmysql:query_async("SELECT * FROM `groups_blacklist` WHERE `user_id` = @user_id",{ user_id = parseInt(id)})
		if query[1].time + config.blacklist * 24 * 60 * 60 <= os.time() then
			local group = config.organizations[open[user_id]].groups[id_group]
			local fac = open[user_id]
			if vRP.request(nsource, 'Você foi convidado para entrar para uma organização, deseja entrar?', 30) then
				vRP.addUserGroup(id,group)
				TriggerClientEvent("Notify",source,"sucesso","Passaporte <b>"..vRP.format(id).."</b> adicionado com sucesso.",5000)
				AddMemberDiscord(id, fac, id_group)
				return true
			else
				TriggerClientEvent("Notify",source,"negado","Pedido recusado",5000)
			end
		else
			TriggerClientEvent("Notify",source,"negado","Esse usuário está atualmente em blacklist!",5000)
		end
	else
		TriggerClientEvent("Notify",source,"negado","Usuário ERRADO ou encontra-se OFFLINE",5000)
	end
end

function getUserGroup(user_id)
    local src = vRP.getUserSource(user_id)
    if src then
        local dataTable = vRP.getUserDataTable(user_id)
        local org, group = getUserInfo(dataTable.groups)
        if not group then
            group = getUserGroupByType(user_id,"job")
        end
        return group
    else
        local dataTable = json.decode(vRP.getUData(user_id,"vRP:datatable") or {})
        if dataTable and dataTable.groups then
            local org, group = getUserInfo(dataTable.groups)
            if not group then
                for k,v in pairs(dataTable.groups) do
                    local kgroup = vRP_groups[k]
                    if kgroup then
                        if kgroup._config and kgroup._config.gtype and kgroup._config.gtype == "job" then
                            group = k
                            break
                        end
                    end
                end
            end
            return group
        end
    end
    return false
end


vRP.prepare("donate/del","DELETE FROM groups_donates WHERE user_id = @user_id AND groupname = @groupname")


removeGroupDemitido = function(id, user_id)
	local modgroup
	for l,w in pairs(config.organizations[open[user_id]].modGroups) do
		if getUserGroup(parseInt(user_id)) == w then
			modgroup = { group = w, id = l }
		end
	end
	if not modgroup then TriggerClientEvent("Notify",vRP.getUserSource(user_id),"negado","Você não tem permissão para isso",5000) return end

	local group = vRP.query('vRP/get_perm', {user_id = id})
	local mygroup = nil
	for l,w in pairs(config.organizations[open[user_id]].groups) do
		if getUserGroup(parseInt(id)) == w.onService then
			mygroup = { group = w.onService, id = l }
		end
	end

	if mygroup ~= nil and mygroup.id  then
		local src = vRP.getUserSource(parseInt(id))
		if src then
			for k, v in pairs (orgmembers[open[user_id]]) do
				if v.user_id == id then
					orgmembers[open[user_id]][k] = nil
				end
			end
			vRP.removeUserGroup(parseInt(id),mygroup.group)
			vRP.execute('donate/del', { user_id = parseInt(id), groupname = open[user_id] })
			exports.oxmysql:query("INSERT INTO `groups_blacklist` (`user_id`,`time`) VALUES (@user_id,@time)",{ 
				user_id = parseInt(id),
				time = os.time(),
			})
			open[user_id] = nil
			TriggerClientEvent("gm:closeUI",vRP.getUserSource(user_id))
			return true, nil
		else
			for k, v in pairs (orgmembers[open[user_id]]) do
				if v.user_id == id then
					orgmembers[open[user_id]][k] = nil
				end
			end
			local dataTable = json.decode(vRP.getUData(parseInt(id), "vRP:datatable") or {})
			if dataTable and dataTable.groups then
				local group = getUserGroup(parseInt(id))
				if group and dataTable.groups[group] then
					dataTable.groups[group] = nil
					vRP._setUData(parseInt(id), "vRP:datatable", json.encode(dataTable))
					vRP.execute('donate/del', { user_id = parseInt(id), groupname = open[user_id] })
					exports.oxmysql:query("INSERT INTO `groups_blacklist` (`user_id`,`time`) VALUES (@user_id,@time)",{ 
						user_id = parseInt(id),
						time = os.time(),
					})
					TriggerClientEvent("gm:closeUI",vRP.getUserSource(user_id))
					return true, nil
				end
			end
		end
	end
	return false
end

function removeGroup(id, user_id)
	local modgroup
	for l,w in pairs(config.organizations[open[user_id]].modGroups) do
		if getUserGroup(parseInt(user_id)) == w then
			modgroup = { group = w, id = l }
		end
	end

	if not modgroup then TriggerClientEvent("Notify",vRP.getUserSource(user_id),"negado","Você não tem permissão para isso",5000) return end

	local mygroup = nil
	for l,w in pairs(config.organizations[open[user_id]].groups) do
		if getUserGroup(parseInt(id)) == w.onService then
			mygroup = { group = w.onService, id = l }
		end
	end

	local mygroup2 = nil
	for l,w in pairs(config.organizations[open[user_id]].groups) do
		if getUserGroup(parseInt(user_id)) == w.onService then
			mygroup2 = { group = w.onService, id = l }
		end
	end
	if parseInt(mygroup2.id) < parseInt(mygroup.id) then
		if mygroup.id == #config.organizations[open[user_id]].groups then
			local src = vRP.getUserSource(parseInt(id))
			if src then
				for k, v in pairs (orgmembers[open[user_id]]) do
					if v.user_id == id then
						orgmembers[open[user_id]][k] = nil
					end
				end
				vRP.removeUserGroup(parseInt(id),mygroup.group)
				vRP.execute('donate/del', { user_id = parseInt(id), groupname = open[user_id] })
				exports.oxmysql:query("INSERT INTO `groups_blacklist` (`user_id`,`time`) VALUES (@user_id,@time)",{ 
					user_id = parseInt(id),
					time = os.time(),
				})
				open[user_id] = nil
				TriggerClientEvent("gm:closeUI",vRP.getUserSource(user_id))
				return true, nil
			else
				for k, v in pairs (orgmembers[open[user_id]]) do
					if v.user_id == id then
						orgmembers[open[user_id]][k] = nil
					end
				end
				local dataTable = json.decode(vRP.getUData(parseInt(id), "vRP:datatable") or {})
				if dataTable and dataTable.groups then
					local group = getUserGroup(parseInt(id))
					if group and dataTable.groups[group] then
						dataTable.groups[group] = nil
						vRP._setUData(parseInt(id), "vRP:datatable", json.encode(dataTable))
						vRP.execute('donate/del', { user_id = parseInt(id), groupname = open[user_id] })
						exports.oxmysql:query("INSERT INTO `groups_blacklist` (`user_id`,`time`) VALUES (@user_id,@time)",{ 
							user_id = parseInt(id),
							time = os.time(),
						})
						TriggerClientEvent("gm:closeUI",vRP.getUserSource(user_id))
						return true, nil
					end
				end
			end
		else
			local value = mygroup.id + 1
			local newgroup = config.organizations[open[user_id]].groups[value].onService
			local src = vRP.getUserSource(parseInt(id))
			if src then
				vRP.removeUserGroup(parseInt(id),mygroup.group)
				vRP.addUserGroup(parseInt(id),newgroup)
				open[user_id] = nil
				TriggerClientEvent("gm:closeUI",vRP.getUserSource(user_id))
				return true, newgroup
			else
				local dataTable = json.decode(vRP.getUData(parseInt(id), "vRP:datatable") or {})
				if dataTable and dataTable.groups then
					local group = getUserGroup(parseInt(id))
					if group and dataTable.groups[group] then
						dataTable.groups[group] = nil
						dataTable.groups[newgroup] = true
						vRP._setUData(parseInt(id), "vRP:datatable", json.encode(dataTable))
						TriggerClientEvent("gm:closeUI",vRP.getUserSource(user_id))
						return true, newgroup
					end
				end
			end
		end
	else
		TriggerClientEvent("Notify",vRP.getUserSource(user_id),"negado","Esse usuário tem um cargo maior ou igual ao seu!",5000) return false, nil
	end
	return false
end

function addGroup(id, user_id)
	local modgroup
	for l,w in pairs(config.organizations[open[user_id]].modGroups) do
		if getUserGroup(parseInt(user_id)) == w then
			modgroup = { group = w, id = l }
		end
	end
	if not modgroup then TriggerClientEvent("Notify",vRP.getUserSource(user_id),"negado","Você não tem permissão para isso",5000) return end

	local mygroup = nil
	for l,w in pairs(config.organizations[open[user_id]].groups) do
		if getUserGroup(parseInt(id)) == w.onService then
			mygroup = { group = w.onService, id = l }
		end
	end

	local mygroup2 = nil
	for l,w in pairs(config.organizations[open[user_id]].groups) do
		if getUserGroup(parseInt(user_id)) == w.onService then
			mygroup2 = { group = w.onService, id = l }
		end
	end

	local value = mygroup.id - 1
	if parseInt(mygroup2.id) < parseInt(value) then

		if mygroup.group ~= config.organizations[open[user_id]].groups[1].onService then
			local newgroup = config.organizations[open[user_id]].groups[value].onService
			local src = vRP.getUserSource(parseInt(id))
			if src then
				vRP.removeUserGroup(parseInt(id),mygroup.group)
				vRP.addUserGroup(parseInt(id),newgroup)
				open[user_id] = nil
				TriggerClientEvent("gm:closeUI",vRP.getUserSource(user_id))
				return true, newgroup
			else
				local dataTable = json.decode(vRP.getUData(parseInt(id), "vRP:datatable") or {})
				if dataTable and dataTable.groups then
					local group = getUserGroup(parseInt(id))
					if group and dataTable.groups[group] then
						dataTable.groups[group] = nil
						dataTable.groups[newgroup] = true
						vRP._setUData(parseInt(id), "vRP:datatable", json.encode(dataTable))
						TriggerClientEvent("gm:closeUI",vRP.getUserSource(user_id))
						return true, newgroup
					end
				end
			end
		else
			TriggerClientEvent("Notify",vRP.getUserSource(user_id),"negado","Esse usuário já esta no maior cargo!",5000)
			return false
		end
	else
		TriggerClientEvent("Notify",vRP.getUserSource(user_id),"negado","Você não possui permissão para upar para o cargo acima!",5000)
		return false
	end
	return false
end

function dev.unpromote(id)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		return removeGroup(id, user_id)
	end
end

function dev.demitido(id)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		return removeGroupDemitido(id, user_id)
	end
end

function dev.promote(id)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		return addGroup(id, user_id)
	end
end

function dev.donateMoney(qtd)
	local source = source
	local user_id = vRP.getUserId(source)
	local identity = vRP.getUserIdentity(user_id)
	if vRP.getBankMoney(user_id) >= qtd then
		local value = vRP.query('donate/get', {user_id = user_id, groupname = open[user_id]})
		local org_money = vRP.query('control/get_money', {name = open[user_id]})
		local newvalue = parseInt(qtd)
		if org_money[1] then
			newvalue = newvalue + org_money[1].money
		else
			vRP.execute('control/Create', {money = 0, name = open[user_id]})
		end
		local donate = qtd
		if value[1] then
			donate = donate + value[1].donate
		end
		vRP.setBankMoney(user_id,vRP.getBankMoney(user_id)-qtd)
		vRP.execute('control/update_money', {money = newvalue, name = open[user_id]})
		vRP.execute('donate/update', {donate = donate, groupname = open[user_id], user_id = user_id})
		vRP.execute('control/insetBankLogs', {user_id = user_id, nome = ""..identity.name.." "..identity.firstname.."", tipo = 0, quantidade = qtd, grupo = open[user_id]})
		return true
	end
end

function dev.retrieveMoney(qtd)
	local source = source
	local user_id = vRP.getUserId(source)
	local identity = vRP.getUserIdentity(user_id)
	local org_money = vRP.query('control/get_money', {name = open[user_id]})
	if parseInt(qtd) <= org_money[1].money then
		for k,v in pairs(config.organizations[open[user_id]].groups) do
			if k == 1 then
				print(vRP.hasPermission(user_id, config.adminperm), vRP.hasGroup(user_id, v.onService))
				if not vRP.hasGroup(user_id, v.onService) and not vRP.hasPermission(user_id, config.adminperm) then TriggerClientEvent("Notify",vRP.getUserSource(user_id),"negado","Você não tem permissão para isso",5000) return end
			end
		end
		local newvalue = parseInt(qtd)
		if org_money[1] then
			newvalue = org_money[1].money - newvalue
		else
			vRP.execute('control/Create', {money = 0, name = open[user_id]})
		end
		local value = vRP.query('donate/get', {user_id = user_id, groupname = open[user_id]})
		local donate = parseInt(qtd)
		if value[1] then
			donate = value[1].donate - donate
		end
		vRP.setBankMoney(user_id,vRP.getBankMoney(user_id)+qtd)
		vRP.execute('control/update_money', {money = newvalue, name = open[user_id]})
		vRP.execute('donate/update', {donate = donate, groupname = open[user_id], user_id = user_id})
		vRP.execute('control/insetBankLogs', {user_id = user_id, nome = ""..identity.name.." "..identity.firstname.."", tipo = 1, quantidade = qtd, grupo = open[user_id]})
		
		open[user_id] = nil
		TriggerClientEvent("gm:closeUI",vRP.getUserSource(user_id))
		return true
	else
		TriggerClientEvent("Notify",source,"negado","A sua facção não possui esse dinheiro!!")
	end
end

function dev.donateUpgradeChest(qtd)
	local source = source
	local user_id = vRP.getUserId(source)
	local quantidade = parseInt(qtd)
	local kgvalue = parseInt(config.prices.kgprice) * quantidade
	local query = exports.oxmysql:query_async("SELECT * FROM `chests` WHERE `name` = @name",{ name = open[user_id]})
	if query[1] then
		TriggerClientEvent('gm:closeUI', source)
		local pesonew = parseInt(query[1].weight) + quantidade
		if parseInt(query[1].weight) < parseInt(config.organizations[open[user_id]].maxChest) then
			if vRP.request(source, 'Você deseja pagar '..kgvalue..' para aumentar seu bau ?', 8000) then
				if vRP.tryFullPayment(user_id,kgvalue) then
					exports.oxmysql:query("UPDATE `chests` SET `weight` = @weight WHERE `name` = @name",{ name = open[user_id], weight = pesonew })
					TriggerClientEvent('Notify',source,'sucesso','Peso aumentado com sucesso!!')
					Wait(2000)
					TriggerEvent("UpdateChest")
					return true
				end
			else
				TriggerClientEvent('Notify',source,'negado','Dinheiro insuficiente')
			end
		else
			TriggerClientEvent('Notify',source,'negado','Você está tentando passar a quantidade maxima permitida')
		end
	else
		TriggerClientEvent('Notify',source,'negado','Você precisa poscionar o báu primeiro')
	end
end

local x,y,z

function dev.ChestLocaltion(coords)
	local source = source
	local user_id = vRP.getUserId(source)
	local query = exports.oxmysql:query_async("SELECT * FROM `chests` WHERE `name` = @name",{ name = open[user_id]})
	if query[1] then
		x,y,z = table.unpack(coords)
		exports.oxmysql:query("UPDATE `chests` SET `x` = @x, `y` = @y, `z` = @z WHERE `name` = @name",{ name = open[user_id], x = x, y = y, z = z, })
		TriggerClientEvent('Notify',source,'sucesso','Você mudou o local do bau com sucesso')
		Wait(2000)
		TriggerEvent("UpdateChest")
	else
		x,y,z = table.unpack(coords)
		exports.oxmysql:query("INSERT INTO `chests` (`name`,`weight`,`permission`,`x`, `y`, `z`) VALUES (@name,@weight,@permission,@x,@y,@z)",{ 
			name = open[user_id],
			weight = 1500,
			permission = ""..string.lower(open[user_id])..".permissao",
			x = x,
			y = y,
			z = z,
		})
		TriggerClientEvent('Notify',source,'sucesso','Você colocou o seu bau com sucesso')
		Wait(2000)
		TriggerEvent("UpdateChest")
	end
end

RegisterServerEvent("gm:closeUI")
AddEventHandler("gm:closeUI",function()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		open[user_id] = nil
	end
end)