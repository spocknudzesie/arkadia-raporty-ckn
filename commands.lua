function scripts.rckn:cmdToggle(cmd)
    if not self.interface.window and cmd == '+' then
        return self.interface:init()
    end

    if cmd == '+' then
        self.interface.window:show()
    elseif cmd == '-' then
        self.interface.window:hide()
    end
end

function scripts.rckn:cmdDodajOsobe(imie)
    imie = imie:lower()

    local person = Person:new({name=imie})

    if person:save() then
        self:msg("ok", "Dodano osobe imieniem " .. imie)
    end
end

