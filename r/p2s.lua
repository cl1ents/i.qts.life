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
