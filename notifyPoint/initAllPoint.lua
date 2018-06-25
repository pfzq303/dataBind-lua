local Notify = packMgr:addPackage("app.notifyPoint.Notify")

--初始化所有的红点
packMgr:addPackage("app.notifyPoint.PointFriend")
packMgr:addPackage("app.notifyPoint.PointTask")
packMgr:addPackage("app.notifyPoint.PointSign")
packMgr:addPackage("app.notifyPoint.PointActivity")
packMgr:addPackage("app.notifyPoint.PointRankWeekReward")
packMgr:addPackage("app.notifyPoint.PointRank")

--启动红点检测
Notify.NotifyMgr:start()
