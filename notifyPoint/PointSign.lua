local Notify = require("app.notifyPoint.Notify")
local PointSign = class("PointSign" , Notify.NotifyPoint)

-- 初始化
function PointSign:init()
    modelMgr.player:addEventListener(modelMgr.player.REFRESH_SIGN, function()
        self:check()
    end)
end

-- 刷新
function PointSign:check()
    if modelMgr.player:isSigned() then
        self:setBindCnt(0)
    else
        self:setBindCnt(1)
    end
end

Notify.NotifyMgr:registPoint("PointSign" , PointSign.new())

return PointSign
