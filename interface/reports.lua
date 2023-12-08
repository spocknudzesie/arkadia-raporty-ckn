function scripts.rckn.interface:createMassReport(reportablePersons)
    if not self.filter then
        self:printToOutput('Raport mozna utworzyc tylko z podanego zakresu czasowego.\n', false, 'warn')
        return
    end

    
end


function scripts.rckn.interface:createPersonalReport(person)
    if not self.filter then
        self:printToOutput('Raport mozna utworzyc tylko z podanego zakresu czasowego.\n', false, 'warn')
        return
    end

    self:printToOutput(string.format(
        'Generowanie raportu dla: #ffffff%s#r za okres #ffffffod %s do %s#r\n',
            person.name:capitalize(), self.filter.from, self.filter.to))

    
end
