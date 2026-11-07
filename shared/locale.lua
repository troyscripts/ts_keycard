-- Elke resource heeft eigen locales; Nederlands is de vaste fallback.
Locales = Locales or {}
function TSL(key, ...)
    local cfg = Config or {}
    local selected = Locales[cfg.Locale or 'nl'] or {}
    local fallback = Locales.nl or {}
    local value = selected[key] or fallback[key] or key
    if type(value) ~= 'string' then value = fallback[key] or key end
    if select('#', ...) == 0 then return value end
    local ok, text = pcall(string.format, value, ...)
    return ok and text or value
end
