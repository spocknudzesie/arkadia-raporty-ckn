function scripts.rckn.db:addPersonToDelivery(delivery, person)
    local id, err = self:query(string.format([[
        SELECT * FROM deliveries
        WHERE _row_id=%s
    ]], delivery))

    if #id == 0 then
        scripts.rckn:msg('debug', 'Brak dostawy od id=%s', delivery)
        return false
    end

    local ok, err = self:query(string.format([[
        SELECT * FROM delivery_persons
        WHERE delivery_id=%s AND person_id=(
            SELECT _row_id FROM persons WHERE name='%s')
        ]], delivery, person))

    if not err and #ok > 0 then
        scripts.rckn:msg('debug', 'Para dostawa-osoba %s-%s juz istnieje: %s', delivery, person, dump_table(ok))
        return false
    end

    ok = self:query(string.format([[
    INSERT INTO delivery_persons (delivery_id, person_id)
    VALUES (%s, (
        SELECT _row_id FROM persons WHERE name='%s'
    ))]], delivery, person))

    return self:query(string.format([[
        SELECT 
            d._row_id AS delivery_id, strftime('%Y-%m-%d', datetime(d.date, 'unixepoch')) AS date, d.description,
            p._row_id AS person_id, p.name
        FROM
            deliveries AS d
        JOIN
            
    ]]))
end


function scripts.rckn.db:removePersonFromDelivery(delivery, person)
    return self:query(string.format([[
    DELETE FROM delivery_persons
    WHERE delivery_id=%s AND person_id=(SELECT _row_id FROM persons WHERE name='%s')]],
    delivery, person))
end


function scripts.rckn.db:addCategoryToDelivery(delivery, category, count)
    if not count or count <= 0 then
        scripts.rckn:msg('error', 'Liczba przedmiotow musi byc wieksza niz 0')
        return false
    end

    local id, err = self:query(string.format([[
        SELECT * FROM deliveries
        WHERE _row_id=%s
    ]], delivery))

    if #id == 0 then
        scripts.rckn:msg('debug', 'Brak dostawy o id=%s', delivery)
        return false
    elseif err then
        scripts.rckn.error = err
        return false
    end

    local id, err = self:query(string.format([[
        SELECT * FROM categories
        WHERE name='%s'
    ]], category))

    if #id == 0 then
        scripts.rckn:msg('debug', 'Brak kategorii o id=%s', delivery)
        return false
    elseif err then
        scripts.rckn.error = err
        return false
    end

    local ok, err = self:query(string.format([[
        SELECT * FROM delivery_categories
        WHERE delivery_id=%s AND category_id=(
            SELECT _row_id FROM categories WHERE name='%s')
        ]], delivery, category))

    if not err and #ok > 0 then
        scripts.rckn:msg('debug', 'Para dostawa-kategoria %s-%s juz istnieje: %s', delivery, category, dump_table(ok))
        scripts.rckn:msg('debug', 'Probuje zrobic update dla dostawy %s', delivery)

        ok, err = self:query(string.format([[
            UPDATE delivery_categories
            SET count = %s
            WHERE
                delivery_id=%s
                AND category_id=(
                    SELECT _row_id FROM categories WHERE name='%s'
                )
        ]], count, delivery, category))

        if ok then
            return ok
        end

        return false
    end

    return self:query(string.format([[
    INSERT INTO delivery_categories (delivery_id, category_id, count)
    VALUES (%s, (
        SELECT _row_id FROM categories WHERE name='%s'
    ), %s)]], delivery, category, count))
end


function scripts.rckn.db:getDeliveryItems(delivery)
    local ok, err = self:query(string.format([[
        SELECT 
            d._row_id AS delivery_id,
            d.date, d.description,
            c.name, (c.points * dc.count) AS points,
            dc.count
        FROM
            deliveries d
        JOIN
            delivery_categories dc ON d._row_id = dc.delivery_id
        JOIN
            categories c ON dc.category_id = c._row_id
        WHERE
            d._row_id = %s
        GROUP BY
            d._row_id, c._row_id
        ORDER BY
            d._row_id, c._row_id;
    ]], delivery))

    return ok
end


function scripts.rckn.db:getDeliveryScore(delivery)
    local ok, err = self:query(string.format([[
        SELECT 
            d._row_id AS delivery_id,
            d.date, d.description,
            p._row_id AS person_id,
            p.name AS person_name,
            SUM(c.points * dc.count) AS total_points_collected,
            c.points
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
            d._row_id = %s
        GROUP BY
            d._row_id, p._row_id
        ORDER BY
            d._row_id, p._row_id;
    ]], delivery))

    -- local ok, err = self:query(string.format([[
    --     SELECT
    --     d._row_id AS delivery_id,
    --     SUM(c.points * dc.count) AS total_points_collected
    -- FROM
    --     deliveries d
    -- JOIN
    --     delivery_categories dc ON d._row_id = dc.delivery_id
    -- JOIN
    --     categories c ON dc.category_id = c._row_id
    -- WHERE
    --     d._row_id = %s
    -- GROUP BY
    --     d._row_id;        
    -- ]], delivery))
    return ok
end


function scripts.rckn.db:getScoreInPeriod(from, to)

    local y,m,d
    
    if type(from) == 'string' then
        y,m,d = unpack(string.split(from, '-'))
        from = os.time({year=y, month=m, day=d, hour=0, min=0, sec=0})
    end

    if type(to) == 'string' then
        y,m,d = unpack(string.split(to, '-'))
        to = os.time({year=y, month=m, day=d, hour=23, min=59, sec=59})
    end

    scripts.rckn:msg('debug', 'Szukanie dla okresu %d - %d', from, to)
    
    local ok, err = scripts.rckn.db:query(string.format([[
    SELECT
        p._row_id AS person_id,
        p.name AS person_name,
        COUNT(DISTINCT d._row_id) AS delivery_count,
        SUM(c.points) AS total_points_collected
    FROM
        persons p
    JOIN
        delivery_persons dp ON p._row_id = dp.person_id
    JOIN
        deliveries d ON dp.delivery_id = d._row_id
    JOIN
        delivery_categories dc ON d._row_id = dc.delivery_id
    JOIN
        categories c ON dc.category_id = c._row_id
    WHERE
        d.date >= %s
        AND d.date <= %s
    GROUP BY
        p._row_id, p.name
    ORDER BY
        p._row_id;
    
    ]], from, to))

    if err then
        scripts.rckn:msg('error', 'Blad wyszukiwania: %s', err)
    end

    return ok
end


function scripts.rckn.db:getAllDeliveries()
    local ok, err = self:query([[
        SELECT 
            d._row_id AS delivery_id,
            strftime('%Y-%m-%d', datetime(d.date, 'unixepoch')) AS date, d.description,
            SUM(c.points * dc.count) AS total_points_collected,
            COUNT(DISTINCT dp._row_id) AS persons
        FROM
            deliveries d
        JOIN
            delivery_persons dp ON d._row_id = dp.delivery_id
        JOIN
            delivery_categories dc ON d._row_id = dc.delivery_id
        JOIN
            categories c ON dc.category_id = c._row_id
        GROUP BY
            d._row_id
        ORDER BY
            d._row_id;
    ]])

    if err then
        scripts.rckn:msg('error', 'Blad zapytania: %s', err)
    end

    return ok
end