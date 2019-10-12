---
--- 用于游戏项目《百世文华录》中的抽奖活动——招财猫。
--- 招财猫的抽奖形式是一组随机数字滚轮，这份代码就是单个数字滚轮的逻辑。
--- UI结构= 
    --gameobject_scroll_region --滚动区域，一个只包含RectTransform组件的空对象即可
        --text_number_0 --显示当前滚到的数字
        --text_number_1 --显示当前滚到的数字的前一个或后一个数字（取决于滚动方向）
--- Created by yangfan
--- DateTime: 2019/8/12 10:34
---


NumberWheelScrollDir = {
    Up = 1,
    Down = -1
}

local UINumberWheel = class("UINumberWheel")

function UINumberWheel:ctor(go)

    self.gameObject = go
    self.transform = go.transform

    self.m_scrollDir = -1 --滚动方向
    self.m_curSpeed = 0--当前速度
    self.m_targetSpeed = 0--目标速度
    self.m_acceleratedDir = 1--当前加速度方向，1加速，-1减速
    self.m_duration = 0--达到最大速度后持续滚动的时间

    self.m_timeDelta = 0--时间累计
    self.m_distanceOfAccelerated = 0--滚轮在加速阶段移动的距离,用于在减速时计算滚动的起始数字

    self.m_varyingVelocityDuration = 0--当前匀变速持续时间
    self.m_maxSpeed = 1--最大速度
    self.m_maxDuration = 2--最大持续时间
    self.m_targetNumber = 0

    self.m_m_isScrolling = false

    self.m_width = 0
    self.m_height = 0

    self.m_number = 0--当前滚到的数字
    self.m_minNumber = 0--
    self.m_maxNumber = 9--


    self.m_rectTrans = nil
    self.m_texts = {}

    self.m_finishedCallbacks = {}
end


---@public
function UINumberWheel:Init()

    self.m_rectTrans =LuaCallCS.GetComponent(self.gameObject,nil,"RectTransform")
    self.m_width = LuaCallCS.GetSizeDelta(self.gameObject,true)
    self.m_height = LuaCallCS.GetSizeDelta(self.gameObject,false)

    local textRectTrans = nil
    for i = 1,self.transform.childCount do
        textRectTrans = self.transform:GetChild(i-1):GetComponent("RectTransform")
        textRectTrans.anchoredPosition = Vector2.New(0, ((i - 1) * self.m_height * self.m_scrollDir * -1))
        self.m_texts[i] = textRectTrans:GetComponent("Text")
    end

    self.m_curSpeed = 0
    self.m_targetSpeed = self.m_maxSpeed
    self.m_duration = self.m_maxDuration

    self.m_number = self.m_minNumber
    self:SetNumberAtMiddle(self.m_number)

    g_event.Add(EventsType.UIUpdateDt,self.Update,self)
end


---@public
function UINumberWheel:UnInit()
    g_event.Remove(EventsType.UIUpdateDt,self.Update,self)

    self.m_rectTrans = nil

    for i = 1,#self.m_texts do
        self.m_texts[i] = nil
    end

    for i = 1,#self.m_finishedCallbacks do
        self.m_finishedCallbacks[i] = nil
    end
    self.m_finishedCallbacks = nil
end




---@public
function UINumberWheel:SetScrollDirection(dir)

    if type(dir) ~= 'number' then
        return
    end

    self.m_scrollDir = dir
end



---@public 设置目标数字
function UINumberWheel:SetTargetNumber(number)

    if type(number) ~= 'number' then
        return
    end

    self.m_targetNumber = number
end


---@public 设置滚动速度
function UINumberWheel:SetSpeed(speed)

    if type(speed) ~= 'number' then
        return
    end

    self.m_maxSpeed = speed
end



---@public 设置滚动持续时间
function UINumberWheel:SetDurationTime(duration)

    if type(duration) ~= 'number' then
        return
    end

    self.m_maxDuration = duration
end



---@public 设置变速持续时间
function UINumberWheel:SetVaryingVelocietyDurationTime(duration)

    if type(duration) ~= 'number' then
        return
    end

    self.m_varyingVelocityDuration = duration
end


---@public 设置边界值
function UINumberWheel:SetMaxNumber(number)

    if type(number) ~= 'number' then
        return
    end

    self.m_maxNumber = number
end


---@public
function UINumberWheel:SetNumberInterval(min,max)
    if type(min) == 'number' then
        self.m_minNumber = min
    end

    if type(max) == 'number' then
        self.m_maxNumber = max
    end
end





---@public 添加滚动完成回调
function UINumberWheel:AddFinishedCallback(obj,func)

    if not obj or not func then
        return
    end

    local isExist = false
    local curCallbacksCnt = #self.m_finishedCallbacks

    local callBack = nil
    for i = 1,curCallbacksCnt do
        callBack = self.m_finishedCallbacks[i]
        if callBack.obj == obj and callBack.func == func then
            isExist = true
            break
        end
    end

    if not isExist then

        self.m_finishedCallbacks[curCallbacksCnt + 1] = {
            obj = obj,
            func = func
        }
    end
end



---@public 移除回调
function UINumberWheel:RemoveFinishedCllback(obj,func)
    if not obj then
        return
    end

    local curCallbacksCnt = #self.m_finishedCallbacks
    local callBack = nil
    for i = curCallbacksCnt,1,-1 do
        callBack = self.m_finishedCallbacks[i]
        if callBack.obj == obj and callBack.func == func then
            table.remove(self.m_finishedCallbacks,i)
        end
    end

end



---@public 移除回调
function UINumberWheel:RemoveFinishedCllbackByObj(obj)
    if not obj then
        return
    end

    local curCallbacksCnt = #self.m_finishedCallbacks
    local callBack = nil
    for i = curCallbacksCnt,1,-1 do
        callBack = self.m_finishedCallbacks[i]
        if callBack.obj == obj then
            table.remove(self.m_finishedCallbacks,i)
        end
    end

end



---@public
function UINumberWheel:ResetNumber()
    self.m_number = self.m_minNumber
    self.m_rectTrans.anchoredPosition = Vector2.zero;
    self:SetNumberAtMiddle(self.m_number)
end



---@public 开始滚动
function UINumberWheel:BeginScroll()

    self.m_isScrolling = true

    self.m_curSpeed = 0
    self.m_targetSpeed = self.m_maxSpeed

    self.m_duration = self.m_maxDuration
    self.m_acceleratedDir = 1

    self.m_number = self.m_minNumber
    self.m_rectTrans.anchoredPosition = Vector2.zero;
    self:SetNumberAtMiddle(self.m_number)

    self.m_timeDelta = 0
    self.m_distanceOfAccelerated = 0
end




---@private
function UINumberWheel:Update(dt)
    if (self.m_isScrolling) then

        --时间按照固定步长累加
        self.m_timeDelta = self.m_timeDelta + 0.03

        --从加速到匀速
        if self.m_timeDelta <= self.m_varyingVelocityDuration then

            local timeDelta = self.m_acceleratedDir == 1 and self.m_timeDelta or self.m_varyingVelocityDuration - self.m_timeDelta
            self.m_curSpeed = timeDelta / self.m_varyingVelocityDuration * self.m_maxSpeed
            --self.m_curSpeed = math.floor(self.m_curSpeed * 100) / 100
            --记录加速阶段滚动距离
            self.m_distanceOfAccelerated = self.m_distanceOfAccelerated + self.m_curSpeed

        elseif self.m_duration > 0 then --保持最大速度滚动

            self.m_curSpeed = self.m_maxSpeed

            self.m_duration = self.m_duration - dt;--计时

            if (self.m_duration <= 0) then--开始减速

                self.m_timeDelta = 0
                self.m_acceleratedDir = -1;
                self.m_targetSpeed = 0;
                --复位
                self.m_rectTrans.anchoredPosition = Vector2.zero;

                --计算起始数字
                local dis = self.m_distanceOfAccelerated--减速阶段和加速阶段除方向不一样其他条件基本一致，所以这里直接拿来用。
                local offset = math.floor(dis / self.m_height);
                if offset > self.m_targetNumber then
                    --计算一周由几个数字组成
                    local countARound = self.m_maxNumber - self.m_minNumber + 1
                    --
                    local round = math.floor(offset / countARound);
                    round = round < 0 and 0 or round;
                    offset = offset - ( round * countARound );
                    self.m_number = offset > self.m_targetNumber and countARound - (offset - self.m_targetNumber)or self.m_targetNumber - offset;
                else
                    self.m_number = self.m_targetNumber - offset;
                end

                self:SetNumberAtMiddle(self.m_number);
            end
        else

            self.m_curSpeed = 0
            self.m_timeDelta = self.m_varyingVelocityDuration
        end

        ---[[
        if self.m_acceleratedDir == -1 and self.m_curSpeed <= self.m_maxSpeed * 0.1 then
            --提前预判
            if (self.m_number == self.m_targetNumber) then
                self.m_curSpeed = 0
            end
        end--]]

        if self.m_curSpeed <= 0 then

            self:ScrollCompleted()
        else
            self:Scrolling()
        end


    end
end



---@private
function UINumberWheel:Scrolling()

    local anchoredPos = self.m_rectTrans.anchoredPosition
    local step = anchoredPos.y + (self.m_curSpeed * self.m_scrollDir)

    if (math.abs(step) >= self.m_height) then

        local offset = math.floor( math.abs(step / self.m_height ) )

        anchoredPos.y = step - (offset * self.m_height * self.m_scrollDir)

        self.m_number = self.m_number + offset > self.m_maxNumber and self.m_minNumber or self.m_number + offset

        self:SetNumberAtMiddle(self.m_number)


        --AudioMgr.PlayUIAudio("audio/uiaudio/zhuanpangundong.audio")

    else
        anchoredPos.y = step
    end

    self.m_rectTrans.anchoredPosition = anchoredPos
end



---@private
function UINumberWheel:ScrollCompleted()

    self.m_isScrolling = false


    self:SetNumberAtMiddle(self.m_targetNumber)
    --self.m_rectTrans.anchoredPosition = Vector2.zero

    ---[[
    local moveAnim = self.m_rectTrans:DOLocalMoveY(0, 0.8)
    local sequence = DG.Tweening.DOTween.Sequence()
    sequence:Append(moveAnim)--]]


    --AudioMgr.StopAudioByName("audio/uiaudio/zhuanpangundong.audio")

    --执行回调
    local callBack = nil
    for i = 1,#self.m_finishedCallbacks do
        callBack = self.m_finishedCallbacks[i]

        callBack.func(callBack.obj)
    end
end



---@private
function UINumberWheel:SetNumberAtMiddle(num)

    self.m_texts[1].text = num
    self.m_texts[2].text = num + 1 > self.m_maxNumber and self.m_minNumber or num + 1
end


return UINumberWheel
