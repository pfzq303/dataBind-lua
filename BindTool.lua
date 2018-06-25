BindTool = class("BindTool")

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

local function initBind(obj)
    if rawget(obj , "___isBinded") then return end
    local store = {}
    for key , v  in pairs(obj) do
        v = rawget(obj , key)
        if v ~= nil then
            store[key] = v
            obj[key] = nil
        end
    end
    local meta_t = getmetatable(obj)
    if meta_t then setmetatable(store , meta_t) end
    setmetatable(obj , {
        __index = function(t , index)
            local ret = rawget(obj , index)
            if ret ~= nil then return ret end
            return store[index]
        end,
        __newindex = function(t , index , v)
            local event = rawget(obj , "___bind_event")
            local old_v = store[index]
            store[index] = v
            if old_v ~= v then
                if event and event[index] then
                    for _ , func in pairs(event[index]) do
                        func( v , old_v)
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
    rawset(obj , "___isBinded" , true)
    rawset(obj , "___bind_info" , store)
    rawset(obj , "___bind_event" , {})
    rawset(obj , "___bind_id" , 0)
end

function BindTool.bindAttr(obj , attr, callback)
    initBind(obj)
    local event = rawget(obj , "___bind_event")
    local id = rawget(obj , "___bind_id")
    event[attr] = event[attr] or {}
    id = id + 1
    rawset(obj , "___bind_id" , id)
    event[attr][id] = callback
    local value = obj[attr]
    if value ~= nil then
        callback(value)
    end
    return { obj = obj , attr = attr , id = id }
end

function BindTool.unBind(handle)
    local event = rawget(handle.obj , "___bind_event")
    if event and event[handle.attr] then
        event[handle.attr][handle.id] = nil
    end
end

local Node = cc.Node

function Node:bindAttr(obj, attr, func)
    if not self.__bind_info then
        self.__bind_info = {}
        self:enableNodeEvents()
        self:addCleanCallBack(function()
            for key , val in pairs( self.__bind_info ) do
                for _ , item in pairs(val.record) do
                   BindTool.unBind(item) 
                end
                self.__bind_info[key] = nil
            end
            self.__bind_info = {}
        end)
    end
    self.__bind_info[obj] = self.__bind_info[obj] or { length = 0 , record = {}}
    local handle = BindTool.bindAttr(obj , attr, func)
    self.__bind_info[obj].record[handle.id] = handle
    self.__bind_info[obj].length = self.__bind_info[obj].length + 1
    return handle
end

function Node:unBind(handle)
    local obj = handle.obj
    if self.__bind_info and self.__bind_info[obj] then
        BindTool.unBind(handle)
        self.__bind_info[obj].length = self.__bind_info[obj].length - 1
        self.__bind_info[obj].record[handle.id] = nil
        if self.__bind_info[obj].length == 0 then
            self.__bind_info[obj] = nil
        end
    end
end