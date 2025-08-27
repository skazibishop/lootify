# Lootify

• Inventário grid estilo Tarkov para FiveM, com compatibilidade ESX e QBox (QBCore/QBox).  
• Usa ox_lib (callbacks) e oxmysql.  
• Pensado para 800+ players simultâneos com cache em memória, gravações em lote e locks anti-dupe.

## ConVars
setr lootify:framework auto   • auto | esx | qbox | standalone
setr lootify:save_interval 30 • segundos entre saves em lote

## Dependências
• ox_lib • oxmysql • (es_extended ou qb-core/qbx_core) opcional
