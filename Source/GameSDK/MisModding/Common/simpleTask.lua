--  * Copyright (C) 2021  Theros[MisModding|SvalTek]
---@class simpleTask
---@field   name          string      `Task Name`
---@field   status        string      `Task Status [sleeping|waiting|finished|dead]`
---@field   startTime     number      `Task start time (seconds since server/game start)`
---@field   finishTime    number      `Task finish time (seconds since server/game start)`
---@field   runCount      number      `Task run Count`
---@field   runLimit      number      `Task run Limit`
---@field   enabled       boolean     `is the Task Enabled`
---@field   Timer?        fun(self:any,time:number,threadName:string, ...:any[])       `[internal, used to set the task timer]`
local Task = {}
local taskMeta = {
    __index = {
        Extend = function(self)
            local obj = {super = self}
            return setmetatable(obj, Task)
        end
    },
    __type = 'Task',
    __tostring = function(self) return getmetatable(self).__type end,
    __call = function(self, ...)
        if self['super'] and self.super['new'] then
            self.super.new(self, ...)
        end
        if self['new'] then self:new(...) end
        return self
    end
}

local function createThread(self, fn)
    local thread = coroutine.create(function(...)
        local ranOk, compleated, result
        self.startTime = os.clock()
        local args = {...}
        while (not compleated) and (not self.enabled == false) do
            self.status = 'running'
            ranOk, compleated, result = pcall(fn, self, unpack(args))
            self.runCount = (self.runCount or 0) + 1
            if ranOk then
                if (not compleated) then
                    self.status = 'waiting'
                    if result then self.result = result end
                    arg = coroutine.yield(result)
                else
                    self.status = 'finished'
                    if result then self.result = result end
                    self.finishTime = os.clock()
                    return result
                end
            else
                self.status = 'dead'
                if result then self.result = result end
                return result
            end
            if (self.runLimit ~= nil) then
                if (self.runCount >= self.runLimit) then
                    compleated = true
                end
            end
        end
        return result
    end)
    return function(...)
        if self.status == 'sleeping' then
            self.status = 'waiting'
            return coroutine.resume(thread, ...)
        else
            return false
        end
    end
end
--- Create a task.
---@param   name    string      `the task name`
---@param   fn      function    `the task method.`
--- Note: your task method must return `false, result` while its running
--- and `true, result` when compleated.
---@return  simpleTask
function Task:new(name, fn)
    --- This tasks Name
    self.name = name
    --- Current Task Status [sleeping,running,finished,dead]
    self.status = 'sleeping'
    --- is this Task enabled?
    self.enabled = false
    --- how many times this task ran since the last reset
    self.runCount = 0
    --- limit the number of times this task can run
    self.runLimit = nil
    --- when this task was started (in CPU time)
    self.startTime = nil
    --- when this task finished (in CPU time)
    self.finishTime = nil
    --- Task main method
    self.method = fn
    self.thread = createThread(self, fn)
    local meta = getmetatable(self);
    meta['__type'] = string.format('Task::%s', (name or 'Unnamed'))
    return setmetatable(self, meta)
end

--- Enable this Task
function Task:enable()
    if self.enabled then
        return false, 'already enabled'
    elseif self.status == 'dead' then
        return false, 'task error'
    elseif self.status == 'finished' then
        return false, 'task finished'
    end
    self.enabled = true
    return true, 'task enabled'
end

--- Disable this Task
function Task:disable()
    if (not self.enabled) then return false, 'already disabled' end
    self.enabled = false
    return true, 'task disabled'
end

--- Reset this task (allows you to run a finished or dead task), also allows for changing input aguments to ::run()
function Task:reset()
    self.enabled = false
    self.status = 'sleeping'
    self.runCount = 0
    self.startTime = nil
    self.finishTime = nil
    self.thread = createThread(self, self.method)
end

--- Run this Task
--- Any provided arguments will be passed to the tasks main method.
--- Note: you can only set these args once, subsequent calls to Task:run()
--- will use the same values as the first, you have to call Task:reset() to change them
function Task:run(...)
    if (not self.enabled == true) then
        return false, 'Task not Enabled'
    elseif (self.status == 'finished') then
        return false, 'Task Compleated'
    elseif (self.status == 'dead') then
        return false, 'Task Died'
    end
    return self.thread(...)
end

function Task:runAsync(delay, callback, ...)
    local task_new_thread = function(args)
        local result = {self:run(unpack(args))}
        if (type(callback) == 'function') then callback(self, result) end
    end
    self.asyncTaskId = self:Timer(delay, 'task_new_thread', {...})
    return self.asyncTaskId
end

function Task:runAllways(delaySec, callback, ...)
    local args = {...}
    local task_constant_thread = function(this)
        local result = {self:run(unpack(args))}
        if (type(callback) == 'function') then callback(self, result) end
        this.runAllways(callback, unpack(args))
    end
    self.asyncTaskId = self:Timer(delaySec, 'task_constant_thread', self)
    return self.asyncTaskId
end

setmetatable(Task, taskMeta)

local simpleTask = function(timerHandler)
    local task = setmetatable({}, {__index = Task})
    task.Timer = timerHandler
    return task
end

RegisterModule('MisModding.Common.simpleTask', simpleTask)
return simpleTask
