-- Mapear uma tecla para abrir (ex.: F2)
CreateThread(function()
    local key = 289 -- F2
    while true do
        Wait(0)
        if IsControlJustPressed(0, key) then
            ExecuteCommand('lootify')
        end
    end
end)
