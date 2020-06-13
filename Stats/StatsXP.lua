-- Author      : alexn
-- Create Date : 6/10/2020 10:17:38 AM
-- ######################################################################################################################

local POLL_FREQUENCY = 1  -- every second

local STAT_HEIGHT = 10
local TOP_BORDER_PADDING = -10
local BOTTOM_BORDER_PADDING = -5
local TOP_PAIR_PADDING = -5
local H_PADDING = 10
local UNKNOWN_LEVEL_TIME_DISPLAY = "?"

-- STATE BASED VARIABLES
local activePairs = {}
local parentFrameState = {}
local cState = nil
local gState = nil
local resetGlobal = false



-- SLASH COMMANDS --
SLASH_STATSXP1 = "/statsxp"
SlashCmdList["STATSXP"] = function (msg)
	if msg == "rgs" then 
		resetGlobal = true
		print("It's reset!")
	end
end
--------------------



-- ########## UTILITY ########### --
local function getHourlyXP(gainedXP, elapsedSeconds)
	elapsedHours = elapsedSeconds / 60 / 60
	return gainedXP / elapsedHours
end


local function getSecondsToLevel(session)
	local xpneeded = session.pstate.maxXP - session.pstate.xp;
	local hoursNeeded = xpneeded / session.hourlyXP;
	return hoursNeeded * 3600
end
-- ############################## --


-- ########## SESSIONS ########## --
local function getNewSession (name, pollFrequency)
	local s = {}
	s.name = name or "Global"
	s.pstate = SquireAlex.Player.getPlayerState()
	s.initTime = s.pstate.evalTime
	s.elapsedSeconds = 0
	s.initialXP = s.pstate.xp
	s.gainedXP = 0
	s.hourlyXP = 0
	s.pollFrequency = pollFrequency or POLL_FREQUENCY
	s.nextTickTime = s.initTime + s.pollFrequency
	return s
end


local function getRestoredSession (session)
	session.pstate = SquireAlex.Player.getPlayerState()
	return session
end


local function sessionTick(s)
	local pstate = SquireAlex.Player.getPlayerState()
	s.gainedXP = s.gainedXP + SquireAlex.Player.getPlayerXPGain(s.pstate, pstate)
	s.elapsedSeconds = s.elapsedSeconds + SquireAlex.Player.getTimeBetweenStates(s.pstate, pstate)
	s.hourlyXP = getHourlyXP(s.gainedXP, s.elapsedSeconds)
	s.pstate = pstate
	s.nextTickTime = pstate.evalTime + s.pollFrequency
	return s
end


local function outputSessionState(s)
	for i = 1, #activePairs do
		local o = activePairs[i]
		local f = o["frame"]
		local m = o["metadata"]
		if m.onUpdate then 
			m.onUpdate(f, s) 
		end
	end
end
-- ############################## --


-- ############ MAIN ############ --

local function StatsXP_onUpdate ()
	local _now = time()
	for i = 1, #cState.sessions do
		local s = nil
		if resetGlobal then
			s = getNewSession()
			resetGlobal = false
			cState.sessions[i] = s
		else
			s = cState.sessions[i]
			if _now >= s.nextTickTime then
				s = sessionTick(s)
				outputSessionState(s)
				cState.sessions[i] = s
			end
		end
	end
end


local function StatsXP_onAddonLoaded ()
	print("Initializing SquireAlex: XP Stats")
	cState = SquireAlex_StatsXP_CharGameState or {}
	gState = SquireAlex_StatsXP_GlobalGameState or {}
	cState.sessions = cState.sessions or {}
	if #cState.sessions > 0 then
		print("Using existing sessions data.")
		s = cState.sessions[1]
		s = getRestoredSession(s)
		print("Initial XP: "..s.pstate.xp)
		cState.sessions[1] = s
	else
		print("Initializing a new session.")
		cState.sessions[1] = getNewSession()
	end
	SquireAlex_StatsXP:SetScript("OnUpdate", StatsXP_onUpdate)
end


local function StatsXP_onPlayerLogout ()
	SquireAlex_StatsXP_CharGameState = cState
	SquireAlex_StatsXP_GlobalGameState = gState
end


local function StatsXP_onEvent (self, event, ...)
	if event == "PLAYER_LOGOUT" then
		StatsXP_onPlayerLogout()
	elseif event == "PLAYER_LOGIN" then
		StatsXP_onAddonLoaded()
	end
end



-- ######################################################################################################################

local function setParentFrameState()
	parentFrameState.width = SquireAlex_StatsXP:GetWidth();
	parentFrameState.height = SquireAlex_StatsXP:GetHeight();
end


local function deriveParentFrameHeight()
	local height = TOP_BORDER_PADDING + BOTTOM_BORDER_PADDING 
		+ TOP_PAIR_PADDING * #activePairs
		- STAT_HEIGHT * #activePairs  -- STAT_HEIGHT is positive, so subtract.
	height = math.abs(height)  -- Height should be positive.
	return height
end


local function formatParentFrame()
	SquireAlex_StatsXP:SetHeight(deriveParentFrameHeight())
end


local function getStatsPair(name)
	local f = CreateFrame("Frame", "$parent_KVPAIR_"..name, SquireAlex_StatsXP);
	f:SetHeight(STAT_HEIGHT)
	f:SetWidth(f:GetParent():GetWidth() - (H_PADDING * 2))
	return f;
end


local function statsPairSetPoint(frame, metadata)
	if metadata.index == 1 then 
		frame:SetPoint("TOP", SquireAlex_StatsXP, "TOP", 0, TOP_BORDER_PADDING)
	else
		frame:SetPoint("TOP", activePairs[metadata.index - 1]["frame"], "BOTTOM", 0, TOP_PAIR_PADDING)
	end 
end


local function statsPairCreateLabel(frame, metadata)
	local s = frame:CreateFontString("$parent_label", "ARTWORK", "SystemFont_Small")
	s:SetText(metadata.keyText)
	s:SetPoint("LEFT", frame)
	s:SetTextColor("1", "1", "0", "1")
	return s;
end


local function statsPairCreateValue(frame, metadata)
	local s = frame:CreateFontString("$parent_value", "ARTWORK", "SystemFont_Small")
	s:SetText(metadata.valText);
	s:SetPoint("RIGHT", frame)
	s:SetTextColor("1", "1", "0", "1")
	return s; 
end


local function initializeStat (metadata)
	local f = getStatsPair(metadata.name)
	statsPairSetPoint(f, metadata)
	statsPairCreateLabel(f, metadata)
	statsPairCreateValue(f, metadata)
	local o = {}
	o["frame"] = f
	o["metadata"] = metadata
	activePairs[metadata.index] = o
end


local function sessionTimeOnUpdate(frame, session)
	local f = _G[frame:GetName().."_value"]
	f:SetText(SquireAlex.Util.getHumanizedTime(math.floor(session.elapsedSeconds)))
end


local function xpPerHourOnUpdate(frame, session)
	local f = _G[frame:GetName().."_value"]
	local rate = math.floor(session.hourlyXP);
	f:SetText(SquireAlex.Util.getHumanizedInt(rate))
end


local function timeToLevelOnUpdate(frame, session)
	local f = _G[frame:GetName().."_value"]
	if session.hourlyXP > 0 then
		local seconds = getSecondsToLevel(session)
		f:SetText(SquireAlex.Util.getHumanizedTime(seconds))
	else
		f:SetText(UNKNOWN_LEVEL_TIME_DISPLAY)
	end
end


local function getStatsPairMetadata(name, keyText, valText, onUpdate, onLoad)
	local o = {};
	o.name = name;
	o.onUpdate = onUpdate;
	o.onLoad = onLoad or initializeStat;
	o.index = nil;
	o.keyText = keyText;
	o.valText = valText;
	return o;
end


local statsMetadata = {
	getStatsPairMetadata("SESSION_NAME", "Session:", "Global", nil, nil),
	getStatsPairMetadata("SESSION_TIME", "Time:", "?", sessionTimeOnUpdate, nil),
	getStatsPairMetadata("XPPERHOUR", "XP/HR:", "?", xpPerHourOnUpdate, nil),
	getStatsPairMetadata("TIMETOLEVEL", "TTL:", "?", timeToLevelOnUpdate, nil),
};



-- ######################################################################################################################
function SquireAlex_StatsXP_OnLoad ()
	-- Get the current state of the root frame.
	setParentFrameState()
	-- Initialize the key/value data pairs.
	for i = 1, #statsMetadata do 
		local s = statsMetadata[i]
		s.index = i
		initializeStat(s)
	end
	-- Handle reformatting after the data pairs are initialized.
	formatParentFrame()
	SquireAlex.Util.makeMovable(SquireAlex_StatsXP)
	-- Prepare for the user's login and information to be available.
	if SquireAlex.Config.XP_STATS_ENABLED then
		SquireAlex_StatsXP:RegisterEvent("PLAYER_LOGOUT")
		SquireAlex_StatsXP:RegisterEvent("PLAYER_LOGIN")
		SquireAlex_StatsXP:SetScript("OnEvent", StatsXP_onEvent)
	end
end
