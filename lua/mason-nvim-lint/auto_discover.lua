local Config = require "mason-nvim-lint.settings"
local mappings = require "mason-nvim-lint.mapping"
local registry = require "mason-registry"

---@return table<string, string[]>
local function auto_discover()
    local output = {}
    local formatters_by_ft = require("lint").linters_by_ft

    for linter_name, pkg_name in pairs(mappings.nvimlint_to_package) do
        if not registry.is_installed(pkg_name) then
            goto continue
        end

        local mason_pkg = registry.get_package(pkg_name)
        local languages = mason_pkg.spec.languages

        local function activate_linter(ft)
            if not formatters_by_ft[ft] then
                output[ft] = output[ft] or {}
                table.insert(output[ft], linter_name)

                if Config.current.auto_enable.enabled and Config.current.auto_enable.notify then
                    vim.notify("Discovered " .. linter_name .. " for " .. ft)
                end
            end
        end

        for _, lang in ipairs(languages) do
            lang = string.lower(lang)
            if mappings.language_to_ft[lang] then
                for _, ft in ipairs(mappings.language_to_ft[lang]) do
                    activate_linter(ft)
                end
            else
                activate_linter(lang)
            end
        end

        ::continue::
    end
    return output
end

return function()
    if Config.config.auto_enable.enabled then
        local discovered = auto_discover()
        local current_linters = require("lint").linters_by_ft or {}

        for ft, linters in pairs(discovered) do
            if not current_linters[ft] then
                current_linters[ft] = linters
            else
                for _, linter in ipairs(linters) do
                    table.insert(current_linters[ft], linter)
                end
            end
        end
    end
end
