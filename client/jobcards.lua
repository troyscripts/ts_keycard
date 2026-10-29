TSJobCards = {}
function TSJobCards.option()
    return {title=TSL('jobcards_get'), icon='address-card', onSelect=function()
        exports.ts_bridge:OpenJobCardDesk()
    end}
end
