#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../QWebChannel', __FILE__)

require 'QWebChannel/QSignal'
require 'QWebChannel/QObject'
require 'set'
require 'oj' #optimized json
require 'json' #json解析库。

module QWebChannelMessageTypes
    SIGNAL=1
    PROPERTYUPDATE=2
    INIT=3
    IDLE=4
    DEBUG=5
    INVOKEMETHOD=6
    CONNECTTOSIGNAL=7
    DISCONNECTFROMSIGNAL=8
    SETPROPERTY=9
    RESPONSE=10
end


class QWebChannel
    # Communicate with C++ QWebChannel.
    
    #
    # Example:
    #   >> #!/usr/bin/env ruby
    #   >> 
    #   >> require 'websocket-eventmachine-client'
    #   >> require 'QWebChannel'
    #   >> 
    #   >> $core={}
    #   >> 
    #   >> $showReceivedMessageFromServer=Proc.new do |messageFromServer|
    #   >>     puts "Received message from server: #{messageFromServer}"
    #   >> end #$showReceivedMessageFromServer=Proc.new do |messageFromServer|
    #   >> 
    #   >> EM.run do
    #   >>     ws = WebSocket::EventMachine::Client.connect(:uri => 'ws://localhost:12345')
    #   >> 
    #   >>     ws.onopen do
    #   >>         qWebChannel = QWebChannel.new(ws) do |channel|
    #   >>             $core=channel.objects['core']
    #   >>             
    #   >>             puts "Connected to WebChannel, ready to send/receive messages!"
    #   >>             
    #   >>             puts "Sending message 'hello from client' to the server."
    #   >>             $core.receiveText('hello from client') #Call the "receiveText" slot on the server side.
    #   >> 
    #   >>             $core['sendText'].connect($showReceivedMessageFromServer) #Connect to the "sendText" signal on the server side.
    #   >>         end #qWebChannel = QWebChannel.new(ws) do |channel|
    #   >>     end #ws.onopen do
    #   >> 
    #   >>     ws.onclose do |code, reason|
    #   >>         puts "Disconnected with status code: #{code}"
    #   >>         EM.stop
    #   >>     end
    #   >> end #EM.run do
    #   >> 
    
    attr_reader :execId
    attr_writer :execId
    attr_reader :execCallbacks
    attr_writer :execCallbacks
    attr_reader :transport
    attr_writer :transport
    attr_reader :objects
    attr_writer :objects
    
    def send(data)
        if ( !(   data.is_a?(String) ) )
            data=Oj.dump(data)
        end
        
        puts "Sending: #{data}"
        
        @channel.transport.send(data)
    end
    
    def exec(data, &block)
        if !(block_given?)
            @channel.send(data)
            return
        end
        
        @channel.execId=@channel.execId+1
        data['id']=@channel.execId
                
        puts "data id: #{data['id']}"

        @channel.execCallbacks[data['id']]=block
        @channel.send(data)
    end
    
    def handleResponse(message)
        @channel.execCallbacks[message['id']].call(message['data'])
        
        @channel.execCallbacks[message['id']]=nil
    end
    
    def handleSignal(message)
        object=@channel.objects[message['object']]
        
        if (object)
            object.signalEmitted(message['signal'], message['args'])
        end
    end #def handleSignal(message)
    
    def handlePropertyUpdate(message)
        message['data'].each do |data| #一个个数据地处理。
            object= @channel.objects[data['object']] #获取发生变更的对象。
            
            if (object) #对象存在。
                object.propertyUpdate(data['signals'], data['properties']) #更新属性。
            else #对象不存在。
            end #if (object) #对象存在。
        end #message['data'].each do |data| #一个个数据地处理。
        
        @channel.exec({ 'type' => QWebChannelMessageTypes::IDLE })
    end #def handlePropertyUpdate(message)
    
    def initialize(websocket, &block)
        @index = nil #索引对象。
        @execId=0
        @execCallbacks={}
        @objects={}
        
        @transport=websocket
        @channel = self
        
        
        @transport.onmessage do |msg, type|
#             puts "Received message: #{msg}"
            
            puts "msg type: #{msg.class}"
            
            data =msg.to_s
            
            puts "data: #{data}"
            
            if (data.is_a?(String))
                data=JSON.parse(data)
            end
            
            puts "type: #{data.class}"
            
            case(data['type'])
            when QWebChannelMessageTypes::SIGNAL
                @channel.handleSignal(data)
            when QWebChannelMessageTypes::RESPONSE
                @channel.handleResponse(data)
            when QWebChannelMessageTypes::PROPERTYUPDATE
                @channel.handlePropertyUpdate(data)
            else
                puts("Invalid message arrived: #{data}")
            end
        end
        
        @channel.exec({'type' => QWebChannelMessageTypes::INIT}) do |data|
            puts "data type: #{data.class}"
            puts "data content: #{data}"
            
            data.each do |objectName, objectContent|
                puts "objectName type: #{objectName.class}"

                object=QObject.new(objectName, data[objectName], @channel)
            end
            
            @channel.objects.each do |objectName, objectObject| #一个个地解析出属性。
                @channel.objects[objectName].unwrapProperties()
            end #@channel.objects.each do |objectName, objectObject| #一个个地解析出属性。
            
            
#             puts "Self: #{self}"
            yield(self)
            
            
            @channel.exec({ "type" => QWebChannelMessageTypes::IDLE})
        end #@channel.exec({'type' => QWebChannelMessageTypes::INIT}) do |data|
    end #def initialize(websocket, &block)
    
end
