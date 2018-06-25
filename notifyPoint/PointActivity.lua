local Notify = require("app.notifyPoint.Notify")
local PointActivity = class("PointActivity", Notify.NotifyPoint)

-- 初始化
function PointActivity:init()
	modelMgr.player:addEventListener(modelMgr.player.REFRESH_SIGN, function()
		self:check()
	end )
	 modelMgr.player:addEventListener(modelMgr.rank.REFRESH_RANK_REWARD, function()
        self:check()
    end)
end

-- 刷新
function PointActivity:check()
	if not modelMgr.player:isSigned() then
		self:setBindCnt(1)
	elseif modelMgr.rank:isCanGetWeekReward() then
		self:setBindCnt(1)
	else
		self:setBindCnt(0)
	end
end

Notify.NotifyMgr:registPoint("PointActivity", PointActivity.new())

return PointActivity
