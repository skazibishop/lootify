local Locks = {}
local taken = {}

function Locks.acquire(key, timeoutMs)
    timeoutMs = timeoutMs or 5000
    local start = GetGameTimer()
    while taken[key] do
        if GetGameTimer() - start > timeoutMs then return false end
        Wait(0)
    end
    taken[key] = true
    return true
end

function Locks.release(key)
    taken[key] = nil
end

return Locks
