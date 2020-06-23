-- Object To Lua
-- Crazyman32
-- June 6, 2018

-- cli, mrep, evan (Turned into simple function)
-- June 23, 2020

local API = (function() 
	local API = {}

	local API_URL = "https://anaminus.github.io/rbx/json/api/latest.json"
	
	
	function FetchAPI()
		local successGetAsync, data = pcall(function()
			return game:HttpGet(API_URL, true, nil)
		end)
		if (not successGetAsync) then
			warn("Failed to fetch Roblox API: " .. tostring(data))
			return
		end
		local successParse, dataArray = pcall(function()
			return game:GetService("HttpService"):JSONDecode(data)
		end)
		if (not successParse) then
			warn("Failed to parse Roblox API: " .. tostring(dataArray))
			return
		end
		return dataArray
	end
	
	
	function BuildClasses(api)
		
		local classes, classesByName = {}, {}
		
		local function ApplyTags(item)
			if (item.tags) then
				for i = 1,#item.tags do
					local tag = item.tags[i]
					if (tag:match("Security$")) then
						item.Security = tag
					elseif (tag == "readonly") then
						item.ReadOnly = true
					elseif (tag == "hidden") then
						item.Hidden = true
					elseif (tag == "notCreatable") then
						item.NotCreatable = true
					elseif (tag == "notbrowsable") then
						item.NotBrowsable = true
					end
				end
			end
		end
		
		-- Collect all classes:
		for i = 1,#api do
			local item = api[i]
			if (item.type == "Class") then
				classes[#classes + 1] = item
				classesByName[item.Name] = item
				item.Subclasses = {}
				item.Properties = {}
				item.Methods = {}
				item.Events = {}
				ApplyTags(item)
				for _,key in pairs{"Properties", "Methods", "Events"} do
					setmetatable(item[key], {
						__index = function(self, index)
							return item.Superclass and item.Superclass[key][index]
						end;
					})
				end
				function item:GetAllProperties(discludeSecure)
					local properties = {}
					local class = item
					while (class) do
						for propName,propInfo in pairs(class.Properties) do
							if ((not propInfo.Security) or (not discludeSecure)) then
								properties[propName] = propInfo
							end
						end
						class = class.Superclass
					end
					return properties
				end
			end
		end
		
		-- Reference superclasses:
		for i = 1,#classes do
			local class = classes[i]
			if (class.Superclass) then
				class.Superclass = classesByName[class.Superclass]
				table.insert(class.Superclass.Subclasses, class)
			end
		end
		
		-- Collect properties, methods, and events:
		for i = 1,#api do
			local item = api[i]
			if (item.type == "Property") then
				local class = classesByName[item.Class]
				ApplyTags(item)
				class.Properties[item.Name] = item
			elseif (item.type == "Function") then
				local class = classesByName[item.Class]
				ApplyTags(item)
				class.Methods[item.Name] = item
			elseif (item.type == "Event") then
				local class = classesByName[item.Class]
				ApplyTags(item)
				class.Events[item.Name] = item
			end
		end
		
		return classes, classesByName
		
	end
	
	
	function BuildEnums(api)
		
		local enums, enumsByName = {}, {}
		
		-- Collect enums:
		for i = 1,#api do
			local item = api[i]
			if (item.type == "Enum") then
				enums[#enums + 1] = item
				enumsByName[item.Name] = item
				item.EnumItems = {}
			end
		end
		
		-- Collect enum items:
		for i = 1,#api do
			local item = api[i]
			if (item.type == "EnumItem") then
				local enum = enumsByName[item.Enum]
				table.insert(enum.EnumItems, item)
			end
		end
		
		return enums, enumsByName
		
	end
	
	
	function API:Fetch()
		
		if (self._fetched) then
			warn("API already fetched")
			return
		end
		
		if (self._fetching) then
			warn("API is already in the process of being fetched")
			return
		end
		
		self._fetching = true
		local api = FetchAPI()
		self._fetching = nil
		if (not api) then return end
		
		API.Classes, API.ClassesByName = BuildClasses(api)
		API.Enums, API.EnumsByName = BuildEnums(api)
		
		self._fetched = true
		
		return true
		
	end
	
	
	return API
end)()

local apiFetched = false

local PropertyToString = (function()
	local PropertyToString
	
	local CONCAT = table.concat
	local FLOOR = math.floor
		
		
	local types = {}
	
	
	local function GCD(a, b)
		while (b > 0) do
			local _b = b
			b = a % b
			a = _b
		end
		return a
	end
	
	
	local function ColorValue(c)
		c = FLOOR(c * 255)
		if (c == 0) then
			return "0"
		elseif (c == 255) then
			return "1"
		end
		local gcd = GCD(c, 255)
		return (c / gcd .. "/" .. (255 / gcd))
	end
	
	
	types.Axes = function(value)
		
		local returnValue = {"Axes.new("}
		local args = {}
		local props = {"X", "Y", "Z"}
		for i = 1,#props do
			local prop = props[i]
			if (value[prop]) then
				args[#args + 1] = "Enum.Axis." .. prop
			end
		end
		returnValue[#returnValue + 1] = CONCAT(args, ",") .. ")"
		return CONCAT(returnValue, "")
		
	end
		
	types.BrickColor = function(value)
		local r = ColorValue(value.r)
		local g = ColorValue(value.g)
		local b = ColorValue(value.b)
		return "BrickColor.new(" .. r .. "," .. g .. "," .. b .. ")"
	end
		
	types.CFrame = function(value)
		local c = {value:components()}
		return "CFrame.new(" .. CONCAT(c, ",") .. ")"
	end
		
	types.Color3 = function(value)
		local r = ColorValue(value.r)
		local g = ColorValue(value.g)
		local b = ColorValue(value.b)
		return "Color3.new(" .. r .. "," .. g .. "," .. b .. ")"
	end
		
	types.ColorSequence = function(value)
		
		local keypoints = value.Keypoints
		local keypointsStr = {}
		for _,keypoint in pairs(keypoints) do
			keypointsStr[#keypointsStr + 1] = PropertyToString("ColorSequenceKeypoint", keypoint)
		end
		
		return "ColorSequence.new({" .. CONCAT(keypointsStr, ",") .. "})"
		
	end
		
	types.ColorSequenceKeypoint = function(value)
		return "ColorSequenceKeypoint.new(" .. value.Time .. "," .. PropertyToString("Color3", value.Value) .. ")"
	end
		
	types.DockWidgetPluginGuiInfo = function(value)
		return "DockWidgetPluginGuiInfo.new(Enum.InitialDockState." .. value.InitialDockState.Name ..
			"," .. value.InitialEnabled .. "," .. value.InitialEnabledShouldOverrideRestore ..
			"," .. value.FloatingXSize .. "," .. value.FloatingYSize .. "," .. value.MinWidth ..
			"," .. value.MinHeight .. ")"
	end
		
	types.Faces = function(value)
		
		local faces = {"Top", "Bottom", "Back", "Front", "Right", "Left"}
		local args = {}
		
		for i = 1,#faces do
			local prop = faces[i]
			if (value[prop]) then
				args[#args + 1] = "Enum.NormalId." .. prop
			end
		end
		
		return "Faces.new(" .. CONCAT(args, ",") .. ")"
		
	end
		
	types.NumberRange = function(value)
		local min, max = value.Min, value.Max
		if (min == max) then
			return "NumberRange.new(" .. min .. ")"
		else
			return "NumberRange.new(" .. min .. "," .. max .. ")"
		end
	end
		
	types.NumberSequence = function(value)
		
		local keypoints = value.Keypoints
		local keypointsStr = {}
		for _,keypoint in pairs(keypoints) do
			keypointsStr[#keypointsStr + 1] = PropertyToString("NumberSequenceKeypoint", keypoint)
		end
		
		return "NumberSequence.new({" .. CONCAT(keypointsStr, ",") .. "})"
		
	end
		
	types.NumberSequenceKeypoint = function(value)
		return "NumberSequenceKeypoint.new(" .. value.Time .. "," .. value.Value .. "," .. value.Envelope .. ")"
	end
		
	types.PathWaypoint = function(value)
		return "PathWaypoint.new(" .. PropertyToString("Vector3", value.Position) .. ",Enum.PathWaypointAction." .. value.Action.Name .. ")"
	end
		
	types.PhysicalProperties = function(value)
		return "PhysicalProperties.new(" .. value.Density .. "," .. value.Friction .. "," .. value.Elasticity ..
			"," .. value.FrictionWeight .. "," .. value.ElasticityWeight .. ")"
	end
		
	types.Ray = function(value)
		return "Ray.new(" .. PropertyToString("Vector3", value.Origin) .. "," .. PropertyToString("Vector3", value.Direction) .. ")"
	end
		
	types.Rect2D = function(value)
		return "Rect.new(" .. PropertyToString("Vector2", value.Min) .. "," .. PropertyToString("Vector2", value.Max) .. ")"
	end
		
	types.Region3 = function(value)
		local sh = value.Size * 0.5
		local pos = value.CFrame.p
		local min = pos - sh
		local max = pos + sh
		return "Region3.new(" .. PropertyToString("Vector3", min) .. "," .. PropertyToString("Vector3", max) .. ")"
	end
		
	types.Region3int16 = function(value)
		return "Region3int16.new(" .. PropertyToString("Vector3int16", value.Min) .. "," .. PropertyToString("Vector3int16", value.Max) .. ")"
	end
		
	types.TweenInfo = function(value)
		return "TweenInfo.new(" .. value.Time .. ",Enum.EasingStyle." .. value.EasingStyle.Name ..
			",Enum.EasingDirection." .. value.EasingDirection.Name .. "," .. value.RepeatCount .. "," ..
			value.Reverses .. "," .. value.DelayTime .. ")"
	end
		
	types.UDim = function(value)
		if (value.Scale == 0 and value.Offset == 0) then
			return "UDim.new()"
		elseif (value.Offset == 0) then
			return "UDim.new(" .. value.Scale .. ")"
		else
			return "UDim.new(" .. value.Scale .. "," .. value.Offset .. ")"
		end
	end
		
	types.UDim2 = function(value)
		if (value.X.Scale == 0 and value.X.Offset == 0 and value.Y.Scale == 0 and value.Y.Offset == 0) then
			return "UDim2.new()"
		else
			return "UDim2.new(" .. value.X.Scale .. "," .. value.X.Offset .. "," .. value.Y.Scale .. "," .. value.Y.Offset .. ")"
		end
	end
		
	types.Vector2 = function(value)
		if (value.X == 0 and value.Y == 0) then
			return "Vector2.new()"
		else
			return "Vector2.new(" .. value.X .. "," .. value.Y .. ")"
		end
	end
		
	types.Vector3 = function(value)
		if (value.X == 0 and value.Y == 0 and value.Z == 0) then
			return "Vector3.new()"
		else
			return "Vector3.new(" .. value.X .. "," .. value.Y .. "," .. value.Z .. ")"
		end
	end
		
	types.Vector3int16 = function(value)
		if (value.X == 0 and value.Y == 0 and value.Z == 0) then
			return "Vector3int16.new()"
		else
			return "Vector3int16.new(" .. value.X .. "," .. value.Y .. "," .. value.Z .. ")"
		end
	end
	
	types.string = function(value)
		return ("%q"):format(value)
	end
	
	types.Content = types.string
	types.CoordinateFrame = types.CFrame
	
	
	local enumsByName = {}
	for _,enum in pairs(Enum:GetEnums()) do enumsByName[tostring(enum)] = enum end
	
	
	PropertyToString = function(name, value, propName)
		
		local returnValue = tostring(value)
		local serializeFunc = types[name]
		if (serializeFunc) then
			returnValue = serializeFunc(value)
		elseif (enumsByName[name]) then
			return "Enum." .. name .. "." .. value.Name
		else
			if (name:match("^Class:") and value ~= nil) then
				return nil, true
			end
		end
		
		return returnValue
		
	end
	
	
	return PropertyToString
end)()


function Grab(obj)
	
	--local selection = game.Selection:Get()
	--assert(#selection == 1, "Please make sure 1 item is selected")
	
	local selectedItem = obj
	assert(selectedItem.Parent ~= game, "Selected item cannot be at service-level. Please select item within service (e.g. a model inside Workspace)")
	
	local awaitReference = {}
	
	-- Fetch API if needed:
	if (not apiFetched) then
		apiFetched = true
		local success, returnVal = pcall(function()
			return API:Fetch()
		end)
		if ((not success) or (not returnVal)) then
			apiFetched = false
			return
		end
	end
	
	local defaultObjects = {}
	setmetatable(defaultObjects, {
		__index = function(self, index)
			local obj = Instance.new(index)
			rawset(defaultObjects, index, obj)
			return obj
		end;
	})
	
	local codeBuilder = {}
	codeBuilder[#codeBuilder + 1] = "\local partsWithId = {}\
local awaitRef = {}\
\
local root = "
	
	local ref = {}
	local idCount = 0
	
	local objectIds = {}
	
	local function GetProperties(obj)
		local properties = {}
		local default = defaultObjects[obj.ClassName]
		local class = API.ClassesByName[obj.ClassName]
		for propName,propInfo in pairs(class:GetAllProperties(true)) do
			if ((not propInfo.ReadOnly) and (not propInfo.Hidden) and propName ~= "Parent") then
				local val = obj[propName]
				if (default[propName] ~= val) then
					local valStr, isRef = PropertyToString(propInfo.ValueType, val, propName)
					if (isRef) then
						properties[propName] = ("\"_R:%s_\""):format(objectIds[val] or "E")
					else
						properties[propName] = valStr
					end
				end
			end
		end
		return properties
	end
	
	local function Scan(obj, indentLvl)
		local indent = ("\t"):rep(indentLvl)
		if (indentLvl ~= 0) then
			codeBuilder[#codeBuilder + 1] = "\n" .. indent
		end
		codeBuilder[#codeBuilder + 1] = "{\n" .. indent .. "\tID = " .. objectIds[obj] .. ";\n" .. indent .. "\tType = \"" .. obj.ClassName .. "\";\n" .. indent .. "\tProperties = {"
		local props = GetProperties(obj)
		if (next(props)) then
			for propName,propVal in pairs(props) do
				codeBuilder[#codeBuilder + 1] = "\n" .. indent .. "\t\t" .. propName .. " = " .. propVal .. ";"
			end
			codeBuilder[#codeBuilder + 1] = "\n" .. indent .. "\t};"
		else
			codeBuilder[#codeBuilder + 1] = "};"
		end
		local children = obj:GetChildren()
		if (#children > 0) then
			codeBuilder[#codeBuilder + 1] = "\n" .. indent .. "\tChildren = {"
			for _,child in pairs(children) do
				Scan(child, indentLvl + 2)
			end
			codeBuilder[#codeBuilder + 1] = "\n" .. indent .. "\t};\n" .. indent .. "};"
		else
			codeBuilder[#codeBuilder + 1] = "\n" .. indent .. "\tChildren = {};\n" .. indent .. "};"
		end
	end
	
	objectIds[selectedItem] = idCount
	for _,v in pairs(selectedItem:GetDescendants()) do
		idCount = (idCount + 1)
		objectIds[v] = idCount
	end
	
	Scan(selectedItem, 0)
	
	codeBuilder[#codeBuilder + 1] = "\n\
local function Scan(item, parent)\
	local obj = Instance.new(item.Type)\
	if (item.ID) then\
		local awaiting = awaitRef[item.ID]\
		if (awaiting) then\
			awaiting[1][awaiting[2]] = obj\
			awaitRef[item.ID] = nil\
		else\
			partsWithId[item.ID] = obj\
		end\
	end\
	for p,v in pairs(item.Properties) do\
		if (type(v) == \"string\") then\
			local id = tonumber(v:match(\"^_R:(%w+)_$\"))\
			if (id) then\
				if (partsWithId[id]) then\
					v = partsWithId[id]\
				else\
					awaitRef[id] = {obj, p}\
					v = nil\
				end\
			end\
		end\
		obj[p] = v\
	end\
	for _,c in pairs(item.Children) do\
		Scan(c, obj)\
	end\
	obj.Parent = parent\
	return obj\
end\
\
Scan(root, workspace)"
	
	return table.concat(codeBuilder, "")
end

return Grab
