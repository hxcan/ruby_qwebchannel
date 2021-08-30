Gem::Specification.new do |s| 
    s.name = 'QWebChannel'
    s.version = '2019.1.23'
    s.date = '2019-01-23'
    s.summary = "QWebChannel ruby."
    s.description = "QWebChannel ruby. Work with QWebChannel in pure ruby."
    s.authors = ["Hxcan Cai"]
    s.email = 'caihuosheng@gmail.com'
    s.files = ["lib/QWebChannel.rb", "lib/QWebChannel/QSignal.rb", "lib/QWebChannel/MulticastHandler.rb", "lib/QWebChannel/QObject.rb", "lib/QWebChannel/HearchIndexEntry_pb.rb"]
    s.homepage =
            'http://rubygems.org/gems/QWebChannel'
    s.license = 'MIT'
    
    s.add_runtime_dependency 'websocket-eventmachine-client', '~> 1.2', '>= 1.2.0'
    s.add_runtime_dependency 'oj', '~> 3.1', '>= 3.1.3'
#     s.add_runtime_dependency 'plexus-rmmseg', '~> 0.1', '>= 0.1.6'
end
