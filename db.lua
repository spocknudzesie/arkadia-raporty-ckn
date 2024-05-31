function scripts.rckn:initDb()
    self:msg('info', 'Ladowanie bazy ' .. self.db_path .. '... ')
    db:create(self.db_path, {
        persons={
            name = "",
            _index = {"name"},
            _unique = {"name"}
        },
        deliveries={
            date = "",
            description = "",
            _unique = {{"description"}}
        },
        categories={
            name = "",
            points = 0.0,
            _index = {"name"},
            _unique = {"name"},
        },
        delivery_categories={
            delivery_id = 0,
            category_id = 0,
            count = 0,
            _unique = {{"delivery_id", "category_id"}}
        },
        delivery_persons={
            delivery_id = 0,
            person_id = 0,
            extra_points = 0,
            _unique = {{"delivery_id", "person_id"}}
        }
    })
    self:msg('ok', 'Baza zaladowana')
end


function scripts.rckn.db:convertDate(date, h, min, s)
    local y,m,d

    if type(date) == 'string' then
        -- print("Date passed as string")
        if not string.match(date, '%d+-%d+') and not string.match(date, '%d+-%d+-%d+') then
            -- print("In wrong format tho")
            return false
        end

        if string.match(date, '^%d+-%d+$') then
            date = os.date('%Y') .. '-' .. date
        end
        -- print("Date is " .. date)
        y,m,d = unpack(string.split(date, '-'))
        date = os.time({year=y, month=m, day=d, hour=h, min=min, sec=s})
    end

    return date
end


function scripts.rckn.db:query(text)
    -- print("QUERY: " .. text)
    local res, err = db.__conn[scripts.rckn.db_path]:execute(text)
    if not res then
        return self:error(err)
    end

    local d = db:get_database(scripts.rckn.db_path)
    d:_end()
    d:_commit()

    return db:cursorToTable(res)
end


function scripts.rckn.db:q(query, ...)
    -- print(dump_table(arg, true))
    if not arg then arg = {} end
    -- print("FORMAT QUERY: " .. dump_table(arg, true))
    query = self:formatQuery(query, unpack(arg))
    -- local q = string.format(query, unpack(arg))
    -- scripts.rckn:msg('debug', 'Query:\n%s', query:gsub('\n', ' '))
    return self:query(query)
end


function scripts.rckn.db:formatQuery(query, ...)
    local i = 0
    -- scripts.rckn:msg('debug', 'Formatting query:\n%s', query)
    -- scripts.rckn:msg('debug', 'With args: ' .. dump_table(arg, true))
    -- print(#arg)
    query = query:gsub('?', function()
        local token, sub
        i = i+1
        token = arg[i]
        -- scripts.rckn:msg('debug', 'Token %d=%s', i, token)
        if type(token) == 'string' then
            sub = "'%s'"
        elseif type(token) == 'number' then
            local i, f = math.modf(token)
            -- print(dump_table({token, i, f}))
            if f == 0 then
                sub = "%d"
            else
                sub = '%s'
                -- sub = "%." .. (#tostring(f)-2) .. "f"
            end
        end
        return string.format(sub, token)
    end)

    -- scripts.rckn:msg('debug', 'Formatted:\n%s', query)
    return query
end


function scripts.rckn.db:error(err)
    scripts.rckn:msg('debug', 'Blad zapytania: %s', err)
    self.lastError = err
    return false
end


function scripts.rckn.db:getDeliveries(extra)
    local q = string.format([[
        SELECT d._row_id, d.date, d.description,
        COUNT(dp._row_id) AS persons
        FROM deliveries AS d
        JOIN delivery_persons AS dp ON dp.delivery_id = d._row_id
    ]])
    
    if extra then
        q = q .. " " .. extra
    end

    return self:q(q)
end


function scripts.rckn.db:getPersons(start_date)
    local q = self:q([[
        SELECT
        p._row_id AS person_id,
        p.name AS person_name,
            SUM(c.points / total_persons) AS total_points_collected,
            COUNT(DISTINCT dp._row_id) AS total_deliveries
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
        JOIN
            (
                SELECT
                    delivery_id,
                    COUNT(DISTINCT person_id) AS total_persons
                FROM
                    delivery_persons
                GROUP BY
                    delivery_id
            ) dp_count ON d._row_id = dp_count.delivery_id        
        GROUP BY
            p._row_id, p.name, total_persons
        ORDER BY
            p._row_id
        ]], start_date)

    return q
end


function scripts.rckn.db:addDelivery(date, description)
    date = self:convertDate(date)
    description = description or ''

    -- print(dump_table({date, description}, true))
    local ok, err = self:q([[
        INSERT INTO deliveries
        (date, description)
        VALUES (?, ?)
        ]], date, description)

    if ok then
        return self:q([[SELECT * FROM deliveries ORDER BY _row_id DESC LIMIT 1]])[1]
    end

    -- print('not ok')
    return self:error(err)
end

