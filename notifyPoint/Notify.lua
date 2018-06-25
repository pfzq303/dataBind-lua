local Notify = {}

local NotifyPoint = class("NotifyPoint")

function NotifyPoint:ctor()
    self.data = { cnt = 0 }
end

function NotifyPoint:bindTo(node , customFunc)
    node:bindAttr( self.data , "cnt" , function( v )
        if customFunc then 
            customFunc( v , node)
        else
            node:setVisible( v >= 1)
        end
    end)
end

function NotifyPoint:setBindCnt(cnt)
    self.data.cnt = cnt
end

function NotifyPoint:init()
    
end

function NotifyPoint:check()
    
end

Notify.NotifyPoint = NotifyPoint
-----------------------------------------------------
local NotifyGroup = class("NotifyGroup" , NotifyPoint)

function NotifyGroup:ctor()
    NotifyGroup.super.ctor(self)
    self.handles = {}
end

function NotifyGroup:addPoint(item)
    local h = BindTool.bindAttr(item.data , "cnt" , function ( v , o_v)
        o_v = o_v or 0
        self.data.cnt = self.data.cnt + ( v - o_v )
    end)
    self.handles[item] = h
end

function NotifyGroup:removePoint(item)
    self.data.cnt = self.data.cnt - item.data.cnt
    BindTool.unBind(self.handles[item])
    self.handles[item] = nil
end

function NotifyGroup:init()
    for item , _ in pairs(self.handles) do
        item:init()
    end
end

function NotifyGroup:check()
    for item , _ in pairs(self.handles) do
        item:check()
    end
end

Notify.NotifyGroup = NotifyGroup
-----------------------------------------------------
local NotifyMgr = class("NotifyMgr")
NotifyMgr.UpdateTime = 5
function NotifyMgr:ctor()
    self.mapValue = {}
    self.updateArr = {}
    self._is_start = false
end

function NotifyMgr:registPoint(pType, point)
    self.mapValue[pType] = point
    if self._isStart then
        point:init()
        point:check()
    end
end

function NotifyMgr:removePoint(ptype)
    local point = self.mapValue[ptype]
    if point then
        self.mapValue[ptype] = nil
        for index , v in ipairs(self.updateArr) do
            if v == point then
                table.remove(self.updateArr , index)
                return
            end
        end
    end
end

function NotifyMgr:registUpdatePoint(pType, point)
    self.mapValue[pType] = point;
    table.insert(self.updateArr , point)
    if self._isStart then
        point:init()
        point:check()
        self:checkRecycle()
    end
end

function NotifyMgr:getPoint(pType)
    return self.mapValue[pType]
end

function NotifyMgr:start()
    self._isStart = true;
    for _ , point in pairs(self.mapValue) do
        point:init();
        point:check();
    end
    self:checkRecycle()
end

function NotifyMgr:checkRecycle()
    if #self.updateArr > 0 and not self.updateHandler then
        self.updateHandler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(dt)
            self:update(dt)
        end , NotifyMgr.UpdateTime , false)
    else
        if #self.updateArr == 0 and self.updateHandler then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.updateHandler)
            self.updateHandler = nil
        end
    end
end

function NotifyMgr:update(dt)
    for _ , v in pairs(self.updateArr) do
        v:check()
    end
end

Notify.NotifyMgr = NotifyMgr.new()
-----------------------------------------------------

function Notify.BindNode(node , types , customFunc)
    local group = NotifyGroup.new()
    for _ , ptype in ipairs(types) do
        local point = Notify.NotifyMgr:getPoint(ptype)
        if point then group:addPoint(point) end
    end
    group:bindTo(node, customFunc)
end
-----------------------------------------------------

return Notify