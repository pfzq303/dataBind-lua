local Notify = require("app.notifyPoint.Notify")
local PointRank = class("PointRank" , Notify.NotifyPoint) -- 排行榜

-- 初始化
function PointRank:init()
    modelMgr.player:addEventListener(modelMgr.rank.REFRESH_RANK_INFO, function()
        self:check()
    end)
end

-- 刷新
function PointRank:check()
    if not modelMgr.rank:isCanGetWeekReward() then
        self:setBindCnt(0)
    else
        self:setBindCnt(1)
    end
end

Notify.NotifyMgr:registPoint("PointRank" , PointRank.new())

return PointRank