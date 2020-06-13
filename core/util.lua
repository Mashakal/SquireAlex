

local P = {}
SquireAlex.Util = P

-- ############## Standardized Output ############## --
function P.output (msg)
	print(msg)
end
-- ################################################## --



-- INTEGER FORMATTING --
function P.getHumanizedInt(i)
    -- https://stackoverflow.com/questions/10989788/lua-format-integer
	return tostring(i):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

-- --



-- ################ DateTime Utility ################ --
function P.getHumanizedDatetime ()
	return date(SquireAlex.Config.PREFERRED_DATETIME_FORMAT)
end
-- ################################################## --



-- ################## Time Utility ################## --
local function ftime (timeToFormat, formatString)
	return string.format(formatString or "%02d", timeToFormat);
end


function P.getHumanizedTime(secondsDelta)
	hours = math.floor(secondsDelta / 60 / 60)
	total = hours * 3600
	minutes = math.floor((secondsDelta - total) / 60)
	if hours >= 1 then
		return ftime(hours, "%d") .. "h " .. ftime(minutes) .. "m"
	elseif minutes >= 1 then
		total = total + minutes * 60
		seconds = secondsDelta - total
		return ftime(minutes, "%d") .. "m " .. ftime(seconds) .. "s"
	else
		return ftime(secondsDelta, "%d") .. "s"
	end
end

-- ################################################## --


-- ################## Frame Utility ################# --
function P.makeMovable(frame)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
end
-- ################################################## --

return SquireAlex.Util