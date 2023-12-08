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
    self.db.database = db:get_database(self.db_path)
end

tempTimer(0.0, function()
    scripts.rckn:msg('info', "Wczytywanie modulu RCKN")
    scripts.rckn:init()
end)
