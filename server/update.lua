-- Troy Scripts | ts_keycard | v1.1.3
local function log(message)
    print(('^3[TroyScripts]^7 [ts_keycard] %s'):format(message))
end

local function parseVersion(value)
    if type(value) ~= 'string' or #value > 64 then return nil end
    local major, minor, patch = value:match('^%s*v?(%d+)%.(%d+)%.(%d+)%s*$')
    if not major then return nil end
    return { tonumber(major), tonumber(minor), tonumber(patch) }
end

CreateThread(function()
    local current = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
    -- Ook bruikbaar wanneer een bestaande config.lua behouden wordt.
    local settings = Config.UpdateCheck
    if settings == nil then
        settings = { Enabled = true, Repository = 'troyenrobin-source/ts_keycard', Branch = 'main' }
    end
    if type(settings) ~= 'table' or not settings.Enabled then return end

    local repository, branch = settings.Repository, settings.Branch
    if type(repository) ~= 'string'
        or not repository:match('^[%w_-][%w_.-]*/[%w_-][%w_.-]*$')
        or type(branch) ~= 'string' or not branch:match('^[%w_.-]+$') then
        log('Updatecontrole: ongeldige Repository of Branch in config.lua.')
        return
    end
    local installed = parseVersion(current)
    if not installed then
        log('Updatecontrole: ongeldige lokale versie in fxmanifest.lua.')
        return
    end

    local completed = false
    SetTimeout(15000, function()
        if completed then return end
        completed = true
        log('Updatecontrole: GitHub heeft niet op tijd geantwoord. Probeer bij een volgende start opnieuw.')
    end)
    local url = ('https://raw.githubusercontent.com/%s/%s/version.txt'):format(repository, branch)
    PerformHttpRequest(url, function(status, body)
        if completed then return end
        completed = true
        if status ~= 200 then
            log(('Updatecontrole mislukt (HTTP %s). Controleer repository, branch en version.txt.'):format(tostring(status)))
            return
        end
        local latest = parseVersion(body)
        if not latest then
            log('Updatecontrole: version.txt bevat geen geldige stabiele versie (bijvoorbeeld 1.1.3).')
            return
        end
        local comparison = 0
        for i = 1, 3 do
            if latest[i] ~= installed[i] then
                comparison = latest[i] > installed[i] and 1 or -1
                break
            end
        end
        local remoteVersion = table.concat(latest, '.')
        if comparison > 0 then
            log(('Nieuwe versie beschikbaar: %s (geinstalleerd: %s).'):format(remoteVersion, current))
            log(('Download: https://github.com/%s'):format(repository))
        elseif comparison == 0 then
            log(('Je gebruikt de nieuwste versie (%s).'):format(current))
        else
            log(('Lokale versie %s is nieuwer dan GitHub (%s).'):format(current, remoteVersion))
        end
    end, 'GET', '', { ['Accept'] = 'text/plain' })
end)
