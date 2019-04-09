
## 缺省定义变量

    - MESSAGES: 每次on_tick 时可以通过读取该变量, 获得从http或web socket那里获得的信息. 
    - UPTIME: 从服务器启动到当前经过的时间, 单位毫秒
    - DELTA_TIME: 上次tick到当前的时间经过

## MESSAGES 结构

    MESSAGES 是一个数组, 数组里面的每一项代表外部传入的信息. 每一数组项又由三个元素组成:
    
    - 第一个代表信息的类型, 1为http传入的信息, 2为websocket传入的信息
    - 第二个代表发送信息的来源id(类型:number), 每个来源id都是唯一的. 对于websocket来说同一个链接来源id相同; 对于http来说, 每次访问都会产生不同的来源id
    - 第三个代表信息的具体内容

## 传输的信息要求

    - websocket 必须为json类型
    - http 必须为键值对