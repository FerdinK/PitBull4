if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_CastBar requires PitBull4")
end

local PitBull4_CastBar = PitBull4.NewModule("CastBar", "Cast Bar", "Show a cast bar", {}, {
	size = 1,
	position = 10,
}, "statusbar")

local castData = {}
PitBull4_CastBar.castData = castData

function PitBull4_CastBar.GetValue(frame)
	local unit = frame.unitID
	local data = castData[unit]
	if not data then
		return 0
	end
	
	if data.casting then
		local startTime = data.startTime
		return (GetTime() - startTime) / (data.endTime - startTime)
	elseif data.channeling then	
		local endTime = data.endTime
		castBar:SetValue((endTime - GetTime()) / (endTime - data.startTime))
	elseif data.fadeOut then
		return frame.CastBar:GetValue()
	end
	return 0
end

function PitBull4_CastBar.GetColor(frame)
	local unit = frame.unitID
	local data = castData[unit]
	if not data then
		return 0, 0, 0, 0
	end
	
	if data.casting then
		return 0, 1, 0, 1
	elseif data.channeling then
		return 0, 1, 0, 1
	elseif data.fadeOut then
		local alpha
		local stopTime = data.stopTime
		if stopTime then
			alpha = stopTime - GetTime() + 1
		else
			alpha = 0
		end
		if alpha >= 1 then
			alpha = 1
		end
		if alpha <= 0 then
			wipe(data)
			return 0, 0, 0, 0
		else
			return 0, 1, 0, alpha
		end
	else
		wipe(data)
	end
	return 0, 0, 0, 0
end

PitBull4_CastBar:SetValueFunction('GetValue')
PitBull4_CastBar:SetColorFunction('GetColor')

function PitBull4_CastBar.UNIT_SPELLCAST_SENT(event, unit, spell, rank, target)
	local found = false
	for frame in PitBull4.IterateFramesForUnitID(unit, true) do
		if frame.CastBar then
			found = true
			break
		end
	end
	if not found then
		return
	end

	local data = castData[unit]
	if not data then
		data = {}
		castData[unit] = data
	end

	if target == "" then
		target = nil
	end
	data.target = target
end

function PitBull4_CastBar.UNIT_SPELLCAST_START(event, unit)
	local found = false
	for frame in PitBull4.IterateFramesForUnitID(unit, true) do
		if frame.CastBar then
			found = true
			break
		end
	end
	if not found then
		return
	end

	local data = castData[unit]
	if not data then
		data = {}
		castData[unit] = data
	end	

	local spell, rank, displayName, icon, startTime, endTime = UnitCastingInfo(unit)
	data.spell = spell
	data.rank = rank
	data.displayName = displayName
	data.icon = icon
	data.startTime = startTime * 0.001
	data.endTime = endTime * 0.001
	local channeling = event == "UNIT_SPELLCAST_CHANNEL_START"
	data.casting = not channeling
	data.channeling = channeling
	data.fadeOut = nil
end

function PitBull4_CastBar.UNIT_SPELLCAST_STOP(event, unit)
	local data = castData[unit]
	if not data or not data.casting then
		return
	end
	data.casting = nil
	data.fadeOut = 1
	data.stopTime = GetTime()
end

function PitBull4_CastBar.UNIT_SPELLCAST_FAILED(event, unit)
	local data = castData[unit]
	if not data or data.fadeOut then
		return
	end
	data.casting = nil
	data.channeling = nil
	data.fadeOut = 1
	data.stopTime = GetTime()
end

function PitBull4_CastBar.UNIT_SPELLCAST_INTERRUPTED(event, unit)
	local data = castData[unit]
	if not data then
		return
	end
	data.casting = nil
	data.channeling = nil
	data.fadeOut = 1
	data.stopTime = GetTime()
end

function PitBull4_CastBar.UNIT_SPELLCAST_DELAYED(event, unit)
	local data = castData[unit]
	if not data or not data.casting then
		return
	end
	
	local spell, rank, displayName, icon, startTime, endTime = UnitCastingInfo(unit)

	if not spell or not startTime or not endTime then
		return
	end

	local oldStart = data.startTime

	data.startTime = startTime * 0.001
	data.endTime = endTime * 0.001
end

function PitBull4_CastBar.UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit)
	local data = castData[unit]
	if not data then
		return
	end

	local spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo(unit)

	if not spell then
		wipe(data)
		return
	end

	local oldStart = data.startTime
	data.startTime = startTime * 0.001
	data.endTime = endTime * 0.001
end

function PitBull4_CastBar.UNIT_SPELLCAST_CHANNEL_STOP(event, unit)
	local data = castData[unit]
	if not data then
		return
	end
	
	data.channeling = nil
	data.casting = nil
	data.fadeOut = 1
	data.stopTime = GetTime()
end

function PitBull4_CastBar.FixCastData()
	local frame
	local currentTime = GetTime()
	for unit, data in pairs(castData) do
		local found = false
		for frame in PitBull4.IterateFramesForUnitID(unit, true) do
			local castBar = frame.CastBar
			if castBar then
				found = true
				if data.casting then
					if currentTime > data.endTime and not UnitIsUnit("player", unit) then
						data.casting = nil
						data.fadeOut = 1
						data.stopTime = currentTime
					end
				elseif data.channeling then
					if currentTime > data.endTime then
						data.channeling = nil
						data.fadeOut = 1
						data.stopTime = currentTime
					end
				elseif data.fadeOut then
				else
					wipe(data)
				end
			end	
			break
		end
		if not found then
			wipe(data)
		end
	end
end

PitBull4.Utils.AddTimer(function()
	PitBull4_CastBar.FixCastData()
	PitBull4_CastBar:UpdateAll()
end)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_SENT", PitBull4_CastBar.UNIT_SPELLCAST_SENT)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_START", PitBull4_CastBar.UNIT_SPELLCAST_START)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_CHANNEL_START", PitBull4_CastBar.UNIT_SPELLCAST_START)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_STOP", PitBull4_CastBar.UNIT_SPELLCAST_STOP)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_FAILED", PitBull4_CastBar.UNIT_SPELLCAST_FAILED)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_INTERRUPTED", PitBull4_CastBar.UNIT_SPELLCAST_INTERRUPTED)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_DELAYED", PitBull4_CastBar.UNIT_SPELLCAST_DELAYED)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_CHANNEL_UPDATE", PitBull4_CastBar.UNIT_SPELLCAST_CHANNEL_UPDATE)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_CHANNEL_STOP", PitBull4_CastBar.UNIT_SPELLCAST_CHANNEL_STOP)
