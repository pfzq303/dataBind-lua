local Vue             = import(".vue")

local Node = cc.Node

Node.removeCleanCallBack = Node.removeCleanCallBack or function(self, cleanIndex)
    self._cleanCallbackList[cleanIndex] = nil
end

Node.addCleanCallBack = Node.addCleanCallBack or function (self, func)
    if not self._cleanCallbackList then
        self._cleanCallbackList = {}
        self:registerScriptHandler(function(state)
            if state == "cleanup" then
                if self._cleanCallbackList then
                    for _ , v in pairs(self._cleanCallbackList) do
                        v()
                    end
                end
            end
        end)
    end
    self._cleanIndex = self._cleanIndex and self._cleanIndex + 1 or 1
    self._cleanCallbackList[self._cleanIndex] = func
    return self._cleanIndex
end

function Node:bindAttrWithOption(obj, attr, options, func, unbindFunc)
    if not self.__vue_info then
        self.__vue_info = {}
        self:addCleanCallBack(function()
            for key , val in pairs( self.__vue_info ) do
                key:destroy()
                if(val.unbind) then
                    val.unbind()
                end
            end
            self.__vue_info = {}
        end)
    end
    local vm = Vue.new(obj, attr, func, options)
    self.__vue_info[vm] = { unbind = unbindFunc }
    return vm
end

function Node:bindAttr(obj, attr, func, unbindFunc)
    return self:bindAttrWithOption(obj, attr, nil, func, unbindFunc)
end

function Node:unBind(vm)
    if self.__vue_info and self.__vue_info[vm] then
        vm:destroy()
        if(self.__vue_info[vm]) then
            self.__vue_info[vm]()
        end
        self.__vue_info[vm] = nil
    end
end
