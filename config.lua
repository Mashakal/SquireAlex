-- Author      : alexn
-- Create Date : 6/4/2020 11:18:38 AM

local P = {}
SquireAlex.Config = P


P.ENABLED = true
P.POLL_FREQUENCY = 60 * 3  --> 3 minutes
P.INCLUDE_TIME_IN_MAJOR_CITIES = true
P.INCLUDE_TIME_IN_FLIGHT = true
P.PREFERRED_DATETIME_FORMAT = "%m/%d/%y %H:%M:%S"


--> APPS
P.XP_STATS_ENABLED = true


return SquireAlex.Config