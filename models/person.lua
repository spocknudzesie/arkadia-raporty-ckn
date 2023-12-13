Person = {
    _tableName = 'persons'
}

setmetatable(Person, { __index = Model })


function Person:details(filter)
    local deliveries
    local dp = DeliveryPerson:where({person_id=self._row_id}) or {}

    if filter and #filter then
        deliveries = self.db:q([[
        SELECT 
            dp.delivery_id, d.date, d.description, d._row_id, dp.extra_points
        FROM
            deliveries AS d
        JOIN
            delivery_persons AS dp ON dp.delivery_id = d._row_id
        WHERE
            dp.person_id = ? AND
            (d.date >= ? AND d.date <= ?)
        GROUP BY
            dp.delivery_id
        ]], self._row_id, filter.from, filter.to)    
    else
        deliveries = self.db:q([[
        SELECT 
            dp.delivery_id, d.date, d.description, d._row_id, dp.extra_points
        FROM
            deliveries AS d
        JOIN
            delivery_persons AS dp ON dp.delivery_id = d._row_id
        WHERE
            dp.person_id = ?
        GROUP BY
            dp.delivery_id
        ]], self._row_id)
    end

    if not deliveries then
        deliveries = {}
    end

    -- print("PERSONS DELIVERIES = " .. dump_table(deliveries))
    local sum = 0
    local bonusPoints = 0
    local details = self.db:q([[
        SELECT 
            p._row_id, p.name
        FROM
            persons AS p
        WHERE p._row_id = ?
    ]], self._row_id)[1]

    -- print("DP")
    -- print(dump_table(dp, true))
    -- print('SIZE=' .. #dp)
    -- print("/DP")

    for i, d in ipairs(dp) do
        -- print(string.format("%d: %s", i, dump_table(d)))
        bonusPoints = bonusPoints + d.extra_points
    end

    for i, dId in ipairs(deliveries) do
        local dets = Delivery:get(dId.delivery_id):friendlyTable()
        local ppp
        if dets and dets.total_points then
            ppp = dets.total_points / dets.persons_count
        else
            ppp = 0
        end
        sum = sum + ppp
        deliveries[i].points_per_person = ppp
    end
    
    table.sort(deliveries, function(a,b) return a.date > b.date end)

    details.extra_points = bonusPoints
    details.total_points = sum
    details.deliveries = deliveries
    details.deliveries_count = #deliveries
    return details
end


function Person:calculateReward(total_points)
    local settings = scripts.rckn.settings
    -- print(dump_table(settings))
    local base = settings.baza

    if not total_points or total_points <= 0 then
        return 0
    end

    if total_points <= settings.prog then
        return base
    end
-- 
    -- print("Lacznie punktow: " .. total_points)
    local excess = math.max(0, total_points - settings.prog)
    -- print("Nadmiarowych punktow do nagrody: " .. excess)
    
    local steps = math.ceil(excess/settings.skok)
    -- print("Stopni ponad minimum: " .. steps)

    local reward = base + settings.bonus * steps
    -- print("Do wyplaty: " .. base .. " + " .. settings.bonus*steps)
    
    return reward
end
