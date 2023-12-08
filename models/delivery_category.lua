DeliveryCategory = {
    _tableName = 'delivery_categories',
    _primaryKey = {'delivery_id', 'category_id'}
}

setmetatable(DeliveryCategory, { __index = Model })
