function scripts.rckn.getMaxLength(t, index)
    local max = 0

    for i, value in ipairs(t) do
        if value[index] and #(value[index] > max) then
            max = #(value[index])
        end
    end

    return max
end


dump_table = dump_table or function(o, newline)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          if newline then
           s = s .. '['..k..'] = ' .. dump_table(v, newline) .. ',\n'
          else
           s = s .. '['..k..'] = ' .. dump_table(v, newline) .. ','
          end
       end
       return s .. '} '
    else
       return tostring(o)
    end
end
