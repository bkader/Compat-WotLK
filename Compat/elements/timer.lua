local parent, ns = ...
local Compat = ns.Compat

local error = error
local format = string.format
local max = math.max
local next = next
local setmetatable = setmetatable
local tinsert = table.insert
local tremove = table.remove
local type = type

local C_Timer = {}

local TickerPrototype = {}
local TickerMetatable = {__index = TickerPrototype, __metatable = true}

local WaitTable = {}

local new, del
do
	C_Timer.__timers = C_Timer.__timers or {}
	C_Timer.__afters = C_Timer.__afters or {}
	local listT = C_Timer.__timers
	local listA = C_Timer.__afters

	function new(temp)
		if temp then
			local t = next(listA) or {}
			listA[t] = nil
			return t
		end

		local t = next(listT) or setmetatable({}, TickerMetatable)
		listT[t] = nil
		return t
	end

	function del(t)
		if t then
			local temp = t._temp
			t[true] = true
			t[true] = nil
			if temp then
				listA[t] = true
			else
				listT[t] = true
			end
		end
	end
end

local function WaitFunc(self, elapsed)
	local total = #WaitTable
	local i = 1

	while i <= total do
		local ticker = WaitTable[i]

		if ticker._cancelled then
			del(tremove(WaitTable, i))
			total = total - 1
		elseif ticker._delay > elapsed then
			ticker._delay = ticker._delay - elapsed
			i = i + 1
		else
			ticker._callback(ticker)

			if ticker._remainingIterations == -1 then
				ticker._delay = ticker._duration
				i = i + 1
			elseif ticker._remainingIterations > 1 then
				ticker._remainingIterations = ticker._remainingIterations - 1
				ticker._delay = ticker._duration
				i = i + 1
			elseif ticker._remainingIterations == 1 then
				del(tremove(WaitTable, i))
				total = total - 1
			end
		end
	end

	if #WaitTable == 0 then
		self:Hide()
	end
end

local WaitFrame = _G[parent .. "_WaitFrame"] or CreateFrame("Frame", parent .. "_WaitFrame", UIParent)
WaitFrame:SetScript("OnUpdate", WaitFunc)

local function AddDelayedCall(ticker, oldTicker)
	ticker = (oldTicker and type(oldTicker) == "table") and oldTicker or ticker
	tinsert(WaitTable, ticker)
	WaitFrame:Show()
end

local function ValidateArguments(duration, callback, callFunc)
	if type(duration) ~= "number" then
		error(format(
			"Bad argument #1 to '" .. callFunc .. "' (number expected, got %s)",
			duration ~= nil and type(duration) or "no value"
		), 2)
	elseif type(callback) ~= "function" then
		error(format(
			"Bad argument #2 to '" .. callFunc .. "' (function expected, got %s)",
			callback ~= nil and type(callback) or "no value"
		), 2)
	end
end

function C_Timer.After(duration, callback, ...)
	ValidateArguments(duration, callback, "After")

	local ticker = new(true)

	ticker._remainingIterations = 1
	ticker._delay = max(0.01, duration)
	ticker._callback = callback
	ticker._cancelled = nil
	ticker._temp = true

	AddDelayedCall(ticker)
end

local function CreateTicker(duration, callback, iterations, ...)
	local ticker = new()

	ticker._remainingIterations = iterations or -1
	ticker._delay = max(0.01, duration)
	ticker._duration = ticker._delay
	ticker._callback = callback
	ticker._cancelled = nil

	AddDelayedCall(ticker)
	return ticker
end

function C_Timer.NewTicker(duration, callback, iterations, ...)
	ValidateArguments(duration, callback, "NewTicker")
	return CreateTicker(duration, callback, iterations, ...)
end

function C_Timer.NewTimer(duration, callback, ...)
	ValidateArguments(duration, callback, "NewTimer")
	return CreateTicker(duration, callback, 1, ...)
end

function C_Timer.CancelTimer(ticker)
	if ticker and ticker.Cancel then
		ticker:Cancel()
	end
	return nil
end

function TickerPrototype:Cancel()
	self._cancelled = true
end

function TickerPrototype:IsCancelled()
	return self._cancelled
end

Compat.C_Timer = C_Timer

-- backwards compatibility
Compat.After = C_Timer.After
Compat.NewTicker = C_Timer.NewTicker
Compat.NewTimer = C_Timer.NewTimer
Compat.CancelTimer = C_Timer.CancelTimer