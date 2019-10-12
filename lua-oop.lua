---
--- Created by yangfan
--- DateTime: 2019/10/8 16:49
---

--执行构造函数 by.yangfan -19-9-28
local function invokeCtor(class_type,instance,...)

    if class_type.super then
        invokeCtor(class_type.super,instance,...)
    end

    if class_type.ctor then
        class_type.ctor(instance,...)
    end

end


--构建类的方法  --by.yangfan --19-9-28
function DeclareClass(className,super)

    local class_type = {}--代表类原型的table

    class_type.__classname = className
    class_type.super = super
    --预先声明构造函数
    class_type.ctor = function() end

    --成员函数表
    local funcTable = {}
    class_type.funcTable = funcTable

    class_type.meta = {
        __index = class_type.funcTable
    }

    if super then
        setmetatable(funcTable,{
            __index = function(t,k)
                local ret = super.funcTable[k]
                funcTable[k] = ret
                return ret
            end
        })
    end

    class_type.new = function(...)

        local instance = {}
        local fields = {}--成员变量表

        instance.__classname = class_type.__classname
        instance.__fields = fields

        --递归调用构造函数(包括父类的构造函数)，将构造函数中声明的成员写入实例对象中。
        invokeCtor(class_type,fields,...)

        setmetatable(instance,{
            __index = function(t,k)
                local ret = fields[k]
                return ret
            end,
            __newindex = function(t,k,v)
                fields[k] = v
            end
        })

        setmetatable(fields,class_type.meta)

        return instance
    end


    --对于代表类的table只允许声明function类型的值
    --Tips.除了构造函数，其他声明的函数会存入funcTable表中
    setmetatable(class_type,{
        __newindex = function(t,k,v)
            if type(v) ~= 'function' then
                return
            end
            t.funcTable[k] = v
        end
    })

    return class_type
end
