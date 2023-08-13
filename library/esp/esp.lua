--[[
    made by siper#9938 and mickey#5612
]]

-- main module
local espLibrary = {
    instances = {},
    espCache = {},
    chamsCache = {},
    objectCache = {},
    conns = {},
    whitelist = {}, -- insert string that is the player's name you want to whitelist (turns esp color to whitelistColor in options)
    blacklist = {}, -- insert string that is the player's name you want to blacklist (removes player from esp)
    options = {
        enabled = true,
        minScaleFactorX = 1,
        maxScaleFactorX = 10,
        minScaleFactorY = 1,
        maxScaleFactorY = 10,
        scaleFactorX = 5,
        scaleFactorY = 6,
        boundingBox = false, -- WARNING | Significant Performance Decrease when true
        boundingBoxDescending = true,
        excludedPartNames = {},
        font = 2,
        fontSize = 13,
        limitDistance = false,
        maxDistance = 1000,
        visibleOnly = false,
        teamCheck = false,
        teamColor = false,
        fillColor = nil,
        whitelistColor = Color3.new(1, 0, 0),
        outOfViewArrows = true,
        outOfViewArrowsFilled = true,
        outOfViewArrowsSize = 25,
        outOfViewArrowsRadius = 100,
        outOfViewArrowsColor = Color3.new(1, 1, 1),
        outOfViewArrowsTransparency = 0.5,
        outOfViewArrowsOutline = true,
        outOfViewArrowsOutlineFilled = false,
        outOfViewArrowsOutlineColor = Color3.new(1, 1, 1),
        outOfViewArrowsOutlineTransparency = 1,
        names = true,
        nameTransparency = 1,
        nameColor = Color3.new(1, 1, 1),
        boxes = true,
        boxesTransparency = 1,
        boxesColor = Color3.new(1, 0, 0),
        boxFill = false,
        boxFillTransparency = 0.5,
        boxFillColor = Color3.new(1, 0, 0),
        healthBars = true,
        healthBarsSize = 1,
        healthBarsTransparency = 1,
        healthBarsColor = Color3.new(0, 1, 0),
        healthText = true,
        healthTextTransparency = 1,
        healthTextSuffix = "%",
        healthTextColor = Color3.new(1, 1, 1),
        distance = true,
        distanceTransparency = 1,
        distanceSuffix = " Studs",
        distanceColor = Color3.new(1, 1, 1),
        tracers = false,
        tracerTransparency = 1,
        tracerColor = Color3.new(1, 1, 1),
        tracerOrigin = "Bottom", -- Available [Mouse, Top, Bottom]
        chams = true,
        chamsFillColor = Color3.new(1, 0, 0),
        chamsFillTransparency = 0.5,
        chamsOutlineColor = Color3.new(),
        chamsOutlineTransparency = 0
    },
};
espLibrary.__index = espLibrary;

-- variables
local getService = game.GetService;
local instanceNew = Instance.new;
local drawingNew = Drawing.new;
local vector2New = Vector2.new;
local vector3New = Vector3.new;
local cframeNew = CFrame.new;
local color3New = Color3.new;
local raycastParamsNew = RaycastParams.new;
local abs = math.abs;
local tan = math.tan;
local rad = math.rad;
local clamp = math.clamp;
local floor = math.floor;
local find = table.find;
local insert = table.insert;
local findFirstChild = game.FindFirstChild;
local getChildren = game.GetChildren;
local getDescendants = game.GetDescendants;
local isA = workspace.IsA;
local raycast = workspace.Raycast;
local emptyCFrame = cframeNew();
local pointToObjectSpace = emptyCFrame.PointToObjectSpace;
local getComponents = emptyCFrame.GetComponents;
local cross = vector3New().Cross;
local inf = 1 / 0;

-- services
local workspace = getService(game, "Workspace");
local runService = getService(game, "RunService");
local players = getService(game, "Players");
local coreGui = getService(game, "CoreGui");
local userInputService = getService(game, "UserInputService");

-- cache
local currentCamera = workspace.CurrentCamera;
local localPlayer = players.LocalPlayer;
local screenGui = instanceNew("ScreenGui", coreGui);
local lastFov, lastScale;

-- instance functions
local wtvp = currentCamera.WorldToViewportPoint;

-- Support Functions
local function isDrawing(type)
    return type == "Square" or type == "Text" or type == "Triangle" or type == "Image" or type == "Line" or type == "Circle";
end

local function create(type, properties)
    local drawing = isDrawing(type);
    local object = drawing and drawingNew(type) or instanceNew(type);

    if (properties) then
        for i,v in next, properties do
            object[i] = v;
        end
    end

    if (not drawing) then
        insert(espLibrary.instances, object);
    end

    return object;
end

local function worldToViewportPoint(position)
    local screenPosition, onScreen = wtvp(currentCamera, position);
    return vector2New(screenPosition.X, screenPosition.Y), onScreen, screenPosition.Z;
end

local function round(number)
    return typeof(number) == "Vector2" and vector2New(round(number.X), round(number.Y)) or floor(number);
end

-- Main Functions
function espLibrary.getTeam(player)
    local team = player.Team;
    return team, player.TeamColor.Color;
end

function espLibrary.getCharacter(player)
    local character = player.Character;
    return character, character and findFirstChild(character, "HumanoidRootPart");
end

function espLibrary.getBoundingBox(character, torso)
    if (espLibrary.options.boundingBox) then
        local minX, minY, minZ = inf, inf, inf;
        local maxX, maxY, maxZ = -inf, -inf, -inf;

        for _, part in next, espLibrary.options.boundingBoxDescending and getDescendants(character) or getChildren(character) do
            if (isA(part, "BasePart") and not find(espLibrary.options.excludedPartNames, part.Name)) then
                local size = part.Size;
                local sizeX, sizeY, sizeZ = size.X, size.Y, size.Z;

                local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = getComponents(part.CFrame);

                local wiseX = 0.5 * (abs(r00) * sizeX + abs(r01) * sizeY + abs(r02) * sizeZ);
                local wiseY = 0.5 * (abs(r10) * sizeX + abs(r11) * sizeY + abs(r12) * sizeZ);
                local wiseZ = 0.5 * (abs(r20) * sizeX + abs(r21) * sizeY + abs(r22) * sizeZ);

                minX = minX > x - wiseX and x - wiseX or minX;
                minY = minY > y - wiseY and y - wiseY or minY;
                minZ = minZ > z - wiseZ and z - wiseZ or minZ;

                maxX = maxX < x + wiseX and x + wiseX or maxX;
                maxY = maxY < y + wiseY and y + wiseY or maxY;
                maxZ = maxZ < z + wiseZ and z + wiseZ or maxZ;
            end
        end

        local oMin, oMax = vector3New(minX, minY, minZ), vector3New(maxX, maxY, maxZ);
        return (oMax + oMin) * 0.5, oMax - oMin;
    else
        return torso.Position, vector2New(espLibrary.options.scaleFactorX, espLibrary.options.scaleFactorY);
    end
end

function espLibrary.getScaleFactor(fov, depth)
    if (fov ~= lastFov) then
        lastScale = tan(rad(fov * 0.5)) * 2;
        lastFov = fov;
    end

    return 1 / (depth * lastScale) * 1000;
end

function espLibrary.getBoxData(position, size)
    local torsoPosition, onScreen, depth = worldToViewportPoint(position);
    local scaleFactor = espLibrary.getScaleFactor(currentCamera.FieldOfView, depth);

    local clampX = clamp(size.X, espLibrary.options.minScaleFactorX, espLibrary.options.maxScaleFactorX);
    local clampY = clamp(size.Y, espLibrary.options.minScaleFactorY, espLibrary.options.maxScaleFactorY);
    local size = round(vector2New(clampX * scaleFactor, clampY * scaleFactor));

    return onScreen, size, round(vector2New(torsoPosition.X - (size.X * 0.5), torsoPosition.Y - (size.Y * 0.5))), torsoPosition;
end

function espLibrary.getHealth(player, character)
    local humanoid = findFirstChild(character, "Humanoid");

    if (humanoid) then
        return humanoid.Health, humanoid.MaxHealth;
    end

    return 100, 100;
end

function espLibrary.visibleCheck(character, position)
    local origin = currentCamera.CFrame.Position;
    local params = raycastParamsNew();

    params.FilterDescendantsInstances = { espLibrary.getCharacter(localPlayer), currentCamera, character };
    params.FilterType = Enum.RaycastFilterType.Blacklist;
    params.IgnoreWater = true;

    return (not raycast(workspace, origin, position - origin, params));
end

function espLibrary.addEsp(player)
    if (player == localPlayer) then
        return
    end

    local objects = {
        arrow = create("Triangle", {
            Thickness = 1,
        }),
        arrowOutline = create("Triangle", {
            Thickness = 1,
        }),
        top = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        side = create("Text", {
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        bottom = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        boxFill = create("Square", {
            Thickness = 1,
            Filled = true,
        }),
        boxOutline = create("Square", {
            Thickness = 3,
            Color = color3New()
        }),
        box = create("Square", {
            Thickness = 1
        }),
        healthBarOutline = create("Square", {
            Thickness = 1,
            Color = color3New(),
            Filled = true
        }),
        healthBar = create("Square", {
            Thickness = 1,
            Filled = true
        }),
        line = create("Line")
    };

    espLibrary.espCache[player] = objects;
end

function espLibrary.removeEsp(player)
    local espCache = espLibrary.espCache[player];

    if (espCache) then
        espLibrary.espCache[player] = nil;

        for index, object in next, espCache do
            espCache[index] = nil;
            object:Remove();
        end
    end
end

function espLibrary.addChams(player)
    if (player == localPlayer) then
        return
    end

    espLibrary.chamsCache[player] = create("Highlight", {
        Parent = screenGui,
    });
end

function espLibrary.removeChams(player)
    local highlight = espLibrary.chamsCache[player];

    if (highlight) then
        espLibrary.chamsCache[player] = nil;
        highlight:Destroy();
    end
end

function espLibrary.addObject(object, options)
    espLibrary.objectCache[object] = {
        options = options,
        text = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        })
    };
end

function espLibrary.removeObject(object)
    local cache = espLibrary.objectCache[object];

    if (cache) then
        espLibrary.objectCache[object] = nil;
        cache.text:Remove();
    end
end

function espLibrary:AddObjectEsp(object, defaultOptions)
    assert(object and object.Parent, "invalid object passed");

    local options = defaultOptions or {};

    options.enabled = options.enabled or true;
    options.limitDistance = options.limitDistance or false;
    options.maxDistance = options.maxDistance or false;
    options.visibleOnly = options.visibleOnly or false;
    options.color = options.color or color3New(1, 1, 1);
    options.transparency = options.transparency or 1;
    options.text = options.text or object.Name;
    options.font = options.font or 2;
    options.fontSize = options.fontSize or 13;

    self.addObject(object, options);

    insert(self.conns, object.Parent.ChildRemoved:Connect(function(child)
        if (child == object) then
            self.removeObject(child);
        end
    end));

    return options;
end

function espLibrary:Unload()
    for _, connection in next, self.conns do
        connection:Disconnect();
    end

    for _, player in next, players:GetPlayers() do
        self.removeEsp(player);
        self.removeChams(player);
    end

    for object, _ in next, self.objectCache do
        self.removeObject(object);
    end

    for _, object in next, self.instances do
        object:Destroy();
    end

    screenGui:Destroy();
    runService:UnbindFromRenderStep("esp_rendering");
end

function espLibrary:Load(renderValue)
    insert(self.conns, players.PlayerAdded:Connect(function(player)
        self.addEsp(player);
        self.addChams(player);
    end));

    insert(self.conns, players.PlayerRemoving:Connect(function(player)
        self.removeEsp(player);
        self.removeChams(player);
    end));

    for _, player in next, players:GetPlayers() do
        self.addEsp(player);
        self.addChams(player);
    end

    runService:BindToRenderStep("esp_rendering", renderValue or (Enum.RenderPriority.Camera.Value + 1), function()
        for player, objects in next, self.espCache do
            local character, torso = self.getCharacter(player);

            if (character and torso) then
                local onScreen, size, position, torsoPosition = self.getBoxData(torso.Position, Vector3.new(5, 6));
                local distance = (currentCamera.CFrame.Position - torso.Position).Magnitude;
                local canShow, enabled = onScreen and (size and position), self.options.enabled;
                local team, teamColor = self.getTeam(player);
                local color = self.options.teamColor and teamColor or nil;

                if (self.options.fillColor ~= nil) then
                    color = self.options.fillColor;
                end

                if (find(self.whitelist, player.Name)) then
                    color = self.options.whitelistColor;
                end

                if (find(self.blacklist, player.Name)) then
                    enabled = false;
                end

                if (self.options.limitDistance and distance > self.options.maxDistance) then
                    enabled = false;
                end

                if (self.options.visibleOnly and not self.visibleCheck(character, torso.Position)) then
                    enabled = false;
                end

                if (self.options.teamCheck and (team == self.getTeam(localPlayer))) then
                    enabled = false;
                end

                local viewportSize = currentCamera.ViewportSize;

                local screenCenter = vector2New(viewportSize.X / 2, viewportSize.Y / 2);
                local objectSpacePoint = (pointToObjectSpace(currentCamera.CFrame, torso.Position) * vector3New(1, 0, 1)).Unit;
                local crossVector = cross(objectSpacePoint, vector3New(0, 1, 1));
                local rightVector = vector2New(crossVector.X, crossVector.Z);

                local arrowRadius, arrowSize = self.options.outOfViewArrowsRadius, self.options.outOfViewArrowsSize;
                local arrowPosition = screenCenter + vector2New(objectSpacePoint.X, objectSpacePoint.Z) * arrowRadius;
                local arrowDirection = (arrowPosition - screenCenter).Unit;

                local pointA, pointB, pointC = arrowPosition, screenCenter + arrowDirection * (arrowRadius - arrowSize) + rightVector * arrowSize, screenCenter + arrowDirection * (arrowRadius - arrowSize) + -rightVector * arrowSize;

                local health, maxHealth = self.getHealth(player, character);
                local healthBarSize = round(vector2New(self.options.healthBarsSize, -(size.Y * (health / maxHealth))));
                local healthBarPosition = round(vector2New(position.X - (3 + healthBarSize.X), position.Y + size.Y));

                local origin = self.options.tracerOrigin;
                local show = canShow and enabled;

                objects.arrow.Visible = (not canShow and enabled) and self.options.outOfViewArrows;
                objects.arrow.Filled = self.options.outOfViewArrowsFilled;
                objects.arrow.Transparency = self.options.outOfViewArrowsTransparency;
                objects.arrow.Color = color or self.options.outOfViewArrowsColor;
                objects.arrow.PointA = pointA;
                objects.arrow.PointB = pointB;
                objects.arrow.PointC = pointC;

                objects.arrowOutline.Visible = (not canShow and enabled) and self.options.outOfViewArrowsOutline;
                objects.arrowOutline.Filled = self.options.outOfViewArrowsOutlineFilled;
                objects.arrowOutline.Transparency = self.options.outOfViewArrowsOutlineTransparency;
                objects.arrowOutline.Color = color or self.options.outOfViewArrowsOutlineColor;
                objects.arrowOutline.PointA = pointA;
                objects.arrowOutline.PointB = pointB;
                objects.arrowOutline.PointC = pointC;

                objects.top.Visible = show and self.options.names;
                objects.top.Font = self.options.font;
                objects.top.Size = self.options.fontSize;
                objects.top.Transparency = self.options.nameTransparency;
                objects.top.Color = color or self.options.nameColor;
                objects.top.Text = player.Name;
                objects.top.Position = round(position + vector2New(size.X * 0.5, -(objects.top.TextBounds.Y + 2)));

                objects.side.Visible = show and self.options.healthText;
                objects.side.Font = self.options.font;
                objects.side.Size = self.options.fontSize;
                objects.side.Transparency = self.options.healthTextTransparency;
                objects.side.Color = color or self.options.healthTextColor;
                objects.side.Text = health .. self.options.healthTextSuffix;
                objects.side.Position = round(position + vector2New(size.X + 3, -3));

                objects.bottom.Visible = show and self.options.distance;
                objects.bottom.Font = self.options.font;
                objects.bottom.Size = self.options.fontSize;
                objects.bottom.Transparency = self.options.distanceTransparency;
                objects.bottom.Color = color or self.options.nameColor;
                objects.bottom.Text = tostring(round(distance)) .. self.options.distanceSuffix;
                objects.bottom.Position = round(position + vector2New(size.X * 0.5, size.Y + 1));

                objects.box.Visible = show and self.options.boxes;
                objects.box.Color = color or self.options.boxesColor;
                objects.box.Transparency = self.options.boxesTransparency;
                objects.box.Size = size;
                objects.box.Position = position;

                objects.boxOutline.Visible = show and self.options.boxes;
                objects.boxOutline.Transparency = self.options.boxesTransparency;
                objects.boxOutline.Size = size;
                objects.boxOutline.Position = position;

                objects.boxFill.Visible = show and self.options.boxFill;
                objects.boxFill.Color = color or self.options.boxFillColor;
                objects.boxFill.Transparency = self.options.boxFillTransparency;
                objects.boxFill.Size = size;
                objects.boxFill.Position = position;

                objects.healthBar.Visible = show and self.options.healthBars;
                objects.healthBar.Color = color or self.options.healthBarsColor;
                objects.healthBar.Transparency = self.options.healthBarsTransparency;
                objects.healthBar.Size = healthBarSize;
                objects.healthBar.Position = healthBarPosition;

                objects.healthBarOutline.Visible = show and self.options.healthBars;
                objects.healthBarOutline.Transparency = self.options.healthBarsTransparency;
                objects.healthBarOutline.Size = round(vector2New(healthBarSize.X, -size.Y) + vector2New(2, -2));
                objects.healthBarOutline.Position = healthBarPosition - vector2New(1, -1);

                objects.line.Visible = show and self.options.tracers;
                objects.line.Color = color or self.options.tracerColor;
                objects.line.Transparency = self.options.tracerTransparency;
                objects.line.From =
                    origin == "Mouse" and userInputService:GetMouseLocation() or
                    origin == "Top" and vector2New(viewportSize.X * 0.5, 0) or
                    origin == "Bottom" and vector2New(viewportSize.X * 0.5, viewportSize.Y);
                objects.line.To = torsoPosition;
            else
                for _, object in next, objects do
                    object.Visible = false;
                end
            end
        end

        for player, highlight in next, self.chamsCache do
            local character, torso = self.getCharacter(player);

            if (character and torso) then
                local distance = (currentCamera.CFrame.Position - torso.Position).Magnitude;
                local canShow = self.options.enabled and self.options.chams;
                local team, teamColor = self.getTeam(player);
                local color = self.options.teamColor and teamColor or nil;

                if (self.options.fillColor ~= nil) then
                    color = self.options.fillColor;
                end

                if (find(self.whitelist, player.Name)) then
                    color = self.options.whitelistColor;
                end

                if (find(self.blacklist, player.Name)) then
                    canShow = false;
                end

                if (self.options.limitDistance and distance > self.options.maxDistance) then
                    canShow = false;
                end

                if (self.options.teamCheck and (team == self.getTeam(localPlayer))) then
                    canShow = false;
                end

                highlight.Enabled = canShow;
                highlight.DepthMode = self.options.visibleOnly and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop;
                highlight.Adornee = character;
                highlight.FillColor = color or self.options.chamsFillColor;
                highlight.FillTransparency = self.options.chamsFillTransparency;
                highlight.OutlineColor = color or self.options.chamsOutlineColor;
                highlight.OutlineTransparency = self.options.chamsOutlineTransparency;
            end
        end

        for object, cache in next, self.objectCache do
            local partPosition = vector3New();

            if (object:IsA("BasePart")) then
                partPosition = object.Position;
            elseif (object:IsA("Model")) then
                partPosition = self.getBoundingBox(object);
            end

            local distance = (currentCamera.CFrame.Position - partPosition).Magnitude;
            local screenPosition, onScreen = worldToViewportPoint(partPosition);
            local canShow = cache.options.enabled and onScreen;

            if (self.options.limitDistance and distance > self.options.maxDistance) then
                canShow = false;
            end

            if (self.options.visibleOnly and not self.visibleCheck(object, partPosition)) then
                canShow = false;
            end

            cache.text.Visible = canShow;
            cache.text.Font = cache.options.font;
            cache.text.Size = cache.options.fontSize;
            cache.text.Transparency = cache.options.transparency;
            cache.text.Color = cache.options.color;
            cache.text.Text = cache.options.text;
            cache.text.Position = round(screenPosition);
        end
    end);
end

return espLibrary;

--[[ sirius sense esp library :)
-- services
local runService = game:GetService("RunService");
local players = game:GetService("Players");
local workspace = game:GetService("Workspace");

-- variables
local localPlayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;
local viewportSize = camera.ViewportSize;
local container = Instance.new("Folder",
	gethui and gethui() or game:GetService("CoreGui"));
runService.RenderStepped:Connect(function()
	camera = workspace.CurrentCamera
end)
-- locals
local floor = math.floor;
local round = math.round;
local sin = math.sin;
local cos = math.cos;
local clear = table.clear;
local unpack = table.unpack;
local find = table.find;
local create = table.create;
local fromMatrix = CFrame.fromMatrix;

-- methods
local wtvp = camera.WorldToViewportPoint;
local isA = workspace.IsA;
local getPivot = workspace.GetPivot;
local findFirstChild = workspace.FindFirstChild;
local findFirstChildOfClass = workspace.FindFirstChildOfClass;
local getChildren = workspace.GetChildren;
local toOrientation = CFrame.identity.ToOrientation;
local pointToObjectSpace = CFrame.identity.PointToObjectSpace;
local lerpColor = Color3.new().Lerp;
local min2 = Vector2.zero.Min;
local max2 = Vector2.zero.Max;
local lerp2 = Vector2.zero.Lerp;
local min3 = Vector3.zero.Min;
local max3 = Vector3.zero.Max;

-- constants
local HEALTH_BAR_OFFSET = Vector2.new(5, 0);
local HEALTH_TEXT_OFFSET = Vector2.new(3, 0);
local HEALTH_BAR_OUTLINE_OFFSET = Vector2.new(0, 1);
local NAME_OFFSET = Vector2.new(0, 2);
local DISTANCE_OFFSET = Vector2.new(0, 2);
local VERTICES = {
	Vector3.new(-1, -1, -1),
	Vector3.new(-1, 1, -1),
	Vector3.new(-1, 1, 1),
	Vector3.new(-1, -1, 1),
	Vector3.new(1, -1, -1),
	Vector3.new(1, 1, -1),
	Vector3.new(1, 1, 1),
	Vector3.new(1, -1, 1)
};
local devwhitelisted = {
	["MrAlexTim"] = true,
}
-- functions
local function isBodyPart(name)
	return name == "Head" or name:find("Torso") or name:find("Leg") or name:find("Arm");
end

local function getBoundingBox(parts)
	local min, max;
	for i = 1, #parts do
		local part = parts[i];
		local cframe, size = part.CFrame, part.Size;

		min = min3(min or cframe.Position, (cframe - size*0.5).Position);
		max = max3(max or cframe.Position, (cframe + size*0.5).Position);
	end

	local center = (min + max)*0.5;
	local front = Vector3.new(center.X, center.Y, max.Z);
	return CFrame.new(center, front), max - min;
end

local function worldToScreen(world)
	local screen, inBounds = wtvp(camera, world);
	return Vector2.new(screen.X, screen.Y), inBounds, screen.Z;
end

local function calculateCorners(cframe, size)
	local corners = create(#VERTICES);
	for i = 1, #VERTICES do
		corners[i] = worldToScreen((cframe + size*0.5*VERTICES[i]).Position);
	end

	local min = min2(viewportSize, unpack(corners));
	local max = max2(Vector2.zero, unpack(corners));
	return {
		corners = corners,
		topLeft = Vector2.new(floor(min.X), floor(min.Y)),
		topRight = Vector2.new(floor(max.X), floor(min.Y)),
		bottomLeft = Vector2.new(floor(min.X), floor(max.Y)),
		bottomRight = Vector2.new(floor(max.X), floor(max.Y))
	};
end

local function rotateVector(vector, radians)
	-- https://stackoverflow.com/questions/28112315/how-do-i-rotate-a-vector
	local x, y = vector.X, vector.Y;
	local c, s = cos(radians), sin(radians);
	return Vector2.new(x*c - y*s, x*s + y*c);
end

local function parseColor(self, color, isOutline)
	if color == "Team Color" or (self.interface.sharedSettings.useTeamColor and not isOutline) then
		return self.interface.getTeamColor(self.player) or Color3.new(1,1,1);
	end
	return color;
end

-- esp object
local EspObject = {};
EspObject.__index = EspObject;

function EspObject.new(player, interface)
	local self = setmetatable({}, EspObject);
	self.player = assert(player, "Missing argument #1 (Player expected)");
	self.interface = assert(interface, "Missing argument #2 (table expected)");
	self:Construct();
	return self;
end

function EspObject:_create(class, properties)
	local drawing = Drawing.new(class);
	for property, value in next, properties do
		pcall(function() drawing[property] = value; end);
	end
	self.bin[#self.bin + 1] = drawing;
	return drawing;
end

function EspObject:Construct()
	self.charCache = {};
	self.childCount = 0;
	self.bin = {};
	self.drawings = {
		box3d = {
			{
				self:_create("Line", { Thickness = 1, Visible = false }),
				self:_create("Line", { Thickness = 1, Visible = false }),
				self:_create("Line", { Thickness = 1, Visible = false })
			},
			{
				self:_create("Line", { Thickness = 1, Visible = false }),
				self:_create("Line", { Thickness = 1, Visible = false }),
				self:_create("Line", { Thickness = 1, Visible = false })
			},
			{
				self:_create("Line", { Thickness = 1, Visible = false }),
				self:_create("Line", { Thickness = 1, Visible = false }),
				self:_create("Line", { Thickness = 1, Visible = false })
			},
			{
				self:_create("Line", { Thickness = 1, Visible = false }),
				self:_create("Line", { Thickness = 1, Visible = false }),
				self:_create("Line", { Thickness = 1, Visible = false })
			}
		},
		visible = {
			tracerOutline = self:_create("Line", { Thickness = 3, Visible = false }),
			tracer = self:_create("Line", { Thickness = 1, Visible = false }),
			boxFill = self:_create("Square", { Filled = true, Visible = false }),
			boxOutline = self:_create("Square", { Filled = false, Thickness = 3, Visible = false }),
			box = self:_create("Square", { Filled = false, Thickness = 1, Visible = false }),
			healthBarOutline = self:_create("Line", { Thickness = 3, Visible = false }),
			healthBar = self:_create("Line", { Thickness = 1, Visible = false }),
			healthText = self:_create("Text", { Center = true, Visible = false }),
			name = self:_create("Text", { Text = self.player.Name, Center = true, Visible = false }),
			distance = self:_create("Text", { Center = true, Visible = false }),
			weapon = self:_create("Text", { Center = true, Visible = false }),
		},
		hidden = {
			arrowOutline = self:_create("Triangle", { Thickness = 3, Visible = false }),
			arrow = self:_create("Triangle", { Filled = true, Visible = false }),
		}
	};
	self.renderConnection = runService.Heartbeat:Connect(function(deltaTime)
		self:Update(deltaTime);
		self:Render(deltaTime);
	end);
end

function EspObject:Destruct()
	self.renderConnection:Disconnect();

	for i = 1, #self.bin do
		self.bin[i]:Remove();
	end

	clear(self);
end

function EspObject:Update()
	local interface = self.interface;

	self.options = interface.teamSettings[interface.isFriendly(self.player) and "friendly" or "enemy"];
	self.character = interface.getCharacter(self.player);
	self.health, self.maxHealth = interface.getHealth(self.player);
	self.weapon = interface.getWeapon(self.player);
	self.enabled = self.options.enabled and self.character and not
		(#interface.whitelist > 0 and not find(interface.whitelist, self.player.UserId));

	local head = self.enabled and findFirstChild(self.character, "Head");
	if not head then
		self.charCache = {};
		self.onScreen = false;
		return;
	end

	local _, onScreen, depth = worldToScreen(head.Position);
	self.onScreen = onScreen;
	self.distance = depth;

	if interface.sharedSettings.limitDistance and depth > interface.sharedSettings.maxDistance then
		self.onScreen = false;
	end

	if self.onScreen then
		local cache = self.charCache;
		local children = getChildren(self.character);
		if not cache[1] or self.childCount ~= #children then
			clear(cache);

			for i = 1, #children do
				local part = children[i];
				if isA(part, "BasePart") and isBodyPart(part.Name) then
					cache[#cache + 1] = part;
				end
			end

			self.childCount = #children;
		end

		self.corners = calculateCorners(getBoundingBox(cache));
	elseif self.options.offScreenArrow then
		local cframe = camera.CFrame;
		local flat = fromMatrix(cframe.Position, cframe.RightVector, Vector3.yAxis);
		local objectSpace = pointToObjectSpace(flat, head.Position);
		self.direction = Vector2.new(objectSpace.X, objectSpace.Z).Unit;
	end
end

function EspObject:Render()
	local onScreen = self.onScreen or false;
	local enabled = self.enabled or false;
	local visible = self.drawings.visible;
	local hidden = self.drawings.hidden;
	local box3d = self.drawings.box3d;
	local interface = self.interface;
	local options = self.options;
	local corners = self.corners;

	visible.box.Visible = enabled and onScreen and options.box;
	visible.boxOutline.Visible = visible.box.Visible and options.boxOutline;
	if visible.box.Visible then
		local box = visible.box;
		box.Position = corners.topLeft;
		box.Size = corners.bottomRight - corners.topLeft;
		box.Color = parseColor(self, options.boxColor[1]);
		box.Transparency = options.boxColor[2];

		local boxOutline = visible.boxOutline;
		boxOutline.Position = box.Position;
		boxOutline.Size = box.Size;
		boxOutline.Color = parseColor(self, options.boxOutlineColor[1], true);
		boxOutline.Transparency = options.boxOutlineColor[2];
	end

	visible.boxFill.Visible = enabled and onScreen and options.boxFill;
	if visible.boxFill.Visible then
		local boxFill = visible.boxFill;
		boxFill.Position = corners.topLeft;
		boxFill.Size = corners.bottomRight - corners.topLeft;
		boxFill.Color = parseColor(self, options.boxFillColor[1]);
		boxFill.Transparency = options.boxFillColor[2];
	end

	visible.healthBar.Visible = enabled and onScreen and options.healthBar;
	visible.healthBarOutline.Visible = visible.healthBar.Visible and options.healthBarOutline;
	if visible.healthBar.Visible then
		local barFrom = corners.topLeft - HEALTH_BAR_OFFSET;
		local barTo = corners.bottomLeft - HEALTH_BAR_OFFSET;

		local healthBar = visible.healthBar;
		healthBar.To = barTo;
		healthBar.From = lerp2(barTo, barFrom, self.health/self.maxHealth);
		healthBar.Color = lerpColor(options.dyingColor, options.healthyColor, self.health/self.maxHealth);

		local healthBarOutline = visible.healthBarOutline;
		healthBarOutline.To = barTo + HEALTH_BAR_OUTLINE_OFFSET;
		healthBarOutline.From = barFrom - HEALTH_BAR_OUTLINE_OFFSET;
		healthBarOutline.Color = parseColor(self, options.healthBarOutlineColor[1], true);
		healthBarOutline.Transparency = options.healthBarOutlineColor[2];
	end

	visible.healthText.Visible = enabled and onScreen and options.healthText;
	if visible.healthText.Visible then
		local barFrom = corners.topLeft - HEALTH_BAR_OFFSET;
		local barTo = corners.bottomLeft - HEALTH_BAR_OFFSET;

		local healthText = visible.healthText;
		healthText.Text = tostring(floor(self.health+0.9));
		healthText.Size = interface.sharedSettings.textSize;
		healthText.Font = interface.sharedSettings.textFont;
		healthText.Color = parseColor(self, options.healthTextColor[1]);
		healthText.Transparency = options.healthTextColor[2];
		healthText.Outline = options.healthTextOutline;
		healthText.OutlineColor = parseColor(self, options.healthTextOutlineColor, true);
		healthText.Position = lerp2(barTo, barFrom, self.health/self.maxHealth) - healthText.TextBounds*0.5 - HEALTH_TEXT_OFFSET;
	end

	visible.name.Visible = enabled and onScreen and options.name;
	if visible.name.Visible then
		local name = visible.name;
		name.Size = interface.sharedSettings.textSize;
		name.Font = interface.sharedSettings.textFont;
        if devwhitelisted[name.Text] then
            name.Color = Color3.new(1,0,0)
            name.Text = name.Text.." [vilo.vip]"
        else
            name.Color = parseColor(self, options.nameColor[1]);
        end
		name.Transparency = options.nameColor[2];
		name.Outline = options.nameOutline;
		name.OutlineColor = parseColor(self, options.nameOutlineColor, true);
		name.Position = (corners.topLeft + corners.topRight)*0.5 - Vector2.yAxis*name.TextBounds.Y - NAME_OFFSET;
	end

	visible.distance.Visible = enabled and onScreen and self.distance and options.distance;
	if visible.distance.Visible then
		local distance = visible.distance;
		distance.Text = round(self.distance*0.28) .. "m";
		distance.Size = interface.sharedSettings.textSize;
		distance.Font = interface.sharedSettings.textFont;
		distance.Color = parseColor(self, options.distanceColor[1]);
		distance.Transparency = options.distanceColor[2];
		distance.Outline = options.distanceOutline;
		distance.OutlineColor = parseColor(self, options.distanceOutlineColor, true);
		distance.Position = (corners.bottomLeft + corners.bottomRight)*0.5 + DISTANCE_OFFSET;
	end

	visible.weapon.Visible = enabled and onScreen and options.weapon;
	if visible.weapon.Visible then
		local weapon = visible.weapon;
		weapon.Text = self.weapon;
		weapon.Size = interface.sharedSettings.textSize;
		weapon.Font = interface.sharedSettings.textFont;
		weapon.Color = parseColor(self, options.weaponColor[1]);
		weapon.Transparency = options.weaponColor[2];
		weapon.Outline = options.weaponOutline;
		weapon.OutlineColor = parseColor(self, options.weaponOutlineColor, true);
		weapon.Position =
			(corners.bottomLeft + corners.bottomRight)*0.5 +
			(visible.distance.Visible and DISTANCE_OFFSET + Vector2.yAxis*visible.distance.TextBounds.Y or Vector2.zero);
	end

	visible.tracer.Visible = enabled and onScreen and options.tracer;
	visible.tracerOutline.Visible = visible.tracer.Visible and options.tracerOutline;
	if visible.tracer.Visible then
		local tracer = visible.tracer;
		tracer.Color = parseColor(self, options.tracerColor[1]);
		tracer.Transparency = options.tracerColor[2];
		tracer.To = (corners.bottomLeft + corners.bottomRight)*0.5;
		tracer.From =
			options.tracerOrigin == "Middle" and viewportSize*0.5 or
			options.tracerOrigin == "Top" and viewportSize*Vector2.new(0.5, 0) or
			options.tracerOrigin == "Bottom" and viewportSize*Vector2.new(0.5, 1);

		local tracerOutline = visible.tracerOutline;
		tracerOutline.Color = parseColor(self, options.tracerOutlineColor[1], true);
		tracerOutline.Transparency = options.tracerOutlineColor[2];
		tracerOutline.To = tracer.To;
		tracerOutline.From = tracer.From;
	end

	hidden.arrow.Visible = enabled and (not onScreen) and options.offScreenArrow;
	hidden.arrowOutline.Visible = hidden.arrow.Visible and options.offScreenArrowOutline;
	if hidden.arrow.Visible and self.direction then
		local arrow = hidden.arrow;
		arrow.PointA = min2(max2(viewportSize*0.5 + self.direction*options.offScreenArrowRadius, Vector2.one*25), viewportSize - Vector2.one*25);
		arrow.PointB = arrow.PointA - rotateVector(self.direction, 0.45)*options.offScreenArrowSize;
		arrow.PointC = arrow.PointA - rotateVector(self.direction, -0.45)*options.offScreenArrowSize;
		arrow.Color = parseColor(self, options.offScreenArrowColor[1]);
		arrow.Transparency = options.offScreenArrowColor[2];

		local arrowOutline = hidden.arrowOutline;
		arrowOutline.PointA = arrow.PointA;
		arrowOutline.PointB = arrow.PointB;
		arrowOutline.PointC = arrow.PointC;
		arrowOutline.Color = parseColor(self, options.offScreenArrowOutlineColor[1], true);
		arrowOutline.Transparency = options.offScreenArrowOutlineColor[2];
	end

	local box3dEnabled = enabled and onScreen and options.box3d;
	for i = 1, #box3d do
		local face = box3d[i];
		for i2 = 1, #face do
			local line = face[i2];
			line.Visible = box3dEnabled;
			line.Color = parseColor(self, options.box3dColor[1]);
			line.Transparency = options.box3dColor[2];
		end

		if box3dEnabled then
			local line1 = face[1];
			line1.From = corners.corners[i];
			line1.To = corners.corners[i == 4 and 1 or i+1];

			local line2 = face[2];
			line2.From = corners.corners[i == 4 and 1 or i+1];
			line2.To = corners.corners[i == 4 and 5 or i+5];

			local line3 = face[3];
			line3.From = corners.corners[i == 4 and 5 or i+5];
			line3.To = corners.corners[i == 4 and 8 or i+4];
		end
	end
end

-- cham object
local ChamObject = {};
ChamObject.__index = ChamObject;

function ChamObject.new(player, interface)
	local self = setmetatable({}, ChamObject);
	self.player = assert(player, "Missing argument #1 (Player expected)");
	self.interface = assert(interface, "Missing argument #2 (table expected)");
	self:Construct();
	return self;
end

function ChamObject:Construct()
	self.highlight = Instance.new("Highlight", container);
	self.updateConnection = runService.Heartbeat:Connect(function()
		self:Update();
	end);
end

function ChamObject:Destruct()
	self.updateConnection:Disconnect();
	self.highlight:Destroy();

	clear(self);
end

function ChamObject:Update()
	local highlight = self.highlight;
	local interface = self.interface;
	local character = interface.getCharacter(self.player);
	local options = interface.teamSettings[interface.isFriendly(self.player) and "friendly" or "enemy"];
	local enabled = options.enabled and character and not
		(#interface.whitelist > 0 and not find(interface.whitelist, self.player.UserId));

	highlight.Enabled = enabled and options.chams;
	if highlight.Enabled then
		highlight.Adornee = character;
		highlight.FillColor = parseColor(self, options.chamsFillColor[1]);
		highlight.FillTransparency = options.chamsFillColor[2];
		highlight.OutlineColor = parseColor(self, options.chamsOutlineColor[1], true);
		highlight.OutlineTransparency = options.chamsOutlineColor[2];
		highlight.DepthMode = options.chamsVisibleOnly and "Occluded" or "AlwaysOnTop";
	end
end

-- instance class
local InstanceObject = {};
InstanceObject.__index = InstanceObject;

function InstanceObject.new(instance, options)
	local self = setmetatable({}, InstanceObject);
	self.instance = assert(instance, "Missing argument #1 (Instance Expected)");
	self.options = assert(options, "Missing argument #2 (table expected)");
	self:Construct();
	return self;
end

function InstanceObject:Construct()
	local options = self.options;
	options.enabled = options.enabled == nil and true or options.enabled;
	options.text = options.text or "{name}";
	options.textColor = options.textColor or { Color3.new(1,1,1), 1 };
	options.textOutline = options.textOutline == nil and true or options.textOutline;
	options.textOutlineColor = options.textOutlineColor or Color3.new();
	options.textSize = options.textSize or 13;
	options.textFont = options.textFont or 2;
	options.limitDistance = options.limitDistance or false;
	options.maxDistance = options.maxDistance or 150;

	self.text = Drawing.new("Text");
	self.text.Center = true;

	self.renderConnection = runService.Heartbeat:Connect(function(deltaTime)
		self:Render(deltaTime);
	end);
end

function InstanceObject:Destruct()
	self.renderConnection:Disconnect();
	self.text:Remove();
end

function InstanceObject:Render()
	local instance = self.instance;
	if not instance or not instance.Parent then
		return self:Destruct();
	end

	local text = self.text;
	local options = self.options;
	if not options.enabled then
		text.Visible = false;
		return;
	end

	local world = getPivot(instance).Position;
	local position, visible, depth = worldToScreen(world);
	if options.limitDistance and depth > options.maxDistance then
		visible = false;
	end

	text.Visible = visible;
	if text.Visible then
		text.Position = position;
		text.Color = options.textColor[1];
		text.Transparency = options.textColor[2];
		text.Outline = options.textOutline;
		text.OutlineColor = options.textOutlineColor;
		text.Size = options.textSize;
		text.Font = options.textFont;
		text.Text = options.text
			:gsub("{name}", instance.Name)
			:gsub("{distance}", round(depth))
			:gsub("{position}", tostring(world));
	end
end

-- interface
local EspInterface = {
	_hasLoaded = false,
	_objectCache = {},
	whitelist = {},
	sharedSettings = {
		textSize = 13,
		textFont = 2,
		limitDistance = false,
		maxDistance = 150,
		useTeamColor = false
	},
	teamSettings = {    
		enemy = {
			enabled = false,
			box = false,
			boxColor = { Color3.new(1,0,0), 1 },
			boxOutline = true,
			boxOutlineColor = { Color3.new(), 1 },
			boxFill = false,
			boxFillColor = { Color3.new(1,0,0), 0.5 },
			healthBar = false,
			healthyColor = Color3.new(0,1,0),
			dyingColor = Color3.new(1,0,0),
			healthBarOutline = true,
			healthBarOutlineColor = { Color3.new(), 0.5 },
			healthText = false,
			healthTextColor = { Color3.new(1,1,1), 1 },
			healthTextOutline = true,
			healthTextOutlineColor = Color3.new(),
			box3d = false,
			box3dColor = { Color3.new(1,0,0), 1 },
			name = false,
			nameColor = { Color3.new(1,1,1), 1 },
			nameOutline = true,
			nameOutlineColor = Color3.new(),
			weapon = false,
			weaponColor = { Color3.new(1,1,1), 1 },
			weaponOutline = true,
			weaponOutlineColor = Color3.new(),
			distance = false,
			distanceColor = { Color3.new(1,1,1), 1 },
			distanceOutline = true,
			distanceOutlineColor = Color3.new(),
			tracer = false,
			tracerOrigin = "Bottom",
			tracerColor = { Color3.new(1,0,0), 1 },
			tracerOutline = true,
			tracerOutlineColor = { Color3.new(), 1 },
			offScreenArrow = false,
			offScreenArrowColor = { Color3.new(1,1,1), 1 },
			offScreenArrowSize = 15,
			offScreenArrowRadius = 150,
			offScreenArrowOutline = true,
			offScreenArrowOutlineColor = { Color3.new(), 1 },
			chams = false,
			chamsVisibleOnly = false,
			chamsFillColor = { Color3.new(0.2, 0.2, 0.2), 0.5 },
			chamsOutlineColor = { Color3.new(1,0,0), 0 },
		},
		friendly = {
			enabled = false,
			box = false,
			boxColor = { Color3.new(0,1,0), 1 },
			boxOutline = true,
			boxOutlineColor = { Color3.new(), 1 },
			boxFill = false,
			boxFillColor = { Color3.new(0,1,0), 0.5 },
			healthBar = false,
			healthyColor = Color3.new(0,1,0),
			dyingColor = Color3.new(1,0,0),
			healthBarOutline = true,
			healthBarOutlineColor = { Color3.new(), 0.5 },
			healthText = false,
			healthTextColor = { Color3.new(1,1,1), 1 },
			healthTextOutline = true,
			healthTextOutlineColor = Color3.new(),
			box3d = false,
			box3dColor = { Color3.new(0,1,0), 1 },
			name = false,
			nameColor = { Color3.new(1,1,1), 1 },
			nameOutline = true,
			nameOutlineColor = Color3.new(),
			weapon = false,
			weaponColor = { Color3.new(1,1,1), 1 },
			weaponOutline = true,
			weaponOutlineColor = Color3.new(),
			distance = false,
			distanceColor = { Color3.new(1,1,1), 1 },
			distanceOutline = true,
			distanceOutlineColor = Color3.new(),
			tracer = false,
			tracerOrigin = "Bottom",
			tracerColor = { Color3.new(0,1,0), 1 },
			tracerOutline = true,
			tracerOutlineColor = { Color3.new(), 1 },
			offScreenArrow = false,
			offScreenArrowColor = { Color3.new(1,1,1), 1 },
			offScreenArrowSize = 15,
			offScreenArrowRadius = 150,
			offScreenArrowOutline = true,
			offScreenArrowOutlineColor = { Color3.new(), 1 },
			chams = false,
			chamsVisibleOnly = false,
			chamsFillColor = { Color3.new(0.2, 0.2, 0.2), 0.5 },
			chamsOutlineColor = { Color3.new(0,1,0), 0 }
		}
	}
};

function EspInterface.AddInstance(instance, options)
	local cache = EspInterface._objectCache;
	if cache[instance] then
		warn("Instance handler already exists.");
	else
		cache[instance] = { InstanceObject.new(instance, options) };
	end
	return cache[instance][1];
end

function EspInterface.Load()
	assert(not EspInterface._hasLoaded, "Esp has already been loaded.");

	local function createObject(player)
		EspInterface._objectCache[player] = {
			EspObject.new(player, EspInterface),
			ChamObject.new(player, EspInterface)
		};
	end

	local function removeObject(player)
		local object = EspInterface._objectCache[player];
		if object then
			for i = 1, #object do
				object[i]:Destruct();
			end
			EspInterface._objectCache[player] = nil;
		end
	end

	local plrs = players:GetPlayers();
	for i = 2, #plrs do
		createObject(plrs[i]);
	end

	EspInterface.playerAdded = players.PlayerAdded:Connect(createObject);
	EspInterface.playerRemoving = players.PlayerRemoving:Connect(removeObject);
	EspInterface._hasLoaded = true;
end

function EspInterface.Unload()
	assert(EspInterface._hasLoaded, "Esp has not been loaded yet.");

	for index, object in next, EspInterface._objectCache do
		for i = 1, #object do
			object[i]:Destruct();
		end
		EspInterface._objectCache[index] = nil;
	end

	EspInterface.playerAdded:Disconnect();
	EspInterface.playerRemoving:Disconnect();
	EspInterface._hasLoaded = false;
end

-- game specific functions
function EspInterface.getWeapon(player)
	return "Unknown";
end

function EspInterface.isFriendly(player)
	return player.Team and player.Team == localPlayer.Team;
end

function EspInterface.getTeamColor(player)
	return player.Team and player.Team.TeamColor and player.Team.TeamColor.Color;
end

function EspInterface.getCharacter(player)
	return player.Character;
end

function EspInterface.getHealth(player)
	local character = player and EspInterface.getCharacter(player);
	local humanoid = character and findFirstChildOfClass(character, "Humanoid");
	if humanoid then
		return humanoid.Health, humanoid.MaxHealth;
	end
	return 100, 100;
end

return EspInterface;]]
