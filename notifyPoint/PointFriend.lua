local Notify = require("app.notifyPoint.Notify")
local PointFriend = class("PointFriend" , Notify.NotifyPoint)

-- 初始化
function PointFriend:init()
    modelMgr.friends:addEventListener(modelMgr.friends.ASKS_REFRESH, function()
        self:check()
    end)
end

-- 刷新
function PointFriend:check()
    local askList = modelMgr.friends:getAskInfo()
    local cnt = 0
    for _ , v in pairs(askList) do
        cnt = cnt + 1
    end
    self:setBindCnt(cnt)
end

Notify.NotifyMgr:registPoint("PointFriend" , PointFriend.new())

return PointFriend