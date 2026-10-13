-- Utility function to convert hex string to number
local function hexToNum(hex)
    return tonumber(hex:sub(2), 16);
end;

-- Utility function to ensure color is in numeric format
local function ensureColorNum(color)
    if type(color) == "string" and color:sub(1, 1) == "#" then
        return hexToNum(color);
    end;
    return color;
end;

local function mergeColors(color1, color2, weight)
    weight = weight or 0.5;
    color1 = ensureColorNum(color1);
    color2 = ensureColorNum(color2);

    -- Extract RGB components
    local r1 = math.floor(color1 / 0x10000);
    local g1 = math.floor((color1 % 0x10000) / 0x100);
    local b1 = color1 % 0x100;

    local r2 = math.floor(color2 / 0x10000);
    local g2 = math.floor((color2 % 0x10000) / 0x100);
    local b2 = color2 % 0x100;

    -- Merge components
    local r = math.floor(r1 * weight + r2 * (1 - weight));
    local g = math.floor(g1 * weight + g2 * (1 - weight));
    local b = math.floor(b1 * weight + b2 * (1 - weight));

    return string.format("#%02X%02X%02X", r, g, b);
end;

local function darkenColor(color, amount)
    amount = amount or 0.1;

    if type(color) == "string" and color:sub(1, 1) == "#" then
        color = tonumber(color:sub(2), 16);
    end;

    local r = math.floor(color / 0x10000);
    local g = math.floor((color % 0x10000) / 0x100);
    local b = color % 0x100;

    r = math.max(math.floor(r * (1 - amount)), 0);
    g = math.max(math.floor(g * (1 - amount)), 0);
    b = math.max(math.floor(b * (1 - amount)), 0);

    return string.format("#%02X%02X%02X", r, g, b);
end;

local function lightenColor(color, amount)
    amount = amount or 0.1;
    if type(color) == "string" and color:sub(1, 1) == "#" then
        color = tonumber(color:sub(2), 16);
    end;

    local r = math.floor(color / 0x10000);
    local g = math.floor((color % 0x10000) / 0x100);
    local b = color % 0x100;

    r = math.min(math.floor(r + r * amount), 255);
    g = math.min(math.floor(g + g * amount), 255);
    b = math.min(math.floor(b + b * amount), 255);

    return string.format("#%02X%02X%02X", r, g, b);
end;

return {
    darkenColor = darkenColor,
    lightenColor = lightenColor,
    mergeColors = mergeColors
}
