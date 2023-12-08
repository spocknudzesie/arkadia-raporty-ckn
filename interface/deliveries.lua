--
-- DELIVERIES
--


function scripts.rckn.interface:printModButton(value, callback)
    local hint = 'Zwieksz wartosc o ' .. value
    local label = value
    local color = '#bb0000'

    if value < 0 then
        hint = 'Zmniejsz wartosc o ' .. value
    end
    
    if value > 0 then
        label = '+'..value
        color = '#00bb00'
    end

    self:textLink(label, callback, hint, color)
end


function scripts.rckn.interface:printDelivery(id)
    local delivery
    local mods = {-10, -1, 1, 10}

    self.currentSection = "Dostawy"
    self.currentSubsection = id
    self:printMenuBar()

    -- print("Printing delivbery " .. id)
    
    if not id and self.delivery then
        delivery = self.delivery
    else
        delivery = Delivery:get(id)
    end
    self:setTitle(string.format('\rEdycja dostawy id=%d z %s - %s', delivery._row_id, delivery.date, delivery.description))

    local persons, categories, details
    local missingCategories, missingPersons

    persons = delivery:getPersons()
    categories = delivery:getCategories()
    details = delivery:friendlyTable()

    missingPersons = Person:where(
        string.format('_row_id NOT IN (%s)',
        table.concat(Model:map(persons, function(p) return p.person_id end), ', '))
    )

    missingCategories = Category:where(
        string.format(
            "name NOT IN (%s)",
            table.concat(Category:map(
                categories,
                function(c) return string.format("'%s'", c['name']) end), ', ')))

    -- print(dump_table(allCategories, true))
    self:printToConsole('\n(+) Uczestnicy dostawy (' .. #persons .. '): ', true)

    local j = 1
    -- print("#PERSONS="..#persons)
    
    for i, p in spairs(persons, function(t,a,b) return t[a].name < t[b].name end) do
        -- print("i="..i..', p='..p.name)
        
        self.console:hechoLink(string.format("#ffffff%s#r ", p.name:capitalize()), function()
            self:printPerson(p.person_id)
        end, "Przejdz do osoby imieniem " .. p.name:capitalize(), true)

        self.console:hechoLink('#dd0000(-)#r', function()
            local action = 'delete person ' .. p.person_id .. ' from delivery ' .. delivery._row_id
            -- print("ACTION="..action .. ", #p="..#persons)
            -- print(dump_table(self.confirmations, true))
            if #persons == 1 and not self:getConfirmation(action) then
                self:printToOutput('Usuniecie ostatniej osoby spowoduje usuniecie calej dostawy. Powtorz akcje, aby potwierdzic.\n', false, 'warn')
            else
                local res = delivery:removePersonFromDelivery(p.name)

                if res then
                    self:printToOutput(string.format("Usunieto postac imieniem %s z dostawy z dnia %s (%s)\n", p.name:capitalize(), delivery.date, delivery.description), false, 'nok')
                else
                    self:printToOutput(string.format("Blad usuwania osoby.\n", false, 'error'))
                    return
                end

                if #persons == 1 then
                    delivery:delete()
                    self:printToOutput(string.format("Usunieto dostawe nr %s z dnia %s (%s)\n", delivery._row_id, delivery.date, delivery.description), false, 'nok')
                    self:printDeliveries()
                else
                    self:printDelivery(id)
                end
            end                
                    
        end, "Usun osobe imieniem " .. p.name:capitalize() .. " z dostawy " .. delivery._row_id, true)
        if j < #persons then
            self:text(', ')
        end
        j = j+1
    end

    self:text("\n")

    if #missingPersons > 0 then
        local totalLen = 0
        self:text("(-) Nie uczestniczyli: \n")
        
        j = 1
        for i, p in spairs(missingPersons, function(t,a,b) return t[a].name < t[b].name end) do
            self.console:hechoLink(string.format("#7f7f7f%11s#r", p.name:capitalize()), function()
                self:printPerson(p.person_id)
            end, "Przejdz do osoby imieniem " .. p.name:capitalize(), true)
            
            self:printToConsole(' ')
            
            self.console:hechoLink('#00dd00(+)#r', function()
                if delivery:addPersonToDelivery(p.name) then
                    self:printToOutput(string.format(
                        'Dodano osobe imieniem %s do dostawy nr %s z dnia %s (%s)\n',
                            p.name:capitalize(), delivery._row_id, delivery.date, delivery.description),
                            false, 'ok')
                        end
                        self:printDelivery(id)
                    end, "Dodaj osobe imieniem " .. p.name:capitalize(), true)
                    
            if j < #missingPersons then
                self:text(", ")
            end
            
            if j%5 == 0 then
                self:text('\n')
            end
            j = j+1
        end

        self:text("\n")
    end

    self:text('\n(+) Zdobyte przedmioty:\n')

    -- print(dump_table(details, true))
    -- print(dump_table(categories, true))

    for i, c in ipairs(missingCategories) do
        self:printToConsole(string.format('#ffffff%10s#r  ', c.name))
        self.console:hechoLink('#ffffff[DODAJ]#r', function()
            local dc = DeliveryCategory:new({delivery_id=id, category_id=c._row_id, count=1})
            if dc:save() then
                self:printDelivery(id)
            else
                self:displayError('Blad dodawania kategorii ' .. dc.name .. ' do dostawy ' .. id)
            end
        end, 'Dodaj kategorie ' .. c.name .. ' do dostawy', true)

        self:printToConsole('\n')
    end

    for i, c in ipairs(categories) do
        local dc
        dc = DeliveryCategory:findBy(
            string.format(
                'delivery_id=%s AND category_id=%s',
                id, c.category_id))

        self:printToConsole(
            string.format('#ffffff%10s#r: %2d x %.2f = %6.2f  ',
            c.name,
            c.count,
            c.points,
            c.count * c.points))

        for _, mod in ipairs(mods) do
            self:printModButton(mod, function()
                local newVal = c.count + mod
                -- print(dump_table(dc, true))
                if newVal <= 0 then
                    delivery:removeCategoryFromDelivery(c.name)
                    self:printToOutput(string.format("Usunieto kategorie '%s' z dostawy id=%d z dnia %s - %s\n",
                    c.name, id, delivery.date, delivery.description))
                else
                    dc:setAttribute('count', newVal)
                end
                self:printDelivery(id)
            end)
            self:printToConsole(' ')
        end

        self:printToConsole('\n')
    end


    if details and details.total_points then
        self:text(string.format('#7fff7f%-22s   %5.2f#r\n', ' RAZEM PUNKTOW', details.total_points))
        self:text(string.format('#7fff7f%-22s   %5.2f#r\n', ' PUNKTOW NA OSOBE', details.total_points/#persons))
    end
end


function scripts.rckn.interface:editDelivery(id)
    local delivery = Delivery:get(id)
    self:printDelivery(id)
end


function scripts.rckn.interface:printDeliveries()
    local deliveries
    local title = 'Zarejestrowane dostawy'
    local subMenuOptions = {
        {
            label = 'Lista',
            callback = function()
                self:printDeliveries()
            end
        }
    }

    self.currentSubsection = nil

    if self.filter then
        deliveries = Delivery:where(string.format('date >= "%s" AND date <= "%s"', self.filter.from, self.filter.to))
        title = title .. string.format(' (%s do %s)', self.filter.from, self.filter.to)
        table.insert(subMenuOptions, {
            label = 'Wyczysc filtr',
            callback = function()
                self:setFilter(nil)
                self:printDeliveries()
            end
        })
    else
        deliveries = Delivery:getAll()
    end

    self:printSubMenuBar(subMenuOptions, 'Dostawy: ')
    self:setTitle(title)
    self.console:clear()

    local printLine = function(i, delivery)

        local friendlyTable = delivery:friendlyTable()
        
        self:textLink('#ffffff[E]#r', function()
            self:editDelivery(delivery._row_id)
        end, 'Edytuj dostawe ' .. delivery._row_id) 

        self:text(' ')

        self:textLink('#aa0000[-]#r', function()
            local action = 'delete delivery ' .. delivery._row_id
            if self:getConfirmation(action) then
                delivery:delete()
                self:printDeliveries()
            else
                self:printToOutput(string.format(
                    'Czy na pewno chcesz usunac dostawe nr %d z dnia %s - %s? Moze spowodowac to zmiane w sumie punktow jej uczestnikow.\n',
                    delivery._row_id,
                    delivery.date,
                    delivery.description), false, 'warn')
            end
        end, 'Usun dostawe ' .. delivery._row_id)
        self:text(' ')

        if not friendlyTable then
            self:text(string.format('[%3d] | #7f7f7fid %3d#r | %10s | %s - #ff7f00brakujace dane dostawy#r',
            i, delivery._row_id, delivery.date, delivery.description),
            '')
        else
            self:text(string.format('[%3d] | id %3d | %10s | %5.2f pkt | %2d osob(y) | %s',
            i,
            delivery._row_id,
            delivery:getTimestamp(),
            friendlyTable.total_points or 0,
            friendlyTable.persons_count or 0,
            delivery.description or 'n/a'))            
        end
        
        self:text("\n")
    end

    self:printToConsole('\n')
    for i, delivery in ipairs(deliveries) do
        printLine(i, delivery)
    end
end
