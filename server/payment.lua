if not TSBridgeGuard.Await() then return end
local bridge = exports.ts_bridge
KeycardPayment = { busy = false }
local serial = 0
local function failure(message) return { ok = false, message = message } end
local function confirmed(result) return type(result) == 'table' and result.ok == true end
local function uncertain(result) return type(result) ~= 'table' or result.uncertain == true end
local function issue(owner, target, metadata, freeReplacement)
    local price = Config.CardPrice or 10
    if type(price) ~= 'number' or price < 0 or price % 1 ~= 0 or price == math.huge then
        return failure(TSL('payment_ongeldige_kaartprijs_controleer_config_lua'))
    end
    local account = Config.PaymentAccount or 'cash'
    if account ~= 'cash' and account ~= 'bank' then return failure(TSL('payment_paymentaccount_moet_cash_of_bank_zijn')) end
    if not owner or not owner.job or not owner.identifier then return failure(TSL('payment_de_ontvanger_is_niet_beschikbaar')) end
    if (tonumber(owner.job.grade) or -1) >= (Config.FreeCardMinimumGrade or 7) or freeReplacement then price = 0 end
    local function samePlayer()
        local current = bridge:GetPlayerData(target)
        return current and current.identifier == owner.identifier
    end
    if not samePlayer() then return failure(TSL('payment_de_ontvanger_is_niet_meer_online')) end
    local societyKey = Config.SocietyAccount or 'police'
    if price > 0 then
        local balance, resolved = bridge:GetSocietyBalance(societyKey)
        if balance == nil then return failure(TSL('payment_de_societyrekening_is_niet_beschikbaar_er_is')) end
        -- Pin de opgeloste rekening: bijschrijving en eventuele terugboeking gaan naar dezelfde rekening.
        societyKey = resolved
        local funds = bridge:GetMoney(target, account)
        if funds == nil then return failure(TSL('payment_het_betaalaccount_is_niet_beschikbaar_controleer_de')) end
        if funds < price then return failure((TSL('payment_de_ontvanger_heeft_nodig')):format(price, account == 'bank' and TSL('payment_op_de_bank') or TSL('payment_cash'))) end
    end
    if not bridge:CanCarryItem(target, Config.Item, 1, metadata) then
        return failure(TSL('payment_geen_ruimte_voor_de_kaart_of_inventory'))
    end
    serial = serial + 1
    local reference = ('ts_keycard:%s:%s:%s'):format(os.time(), GetGameTimer(), serial)
    metadata.tsKeycardTransaction = reference
    local debit, credit, debitAttempted, creditAttempted, itemAttempted, itemUncertain
    local ok, err = xpcall(function()
        if price > 0 then
            if not samePlayer() then error(TSL('payment_ontvanger_niet_meer_online')) end
            debitAttempted = true
            debit = bridge:RemoveMoney(target, account, price, TSL('payment_politie_sleutelkaart') .. reference)
            if not confirmed(debit) then error(TSL('payment_afschrijving') .. tostring(type(debit) == 'table' and debit.code)) end
            creditAttempted = true
            credit = bridge:AddSocietyMoney(societyKey, price)
            if not confirmed(credit) then error(TSL('payment_society_bijschrijving') .. tostring(type(credit) == 'table' and credit.code)) end
        end
        if not samePlayer() then error(TSL('payment_ontvanger_niet_meer_online_voor_kaartuitgifte')) end
        -- Na de betaling opnieuw ruimte controleren; providers kunnen tussentijds yielden.
        if not bridge:CanCarryItem(target, Config.Item, 1, metadata) then error(TSL('payment_inventory_inmiddels_vol')) end
        itemAttempted = true
        local added, reason = bridge:AddItem(target, Config.Item, 1, metadata)
        if not added then
            itemUncertain = reason == 'inventory_call_failed'
            error(TSL('payment_kaart_kon_niet_worden_toegevoegd') .. tostring(reason))
        end
        itemAttempted = false -- geslaagde uitgifte, geen verdere mutaties hierna
    end, debug.traceback)
    if not ok then
        print((TSL('payment_troy_scripts_ts_keycard_betaling_voor_id_mislukt')):format(reference, target, tostring(err)))
        local ambiguous = (debitAttempted and uncertain(debit)) or (creditAttempted and uncertain(credit))
            or itemUncertain or (itemAttempted and itemUncertain == nil)
        if not ambiguous then
            local rollbackOk, rollbackResult = pcall(function()
                if confirmed(credit) then
                    local reversed = bridge:RemoveSocietyMoney(societyKey, price)
                    if not confirmed(reversed) then return false end
                end
                if confirmed(debit) then
                    if not samePlayer() then return false end
                    local refunded = bridge:AddMoney(target, account, price, TSL('payment_terugbetaling_politie_sleutelkaart') .. reference)
                    if not confirmed(refunded) then return false end
                end
                return true
            end)
            if rollbackOk and rollbackResult then return failure(TSL('payment_kaartuitgifte_mislukt_er_is_geen_geld_ingehouden')) end
        end
        print(TSL('payment_troy_scripts_handmatige_controle_nodig') .. reference .. TSL('payment_controleer_kaart_betaalaccount_en_society_niet_blind'))
        return failure(TSL('payment_uitgifte_niet_afgerond_de_betaalstatus_moet_worden') .. reference)
    end
    return { ok = true, paidAmount = price, paymentAccount = account, message = price > 0
        and (TSL('payment_kaart_gemaakt_voor_betaald_aan_de_society')):format(metadata.ownerName, price, account == 'bank' and TSL('payment_via_de_bank') or TSL('payment_cash'))
        or (TSL('payment_kaart_gratis_gemaakt_voor')):format(metadata.ownerName) }
end
function KeycardPayment.issue(...)
    if not TSBridgeGuard.IsReady() then return failure(TSL('main_de_bridge_is_niet_beschikbaar')) end
    if KeycardPayment.busy then return failure(TSL('payment_er_wordt_al_een_kaart_betaald_probeer')) end
    KeycardPayment.busy = true
    local ok, result = xpcall(issue, debug.traceback, ...)
    KeycardPayment.busy = false
    if not ok then
        print(TSL('payment_troy_scripts_ts_keycard_betaalcontrole_mislukt') .. tostring(result))
        return failure(TSL('payment_betaalcontrole_mislukt_bekijk_de_serverconsole'))
    end
    return result
end
