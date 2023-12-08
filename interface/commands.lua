function scripts.rckn.interface:command(cmd)
    local w = string.split(cmd, ' ')
    local m, c
    self.lastCommand = cmd

    -- print("COMMAND="..cmd)

    if self.currentSection == 'Kategorie' or self.currentSection == "Osoby" then
        c = cmd:match('^(%+)') or cmd:match('^(dodaj)')
        -- print(dump_table({i,j,m}))
        if c then
            m = cmd:match('^%+(.+)') or cmd:match('^dodaj (.+)')
            -- print("CORRECT COMMAND")
            if m then
                -- print("addd")
                if self.currentSection == 'Kategorie' then
                    -- print("CMD ADD")
                    return self:cmdAddCategory(m)
                elseif self.currentSection == 'Osoby' then
                    return self:cmdAddPerson(m)
                end
            else
                local error = 'Komenda ' .. c .. ' wymaga podania parametru <kategoria>\n'
                self:printToOutput(error, false, 'warn')
                self:displayError(error)
            end
        else
            self:printToOutput(
                'W menu "' .. self.currentSection .. '" mozesz wykonac jedynie komende + lub dodaj.\n', false, 'warn')
        end

        return
    end

    if self.currentSection == 'Dostawy' then
        -- mamy okno edycji
        if self.currentSubsection then
            if cmd:match('^data') then
                c = cmd:match('^data (%d%d%d%d%-%d%d%-%d%d)')
                if not c then
                    local error = 'Komenda "data" wymaga podania daty w formacie YYYY-MM-DD.\n'
                    self:printToOutput(error, false, 'warn')
                    self:displayError(error)
                    return
                else
                    self:cmdEditDeliveryDate(c, self.currentSubsection)
                    self:printDelivery(self.currentSubsection)
                    return
                end
            elseif cmd:match('^opis') then
                c = cmd:match('^opis (.+)')
                if not c then
                    local error = 'Komenda "opis" wymagania podania opisu dostawy.\n'
                    self:printToOutput(error, false, 'warn')
                    self:displayError(error)
                else
                    self:cmdEditDeliveryDescription(c, self.currentSubsection)
                    self:printDelivery(self.currentSubsection)
                    return
                end
            else
                self:printToOutput("W sekcji edycji dostawy mozesz wykonac komendy 'data' i 'opis'.\n", false, 'warn')
            end
        else -- okno glowne
            if cmd:match('^dodaj') then
                local args = {cmd:match('^dodaj (%d%d%d%d%-%d%d%-%d%d) (.+)')}
                if not args then
                    local error = 'Komenda "dodaj" wymaga podania daty w formacie YYYY-MM-DD i opisu dostawy.\n'
                    self:printToOutput(error, false, 'warn')
                    self:displayError(error)
                else
                    self:cmdAddDelivery(args[1], args[2])
                    self:printDeliveries()
                end
            else
                self:printToOutput("W sekcji dostaw mozesz wykonac tylko komende 'dodaj'.\n", false, 'warn')
            end
        end

        return
    end
end


function scripts.rckn.interface:cmdAddCategory(cat)
    print("ADD CATEGOR CALLED with " .. cat)
    local category = Category:new({name=cat, points=1})

    if category:save() then
        self:printToOutput('Kategoria "' .. cat .. "' dodana.\n", false, 'ok')
        self:displayCategories()
        return
    else
        self:printToOutput('Blad dodawania kategorii "' .. cat .. '": ' .. category.db.lastError .. '\n', false, 'warn')
        return
    end
end


function scripts.rckn.interface:cmdAddPerson(name)
    print("ADD PERSON CALLED with " .. name)
    name = name:lower()
    local person = Person:new({name=name})

    if person:save() then
        self:printToOutput('Osoba "' .. name .. "' dodana.\n", false, 'ok')
        self:printPersons()
        return
    else
        self:printToOutput('Blad dodawania osoby "' .. name .. '": ' .. person.db.lastError .. '\n', false, 'warn')
        return
    end
end


function scripts.rckn.interface:cmdAddDelivery(date, description)
    local delivery = Delivery:new({date=date, description=description})

    print(dump_table(delivery._attributes))
    local res = delivery:save()

    if res then
        self:printToOutput(string.format('Dodano nowa dostawe z dnia %s (%s) o nr %s.\n', res.date, res.description, res._row_id), false, 'ok')
    else
        self:printToOutput('Blad dodawania dostawy: ' .. delivery.db.lastError .. '\n', false, 'warn')
    end       

end


function scripts.rckn.interface:cmdEditDelivery(id, param, value)
    local delivery = Delivery:get(id)
    return delivery:setAttribute(param, value), delivery
end


function scripts.rckn.interface:cmdEditDeliveryDate(date, id)
    local res, delivery = self:cmdEditDelivery(id, 'date', date)
    
    if res then
        self:printToOutput(string.format('Data dostawy nr %s ustawiona na %s.\n', id, date), false, 'ok')
    else
        self:printToOutput('Blad: ' .. delivery.db.lastError)
    end
end


function scripts.rckn.interface:cmdEditDeliveryDescription(desc, id)
    local res, delivery = self:cmdEditDelivery(id, 'description', desc)
    
    if res then
        self:printToOutput(string.format('Opis dostawy nr %s z dnia %s ustawiony na %s.\n', id, delivery.date, desc), false, 'ok')
    else
        self:printToOutput('Blad: ' .. delivery.db.lastError)
    end
end