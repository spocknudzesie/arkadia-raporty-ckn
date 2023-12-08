string.capitalize = string.capitalize or function(s)
    return s:gsub("^%l", string.upper)
end


scripts.rckn.interface = {
    colors = {
        error = {
            fg='#aa0000',
        },
        warn = {
            fg='#aaaa00',
        },
        default = {
            fg='#eeeeee',
            bg='#111111'
        },
        output = {
            bg='000000',
            fg='aaaaaa'
        }
        
    },
    width = 100
}


function scripts.rckn.interface:showWindow()
    self.window = self.window or Geyser.MiniConsole:new({
        name = "rckn",
        titleText ="Raporty CKN",
        x = "20%", y="20%",
        width=self.width .. 'c', height ="40c",
        autoWrap = true,
        bgcolor = '#000000'
    })

    return self.window
end


function scripts.rckn.interface:setupCommandLine()
    self.cmdLine = self.cmdLine or Geyser.CommandLine:new({
        name='rcknCmdLine',
        x=0, y='-2c', width='100%', height='2c'
    }, self.container)

    -- print("BINDING COMMAND BAR")
    self.cmdLine:setAction(function(cmd)
         self:command(cmd)
    end)
end


function scripts.rckn.interface:selectSection(section, args)
    local sectionFunction = 'display' .. section:capitalize()

    if self[sectionFunction] then
        -- print('Moving to section ' .. section .. ' using ' .. sectionFunction)
        self.currentSection = section

        self.window:clear()
        self:printShortcuts()
        self:printErrors()

        self[sectionFunction](self, args)
    end
end


function scripts.rckn.interface:printMenuBar()
    local options = {'Dostawy', 'Osoby', 'Kategorie', 'Filtr', 'Pomoc'}
    local bgColor = '111111'
    local fgColor = 'eeeeee'

    self.menuBar:clear()
    -- print("PRINTING MENU BAR")

    for i, opt in ipairs(options) do
        local label
        -- print("OPTION="..opt)
        if self.currentSection then
            -- print("Current section " .. self.currentSection)
        end
        if self.currentSection == opt then
            -- print("THIS IS TEH SECTION")
            label = string.format('#%s,%s %s #r', bgColor, fgColor, opt)
        else
            label = string.format('#%s,%s %s #r', fgColor, bgColor, opt)
        end
        -- print(label)

        self.menuBar:hechoLink(label, function()
            self.currentSection = opt
            self:menuClicked(opt)
        end, opt, true)
        self.menuBar:echo('|')
    end
end


function scripts.rckn.interface:printSubMenuBar(options, title)
    local bgColor = '222222'
    local fgColor = 'eeeeee'

    self.subMenuBar:clear()
    if not options then
        return
    end

    if title then
        self.subMenuBar:hecho(title .. ' ')
    end

    for i, item in ipairs(options) do
        self.subMenuBar:hechoLink(
            string.format('#%s,%s %s ', fgColor, bgColor, item.label),
            function()
                item.callback(item.label)
            end,
            item.hint or item.label,
            true
        )
        self.subMenuBar:echo('|')
    end
end


function scripts.rckn.interface:clearAll()
    local items = {'window', 'console', 'titleBar', 'menuBar', 'subMenuBar', 'output'}

    for i, item in ipairs(items) do
        if self[item] then
            -- print("Clearing " .. item)
            self[item]:clear()
        end
    end
end


function scripts.rckn.interface:showPopup(options)
    options = options or {}
    
    local wordWrap = function (str, width)
        local lines = {}
        local current_line = {}
    
        for word in str:gmatch("%S+") do
            if #table.concat(current_line, " ") + #word + 1 <= width then
                table.insert(current_line, word)
            else
                table.insert(lines, table.concat(current_line, " "))
                current_line = {word}
            end
        end
    
        if #current_line > 0 then
            table.insert(lines, table.concat(current_line, " "))
        end
    
        return lines
    end

    local lines = wordWrap(options.message, 40)

    -- print(dump_table(lines, true))
    -- Example usage:
    local colors = {
        fg = 'black',
        bg = 'white'
    }

    if options.type == 'error' then
        colors.fg = 'white'
        colors.bg = self.colors.error.fg
    end

    self.popupFrame = self.popupFrame or Geyser.Container:new({
        x = '25%', y='25%',
        name = 'rcknPopup',
        width = '40c', height = #lines .. 'c'
    }, self.container)

    self.popupFrame:show()
    local style = Geyser.StyleSheet:new({
        ['border'] = '5px solid red',
        ['padding'] = '20px',
        ['background'] = colors.bg,
        ['color'] = colors.fg
    })

    -- print(style:getCSS())

    self.popupBody = self.popupBody or Geyser.MiniConsole:new({
        x = '1c', y='1c',
        name = 'rcknPopupBody',
        fgColor = '#ffffff',
        bgColor = '#7f0000',
        width = '100% - 2c', height = #lines .. 'c',
    }, self.popupFrame)

    -- self.popupBody:setStyleSheet(style:getCSS())

    self.popupBody:clear()
    
    local msg = table.concat(lines, '\n') or "PLACEHOLDER"
    -- print(msg)
    self.popupBody:echo(msg)

    tempTimer(options.timeout or 5.0, function() self.popupFrame:hide() end)
end


function scripts.rckn.interface:init()

    self.window = self.window or Geyser.UserWindow:new({
        x = '20%', y='20%',
        title='Raporty CKN',
        name = 'rckn',
        width = self.width .. 'c', height='43c',
    })

    self.container = self.container or Geyser.Container:new({
        x = 0, y = 0,
        name = "rcknContainer", padding = 15,
        width = "100%", height = "100%",
    }, self.window)

    self.menuBar = self.menuBar or Geyser.MiniConsole:new({
        name = 'rcknMenuBar',
        bgColor = '#111111',
        fgColor = '#eeeeee',
        x=0, y=0,
        fontSize = 8,
        width = '100%', height = '1c'
    }, self.container)

    self.subMenuBar = self.subMenuBar or Geyser.MiniConsole:new({
        name = 'rcknSubMenuBar',
        bgColor = '#111111',
        fgColor = '#eeeeee',
        x=0, y='1c',
        fontSize = 8,
        width = '100%', height = '1c'
    }, self.container)

    self.titleBar = self.titleBar or Geyser.MiniConsole:new({
        name = 'rcknTitleBar',
        bgColor = '#eeeeee',
        fgColor = '#7f0000',
        x=0, y='2c',
        -- x = '25%', y='25%', width='25%', height='25%',
        fontSize = 8,
        width = '100%', height = '1c'
    }, self.container)

    self.console = self.console or Geyser.MiniConsole:new({
        name = 'rcknConsole',
        x=0, y="3c",
        autoWrap = true,
        fgColor = '#aa0000',
        bgColor = "#111111",
        fontSize = 8,
        width = "100%", height = "100% - 6c"
    }, self.container)

    self.output = self.output or Geyser.MiniConsole:new({
        name = 'rcknOutput',
        bgColor = '#' .. self.colors.output.bg,
        fgColor = '#' .. self.colors.output.fg,
        color = '#' .. self.colors.output.bg,
        -- color = '#7faa00,222222',
        x=0, y="-5c",
        autoWrap=true,
        fontSize = 8,
        width = '100%', height = '3c'
    }, self.container)

    self.container:show()

    self:clearAll()

    self:printMenuBar()
    self:printSubMenuBar()
    -- self.subMenuBar:echo("SUBMENU")
    -- self.titleBar:echo("TITLE BAR TEST")
    -- self.titleBar:setStyleSheet([[
    --     border: 5px solid red
    -- ]])
    -- self.console:echo("CONSOLE TEST TEEST 2")
    -- self.output:echo("OUTPUT TEST")

    self:setupCommandLine()
    self:menuClicked('Pomoc')
    -- self:selectSection('pomoc')
end

function scripts.rckn.interface:displayError(error)
    local label = self.colors.error.fg .. error
    self.output:hecho(label .. '\n')
    self:showPopup({message=error, type='error'})
end


function scripts.rckn.interface:setTitle(text, dontClear)
    if not dontClear then
        self.titleBar:clear()
    end

    self.titleBar:fg('white')
    self.titleBar:hecho('#222222,eeeeee\r ' .. text .. string.rep(' ', (self.width - #text)))
end


function scripts.rckn.interface:printToConsole(text, clear)
    if clear then
        self.console:clear()
    end

    self.console:hecho(text)
end


function scripts.rckn.interface:printToOutput(text, clear, t)
    if clear then
        self.output:clear()
    end

    local formats = {
        warn = {
            color = '#aa0000#b',
            symbol = '!'
        },
        ok = {
            color = '#00aa00',
            symbol = '+',           
        },
        info = {
            color = '#aaaa00',
            symbol = '*',
        },
        nok = {
            color = '#ff7f00',
            symbol = '-'
        }
    }

    if t then
        self.output:hecho(string.format('%s(%s) %s#r#/b', formats[t].color, formats[t].symbol, text))
    else
        self.output:hecho(string.format('#%s,%s\r%s#r', self.colors.output.fg, self.colors.output.bg, text))
    end
end


function scripts.rckn.interface:menuClicked(item)
    -- print("MENUY CLICKED: " .. item)

    self:printMenuBar()

    if item == 'Start' then
        return self:displayHelp()
    end

    if item == 'Pomoc' then
        return self:displayHelp()
    end

    if item == 'Dostawy' then
        return self:printDeliveries()
    end

    if item == "Osoby" then
        return self:printPersons()
    end

    if item == "Kategorie" then
        return self:displayCategories()
    end

    if item == "Filtr" then
        return self:displayCalendar()
    end    
end


function scripts.rckn.interface:displayHelp(cmd)
    local line = function(command, params, desc)
        self:printToConsole(string.format('#ffffff- %s %s#r - %s\n', command, params, desc))
    end

    self:printSubMenuBar({
        {
            label = 'ogolna',
            callback = function()
                self:displayHelp()
            end,
        },
        {
            label = 'dostawy',
            callback = function()
                self:displayHelp('dostawy')
            end,
        },
        {
            label = 'osoby',
            callback = function()
                self:displayHelp('osoby')
            end,
        },
        {
            label = 'kategorie',
            callback = function()
                self:displayHelp('kategorie')
            end
        },
        {
            label = 'filtr',
            callback = function()
                self:displayHelp('filtr')
            end
        }
    })
    self:setTitle('Pomoc raportow CKN')

    self:printToConsole('\n', true)
    if not cmd then
        self:printToConsole('Z menu u gory wybierz odpowiednia sekcje.\n'
            .. 'Z submenu wybierz odpowiednia opcje dla tej sekcji.\n'
            .. 'Mozesz tez uzyc komend opisanych w pomocy.\n\n')
        self:printToConsole('Szczegolowa pomoc: "pomoc <komenda>" lub wybierz z menu powyzej.\n')
        self:printToConsole('- dostawy\n')
        self:printToConsole('- osoby\n')
        self:printToConsole('- kategorie\n')
        return
    end

    local m, i = cmd:match("(dostaw.)")
    -- print(dump_table({m, i}))

    if m then
        self:setTitle("Pomoc - dostawy")
        self:printToConsole('\n', true)
        self:printToConsole("Dostawy posiadaja <date> oraz <opis>. "
        .. "Do kazdej dostawy przypisane sa <osoby> oraz <kategorie>. "
        .. "Kazda <kategoria> przypisana do dostawy ma pewna ilosc, ktora sklada sie na sume "
        .. "punktow za dana dostawe. Punkty sa rozdzielane rowno miedzy przypisane do dostawy <osoby>.\n\n")
        
        self:printToConsole("W oknie listy dostaw dostepna jest komenda:\n")
        self:printToConsole("- dodaj <data> <opis> - dodaje dostawe do listy\n\n")

        self:printToConsole("W oknie edycji dostawy dostepne sa komendy:\n")
        self:printToConsole("- data <wartosc> - ustawia date danej dostawy\n")
        self:printToConsole("- opis <wartosc> - ustawia opis danej dostawy\n")
        return
    end

    m, i = cmd:match("(osob.)")
    -- print(dump_table({m, i}))
    
    if m then
        self:setTitle("Pomoc - osoby")
        self:printToConsole('\n', true)
        self:printToConsole("Osoby posiadaja <imie>. Kazda osoba gromadzi punkty "
        .. "poprzez uczestniczenie w <dostawach>.\n\n")
        self:printToConsole("W oknie listy osob dostepne sa komendy:\n")
        self:printToConsole("- dodaj <imie> - dodaje osobe o podanym imieniu\n")
        self:printToConsole("- +<imie> - j/w\n")
        return
    end

    m, i = cmd:match("(kategori.)")
    -- print(dump_table({m, i}))

    if m then
        self:setTitle("Pomoc - kategorie")
        self:printToConsole('\n', true)
        self:printToConsole("Kategorie posiadaja <nazwe> oraz <punkty>. W ramach dostawy, w ktorej "
        .. "zdobyto towary poszczegolnych kategorii, kazda z nich ma przypisana pewna <ilosc>, ktora "
        .. "przemnozona przez <punkty> kategorii, daje sume zdobytych punktow.\n")
        self:printToConsole("W oknie listy osob kategorii dostepne sa komendy:\n")
        self:printToConsole("- dodaj <nazwa> - dodaje kategorie o podanej nazwie\n")
        self:printToConsole("- +<nazwa> - j/w\n")
        return
    end

    if m then
        self:setTitle("Pomoc - filtry")
        self:printToConsole('\n', true)
        self:printToConsole("Filtr ogranicza wyswietlane <dostawy> do wybranego zakresu czasowego.\n")
        return
    end

    self:displayError('Bledna komenda pomocy')
    self:displayHelp()
end


function scripts.rckn.interface:textLabel(label, color)
    return string.format('%s%s#r', color, label)
end


function scripts.rckn.interface:textLink(label, callback, hint, color)
    color = color or '#dddddd'

    -- print(dump_table({label, hint, color}))
    return self.console:hechoLink(self:textLabel(label, color), callback, hint, true)
end


function scripts.rckn.interface:text(text, color)
    if color then
        self.console:hecho(color .. text .. '#r')
    else
        self.console:hecho(text)
    end
end


function scripts.rckn.interface:printHeader(text)
    local filler = 80 - #text

    self:text('#dddddd,00000000' .. text .. string.rep(' ', filler) .. '\n')
    self:text('#dddddd,00000000' .. string.rep('⎯', 80) .. '#r\n')
end


function scripts.rckn.interface:setFilter(arg)
    self.filter = arg
end


function scripts.rckn.interface:getConfirmation(action)
    self.confirmations = self.confirmations or {}
    if self.confirmations[action] then
        self.confirmations[action] = nil
        self.confirmations.tempTimer = tempTimer(5.0, function()
            if self.confirmations[action] then
                -- print(string.format("Confirmation for action '%s' removed", action))
                self.confirmations[action] = nil
            end
        end)
        return true
    end

    self.confirmations[action] = true
end

--
-- CALENDAR
--

function scripts.rckn.interface:displayCalendar(y, m, filterField)
    local monthLenghts = {31, 28, 31, 30, 31, 30,  31, 31, 30, 31, 30, 31}
    local year, month, day
    local weekDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'}

    local getWeekday = function(year, month, day)
        local dateString = string.format("%04d-%02d-%02d", year, month, day)
        local pattern = "%a"  -- %A returns the full weekday name
        local timestamp = os.time{year = year, month = month, day = day}
        local weekday = os.date(pattern, timestamp)

        return weekday
    end

    local title
    
    if not y then
        self.tempFilter = nil
    end

    self.tempFilter = self.tempFilter or {}


    self.calendar = {
        year = y or tonumber(os.date('%Y')),
        month = m or tonumber(os.date('%m'))
    }

    if self.calendar.year % 4 == 0 then
        monthLenghts[2] = 29
    end

    filterField = filterField or 'from'

    -- print(dump_table(self.calendar))
    title = 'Zakres dat '

    self:setTitle(title)

    self:printToConsole('\n\t', true)

    if filterField == 'from' then
        self:printToConsole('#ffffff\rWybierz date poczatkowa:#r\n')
    else
        self:printToConsole('#ffffff\rWybierz date koncowa:#r\n')
    end

    if self.filter then
        self:printToConsole(string.format('\n\tObecny filtr: %s do %s\n', self.filter.from, self.filter.to))
    end

    self:printToConsole('\n\n\tROK:     ')
    self.console:hechoLink('<', function()
        self:displayCalendar(self.calendar.year - 1, self.calendar.month)
    end, 'rok wstecz', true)

    self:printToConsole(' ' .. self.calendar.year .. ' ')
    self.console:hechoLink('>', function()
        self:displayCalendar(self.calendar.year + 1, self.calendar.month)
    end, 'rok naprzod', true)

    self:printToConsole('\n\tMIESIAC: ')
    self.console:hechoLink('<', function()
        if self.calendar.month == 1 then
            self.calendar.month = 13
            self.calendar.year = self.calendar.year - 1
        end        
        self:displayCalendar(self.calendar.year, self.calendar.month - 1, filterField)
    end, 'miesiac wstecz', true)

    self:printToConsole(string.format('  %2d  ', self.calendar.month))
    self.console:hechoLink('>', function()
        if self.calendar.month == 12 then
            self.calendar.month = 0
            self.calendar.year = self.calendar.year + 1
        end
        
        self:displayCalendar(self.calendar.year, self.calendar.month + 1, filterField)
    end, 'miesiac naprzod', true)

    local firstWeekdayOfMonth = getWeekday(self.calendar.year, self.calendar.month, 1)
    local weekdayOffset
    -- print(string.format("FIRST WEEKDAY OF %d/%d is %s", self.calendar.year, self.calendar.month, firstWeekdayOfMonth))

    self:printToConsole('\n\n\t')
    for i, day in ipairs(weekDays) do
        self:printToConsole(string.format('%s ', day))
        if firstWeekdayOfMonth == day then
            weekdayOffset = i
        end
    end
    self:printToConsole('\n\t')

    local w = weekdayOffset

    -- self:printToConsole(string.rep('   ', w))

    -- print('weekday offset = ' .. w)
    for i=-(w-2),monthLenghts[self.calendar.month],1 do

        if i < 1 then
            self:printToConsole('    ')
        else
            local date = string.format('%4d-%02d-%02d', self.calendar.year, self.calendar.month, i)
            local dayLabel = string.format(' %2d ', i)

            if filterField == 'to' then
                if date == self.tempFilter.from then
                    if self.tempFilter.to then
                        dayLabel = string.format(' #111111,00aa00\r%2d#r ', i)
                    else
                        dayLabel = string.format(' #111111,ffffff\r%2d#r ', i)
                    end
                elseif date == self.tempFilter.to then
                    dayLabel = string.format(' #111111,00aa00\r%2d#r ', i)
                end
            end

            self.console:hechoLink(dayLabel, function()
                self.tempFilter[filterField] = date
                if filterField == 'to' then
                    if date < self.tempFilter['from'] then
                        local error = 'Data koncowa nie moze byc wczesniejsza niz poczatkowa.\n'
                        self:printToOutput(error, false, 'warn')
                        self:displayError(error)
                        return
                    end

                    self:printToOutput('Data koncowa filtra ustawiona na ' .. date .. '\n', false, 'ok')
                    self:setFilter(self.tempFilter)
                    
                else
                    self:printToOutput('Data poczatkowa filtra ustawiona na ' .. date .. '\n', false, 'ok')
                end
                self:displayCalendar(self.calendar.year, self.calendar.month, 'to')
            end, 'Wybierz ' .. date, true)

            if w % 7 == 0 then
                self:printToConsole('\n\t')
            end            
            w = w + 1
        end
        
    end

    self:printToConsole('\n\n\t')
    self.console:hechoLink('[Wyczysc filtr]', function()
        self.filter=nil
        self:displayCalendar()
    end, 'Wyczysc filtr', true)
end
