# RubyQWebChannel

Ruby implementation for QWebChannel.

QWebChannel，是QT5中自带的一个模块，其作用是将C++ QT5实现的程序进程里的原生C++接口对象反射后映射到某一种动态语言中去，使得动态语言代码和C++语言代码可以用各自语言中原生的语法对对方进行调用。官方自带的实现提供了对于JavaScript的支持。

本项目是实现了对于Ruby的支持。利用Ruby强大的元编程能力实现全套功能。在运行时，初始化过程中，根据对侧传送的QWebChannel消息，动态地创建原生Ruby对象，并为该对象动态添加方法、事件、属性，以将C++侧的对象映射为Ruby侧的对象。在之后的运行过程中，对双方的双向调用进行序列化和反序列化，对方法调用进行调度，对事件进行分发，以支持整个系统的正常运行。

在QWebChannel的具体实现中，只负责实现QWebChannel业务逻辑，以及消息的序列化和反序列化，并不负责消息的具体传送，因而对传输协议没有限制。实际使用过程中，可以按照项目实际情况选择合适的传输协议，只需要按照要求实现发送和接收接口即可。一般在实际项目中会使用WebSocket作为传输协议。

本项目在个人的一些C++QT5/Ruby混合语言项目中使用，用于进程间通信。
