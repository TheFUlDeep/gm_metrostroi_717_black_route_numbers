local matspath = "materials/models/metrostroi_train/common/routes/black/m"
if SERVER then
	for i = 0,9 do
		resource.AddFile(matspath..i..".vmt")
	end
end


local nomerogg = "gmod_subway_81-717_mvm"
local inserted_index = -1
local paramname = "Default Black"

local tablename = "RouteNumberType"
local readtablename = "Тип номера маршрута"

if CLIENT then
	MetrostroiWagNumUpdateRecieve = MetrostroiWagNumUpdateRecieve or function(index)
		local ent = Entity(index)
		--таймер, чтобы дождаться обновления сетевых значений (ну а вдруг)
		timer.Simple(0.3,function()
			if IsValid(ent) and ent.UpdateWagNumCallBack then 
				ent:UpdateWagNumCallBack()
				--ent:UpdateTextures()
			end
		end)
	end
end

if SERVER then
	local hooks = hook.GetTable()
	if not hooks.MetrostroiSpawnerUpdate or not hooks.MetrostroiSpawnerUpdate["Call hook on clientside"] then
		hook.Add("MetrostroiSpawnerUpdate","Call hook on clientside",function(ent)
			if not IsValid(ent) then return end
			local idx = ent:EntIndex()
			for _,ply in pairs(player.GetHumans())do
				if IsValid(ply)then ply:SendLua("MetrostroiWagNumUpdateRecieve("..idx..")")end
			end
		end)
	end
end

local function RemoveEnt(wag,prop)
	local ent = wag.ClientEnts and wag.ClientEnts[prop]
	if IsValid(ent) then SafeRemoveEntity(ent)end
end

local function UpdateModelCallBack(ENT,cprop,callback,precallback)	
	local modelcallback
	if not ENT.UpdateWagNumCallBack then
		function ENT:UpdateWagNumCallBack()end
	end
	
	if modelcallback then
		local oldmodelcallback = ENT.ClientProps[cprop].modelcallback or function() end
		ENT.ClientProps[cprop].modelcallback = function(wag,...)
			return modelcallback(wag) or oldmodelcallback(wag,...)
		end
		
		local oldstartedcallback = ENT.UpdateWagNumCallBack
		ENT.UpdateWagNumCallBack = function(wag)
			oldstartedcallback(wag)
			RemoveEnt(wag,cprop)
		end
	end
	
	if precallback then
		local oldcallback = ENT.ClientProps[cprop].callback or function() end
		ENT.ClientProps[cprop].callback = function(wag,cent,...)
			precallback(wag,cent)
			oldcallback(wag,cent,...)
		end
		
		local oldstartedcallback = ENT.UpdateWagNumCallBack
		ENT.UpdateWagNumCallBack = function(wag)
			oldstartedcallback(wag)
			RemoveEnt(wag,cprop)
		end
	end
	
	if callback then
		local oldcallback = ENT.ClientProps[cprop].callback or function() end
		ENT.ClientProps[cprop].callback = function(wag,cent,...)
			oldcallback(wag,cent,...)
			callback(wag,cent)
		end
		
		local oldstartedcallback = ENT.UpdateWagNumCallBack
		ENT.UpdateWagNumCallBack = function(wag)
			oldstartedcallback(wag)
			RemoveEnt(wag,cprop)
		end
	end
end

hook.Add("InitPostEntity","Metrostroi 717_mvm black route",function()
    local ENT = scripted_ents.GetStored(nomerogg.."_custom")
    if ENT then ENT = ENT.t else return end
	if not ENT.Spawner then return end
	
	local foundtable
	for k,v in pairs(ENT.Spawner) do
		if istable(v) and v[1] == tablename then foundtable = k break end
	end
	
	if not foundtable then
		table.insert(ENT.Spawner,6,{tablename,readtablename,"List",{"Default",paramname}})
		inserted_index = 2
	else
		inserted_index = table.insert(ENT.Spawner[foundtable][4],paramname)
	end
	
	if SERVER then return end	
	
	matspath = matspath:sub(11)
	local defaultmatspath = "models/metrostroi_train/common/routes/ezh/m"
	
	local ENT = scripted_ents.GetStored(nomerogg).t
	for i = 1,2 do
		local propname = "route"..i
		UpdateModelCallBack(
			ENT,
			propname,
			function(wag)
				if wag:GetNW2Int(tablename,0) == inserted_index then 
					local ent = wag.ClientEnts and wag.ClientEnts[propname]
					if not IsValid(ent) then return end	
					for i = 0,9 do
						ent:SetSubMaterial(i,matspath..i)
					end
				end
				if wag:GetNW2Int(tablename,0) == 1 then
					local ent = wag.ClientEnts and wag.ClientEnts[propname]
					if not IsValid(ent) then return end
					for i = 0,9 do
						ent:SetSubMaterial(i,defaultmatspath..i)
					end
				end
			end
		)
	end
	
end)


