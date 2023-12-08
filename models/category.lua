Category = {
    _tableName = 'categories',
    _beforeDelete = function(d)
        d.db:q('DELETE FROM delivery_categories WHERE category_id=?', d._row_id)
    end,
    _validation = function(attributes)
        local errors = {}
        if not tonumber(attributes.count) then
            errors.count = 'wartosc musi byc liczba'
        end

        if #errors then
            return false
        end
        
        return true
    end,
    _defaultOrder = 'name ASC'
}

setmetatable(Category, { __index = Model })


function Category:getPointsFormat(padding)
    local d, f = math.modf(self.points)
    padding = padding or ''

    if f == 0 then
        format = "%" .. padding .. "d"
    else
        format = "%" .. padding .. "." .. (#tostring(f)-2) .. "f"
    end

    return format
end
