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
    local rewards = {}
    local persons = {}

    if not self.filter then
        self:printToOutput('Raport mozna utworzyc tylko z podanego zakresu czasowego.\n', false, 'warn')
        return
    end

    scripts.rckn:msg('ok', 'Raport z dostaw za okres %s do %s', self.filter.from, self.filter.to)

    for i, person in ipairs(reportablePersons) do
        local points, reward, personal_points, total_points
        local name

        details[i] = person:details(self.filter)
        -- print(dump_table(details))
        
        points = math.ceil(details[i].total_points)
        personal_points = math.ceil(details[i].extra_points)
        total_points = points + personal_points

        -- print(string.format("%s - %.2f | %.2f - %.2f | %.2f", details[i].name, details[i].total_points, points, personal_points, details[i].extra_points))

        reward = person:calculateReward(total_points)
        name = details[i].name:capitalize()

        details[i].reward = reward
        
        if points > 0 or personal_points > 0 then
            groupedByPoints[total_points] = groupedByPoints[total_points] or {}
            table.insert(groupedByPoints[total_points], name)
            persons[name] = total_points
            rewards[name] = person:calculateReward(total_points)
        end


        if reward > 0 then
            groupedByRewards[reward] = groupedByRewards[reward] or {}
            table.insert(groupedByRewards[reward], name)
        end

    end

    local pointKeys = table.keys(groupedByPoints)
    local rewardKeys = table.keys(groupedByRewards)
    local names = table.keys(persons)

    -- print(dump_table(pointKeys))
    -- print(dump_table(rewardKeys))
    
    table.sort(pointKeys, function(a,b) return a>b end)
    table.sort(rewardKeys, function(a,b) return a>b end)
    table.sort(names, function(a, b) return persons[a] > persons[b] end)
    
    -- print("POINT KES")
    -- print(dump_table(pointKeys))    

    -- echo(string.format("Punktacja za okres %s do %s (wg gnomiej miary):\n\n", self.filter.from, self.filter.to))

    -- for _, name in ipairs(names) do
    --     echo(string.format('%-11s - %3d pkt\n', name, persons[name]))
    -- end

    -- echo('\n\n')

    -- echo('Oto kwoty wynagrodzen do odebrania w zachodniej sortowni:\n\n')

    -- for _, pts in ipairs(rewardKeys) do
    --     echo(string.format('%s - %d %s\n',
    --     table.concat(groupedByRewards[pts], ', '),
    --     pts/100,
    --     self:rewardToString(pts)))
    -- end

    -- echo("---------\n")

    echo(string.format("Punktacja za okres %s do %s (wg gnomiej miary):\n\n", self.filter.from, self.filter.to))

    echo(string.format("%11s | %6s | %s\n", "Zbrojny/a", "Punkty", "Zaplata"))
    echo("------------|--------|-------------------------\n")

    for _, name in ipairs(names) do
        echo(string.format("%11s | %6d | %3d %s\n",
            name, persons[name], rewards[name]/100, self:rewardToString(rewards[name])))
    end

    echo('\nPodane wynagrodzenia sa do odebrania w zachodniej sortowni.\n')

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
