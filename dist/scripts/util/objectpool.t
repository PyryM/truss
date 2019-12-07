-- utils/objectpool.t
--
-- manages a pool of (terra) objects backed by a flat array

local class = require("class")
local m = {}

function m.TerraObjectPool(T, maxObjects)
    local struct PoolItem {
        occupied: bool;
        id: uint64;
        item: T;
    }
    local struct Pool {
        pool: PoolItem[maxObjects];
        maxObjects: uint64;
        freeSlots: uint64[maxObjects];
        numFreeSlots: uint64;
    }
    terra Pool:init()
        self.numFreeSlots = maxObjects
        self.maxObjects = maxObjects
        for i = 0,maxObjects do
            self.freeSlots[i] = i
            self.pool[i].occupied = false
            self.pool[i].id = i
        end
    end
    terra Pool:allocate() : &PoolItem
        if self.numFreeSlots == 0 then return nil end
        self.numFreeSlots = self.numFreeSlots - 1
        var newslot = self.freeSlots[self.numFreeSlots]
        var item = self.pool[newslot]
        item.occupied = true
        return item
    end
    terra Pool:release(item: &PoolItem)
        var id = item.id
        if not item.occupied then return end
        if self.numFreeSlots == maxObjects then return end
        if id >= maxObjects then return end
        item.occupied = false
        self.freeSlots[self.numFreeSlots] = id
        self.numFreeSlots = self.numFreeSlots + 1
    end
    return {Pool = Pool, PoolItem = PoolItem}
end

local ObjectPool = class("ObjectPool")
function ObjectPool:init(options)
    -- todo
end

function ObjectPool:allocate()
    return self.pool:allocate()
end

function ObjectPool:release(obj)
    self.pool:release(obj)
end

return m
