-- Shared server-side budget for all forged keycards. No client event is registered.
if not TSBridgeGuard.Await() then return end
local bridge = exports.ts_bridge
KeycardForgedUsage = {}
local U = KeycardForgedUsage
local busy = {}

local function definition(name)
    for department, item in pairs(Config.Forgery.Items) do
        if item == name then
            local cfg = ({police=Config, ambulance=Config.Ambulance, firefighter=Config.Firefighter})[department]
            return cfg, department
        end
    end
end

function U.remaining(item)
    if type(item) ~= 'table' or not definition(item.name) then return 0 end
    local m = type(item.metadata) == 'table' and item.metadata or {}
    -- Legacy/admin-created items have no counter. Their FIRST use writes 9,
    -- so this compatibility default can never reset an existing exhausted card.
    if m.usesRemaining == nil then return 10 end
    local n = tonumber(m.usesRemaining)
    if not n or n ~= n or n % 1 ~= 0 or n < 0 or n > 10 then return 0 end
    return n
end

function U.consume(src, slot)
    if not TSBridgeGuard.IsReady() or busy[src] then return false, 'busy' end
    busy[src] = true
    local ok, allowed, remaining = xpcall(function()
        local item = bridge:GetInventorySlot(src, slot)
        local cfg = item and definition(item.name)
        if not cfg then return false, 'not_forged_item' end
        -- Forged cards are individual, non-stackable items. Never replenish a stack.
        if (tonumber(item.count) or 1) ~= 1 then return false, 'invalid_stack' end
        local current = U.remaining(item)
        if current <= 0 then
            bridge:RemoveItem(src, item.name, 1, nil, slot)
            return false, 'exhausted'
        end
        local updated = {}
        for k,v in pairs(type(item.metadata)=='table' and item.metadata or {}) do updated[k]=v end
        updated.forged = true
        updated.sourceItem = cfg.Item
        updated.usesRemaining = current - 1
        updated.description = TSL('forged_description'):format(updated.station or '?', updated.usesRemaining)
        if not bridge:SetItemMetadata(src, slot, updated) then return false, 'write_failed' end
        -- Read back: bridge SetMetadata success alone does not confirm persistence.
        local saved = bridge:GetInventorySlot(src, slot)
        if not saved or saved.name ~= item.name or type(saved.metadata)~='table'
            or saved.metadata.usesRemaining ~= updated.usesRemaining then
            return false, 'readback_failed'
        end
        if updated.usesRemaining == 0 then
            -- Persist zero BEFORE removal. A failed removal cannot reset the budget.
            if not bridge:RemoveItem(src, item.name, 1, nil, slot) then
                return false, 'remove_failed'
            end
        end
        pcall(function() bridge:Notify(src, {title=TSL('forged_title'),
            description=TSL('forged_remaining'):format(updated.usesRemaining), type='inform'}) end)
        return true, updated.usesRemaining
    end, debug.traceback)
    busy[src] = nil
    if not ok then
        print(TSL('forged_failure'):format(src, slot, tostring(allowed)))
        return false, 'internal_error'
    end
    return allowed, remaining
end

local function requiresItem(door, name)
    local items=type(door)=='table' and type(door.access)=='table' and door.access.items
    if type(items)~='table' then return false end
    for key,value in pairs(items) do
        if value==name or (key==name and value~=false and value~=nil)
            or (type(value)=='table' and (value.name==name or value.item==name)) then return true end
    end
    return false
end

local function relock(doorId)
    local ok = pcall(function() exports.vlr_doorlock:setState(doorId,1) end)
    if not ok then print(TSL('forged_relock_failed'):format(tostring(doorId))) end
end

AddEventHandler('vlr_doorlock:stateChanged',function(playerId,doorId,locked,reason)
    -- Documented VLR server event. Automated changes (source 0/nil) do not cost a use.
    if locked~=false and tonumber(locked)~=0 then return end
    local src=tonumber(playerId)
    if not src or src<1 or src%1~=0 or not GetPlayerName(src) then return end
    if not TSBridgeGuard.IsReady() or GetResourceState('vlr_doorlock')~='started' then return end
    local ok,door=pcall(function() return exports.vlr_doorlock:getDoor(doorId) end)
    if not ok or type(door)~='table' or type(door.access)~='table' then
        print(TSL('forged_door_unreadable'):format(tostring(doorId)))
        return
    end
    -- An original card allowed by this door takes priority over a forged card.
    for _,cfg in ipairs({Config,Config.Ambulance,Config.Firefighter}) do
        if requiresItem(door,cfg.Item) then
            local slots,err=bridge:GetItemSlots(src,cfg.Item)
            if err then relock(doorId); return end
            for _,item in pairs(slots or {}) do
                if type(item.metadata)=='table' and item.metadata.owner and item.metadata.job
                    and cfg.Jobs[item.metadata.job] and not KeycardRevocation.isStale(item) then return end
            end
        end
    end
    for _,department in ipairs({'police','ambulance','firefighter'}) do
        local name=Config.Forgery.Items[department]
        if requiresItem(door,name) then
            local slots,err=bridge:GetItemSlots(src,name)
            if err then relock(doorId); print(TSL('forged_inventory_failed')); return end
            -- Deterministic selection prevents random switching between multiple cards.
            local ordered={}
            for _,item in pairs(slots or {}) do ordered[#ordered+1]=item end
            table.sort(ordered,function(a,b) return (tonumber(a.slot) or 0)<(tonumber(b.slot) or 0) end)
            for _,item in ipairs(ordered) do
                if U.remaining(item)>0 then
                    local accepted,detail=U.consume(src,item.slot)
                    if not accepted then relock(doorId) end
                    print(TSL('forged_door_result'):format(src,tostring(doorId),name,tostring(detail)))
                    return
                else
                    -- Legacy exhausted/malformed items must not remain item-only credentials.
                    bridge:RemoveItem(src,name,item.count or 1,nil,item.slot)
                    relock(doorId)
                    print(TSL('forged_failure'):format(src,item.slot,'exhausted_or_invalid'))
                    return
                end
            end
        end
    end
end)

-- Other doorlocks must call this ONCE on their server immediately before granting
-- one unlock. Do not also use the VLR event for the same interaction.
exports('ConsumeForgedCardUse', function(src, slot)
    if type(src)~='number' or src<1 or src%1~=0 or type(slot)~='number' or slot<1 or slot%1~=0 then return false end
    return U.consume(src,slot)
end)
AddEventHandler('playerDropped',function() busy[source]=nil end)
