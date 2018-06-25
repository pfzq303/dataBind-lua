local Notify = require("app.notifyPoint.Notify")
local PointTask = class("PointTask" , Notify.NotifyPoint)

-- 初始化
function PointTask:init()
    modelMgr.task:addEventListener(modelMgr.task.REFRESH_TASK, function()
        self:check()
    end)
end

-- 刷新
function PointTask:check()
    if modelMgr.task:isHasNewTask() or modelMgr.task:isHasFinishTask() then
        self:setBindCnt(1)
    else
        self:setBindCnt(0)
    end
end

Notify.NotifyMgr:registPoint("PointTask" , PointTask.new())

return PointTask
