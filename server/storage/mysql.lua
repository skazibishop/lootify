-- lootify/server/storage/mysql.lua
-- Backend de persistência usando oxmysql
-- - Cria tabelas (inventários e itens)
-- - FetchOrCreateInventory / LoadItems / UpdateInventoryMeta
-- - ApplyOps: INSERT / UPDATE dinâmico / DELETE dentro de transação

local Storage = {}

-- Criação das tabelas (se não existirem)
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS lootify_inventories (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            owner_identifier VARCHAR(64) NOT NULL,
            inv_type VARCHAR(64) NOT NULL,
            grid_w SMALLINT NOT NULL,
            grid_h SMALLINT NOT NULL,
            meta JSON NULL,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY uniq_owner_type (owner_identifier, inv_type),
            INDEX idx_owner (owner_identifier)
        )
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS lootify_items (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            inventory_id BIGINT NOT NULL,
            grid_key VARCHAR(32) NOT NULL DEFAULT 'main',
            name VARCHAR(64) NOT NULL,
            amount INT NOT NULL DEFAULT 1,
            size_w SMALLINT NOT NULL,
            size_h SMALLINT NOT NULL,
            rot TINYINT NOT NULL DEFAULT 0,
            pos_x SMALLINT NOT NULL,
            pos_y SMALLINT NOT NULL,
            durability FLOAT NULL,
            metadata JSON NULL,
            version INT NOT NULL DEFAULT 1,
            INDEX idx_inv (inventory_id),
            INDEX idx_inv_grid (inventory_id, grid_key),
            CONSTRAINT fk_inv FOREIGN KEY (inventory_id) REFERENCES lootify_inventories(id) ON DELETE CASCADE
        )
    ]])
end)

-- Busca um inventário do dono+tipo; se não existir, cria com tamanho/meta iniciais
function Storage.FetchOrCreateInventory(owner_identifier, inv_type, w, h, grids)
    local row = MySQL.single.await(
        'SELECT * FROM lootify_inventories WHERE owner_identifier = ? AND inv_type = ? LIMIT 1',
        { owner_identifier, inv_type }
    )
    if row then return row end

    local meta = grids and { grids = grids } or {}
    local ins = MySQL.insert.await(
        'INSERT INTO lootify_inventories (owner_identifier, inv_type, grid_w, grid_h, meta) VALUES (?, ?, ?, ?, ?)',
        { owner_identifier, inv_type, w, h, json.encode(meta) }
    )
    return MySQL.single.await('SELECT * FROM lootify_inventories WHERE id = ?', { ins })
end

-- Carrega todos os itens de um inventário
function Storage.LoadItems(inventory_id)
    return MySQL.query.await('SELECT * FROM lootify_items WHERE inventory_id = ?', { inventory_id }) or {}
end

-- Atualiza o campo meta do inventário (grids/layout/etc.)
function Storage.UpdateInventoryMeta(inventory_id, metaTable)
    return MySQL.update.await('UPDATE lootify_inventories SET meta=? WHERE id=?', { json.encode(metaTable or {}), inventory_id })
end

-- Executa uma lista de operações num inventário dentro de uma transação
-- ops = {
--   { op='insert', item = { name, amount, size={w,h}, rot, pos={x,y}, grid_key, durability, metadata(table) } },
--   { op='update', item = { id, version, amount?, pos={x,y}?, rot?, grid_key? } },
--   { op='delete', id = <itemId> },
-- }
function Storage.ApplyOps(inventory_id, ops)
    if not ops or #ops == 0 then return true end

    local queries = {}

    for _, o in ipairs(ops) do
        if o.op == 'insert' then
            local it = o.item
            queries[#queries+1] = {
                query = [[
                    INSERT INTO lootify_items
                    (inventory_id, grid_key, name, amount, size_w, size_h, rot, pos_x, pos_y, durability, metadata)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ]],
                values = {
                    inventory_id,
                    it.grid_key or 'main',
                    it.name,
                    it.amount or 1,
                    it.size.w, it.size.h,
                    it.rot or 0,
                    it.pos.x, it.pos.y,
                    it.durability,
                    json.encode(it.metadata or {})
                }
            }

        elseif o.op == 'update' then
            local it = o.item
            local sets, vals = {}, {}

            if it.amount ~= nil then
                sets[#sets+1] = 'amount=?'
                vals[#vals+1] = it.amount
            end
            if it.pos ~= nil then
                sets[#sets+1] = 'pos_x=?'; vals[#vals+1] = it.pos.x or 0
                sets[#sets+1] = 'pos_y=?'; vals[#vals+1] = it.pos.y or 0
            end
            if it.rot ~= nil then
                sets[#sets+1] = 'rot=?'; vals[#vals+1] = it.rot
            end
            if it.grid_key ~= nil then
                sets[#sets+1] = 'grid_key=?'; vals[#vals+1] = it.grid_key
            end

            -- controle de concorrência otimista
            sets[#sets+1] = 'version=version+1'

            local query = ('UPDATE lootify_items SET %s WHERE id=? AND version=?'):format(table.concat(sets, ', '))
            vals[#vals+1] = it.id
            vals[#vals+1] = it.version

            queries[#queries+1] = { query = query, values = vals }

        elseif o.op == 'delete' then
            queries[#queries+1] = {
                query = 'DELETE FROM lootify_items WHERE id=?',
                values = { o.id }
            }
        end
    end

    local ok = MySQL.transaction.await(queries)
    return ok and true or false
end

return Storage
