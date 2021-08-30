class QObject 
    attr_accessor :__propertyCache__
    attr_accessor :__id__
    attr_accessor :__objectSignals__
    attr_accessor :webChannel
    
    def unwrapQObject(response)
        puts "response class: #{response.class}" #debug
        if (response.is_a?(Array))
            ret = []
            
            response.each do |responseI|
                ret << @object.unwrapQObject(responseI)
            end
            
            return ret
        end #if (response.is_a?(Array))
        
        
        if (!response || response.is_a?(Fixnum)  ||  response.is_a?(Float)  || response.is_a?(TrueClass) || !response["__QObject*__"] || response.id == nil)
            return response
        end
        
        objectId=response.id
        
        if (@webChannel.objects[objectId])
            return @webChannel.objects[objectId]
        end


        qObject=QObject.new(objectId, response.data, @webChannel)
        
        qObject.destroyed.connect() do 
            if (@webChannel.objects[objectId]==qObject)
                @webChannel.objects.delete(objectId)
                
                propertyNames=[]
                
                qObject.each do |propertyName|
                    propertyNames << propertyName
                end
                
                propertyNames.each do |propertyName|
                    qObject.delete(propertyName)
                end
            end #if (@webChannel.objects[objectId]==qObject)
        end #qObject.destroyed.connect() do 
        
        qObject.unwrapProperties()
        
        return qObject
    end #def unwrapQObject(response)
    
    #解码出属性。
    def unwrapProperties()
        @object.__propertyCache__.each do |propertyIdx, propertyObject| #一个个地解码属性。
            puts "propertyIdx: #{propertyIdx}" #Debug.
            @object.__propertyCache__[propertyIdx]=@object.unwrapQObject(@object.__propertyCache__[propertyIdx])
        end #@object.__propertyCache__.each do |propertyIdx, propertyObject| #一个个地解码属性。
    end #def unwrapProperties()
    
    def []=(signalName, signalObject)
        @signalNameObjectHash[signalName]=signalObject
    end #def []=(signalName, signalObject)
    
    def [](signalName)
        @signalNameObjectHash[signalName]
    end #def [](signalName)
    
    def bindGetterSetter(propertyInfo)
        propertyIndex=propertyInfo[0]
        propertyName=propertyInfo[1]
        notifySignalData=propertyInfo[2]
        
        @object.__propertyCache__[propertyIndex]=propertyInfo[3]
        
        if (notifySignalData)
            if (notifySignalData[0] == 1)
                notifySignalData[0]=propertyName+"Changed"
            end
            addSignal(notifySignalData, true)
        end #if (notifySignalData)
        
        defineProperty(propertyName, propertyIndex) #定义属性。对应于Object.defineProperty.
    end #def bindGetterSetter(propertyInfo)
    
    def defineProperty(propertyName, propertyIndex)
        @propertyNameIndexMap[propertyName]=propertyIndex #记录映射关系。
#         define_property_by_prototype(propertyName)
        
        
                #getter
#         self.class_eval( " def #{attr_name}; @#{attr_name};   end  " )
        self.instance_eval %Q{
            def #{propertyName}
                propertyIndex=@propertyNameIndexMap["#{propertyName}"] #获取属性索引。
                puts "propertyIndex: #{propertyIndex}, propertyName: #{propertyName}, object: #{@object}" #Debug.
               @object.__propertyCache__[propertyIndex]
            end
            }

        #setter
        self.instance_eval %Q{
            def #{propertyName}=(val)
                propertyIndex=@propertyNameIndexMap["#{propertyName}"] #获取属性索引。

                
                @object.__propertyCache__[propertyIndex]=val
                
                valueToSend=val
                
                if (valueToSend.is_a?(QObject) && @webChannel.objects[valueToSend.__id__] != nil)
                    valueToSend={"id" => valueToSend.__id__}
                    
                end
                
                puts "Sending set property message" #Debug.
                @webChannel.exec( {"type" => QWebChannelMessageTypes::SETPROPERTY, "object" => @object.__id__ , "property" => propertyIndex, "value" => valueToSend } )
                

            end


            }

    end #def defineProperty(propertyName)
    
    def invokeSignalCallbacks(signalName, signalArgs)
        connections=@object.__objectSignals__[signalName]
        
        if (connections) #存在连接。
            connections.each do |callback| #一个个连接地处理。
                callback.call(*signalArgs) #抹平数组。
            end #connections.each do |callback| #一个个连接地处理。
        end #if (connections)
    end #def invokeSignalCallbacks(signalName, signalArgs)
    
    def propertyUpdate(signals, propertyMap)
        propertyMap.each do |propertyIndex, propertyValue|
            puts "updating property, index: #{propertyIndex}, value: #{propertyValue}, object: #{@object}" #Debug.
            @object.__propertyCache__[propertyIndex]=propertyValue
            puts "updating property, property cache: #{@object.__propertyCache__}" #Debug.
            puts "updating property, updated property value: #{@object.__propertyCache__[propertyIndex]}" #Debug.
            
        end #propertyMap.each do |propertyIndex, propertyValue|
        
        signals.each do |signalName|
            invokeSignalCallbacks(signalName, signals[signalName])
        end #signals.each do |signalName|    
    end #def propertyUpdate(signals, propertyMap)
    
    def signalEmitted(signalName, signalArgs)
        puts "signalArgs: #{signalArgs}" #debug.
        invokeSignalCallbacks(signalName, self.unwrapQObject(signalArgs))
    end #def signalEmitted(signalName, signalArgs)
    
    def addSignal(signalData, isPropertyNotifySignal)
        signalName=signalData[0]
        signalIndex=signalData[1]
        
        @object[signalName]=QSignal.new(signalName, signalIndex, @object, isPropertyNotifySignal) #添加信号。
    end #def addSignal(signalData, isPropertyNotifySignal)
    
    def addMethod(methodData)
        methodName=methodData[0]
        methodIdx=methodData[1]
        
        @object.define_singleton_method(methodName) do |*arguments|
            args=[]
            callback=nil
            
            arguments.each do |argument|
                puts "argument class: #{argument.class}" #debug.
                if (argument.is_a?(Proc))
                    callback=argument
                elsif ( (argument.is_a?(QObject))  && (@webChannel.objects[argument.__id__] !=nil ) )
                    args << ({"id" => argument.__id__})
                else
                    args << argument
                end
            end #arguments.each do |argument|
            
            puts "__id__: #{@object.__id__}" #debug.

            
            @webChannel.exec({ "type" => QWebChannelMessageTypes::INVOKEMETHOD,  "object" => @object.__id__, "method" => methodIdx, "args" => args }) do |response|
                if (response!=nil)
                    result = @object.unwrapQObject(response)
                    
                    if (callback)
                        callback.call(result)
                    end
                end #if (response!=nil)
            end #@webChannel.exec() do |response|
            
            
        end #@object.define_singleton_method(methodName) do |*arguments|
    end #def addMethod(methodData)
    
    def initialize(name, data, webChannel)
        @signalNameObjectHash={} #信号名字与信号对象的映射。
        @__id__=name
        @webChannel=webChannel
        @propertyNameIndexMap={} #记录映射关系。属性名字与属性索引之间的映射关系。
        
        webChannel.objects[name]=self
        
        puts "__id__: #{@__id__}" #debug.
        
        
        @__objectSignals__ = {}
        
        @__propertyCache__ = {}
        
        @object=self
        
        data['methods'].each do |method|
            puts "current method: #{method}" #debug
            addMethod(method)
        end
        
        data['properties'].each do |property|
            bindGetterSetter(property)
        end
        
        data['signals'].each do |signal|
            addSignal(signal, false)
        end
        
        puts "enums: #{data['enums']}" #Debug.
        
        if data['enums']
            data['enums'].each do |name|
                @object[name]=data['enums'][name]
            end #data['enums'].each do |name|
        end #if data['enums']
    end
end
