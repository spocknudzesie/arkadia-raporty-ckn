Delivery = {
    _tableName = 'deliveries',
    _beforeDelete = function(d)
        d.db:q('DELETE FROM delivery_persons WHERE delivery_id=?', d._row_id)
        d.db:q('DELETE FROM delivery_categories WHERE delivery_id=?', d._row_id)
    end
}

setmetatable(Delivery, { __index = Model })


function Delivery:getTimestamp()
    if type(self.date) == 'number' then
        return os.date('%Y-%m-%d', self.date)
    else
        return self.date
    end
end


function Delivery:describe()
    return string.format("Delivery #%d, date=%s, description=%s", self._row_id, self:getTimestamp(), self.description)
end


function Delivery:overview()
    -- return self.db:q([[
    --     SELECT
    --         d._row_id as id, d.description, d.date,
    --         SUM(dc.count * c.points) AS total_points
    --     FROM
    --         deliveries AS d
    --     JOIN
    --         delivery_categories AS dc ON dc.delivery_id = d._row_id
    --     JOIN
    --         categories AS c ON c._row_id = dc.category_id
    --     LEFT JOIN
    --         delivery_persons AS dp ON dp.delivery_id = d._row_id
    --     WHERE
    --         d._row_id = ?
    --     GROUP BY
    --         d._row_id
    -- ]], self._row_id)
    return self.db:q([[
        SELECT
        d._row_id as id,
        d.description,
        d.date,
        COALESCE(total_points.total, 0) AS total_points,
        COALESCE(total_extra_points.total_extra, 0) AS total_extra_points
    FROM
        deliveries AS d
    LEFT JOIN
        (SELECT
             dc.delivery_id,
             SUM(dc.count * c.points) AS total
         FROM
             delivery_categories AS dc
         JOIN
             categories AS c ON c._row_id = dc.category_id
         GROUP BY
             dc.delivery_id
        ) AS total_points ON total_points.delivery_id = d._row_id
    LEFT JOIN
        (SELECT
             dp.delivery_id,
             SUM(dp.extra_points) AS total_extra
         FROM
             delivery_persons AS dp
         GROUP BY
             dp.delivery_id
        ) AS total_extra_points ON total_extra_points.delivery_id = d._row_id
    WHERE
        d._row_id = ?        
    ]], self._row_id)
end


function Delivery:addCategoryToDelivery(category, count)
    local categories = self:getCategories()
    -- print(dump_table("CATEGOREUY="..category..", count=".. count))
    local row = self:findRowBy(categories, 'name', category)
    
    -- print(dump_table("ROW=" .. dump_table(row, true)))
    
    if row then
        return self.db:q([[
            UPDATE delivery_categories SET count=? WHERE delivery_id=? AND category_id=?
        ]], count, self._row_id, row.category_id)
    end

    return self.db:q([[
        INSERT INTO
            delivery_categories (delivery_id, count, category_id)
        VALUES
            (?, ?, (SELECT _row_id FROM categories WHERE _row_id=? OR name=?))
    ]], self._row_id, count, category, category)
end



function Delivery:removeCategoryFromDelivery(category)
    return self.db:q([[
        DELETE FROM delivery_categories WHERE delivery_id=? AND category_id=(
            SELECT _row_id FROM categories WHERE name=? OR _row_id=?
        )
    ]], self._row_id, category, category)
end



function Delivery:removePersonFromDelivery(person)
    return self.db:q([[
        DELETE FROM delivery_persons WHERE delivery_id=? AND person_id=(
            SELECT _row_id FROM persons WHERE name=? OR _row_id=?
        )
    ]], self._row_id, person, person)
end


function Delivery:addPersonToDelivery(person)
    local categories = self:getPersons()
    local row = self:findRowBy(categories, 'name', person)

    if row then
        return false
    end

    return self.db:q([[
        INSERT INTO
            delivery_persons (delivery_id, person_id)
        VALUES
            (?, (SELECT _row_id FROM persons WHERE _row_id=? OR name=?))
    ]], self._row_id, person, person)
end


function Delivery:getPersons()
    local rows = self.db:q([[
        SELECT 
            p._row_id AS person_id, p.name AS name,
            dp.extra_points AS extra_points
        FROM
            delivery_persons AS dp
        JOIN
            persons AS p ON dp.person_id = p._row_id
        WHERE
            dp.delivery_id=?
    ]], self._row_id)

    return self:map(rows, function(r) return Person:new(r) end)
end


function Delivery:getCategories()
    local rows = self.db:q([[
        SELECT 
            c._row_id AS category_id, c.name AS name, c.points AS points,
            dc.count * c.points AS points_for_loot, dc.count
        FROM
            delivery_categories AS dc
        JOIN
            categories AS c ON dc.category_id = c._row_id
        WHERE
            dc.delivery_id=?
    ]], self._row_id)

    return self:map(rows, function(r) return Person:new(r) end)
end


function Delivery:getDeliveryCategories()
    self._deliveryCategories = DeliveryCategory:where("delivery_id="..self._row_id)
    return self._deliveryCategories
end


function Delivery:getDeliveryPersons()
    self._deliveryPersons = DeliveryPerson:where("delivery_id="..self._row_id)
    return self._deliveryPersons
end


function Delivery:details()
    local row = self.db:q([[
    SELECT
        d._row_id AS delivery_id,
        p._row_id AS person_id,
        p.name AS person_name,
        SUM(c.points * dc.count)/COUNT(p._row_id) AS points_collected
    FROM
        deliveries d
    JOIN
        delivery_persons dp ON d._row_id = dp.delivery_id
    JOIN
        persons p ON dp.person_id = p._row_id
    JOIN
        delivery_categories dc ON d._row_id = dc.delivery_id
    JOIN
        categories c ON dc.category_id = c._row_id
    WHERE
        d._row_id = ?
    GROUP BY
        p._row_id
    ]], self._row_id)
    
    return row
end


function Delivery:friendlyTable()
    return self.db:q([[
        SELECT
        d._row_id as id,
        d.description,
        d.date,
        COUNT(DISTINCT p._row_id) AS persons_count,
        (
            SELECT SUM(dc.count * c.points)
            FROM delivery_categories AS dc
            JOIN categories AS c ON c._row_id = dc.category_id
            WHERE dc.delivery_id = d._row_id
        ) AS total_points,
        (
            SELECT SUM(dp.extra_points)
            FROM delivery_persons AS dp
            WHERE dp.delivery_id = d._row_id
        ) AS total_extra_points,
        GROUP_CONCAT(p.name, ', ') AS participants
    FROM
        deliveries AS d
    JOIN
        delivery_persons AS dp ON dp.delivery_id = d._row_id
    JOIN
        persons AS p ON p._row_id = dp.person_id
    WHERE
        d._row_id = ?
    GROUP BY
        d._row_id
    ]], self._row_id)[1]
end
