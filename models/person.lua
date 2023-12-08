Person = {
    _tableName = 'persons'
}

setmetatable(Person, { __index = Model })


function Person:details(filter)
    local deliveries

    if filter and #filter then
        deliveries = self.db:q([[
        SELECT 
            dp.delivery_id, d.date, d.description, d._row_id
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
            dp.delivery_id, d.date, d.description, d._row_id
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
    local details = self.db:q([[
        SELECT 
            p._row_id, p.name
        FROM
            persons AS p
        WHERE p._row_id = ?
    ]], self._row_id)[1]

    
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

    details.total_points = sum
    details.deliveries = deliveries    
    details.deliveries_count = #deliveries
    return details
end


