# dataBind-lua
lua简单实现的数据绑定
实现参考了vue的原理
1. 支持表达式自动引用
2. 添加数组的原生修改
已知的bug：
在5.1版本的 “#” 运算符还无法支持
```lua
local data = {
   aa = {1,2,3,4,5},
   bb = 3,
   1,2,3
}
local vm = Vue.new(data, " self:sum() + a" , function(value, oldValue)
    print(value, oldValue)
end, {
    computed = {
        sum = function(self)
            local ret = 0;
            for _,v in ipairs(self.aa) do
                ret = ret + v;
            end
            return ret;
        end
    }
})
-- 下面是测试数据绑定
print("-------------")
table.insert(data.aa, 10)
print("-------------")
data.bb = 2
print("-------------")
table.remove(data.aa)
print("-------------")
data.aa = {2,2,2}
```
输出：
```
18	nil
-------------
28	18
-------------
27	28
-------------
17	27
-------------
8	17
```
notifyPoint 基于数据绑定实现的通知系统。这里会和cocos2dx的节点有点耦合，但无关紧要
