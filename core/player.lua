-- Author      : alexn
-- Create Date : 6/5/2020 12:17:49 PM

local P = {};

P.getPlayerState = function()
	local state = {}
	state.xp = UnitXP("player")
	state.level = UnitLevel("player")
	state.maxXP = UnitXPMax("player")
	state.evalTime = time()
	return state
end


P.getPlayerXPGain = function(formerState, latterState)
	local f, l = formerState, latterState
	gained = 0
	if f.level ~= l.level then
		-- Any experience gained in the current level has been gained since former state.
		gained = gained + l.xp
		-- In addition to the experience needed to level during the former state.
		gained = gained + f.maxXP - f.xp
	else
		-- The difference of current and former xp tells us the gain.
		gained = gained + l.xp - f.xp
	end
	return gained
end


P.getTimeBetweenStates = function(formerState, latterState)
	delta = formerState.evalTime - latterState.evalTime
	return math.abs(delta)
end


SquireAlex.Player = P
return SquireAlex.Player