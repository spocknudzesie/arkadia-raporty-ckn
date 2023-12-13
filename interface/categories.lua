--
-- CATEGORIES
--

function scripts.rckn.interface:displayCategories()
    local categories = Category:getAll()
    local mods = {-0.001, -0.01, -0.1, -1, 1, 0.1, 0.01, 0.001}
    -- local mods = {-0.01, -0.1, -1, 1, 0.1, 0.01}
    local forOnePoint
    local maxLen = 5

    for i, category in ipairs(categories) do
        if #category.name > maxLen then maxLen = #category.name end
    end

    self:printSubMenuBar({})
    self:setTitle("Kategorie towarow")

    self:printToConsole("\n", true)

    self:text(string.format(
        'Nr | #555555Id#r | %'..maxLen..'s | %6s | %5s | \n',
        "Nazwa", "Punkty", "Szt/p"))

    self:text(
        string.rep('-',2)..'-+-'
        ..string.rep('-', 2)..'-+-'
        ..string.rep('-', maxLen)..'-+-'
        ..string.rep('-', 6)..'-+-'
        ..string.rep('-', 5)..'-|'..'\n')

    for i, category in ipairs(categories) do
        forOnePoint = 1/category.points

        self:text(string.format(
            '%2d | #555555%2d#r | %'..maxLen..'s | %6.3f | %5.2f | ',
            i,
            category._row_id,
            category.name,
            category.points,
            forOnePoint))
        for j, mod in ipairs(mods) do
            self:printModButton(mod, function()
                local newVal = category.points + mod
                category:setAttribute('points', newVal)
                self:displayCategories()
            end)
            self:text(' | ')
        end

        self:textLink('#aa0000[-]#r', function()
            local action = 'delete category ' .. category._row_id
            if not self:getConfirmation(action) then
                self:printToOutput(
                    'Usuniecie kategorii ' .. category.name .. ' spowoduje usuniecie jej ze wszystkich dostaw, co moze zaburzyc obliczone punkty.\n',
                    false,
                    'warn')
            else
                category:delete()
                self:displayCategories()
                self:printToOutput(
                    'Kategoria ' .. category.name .. ' trwale usunieta.\n',
                    false,
                    'nok')
            end
        end, 'Usun kategorie ' .. category.name)
        self:printToConsole('\n')
    end


end