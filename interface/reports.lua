function scripts.rckn.interface:rewardToString(value)
    value = value / 100

    if value == 1 then
        return 'mithrylowa moneta'
    elseif value >= 10 and value <= 20 then
        return 'mithrylowych monet'
    elseif value%10 >= 1 and value%10 <= 4 then
        return "mithrylowe monety"
    else
        return 'mithrylowych monet'
    end

end


function scripts.rckn.interface:createMassReport(reportablePersons)
    local details = {}
    local groupedByPoints = {}
    local groupedByRewards = {}
    local persons = {}

    if not self.filter then
        self:printToOutput('Raport mozna utworzyc tylko z podanego zakresu czasowego.\n', false, 'warn')
        return
    end

    scripts.rckn:msg('ok', 'Raport z dostaw za okres %s do %s', self.filter.from, self.filter.to)

    for i, person in ipairs(reportablePersons) do
        local points, reward
        local name

        details[i] = person:details()
        
        reward = person:calculateReward(details[i].total_points)
        name = details[i].name:capitalize()
        points = math.floor(details[i].total_points)

        details[i].reward = reward
        
        if points > 0 then
            groupedByPoints[points] = groupedByPoints[points] or {}
            table.insert(groupedByPoints[points], name)
            persons[name] = points
        end

        if reward > 0 then
            groupedByRewards[reward] = groupedByRewards[reward] or {}
            table.insert(groupedByRewards[reward], name)
        end

    end

    local pointKeys = table.keys(groupedByPoints)
    local rewardKeys = table.keys(groupedByRewards)
    local names = table.keys(persons)
    
    table.sort(pointKeys, function(a,b) return a>b end)
    table.sort(rewardKeys, function(a,b) return a>b end)
    table.sort(names, function(a, b) return persons[a] > persons[b] end)
    
    -- print("POINT KES")
    -- print(dump_table(pointKeys))    

    echo(string.format("Punktacja za okres %s do %s (wg gnomiej miary):\n\n", self.filter.from, self.filter.to))

    for _, name in ipairs(names) do
        echo(string.format('%-11s - %3d pkt\n', name, persons[name]))
    end

    echo('\n\n')

    echo('Oto kwoty wynagrodzen do odebrania w zachodniej sortowni:\n\n')

    for _, pts in ipairs(rewardKeys) do
        echo(string.format('%s - %d %s\n', table.concat(groupedByRewards[pts], ', '), pts/100, self:rewardToString(pts)))
    end

    -- print(dump_table(groupedByPoints))

end


function scripts.rckn.interface:createPersonalReport(person)
    if not self.filter then
        self:printToOutput('Raport mozna utworzyc tylko z podanego zakresu czasowego.\n', false, 'warn')
        return
    end

    self:printToOutput(string.format(
        'Generowanie raportu dla: #ffffff%s#r za okres #ffffffod %s do %s#r\n',
            person.name:capitalize(), self.filter.from, self.filter.to))

    
end
