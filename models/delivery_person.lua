DeliveryPerson = {
    _tableName = 'delivery_persons',
    _primaryKey = {'delivery_id', 'person_id'}
}

setmetatable(DeliveryPerson, { __index = Model })
