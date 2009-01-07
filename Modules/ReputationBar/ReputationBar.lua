if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_ReputationBar requires PitBull4")
end

local L = PitBull4.L

local PitBull4_ReputationBar = PitBull4:NewModule("ReputationBar")

PitBull4_ReputationBar:SetModuleType("status_bar")
PitBull4_ReputationBar:SetName(L["Reputation bar"])
PitBull4_ReputationBar:SetDescription(L["Show a reputation bar."])
PitBull4_ReputationBar:SetDefaults({
	size = 1,
	position = 3,
})

function PitBull4_ReputationBar:GetValue(frame)
	if frame.unit ~= "player" then
		return nil
	end
	
	local name, _, min, max, value = GetWatchedFactionInfo()
	if not name then
		return nil
	end
	
	return (value - min) / (max - min)
end

function PitBull4_ReputationBar:GetColor(frame, value)
	local _, reaction = GetWatchedFactionInfo()
	local color = FACTION_BAR_COLORS[reaction]
	if color then
		return color.r, color.g, color.b
	end
end

function PitBull4_ReputationBar:GetExampleValue(frame)
	if frame.unit ~= "player" then
		return nil
	end
	return 0.3
end

function PitBull4_ReputationBar:GetExampleColor(frame)
	local color = FACTION_BAR_COLORS[5]
	return color.r, color.g, color.b
end

hooksecurefunc("ReputationWatchBar_Update", function()
	if not PitBull4_ReputationBar:IsEnabled() then
		return
	end
	PitBull4_ReputationBar:UpdateForUnitID("player")
end)
