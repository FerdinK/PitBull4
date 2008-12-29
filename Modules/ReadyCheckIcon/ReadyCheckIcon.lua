if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_ReadyCheckIcon requires PitBull4")
end

local PitBull4_ReadyCheckIcon = PitBull4:NewModule("ReadyCheckIcon", "AceEvent-3.0", "AceTimer-3.0")

PitBull4_ReadyCheckIcon:SetModuleType("icon")
PitBull4_ReadyCheckIcon:SetName("Ready Check Icon")
PitBull4_ReadyCheckIcon:SetDescription("Show a ready check icon on the unit frame based on their response.")
PitBull4_ReadyCheckIcon:SetDefaults({
	attach_to = "root",
	location = "edge_bottom_right",
	position = 1,
})

function PitBull4_ReadyCheckIcon:OnEnable()
	self:RegisterEvent("READY_CHECK")
	self:RegisterEvent("READY_CHECK_CONFIRM")
	self:RegisterEvent("READY_CHECK_FINISHED")
end

local status_to_texture = {
	ready = [[Interface\RAIDFRAME\ReadyCheck-Ready]],
	notready = [[Interface\RAIDFRAME\ReadyCheck-NotReady]],
	waiting = [[Interface\RAIDFRAME\ReadyCheck-Waiting]],
}

local guid_to_status = {}

function PitBull4_ReadyCheckIcon:GetTexture(frame)
	if not IsRaidLeader() and not IsRaidOfficer() and not IsPartyLeader() then
		-- gotta be an officer
		return nil
	end
	
	return status_to_texture[guid_to_status[frame.guid]]
end

local PLAYER_GUID = UnitGUID("player")

function PitBull4_ReadyCheckIcon:CacheReachCheckStatuses()
	wipe(guid_to_status)
	if not IsRaidLeader() and not IsRaidOfficer() and not IsPartyLeader() then
		-- gotta be an officer
		return
	end
	if UnitInRaid("player") then
		for i = 1, MAX_RAID_MEMBERS do
			local unit = "raid" .. i
			local guid = UnitGUID(unit)
			if guid then
				guid_to_status[guid] = GetReadyCheckStatus(unit)
			end
		end
	elseif UnitInParty("player") then
		guid_to_status[PLAYER_GUID] = GetReadyCheckStatus("player")
		
		for i = 1, MAX_PARTY_MEMBERS do
			local unit = "party" .. i
			local guid = UnitGUID(unit)
			if guid then
				guid_to_status[guid] = GetReadyCheckStatus(unit)
			end
		end
	end
end

function PitBull4_ReadyCheckIcon:StartFadeOut()
	-- TODO: actually make it have a fade out effect
	self:READY_CHECK()
end

function PitBull4_ReadyCheckIcon:READY_CHECK()
	self:CacheReachCheckStatuses()
	self:UpdateAll()
end
PitBull4_ReadyCheckIcon.READY_CHECK_CONFIRM = PitBull4_ReadyCheckIcon.READY_CHECK
function PitBull4_ReadyCheckIcon:READY_CHECK_FINISHED()
	self:ScheduleTimer("StartFadeOut", 8.5)
end