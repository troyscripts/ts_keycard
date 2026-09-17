-- Troy Scripts | ts_keycard | v1.1.4
local function log(message)
    print((TSL('update_troyscripts_ts_keycard')):format(message))
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
        log(TSL('update_updatecontrole_ongeldige_repository_of_branch_in_config'))
        return
    end
    local installed = parseVersion(current)
    if not installed then
        log(TSL('update_updatecontrole_ongeldige_lokale_versie_in_fxmanifest_lua'))
        return
    end

    local completed = false
    SetTimeout(15000, function()
        if completed then return end
        completed = true
        log(TSL('update_updatecontrole_github_heeft_niet_op_tijd_geantwoord'))
    end)
    local url = ('https://raw.githubusercontent.com/%s/%s/version.txt'):format(repository, branch)
    PerformHttpRequest(url, function(status, body)
        if completed then return end
        completed = true
        if status ~= 200 then
            log((TSL('update_updatecontrole_mislukt_http_controleer_repository_branch_en')):format(tostring(status)))
            return
        end
        local latest = parseVersion(body)
        if not latest then
            log(TSL('update_updatecontrole_version_txt_bevat_geen_geldige_stabiele'))
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
            log((TSL('update_nieuwe_versie_beschikbaar_geinstalleerd')):format(remoteVersion, current))
            log(('Download: https://github.com/%s'):format(repository))
        elseif comparison == 0 then
            log((TSL('update_je_gebruikt_de_nieuwste_versie')):format(current))
        else
            log((TSL('update_lokale_versie_is_nieuwer_dan_github')):format(current, remoteVersion))
        end
    end, 'GET', '', { ['Accept'] = 'text/plain' })
end)
