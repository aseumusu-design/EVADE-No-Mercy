-- ===== CARI & HOOK SEMUA REMOTE DENGAN KATA KUNCI =====
local keywords = {"Hidden", "Stab", "M2", "Leap"}  -- tambahkan kata kunci lain jika perlu

local function findAndHookRemotes(parent, keywords)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            for _, kw in ipairs(keywords) do
                if string.find(child.Name, kw) then
                    hookRemote(child)  -- panggil fungsi hook untuk remote ini
                    break
                end
            end
        elseif child:IsA("Folder") or child:IsA("Model") then
            findAndHookRemotes(child, keywords)
        end
    end
end

local function hookRemote(remote)
    if remote:IsA("RemoteEvent") then
        local original = remote.FireServer
        remote.FireServer = function(self, ...)
            if isEnabled then
                local target = getNearestTarget()
                if target then
                    lockToTarget(target)
                    lockUntil = tick() + LOCK_DURATION
                end
            end
            return original(self, ...)
        end
        print("✅ Hook RemoteEvent: " .. remote.Name)
    elseif remote:IsA("RemoteFunction") then
        local original = remote.InvokeServer
        remote.InvokeServer = function(self, ...)
            if isEnabled then
                local target = getNearestTarget()
                if target then
                    lockToTarget(target)
                    lockUntil = tick() + LOCK_DURATION
                end
            end
            return original(self, ...)
        end
        print("✅ Hook RemoteFunction: " .. remote.Name)
    end
end

-- Jalankan pencarian
findAndHookRemotes(ReplicatedStorage, keywords)
