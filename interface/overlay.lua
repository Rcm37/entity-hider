local Settings = require("settings")

local Overlay = {}

local fontCache = {}

local function fontByName(name)
    if id == nil or id.Font == nil then
        return nil
    end

    local ok, font = pcall(function()
        return id.Font[name]
    end)
    if ok then
        return font
    end
    return nil
end

local function overlayFont(settings)
    local size = Settings.ClampInt(settings.fontSize, 8, 40, 15)
    if fontCache[size] ~= nil then
        return fontCache[size]
    end

    fontCache[size] = fontByName("MUSEO_SANS_" .. tostring(size) .. "PT_REGULAR")
        or fontByName("MUSEO_SANS_15PT_REGULAR")
    return fontCache[size]
end

local function drawText(canvas, x, y, text, font, colour, outline)
    if outline then
        local black = Settings.RGBA("000000", 0.88)
        canvas:AddText(x - 1, y, text, font, black)
        canvas:AddText(x + 1, y, text, font, black)
        canvas:AddText(x, y - 1, text, font, black)
        canvas:AddText(x, y + 1, text, font, black)
    end
    canvas:AddText(x, y, text, font, colour)
end

local function drawFilledSquare(canvas, left, top, size, colour)
    canvas:AddTriangle(left, top, left + size, top, left + size, top + size, colour)
    canvas:AddTriangle(left, top, left + size, top + size, left, top + size, colour)
end

local function drawMarker(canvas, settings)
    local size = Settings.ClampInt(settings.boxSize, 8, 600, 50)
    local left = Settings.ClampInt(settings.boxX, 0, 5000, 780)
    local top = Settings.ClampInt(settings.boxY, 0, 5000, 172)
    local alpha = Settings.ClampInt(settings.menuOpacity, 30, 100, 70) / 100
    local fillColour = Settings.RGBA(settings.accentColor, alpha * 0.32)
    local lineColour = Settings.RGBA(settings.accentColor, alpha)

    if settings.boxStyle == "Filled" or settings.boxStyle == "Filled + outline" then
        drawFilledSquare(canvas, left, top, size, fillColour)
    end

    if settings.boxStyle == "Outline" or settings.boxStyle == "Filled + outline" then
        canvas:AddOutline(left, top, size, size, 2, lineColour)
    end

    if settings.showCross then
        local centerX = left + math.floor(size / 2)
        local centerY = top + math.floor(size / 2)
        canvas:AddLine(centerX - math.floor(size / 2), centerY, centerX + math.floor(size / 2), centerY, 2, lineColour)
        canvas:AddLine(centerX, centerY - math.floor(size / 2), centerX, centerY + math.floor(size / 2), 2, lineColour)
    end

    drawText(
        canvas,
        left + size + 8,
        top - 2,
        tostring(settings.message or ""),
        overlayFont(settings),
        Settings.RGBA(settings.labelColor, 0.98),
        settings.textOutline
    )
end

function Overlay.Mount(parent)
    if parent == nil then
        if log ~= nil then
            log("EntityHider: no UI parent supplied; overlay not mounted")
        end
        return nil
    end

    local canvas = ui.Canvas.new(parent)
    canvas:SetPos(0, 0)
    canvas:SetSize(0, 0, 1.0, 1.0)
    canvas.clickthrough = true

    return {
        canvas = canvas
    }
end

function Overlay.Destroy(ctx)
    if ctx ~= nil and ctx.canvas ~= nil then
        ctx.canvas:Destroy()
    end
end

function Overlay.Draw(ctx, settings)
    if ctx == nil or ctx.canvas == nil then
        return
    end

    pcall(function()
        ctx.canvas:MoveToFront()
    end)
    ctx.canvas:Clear()
    if not settings.enabled then
        return
    end

    drawMarker(ctx.canvas, settings)
end

return Overlay
