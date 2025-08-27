Config = Config or {}

-- Largura/altura das grids padrão
Config.DefaultGrid = { w = 10, h = 18 }

-- Intervalo de save em lote (segundos)
Config.SaveInterval = tonumber(GetConvar('lootify:save_interval', '30'))

-- Framework: auto | esx | qbox | standalone
Config.Framework = GetConvar('lootify:framework', 'auto')

-- Logs básicos
Config.Debug = true
