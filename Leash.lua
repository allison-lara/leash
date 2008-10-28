----------------------
--      Locals      --
----------------------

local L = setmetatable({}, {__index=function(t,i) return i end})
local defaults, defaultsPC, db, dbpc = {}, {}
local following = nil
local tryingToFollow = nil

------------------------------
--      Util Functions      --
------------------------------

local function Print(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99Leash|r:", ...)) end

-----------------------------
--      Event Handler      --
-----------------------------

local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")

local IsFriend = function(name)
	for i=1, GetNumFriends() do
		n, _ = GetFriendInfo(i)
		if n == name then return true end
	end
	return false
end

local LeashTo = function(name) 
	if UnitInParty(name) or UnitInRaid(name) or IsFriend(name) then
		tryingToFollow = name
		Print("Got follow request from", name)
		FollowUnit(name)
	else
		Print("Ignoring follow from", name)
	end
end

-- Have to handle msg coming from passed-in value or arg1, seems some addons nil out the param
local FollowFilter = function(msg)
	if nil == msg then msg = arg1 end
	if strfind(msg, "^!follow") then 
		local name = arg2
		LeashTo(name);
		return true
	end
end

function f:ADDON_LOADED(event, addon)
	if addon ~= "Leash" then return end

	LeashDB = setmetatable(AddonTemplateDB or {}, {__index = defaults})
	db = LeashDB

	-- Do anything you need to do after addon has loaded
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", FollowFilter)
	
	self:UnregisterEvent("ADDON_LOADED")
	self:RegisterEvent("AUTOFOLLOW_BEGIN")
	self:RegisterEvent("AUTOFOLLOW_END")
	self:RegisterEvent("UI_ERROR_MESSAGE")
	
	self.ADDON_LOADED = nil

	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end


function f:PLAYER_LOGIN()
	self:RegisterEvent("PLAYER_LOGOUT")

	-- Do anything you need to do after the player has entered the world

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

function f:PLAYER_LOGOUT()
	for i,v in pairs(defaults) do if db[i] == v then db[i] = nil end end
	for i,v in pairs(defaultsPC) do if dbpc[i] == v then dbpc[i] = nil end end

	-- Do anything you need to do as the player logs out
end

function f:AUTOFOLLOW_BEGIN(event, name)
	following = name
	tryingToFollow = nil
	Print("Following", following)
end

function f:AUTOFOLLOW_END()
	Print("No longer following", following)
	following = nil
end

function f:UI_ERROR_MESSAGE(event, msg)
	if not tryingToFollow then return end
	if msg == ERR_AUTOFOLLOW_TOO_FAR or 
	   msg == ERR_INVALID_FOLLOW_TARGET or
	   msg == ERR_TOOBUSYTOFOLLOW then
		Print("Unable to follow", tryingToFollow)
	end
end
-----------------------------
--      Slash Handler      --
-----------------------------

SLASH_LEASH1 = "/leash"
SlashCmdList.LEASH = function(msg)
	-- Do crap here
end
