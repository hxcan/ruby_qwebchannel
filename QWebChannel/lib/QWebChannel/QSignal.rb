class QSignal
    def initialize(signalName, signalIndex, object, isPropertyNotifySignal)
        @signalName=signalName
        @signalIndex=signalIndex
        @object=object
        @webChannel=@object.webChannel
        @isPropertyNotifySignal=isPropertyNotifySignal
    end
    
    def connect(callback)
        @object.__objectSignals__[@signalIndex]=@object.__objectSignals__[@signalIndex] || []
        @object.__objectSignals__[@signalIndex] << callback
        
        if (!@isPropertyNotifySignal && @signalName!= "destroyed")
            @webChannel.exec( { "type" => QWebChannelMessageTypes::CONNECTTOSIGNAL, "object" => @object.__id__, "signal" => @signalIndex  } )
        end
    end #def connect(callback)
    
    def disconnect(callback)
        @object.__objectSignals__[signalIndex]=@object.__objectSignals__[signalIndex] || []
        idx=@object.__objectSignals__[signalIndex].indexOf(callback)


        @object.__objectSignals__[signalIndex].delete_at(idx) 
        
        if (!isPropertyNotifySignal && @object.__objectSignals__[signalIndex].length == 0)
            @webChannel.exec( { "type" => QWebChannelMessageTypes::DISCONNECTFROMSIGNAL, "object" => @object.__id__, "signal" => signalIndex } )
        end #if (!isPropertyNotifySignal && @object.__objectSignals__[signalIndex].length == 0)
    end #def disconnect(callback)
end #class QSignal

