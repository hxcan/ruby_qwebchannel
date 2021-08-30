#!/usr/bin/env ruby

require 'eventmachine'
require 'ipaddr'

class MulticastHandler < EventMachine::Connection
    def castData(packageString)
        multicastHost = '239.173.40.5' #组播组主机地址。
        multicastPort = 11500 #组播组端口。

#         print("castData\n") #Debug.
#         send_data(packageString)
        send_datagram(packageString, multicastHost, multicastPort) #发送组播数据包。
    end
    
    def receive_data(data)
#         puts data
    end
    
    def post_init
#         print("post_init\n") #Debug.
        port, host = Socket::unpack_sockaddr_in( get_sockname() )
        ip = IPAddr.new( host ).hton + IPAddr.new("0.0.0.0").hton
        set_sock_opt( Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ip )
    end
end

