#!/usr/bin/env ruby

require 'websocket-eventmachine-client'
require 'QWebChannel'

$core={}

$showReceivedMessageFromServer=Proc.new do |messageFromServer|
    puts "Received message from server: #{messageFromServer}"
end #$showReceivedMessageFromServer=Proc.new do |messageFromServer|

EM.run do
    ws = WebSocket::EventMachine::Client.connect(:uri => 'ws://localhost:12345')

    ws.onopen do
        qWebChannel = QWebChannel.new(ws) do |channel|
            $core=channel.objects['core']
            
            puts "Connected to WebChannel, ready to send/receive messages!"
            
            puts "Sending message 'hello from client' to the server."
            $core.receiveText('hello from client') #Call the "receiveText" slot on the server side.

            $core['sendText'].connect($showReceivedMessageFromServer) #Connect to the "sendText" signal on the server side.
        end #qWebChannel = QWebChannel.new(ws) do |channel|
    end #ws.onopen do

    ws.onclose do |code, reason|
        puts "Disconnected with status code: #{code}"
        EM.stop
    end
end #EM.run do
