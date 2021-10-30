local parent, ns = ...
local Compat = ns.Compat

local select = select
local unpack = unpack
local pairs, ipairs = pairs, ipairs
local tinsert = table.insert
local setmetatable = setmetatable
local wipe = wipe
local next = next

function Compat.SafePack(...)
	local t = {...}
	t.n = select("#", ...)
	return t
end

function Compat.SafeUnpack(t)
	return unpack(t, 1, t.n)
end

function Compat.tLength(t)
	local len = 0
	for _ in pairs(t) do
		len = len + 1
	end
	return len
end

function Compat.tCopy(to, from, ...)
	for k, v in pairs(from) do
		local skip = false
		if ... then
			for _, j in ipairs(...) do
				if j == k then
					skip = true
					break
				end
			end
		end
		if not skip then
			if type(v) == "table" then
				to[k] = {}
				Compat.tCopy(to[k], v, ...)
			else
				to[k] = v
			end
		end
	end
end

function Compat.tInvert(t)
	local inverted = {}
	for k, v in pairs(t) do
		inverted[v] = k
	end
	return inverted
end

function Compat.tIndexOf(t, item)
	for i, v in ipairs(t) do
		if item == v then
			return i
		end
	end
end

function Compat.tContains(t, item)
	return (Compat.tIndexOf(t, item) ~= nil)
end

function Compat.tAppendAll(tbl, elems)
	for _, elem in ipairs(elems) do
		tinsert(tbl, elem)
	end
end

local weaktable = {__mode = "v"}
function Compat.WeakTable(t)
	return setmetatable(wipe(t or {}), weaktable)
end

local tablePool = ns.tablePool or setmetatable({}, {__mode = "k"})
ns.tablePool = tablePool

function Compat.NewTable()
	local t = next(tablePool) or {}
	tablePool[t] = nil
	return t
end

function Compat.DelTable(t)
	if type(t) == "table" then
		wipe(t)
		t[true] = true
		t[true] = nil
		tablePool[t] = true
	end
	return nil
end