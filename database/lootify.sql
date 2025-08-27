-- Lootify schema v2 (with grid_key)
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
);

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
);
