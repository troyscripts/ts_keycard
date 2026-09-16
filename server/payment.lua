local inv = exports.ox_inventory
-- Defaults also support keeping a previously customised 1.1.0 config.
Config.CardPrice = Config.CardPrice or 10
Config.FreeCardMinimumGrade = Config.FreeCardMinimumGrade or 7
Config.FreeIssueMinimumGrade = Config.FreeIssueMinimumGrade or 7
Config.SocietyAccounts = Config.SocietyAccounts or { 'socity_police', 'society_police' }
KeycardPayment = {}

local function failure(message) return { ok = false, message = message } end
local function callable(value)
    if type(value) == 'function' then return true end
    if type(value) ~= 'table' then return false end
    local mt = getmetatable(value)
    return type(mt) == 'table' and mt.__call ~= nil
end
local function fetchAccount(name)
    local account
    TriggerEvent('esx_addonaccount:getSharedAccount', name, function(value) account = value end)
    return account
end
local function balance(account, name)
    local money = type(account) == 'table' and tonumber(account.money)
    if not money or money ~= money or math.abs(money) == math.huge then
        error(('Society %s heeft geen numeriek saldo (account=%s, money=%s)'):format(name, type(account), type(type(account) == 'table' and account.money or nil)))
    end
    return money
end
local function societyAccount()
    if GetResourceState('esx_addonaccount') ~= 'started' then return nil end
    for _, name in ipairs(Config.SocietyAccounts) do
        local account = fetchAccount(name)
        if account then
            balance(account, name)
            if not callable(account.addMoney) or not callable(account.removeMoney) then
                error(('Society %s heeft niet-aanroepbare betaalmethoden (addMoney=%s, removeMoney=%s)'):format(name, type(account.addMoney), type(account.removeMoney)))
            end
            -- Cross-resource account data is a snapshot. Request a fresh snapshot for
            -- each balance check; the referenced methods mutate the source resource.
            return {
                getBalance = function() return balance(fetchAccount(name), name) end,
                addMoney = function(amount) account.addMoney(amount) end,
                removeMoney = function(amount) account.removeMoney(amount) end
            }
        end
    end
end

function KeycardPayment.issue(owner, target, metadata, freeReplacement)
    local price = Config.CardPrice
    if type(price) ~= 'number' or price < 0 or price % 1 ~= 0 then return failure('Ongeldige kaartprijs. Controleer config.lua.') end
    local job = owner.getJob()
    if (tonumber(job.grade) or -1) >= Config.FreeCardMinimumGrade then price = 0 end
    if freeReplacement then price = 0 end
    local account, beforeCash, beforeSociety
    if price > 0 then
        account = societyAccount()
        if not account then return failure('De politie-societyrekening is niet beschikbaar. Er is niets betaald.') end
        beforeCash = owner.getMoney()
        if type(beforeCash) ~= 'number' or beforeCash < price then
            return failure(('De ontvanger heeft €%s contant nodig voor een nieuwe kaart.'):format(price))
        end
        beforeSociety = account.getBalance()
    end
    local slot = inv:GetEmptySlot(target)
    if not slot or not inv:CanCarryItem(target, Config.Item, 1, metadata) then
        return failure('De ontvanger heeft geen ruimte voor de kaart. Er is niets betaald.')
    end

    local cardAdded = false
    local ok, err = xpcall(function()
        local added, reason = inv:AddItem(target, Config.Item, 1, metadata, slot)
        if not added then error('Inventory: ' .. tostring(reason)) end
        cardAdded = true
        if price > 0 then
            owner.removeMoney(price, 'Politie sleutelkaart')
            if owner.getMoney() ~= beforeCash - price then error('Contante afschrijving niet bevestigd') end
            account.addMoney(price)
            if account.getBalance() ~= beforeSociety + price then error('Society-bijschrijving niet bevestigd') end
        end
    end, debug.traceback)
    if not ok then
        local rollbackOk, rollbackErr = pcall(function()
            if cardAdded then
                assert(inv:RemoveItem(target, Config.Item, 1, nil, slot), 'Kaart kon niet worden teruggenomen')
            end
            if price > 0 then
                local credited = account.getBalance() - beforeSociety
                if credited == price then account.removeMoney(price)
                elseif credited ~= 0 then error('Onverwacht society-saldo; handmatige controle vereist') end
                assert(account.getBalance() == beforeSociety, 'Society-terugboeking mislukt')
                local deducted = beforeCash - owner.getMoney()
                if deducted == price then owner.addMoney(price, 'Terugbetaling politie sleutelkaart')
                elseif deducted ~= 0 then error('Onverwacht contant saldo; handmatige controle vereist') end
                assert(owner.getMoney() == beforeCash, 'Terugbetaling mislukt')
            end
        end)
        print(('[TroyScripts] Kaartbetaling voor speler %s mislukt: %s'):format(target, tostring(err)))
        if not rollbackOk then
            print('[TroyScripts] HANDMATIGE CONTROLE NODIG: ' .. tostring(rollbackErr))
            return failure('Kaartbetaling mislukt en niet volledig teruggedraaid. Neem contact op met de beheerder.')
        end
        return failure('Kaartuitgifte mislukt. Er is geen geld ingehouden.')
    end
    return { ok = true, message = price > 0
        and ('Kaart gemaakt voor %s. €%s contant betaald aan de politie-societyrekening.'):format(metadata.ownerName, price)
        or ('Kaart gratis gemaakt voor %s.'):format(metadata.ownerName) }
end
