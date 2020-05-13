local BindTool = class("BindTool")

local old_ipairs = ipairs
local old_pairs = pairs

ipairs = function(arr)
    local meta_t = getmetatable(arr)
    if meta_t and meta_t.__ipairs then
        return meta_t.__ipairs(arr)
    end
    return old_ipairs(arr)
end

pairs = function(arr)
    local meta_t = getmetatable(arr)
    if meta_t and meta_t.__pairs then
        return meta_t.__pairs(arr)
    end
    return old_pairs(arr)
end

local function InitBind(obj)
    if rawget(obj, "___isBinded") then return end
    local store = {}
    for key , v  in pairs(obj) do
        v = rawget(obj, key)
        if v ~= nil then
            store[key] = v
            obj[key] = nil
        end
    end
    local meta_t = getmetatable(obj)
    if meta_t then setmetatable(store, meta_t) end
    setmetatable(obj, {
        __index = function(t , index)
            local ret = rawget(obj, index)
            if ret ~= nil then return ret end
            return store[index]
        end,
        __newindex = function(t, index, v)
            local event = rawget(obj, "___bind_event")
            local old_v = store[index]
            store[index] = v
            if old_v ~= v then
                if event and event[index] then
                    event[index].running = true
                    for key , func in pairs(event[index].callList) do
                        if not event[index].removeList[key] then
                            func(v , old_v)
                        end
                    end
                    event[index].running = nil
                    if next(event[index].removeList) then
                        for removeIndex , _ in pairs(event[index].removeList) do
                            event[index].callList[removeIndex] = nil
                        end
                        event[index].removeList = {}
                    end
                end
            end
        end,
        __ipairs = function(t)
            return old_ipairs(store)
        end,
        __pairs = function(t)
            return old_pairs(store)
        end
    })
    rawset(obj, "___isBinded", true)
    rawset(obj, "___bind_store", store)
    rawset(obj, "___bind_event", {})
    rawset(obj, "___bind_id", 0)
end

function BindTool.bindAttr(obj , attr, callback)
    InitBind(obj)
    local event = rawget(obj, "___bind_event")
    local id = rawget(obj, "___bind_id")
    event[attr] = event[attr] or { callList = {}, removeList = {} }
    id = id + 1
    rawset(obj, "___bind_id" , id)
    event[attr].callList[id] = callback
    local value = obj[attr]
    if value ~= nil then
        callback(value)
    end
    return { obj = obj, attr = attr, id = id }
end

function BindTool.getBindInfo(val)
    if type(val) ~= "table" then return val, false end
    if not rawget(val, "___isBinded") then return val, false end
    return rawget(val, "___bind_store"), true
end

function BindTool.unBind(handle)
    local event = rawget(handle.obj, "___bind_event")
    if event and event[handle.attr] then
        if event[handle.attr].running then
            event[handle.attr].removeList[handle.id] = true
        else
            event[handle.attr].callList[handle.id] = nil
        end
    end
end

function BindTool.unBindObj(obj)
    local event = rawget(obj, "___bind_event")
    if event then
        for _ , attrListener in pairs(event) do
            if attrListener.running then
                for key , _ in pairs(attrListener.callList) do
                    attrListener.removeList[key] = true
                end
            end
        end
        rawset(obj, "___bind_event", {})
    end
end

-- 下面的实现不要了。换成用vue的方案实现
-- local Node = cc.Node

-- function Node:addCleanCallBack(func)
--     if not self._cleanCallbackList then
--         self._cleanCallbackList = {}
--         self:registerScriptHandler(function(state)
--             if state == "cleanup" then
--                 if self._cleanCallbackList then
--                     for _ , v in pairs(self._cleanCallbackList) do
--                         v()
--                     end
--                 end
--             end
--         end)
--     end
--     self._cleanIndex = self._cleanIndex and self._cleanIndex + 1 or 1
--     self._cleanCallbackList[self._cleanIndex] = func
--     return self._cleanIndex
-- end

-- function Node:removeCleanCallBack(cleanIndex)
--     self._cleanCallbackList[cleanIndex] = nil
-- end

-- function Node:bindAttr(obj, attr, func, unbindFunc)
--     if not self.__bind_info then
--         self.__bind_info = {}
--         self:addCleanCallBack(function()
--             for key , val in pairs( self.__bind_info ) do
--                 for _ , item in pairs(val.record) do
--                    self:unBind(item.handle) 
--                 end
--                 self.__bind_info[key] = nil
--             end
--             self.__bind_info = {}
--         end)
--     end
--     self.__bind_info[obj] = self.__bind_info[obj] or { length = 0 , record = {}}
--     local handle = BindTool.bindAttr(obj , attr, func)
--     self.__bind_info[obj].record[handle.id] = { handle = handle, unbind = unbindFunc }
--     self.__bind_info[obj].length = self.__bind_info[obj].length + 1
--     return handle
-- end

-- function Node:unBind(handle)
--     local obj = handle.obj
--     if self.__bind_info and self.__bind_info[obj] then
--         BindTool.unBind(handle)
--         self.__bind_info[obj].length = self.__bind_info[obj].length - 1
--         if self.__bind_info[obj].record[handle.id].unbind then
--             self.__bind_info[obj].record[handle.id].unbind()
--         end
--         self.__bind_info[obj].record[handle.id] = nil
--         if self.__bind_info[obj].length == 0 then
--             self.__bind_info[obj] = nil
--         end
--     end
-- end

return BindTool
