scripts.rckn = scripts.rckn or {
    db_path = 'cknreports',
    db = {
        database = nil,
        models = {}
    },
    models = {},
    name = 'rckn',
    pluginName = 'arkadia-raporty-ckn',
    eventHandler = nil,
    debugMode = false,
    settings = {
        prog = 5, -- od ilu punktow nalicza sie bonus
        skok = 10, -- co ile punktow nalicza sie bonus
        bonus = 100, -- ile wynosi bonus w zlotych monetach
        baza = 100, -- bazowa nagroda
    }
}


function scripts.rckn:msg(t, text, ...)
    local prefix = "*"
    local message = string.format(text, unpack(arg))
    local color = "#ffffff"
    local formats = {
        info = {
            prefix = '*',
            color = '#ffffff'
        },
        warn = {
            prefix = '!',
            color = '#ffff00'
        },
        ok = {
            prefix = '+',
            color = '#00ff00'
        },
        error = {
            prefix = '-',
            color = '#ff0000'
        },
        debug = {
            prefix = '#',
            color = '#00aaff',
        }
    }

    if t == 'debug' then
        return
    end
    text = string.format("(%s) [RCKN] %s%s#r\n", formats[t].prefix, formats[t].color, message)
    hecho(text)
end


function scripts.rckn:getSettingsFile()
    local path = getMudletHomeDir() .. "/rckn.lua"
    local attrs = lfs.attributes(path)

    if not attrs then
        table.save(path, self.settings)
    end

    return path
end


function scripts.rckn:load()
    local f = self:getSettingsFile()
    local data

    table.load(f, data)
    if data then
        self.settings = data
    end

    -- self:msg('ok', 'Ustawienia wczytane: ' .. dump_table(self.settings, true))
end


function scripts.rckn:save()
    local f
    table.save(f, self.settings)
end


function scripts.rckn:reload(debug)
    -- print("RELOADING")
    local p = self.pluginName

    if self.reloadKey then killKey(self.reloadKey) end

    self.reloadKey = tempKey(mudlet.keymodifier.Control, mudlet.key.R, function()
        -- print("KEY BOUND")
        self:reload()
    end)

    -- print("UNTER?")
    -- if self.interface and self.interface.window then
    --     print("INTERFANCE")
    --     self.interface.window:clear()
    -- end
    
    scripts[self.name] = nil
    load_plugin('dev/' .. p)
end


function scripts.rckn:init()
    self:initDb()
    self:load()
    self.db.database = db:get_database(self.db_path)
    self:msg('ok', 'Modul RCKN zaladowany. Pomoc dostepna pod komenda /rckn_pomoc')
end

tempTimer(0.0, function()
    scripts.rckn:msg('info', "Wczytywanie modulu RCKN")
    scripts.rckn:init()
end)
