function scripts.rckn:cmdToggle(cmd)
    if not self.interface.window then
        return self.interface:init()
    end

    self.interface.window:show()
end

function scripts.rckn:cmdDodajOsobe(imie)
    imie = imie:lower()

    local person = Person:new({name=imie})

    if person:save() then
        self:msg("ok", "Dodano osobe imieniem " .. imie)
    end
end


function scripts.rckn:cmdPomoc()
    self:msg("info", "Pomoc do skryptu Raporty CKN:")
    hecho('- #ffffff/rckn_pomoc#r - ta pomoc\n')
    hecho('- #ffffff/rckn#r - otwiera okno raportow\n')
    hecho('- #ffffff/rckn_ustaw <opcja> <wartosc> - ustawia podana opcje na podana wartosc\n')
    hecho('- #ffffff/rckn_opcje - wyswietla dostepne opcje i ich wartosci\n')
end


function scripts.rckn:cmdUstaw(matches)
    print(dump_table(matches))
    if #matches < 3 then
        self:msg('error', 'Komenda /rckn_ustaw wymaga parametru <opcja> oraz <wartosc>')
        return false
    end

    local param = matches[2]
    local value = tonumber(matches[3])

    if not value or value <= 0 then
        self:msg('error', 'Parametr wartosc musi byc liczba wieksza niz 0')
        return false
    end

    if not self.settings[param] then
        self:msg('error', string.format('Bledna opcja "%s". Istniejace ustawienia to: %s.\n',
            param, table.concat(table.keys(self.settings), ', ')))
        return false
    end

end


function scripts.rckn:cmdOpcje()
    local printLine = function(opt, desc)
        hecho(string.format('#ffffff%5s#r: %3d #7f7f7f(%s)#r\n', opt, self.settings[opt], desc))
    end

    self:msg("ok", 'Aktualne ustawienia raportow:')
    printLine('baza', 'Bazowa nagroda w zlocie')
    printLine('prog', 'Prog punktow, powyzej ktorego zaczynaja naliczac sie bonusy')
    printLine('skok', 'Co ile punktow naliczana jest wielokrotnosc bonusu')
    printLine('bonus', 'Premia do nagrody w zlocie')


end