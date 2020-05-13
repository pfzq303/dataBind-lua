-- 实现思路借鉴了Vue的源码

local old_ipairs = ipairs
local old_pairs = pairs
local defProp;
local observe;

local loadstring_ = nil
local oldInsert = table.insert

table.insert = function(t, arg1, arg2, ...) 
    local store = rawget(t, "___bind_store")
    local ob = rawget(t, "__ob__")
    if store then t = store end
    if arg2 then
        oldInsert(t, arg1, arg2, ...)
    else
        oldInsert(t, arg1)
    end
    if ob then
        ob:walk(arg2 or arg1)
        ob.dep:notify()
    end
end

local oldTableRemove = table.remove
table.remove = function(t, ...)
    local store = rawget(t, "___bind_store")
    local ob = rawget(t, "__ob__")
    if store then t = store end
    oldTableRemove(t, ...)
    if ob then
        ob.dep:notify()
    end
end

if (loadstring) then
    loadstring_ = loadstring
else
    loadstring_ = load
end

local function extends(obj, Clazz)
    setmetatable(obj, {__index = Clazz})
end

local Dep = {}
local DepId = 1;
function Dep.new()
    local self = {}
    self.subs = {}
    self.subIds = {}
    self.id = DepId;
    DepId = DepId + 1
    extends(self, Dep);
    return self
end

function Dep:addSub(sub)
    if( not self.subIds[sub.id]) then
        self.subIds[sub.id] = true
        table.insert(self.subs, Dep.target)
    end
end

function Dep:removeSub(sub)
    if(self.subIds[sub.id]) then
        self.subIds[sub.id] = nil
        for i, v in ipairs(self.subs) do
            if(v == sub or v.id == sub.id) then
                table.remove(self.subs, i)
            end
        end
    end
end

function Dep:depend()
    if Dep.target then
        Dep.target:addDep(self)
    end
end

function Dep:notify()
    for _, v in ipairs(self.subs) do
        v:update()
    end
end

Dep.target = nil
local targetStack = {}
local function pushTarget(target)
    targetStack[#targetStack+1] = target
    Dep.target = target
end

local function popTarget()
    local len = #targetStack 
    targetStack[len] = nil
    Dep.target = targetStack[len - 1]
end


local Observer = {}
function Observer.new(value)
    local this = {}
    extends(this, Observer)
    this.value = value
    this.dep = Dep.new()
    this.vmCount = 0
    this:walk(value)
    rawset(value, "__ob__", this)
    return this
end

function Observer:walk(value)
    if type(value) == "table" then
        for _, v in pairs(value) do
            observe(v)
        end
        defProp(value)
    end
end

observe = function (val, asRootNode)
    local ob
    if type(val) == "table" then
        ob = rawget(val, "__ob__")
        if not ob then
            ob = Observer.new(val)
        end
    end
    if asRootNode and ob then
        ob.vmCount = ob.vmCount + 1
    end
    return ob
end

defProp = function (obj)
    if rawget(obj, "___isBinded") then return end
    local store = {}
    local depMap = {}
    for key , v  in pairs(obj) do
        v = rawget(obj, key)
        if v ~= nil then
            store[key] = v
            obj[key] = nil
        end
    end
    local function getDep(key)
        depMap[key] = depMap[key] or Dep.new()
        return depMap[key]
    end
    local meta_t = getmetatable(obj)
    if meta_t then setmetatable(store, meta_t) end
    setmetatable(obj, {
        __index = function(t , index)
            local ret = store[index]
            if Dep.target then
                getDep(index):depend()
                local subDeps = observe(ret)
                if(subDeps) then
                    subDeps.dep:depend()
                end
            end
            return ret
        end,
        __newindex = function(t, index, v)
            local old_v = store[index]
            if old_v ~= v then
                store[index] = v
                observe(v)
                if depMap[index] then 
                    depMap[index]:notify() 
                end
            end
        end,
        -- 在5.1版本这个会无用。这个是优先级的问题
        __len = function (t)
            return #store
        end,
        __ipairs = function(t)
            if Dep.target then
                for index , v in old_ipairs(store) do
                    getDep(index):depend()
                    local subDeps = observe(v)
                    if(subDeps) then
                        subDeps.dep:depend()
                    end
                end
            end
            return old_ipairs(store)
        end,
        __pairs = function(t)
            if Dep.target then
                for index , v in old_pairs(store) do
                    getDep(index):depend()
                    local subDeps = observe(v)
                    if(subDeps) then
                        subDeps.dep:depend()
                    end
                end
            end
            return old_pairs(store)
        end
    })
    rawset(obj, "___isBinded", true)
    rawset(obj, "___bind_store", store)
end

local function _proxy(proxy, data)
    if not data or type(data) ~= "table" then
        return
    end
    local proxyMap = rawget(proxy, "_proxyList")
    if not proxyMap then
        proxyMap = {}
        rawset(proxy, "_proxyList", proxyMap)
        local org
        local meta_t = getmetatable(proxy)
        if meta_t then
            org = {}
            setmetatable(org, meta_t);
        end
        local new_meta_t = {
            __index = function(t , index)
                if org then
                    local ov = org[index]
                    if ov then
                        return ov
                    end
                end
                for _, v in ipairs(proxyMap) do
                    local t = v[index]
                    if t then
                        return t
                    end
                end
            end,
            __newindex = function(t, index, v)
                for _, v in ipairs(proxyMap) do
                    local pv = v[index]
                    if pv ~= nil then
                        v[index]= v
                        return;
                    end
                end
                if proxyMap[1] then
                    proxyMap[1][index] = v
                end
            end,
        }
        
        setmetatable(proxy, new_meta_t)
    end
    table.insert(proxyMap, data)
end

local function compile(env, exp)
    local _ENV
    _ENV = env
    local func = assert(loadstring_("return " .. exp))
    if func and setfenv then
        setfenv(func, env)
    end
    return func
end

local Watcher = {}
local watcherID = 1;

function Watcher.new(vm, expfunc, cb, options)
    local self = {}
    extends(self, Watcher)
    self.vm = vm
    self.id = watcherID
    watcherID= watcherID + 1
    vm._watchers[self.id] = self
    self.lazy = options and options.lazy
    self.expfunc = expfunc
    self.cb = cb
    self.active = true
    self.deps = {}
    self.newDeps = {}
    self:run()
end

function Watcher:addDep(dep)
    local id = dep.id
    if not self.newDeps[id] then
        self.newDeps[id] = dep
        if not self.deps[id] then
            self.deps[id] = dep
            dep:addSub(self)
        end
    end
end

function Watcher:cleanupDeps()
    for k,v in pairs(self.deps) do
        if not self.newDeps[k] then
            self.deps[k] = nil
            v:removeSub(self)
        end
    end
    self.newDeps = {}
end

function Watcher:update()
    if(self.lazy) then
        self.dirty = true
    else
        self:run()
    end
end

function Watcher:evaluate()
    self.value = self:get()
    self.dirty = false
end

function Watcher:get()
    pushTarget(self)
    local value = self.expfunc()
    self:cleanupDeps()
    popTarget()
    return value
end

function Watcher:depend()
    for _ , v in pairs(self.deps) do
        v:depend()
    end
end

function Watcher:run()
    local oldValue = self.value
    self.value = self:get()
    if self.cb and oldValue ~= self.value
    then
        self.cb(self.value, oldValue)
    end
end

function Watcher:teardown()
    self.vm._watchers[self.id] = nil
    for _ , v in pairs(self.deps) do
        v:removeSub(self)
    end
    self.deps = {}
    self.newDeps = {}
    self.cb = nil
    self.value = nil
    self.expfunc = nil
end

local Vue = {}

function Vue.new(data, exp, cb, options)
    local vm = {
        _watchers = {}
    }
    vm.self = vm
    extends(vm, Vue)
    observe(data, true)
    _proxy(vm, data)
    if options then
        _proxy(vm, options.computed)
    end
    local func = compile(vm, exp)
    Watcher.new(vm, func, cb)
    return vm
end

function Vue:destroy()
    local _isBeingDestroyed = rawget(self, "_isBeingDestroyed")
    if(_isBeingDestroyed) then
        return 
    end
    rawset(self, "_isBeingDestroyed", true)
    for _, v in pairs(self._watchers) do
        v:teardown()
    end
    rawset(self, "_watchers", {})
end

return Vue
