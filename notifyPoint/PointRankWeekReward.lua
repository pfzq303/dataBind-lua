local Notify = require("app.notifyPoint.Notify")
local PointRankWeekReward = class("PointRankWeekReward" , Notify.NotifyPoint) -- 排行榜奖励

-- 初始化
function PointRankWeekReward:init()
    modelMgr.player:addEventListener(modelMgr.rank.REFRESH_RANK_REWARD, function()
        self:check()
    end)
end

-- 刷新
function PointRankWeekReward:check()
    if not modelMgr.rank:isCanGetWeekReward() then
        self:setBindCnt(0)
    else
        self:setBindCnt(1)
    end
end

Notify.NotifyMgr:registPoint("PointRankWeekReward" , PointRankWeekReward.new())

return PointRankWeekReward
