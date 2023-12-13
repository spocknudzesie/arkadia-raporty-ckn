Model = {
    db = scripts.rckn.db,
    _primaryKey = '_row_id'
}

function Model:new(attributes)
    local obj = attributes or {}
    -- print("Model:new called with: " .. dump_table(attributes))
    self._attributes = table.keys(attributes)
    setmetatable(obj, self)
    self.__index = self
    return obj
end


function Model:whereClause(value)
    local conditions = {}

    -- print("WHERE CLAUSE")
    -- print(dump_table(value))
    
    if type(self._primaryKey) == 'table' then
        for i, key in ipairs(self._primaryKey) do
            local val
            if value then
                val = value[i]
            else
                val = self[key]
            end
            table.insert(conditions, string.format("%s='%s'", key, val))
        end
        return string.format('(%s)', table.concat(conditions, ' AND '))
    else
        value = value or self[self._primaryKey]
        return self._primaryKey .. '=' .. value
    end
end


function Model:get(id)
    local row = self.db:q("SELECT * FROM " .. self._tableName .. " WHERE " .. self:whereClause(id) .. " LIMIT 1")

    if row and #row > 0 then
        -- print("Row " .. id .. " fetched successfully from " .. self._tableName .. ":\n" .. dump_table(row[1], true))
        return self:new(row[1])
    end

    -- print("Row " .. id .. " not found in " .. self._tableName)
    return nil
end


function Model:findBy(conditions, junction)
    local clause = ''

    junction = junction or 'AND'
    
    if type(conditions) == 'table' then
        local partial = {}
        
        for k, v in pairs(conditions) do
            table.insert(partial, string.format("%s='%s'", k, v))
        end

        clause = table.concat(partial, ' ' .. junction .. ' ')
    else
        clause = conditions
    end

    local row = self.db:q("SELECT * FROM " .. self._tableName .. " WHERE (" ..clause .. ") LIMIT 1")

    if row and #row > 0 then
        return self:new(row[1])
    end

    return nil
end


function Model:where(conditions)
    local clause = ''

    junction = junction or 'AND'
    
    if type(conditions) == 'table' then
        local partial = {}
        
        for k, v in pairs(conditions) do
            table.insert(partial, string.format("%s='%s'", k, v))
        end

        clause = table.concat(partial, ' ' .. junction .. ' ')
    else
        clause = conditions
    end

    local row = self.db:q("SELECT * FROM " .. self._tableName .. " WHERE (" .. clause .. ") ")

    if row and #row > 0 then
        return self:map(row, function(r)
            return self:new(r)
        end)
    end

    return {}
end


function Model:delete(conditions)
    local row

    if self._beforeDelete then
        self._beforeDelete(self)
    end

    row = self.db:q(string.format([[
        DELETE FROM %s
        WHERE %s
    ]], self._tableName, self:whereClause()))

    return row
end


function Model:map(data, fun)
    local result = {}

    for k,v in pairs(data) do
        result[k] = fun(v)
    end
    return result
end


function Model:setAttribute(attribute, value)
    local q = string.format([[
        UPDATE %s
        SET %s=?
        WHERE %s
    ]], self._tableName, attribute, self:whereClause())
    self.attribute = value

    return self.db:q(q,value)
end


function Model:setAttributes(attributes)
    local set = {}
    local validation

    if self._validate then
        validation = self._validate(attributes)
        if not validation then
            self.errors = validation
            return false
        end
    end

    for name, value in pairs(attributes) do
        if not string.match(name, '^_') then
            table.insert(set, string.format("%s='%s'", name, value))
            self[name] = value
        end
    end

    return self.db:q(string.format([[
        UPDATE %s
        SET %s
        WHERE %s
    ]], self._tableName, table.concat(set, ', '), self:whereClause()))
end


function Model:insert()
    local columns
    local values = {}

    values = self:map(self._attributes, function(r) return self[r] end)

    local row = self.db:q(string.format([[
        INSERT INTO %s (%s)
        VALUES (%s)
    ]],
        self._tableName,
        table.concat(self._attributes, ', '),
        table.concat(self:map(values, function(r) return '?' end), ', ')),
    unpack(values))

    if row then
        row = self.db:q("SELECT * FROM " .. self._tableName .. " ORDER BY _row_id DESC LIMIT 1")[1]
        return self:new(row)
    else
        return false
    end

    return false
end


function Model:save()
    local attrs = {}
    
    if self._row_id then
        for _, attribute in ipairs(self._attributes) do
            attrs[attribute] = self[attribute]
        end

        self:setAttributes(attrs)
        return self
    else
        return self:insert()
    end

end


function Model:findRowBy(rows, field, value)
    for i, row in ipairs(rows) do
        if row[field] == value then
            return row
        end
    end

    return false
end


function Model:getAll()
    local rows
    
    if self._defaultOrder then
        rows = scripts.rckn.db:q("SELECT * FROM " .. self._tableName .. ' ORDER BY ' .. self._defaultOrder)
    else
        rows = scripts.rckn.db:q("SELECT * FROM " .. self._tableName)
    end

    local res = {}

    if not rows then
        return false
    end

    return self:map(rows, function(r) return self:new(r) end)
end


