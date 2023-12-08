--
-- PERSONS
--


function scripts.rckn.interface:printPerson(id)
    local person = Person:get(id)
    local details

    if not person then
        self:printToConsole('\n#ff0000Postac o id ' .. id .. ' nie istnieje.\n', true)
        return
    end

    self.currentSection = "Osoby"
    self:printMenuBar()

    details = person:details(self.filter)
    -- print(dump_table(details, true))

    if self.filter then
        self:setTitle(string.format(
            "%s (dane od %s do %s)",
                person.name:capitalize(),
                self.filter.from, self.filter.to))
        self:printSubMenuBar({
            {
            label = 'Wyczysc filtr',
            callback = function()
                self:setFilter(nil)
                self:printPerson(id)
            end
        }})                
        -- self:printToConsole(string.format('\n#ffffff\r%s - historia dostaw miedzy %s i %s:#r\n', person.name:capitalize(), self.filter.from, self.filter.to), true)                
    else
        self:setTitle(person.name:capitalize() .. ' - historia dostaw')
    end

    self:printToConsole(string.format("\n(+) Lacznie punktow z dostaw: #ffffff%5.2f pkt#r\n", details.total_points), true)
    self:printToConsole(string.format("(+) Dostawy:\n"))

    for i, delivery in ipairs(details.deliveries) do
        self.console:hechoLink('#ffffff    [E]#r', function()
            self:printDelivery(delivery._row_id)
        end, "Edytuj dostawe " .. delivery._row_id, true)
        self:printToConsole(string.format(" #7f7f7fid %3d#r | %s - %5.2f pkt - %s\n",
            delivery._row_id, delivery.date, delivery.points_per_person, delivery.description))
    end

end


function scripts.rckn.interface:printPersons()
    local persons = Person:getAll()
    local lastDelivery
    local now = os.date('%Y-%m-%d', os.time())
    local diff
    local details = {}
    local points = {min=100000, max=-100000}

    local dateDifference = function(date1, date2)
        local pattern = "(%d+)-(%d+)-(%d+)"
        -- print(dump_table({date1, date2}, true))
        local year1, month1, day1 = date1:match(pattern)
        local year2, month2, day2 = date2:match(pattern)
    
        local time1 = os.time({year=year1, month=month1, day=day1})
        local time2 = os.time({year=year2, month=month2, day=day2})
    
        local difference = os.difftime(time2, time1)
        local daysDifference = difference / (24 * 60 * 60) 
    
        return daysDifference
    end

    local pointsColor = function(p)
        if p == 0 then
            return string.format('<80,80,80>')
        end
        return string.format('<%d,%d,%d>',
            math.max(0, math.min(255, 255-(255*p/points.max))),
            math.max(0, math.min(255, 255*p/points.max)),
            0)
    end

    table.sort(persons, function(a, b) return a.name < b.name end)

    if self.filter then
        self:setTitle(string.format('Lista osob z dostawami w okresie %s - %s', self.filter.from, self.filter.to))

        self:printSubMenuBar({
            {
            label = 'Wyczysc filtr',
            callback = function()
                self:setFilter(nil)
                self:printPersons()
            end
        }})           
    else
        self:setTitle('Lista osob')
    end

    self:printToConsole("\n", true)

    for i, person in ipairs(persons) do
        local dets = person:details(self.filter)
        details[i] = dets

        if dets.total_points > points.max then
            points.max = dets.total_points
        end

        if dets.total_points < points.min then
            points.min = dets.total_points
        end

    end
    

    for i, dets in ipairs(details) do
        local personColor = '#ffffff'

        -- print("PERSON: " .. dets.name)
        
        if #(dets.deliveries) > 0 then
            lastDelivery = dets.deliveries[1].date
            diff = dateDifference(lastDelivery, now)
        else
            diff = -1
            personColor = '#666666'
        end

        -- print("DETAILS")
        -- print(dump_table(dets, true))
        -- print("----------")

        self:printToConsole(string.format(
            ' %2d | #7f7f7fid %2d#r | ',
            i,
            dets._row_id))

        self.console:hechoLink(string.format(
            personColor .. '\r%-11s#r',
            dets.name:capitalize()), function()
                self:printPerson(dets._row_id)
            end, "Historia osoby imieniem " .. dets.name:capitalize(), true)
            -- dets.name:gsub("^%l", string.upper),
            -- dets.deliveries,
            -- dets.total_points))

            -- %-11s | %3d wypraw(y) | %5.2f pkt\n',

            self:printToConsole(string.format(
                " | %3d dostaw(y) | ", dets.deliveries_count))
                
            self.console:decho(string.format('%s%5.2f pkt razem',
                pointsColor(dets.total_points), dets.total_points))

            
        if diff > -1 then
            self:printToConsole(string.format(' | ostatnia dostawa: %3d dni temu', diff))
        end

        self:printToConsole("\n")
    end
end
