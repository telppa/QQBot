/*
示例：
  qqbot    := new mirai("你的 verifyKey", 你的qq号)                        ; 连接 bot
  会话信息 := qqbot.获取会话信息()                                         ; 获取 bot 信息
  图片网址 := qqbot.上传图片("d:\test.jpg").url                            ; 上传图片并得到 url
  ret      := qqbot.发送好友消息(对方qq号, "测试", {img:图片网址}, "通过") ; 发送一条消息（文字+图片+文字）
  loop 5
  {
    收到的消息 := qqbot.获取队列头部()                                     ; 获取收到的消息
    Sleep 5000
  }
  qqbot := ""                                                              ; 释放资源
  ExitApp

目前只封装了部分私聊功能，暂不包含任何群聊功能。
api 文档地址：
  https://github.com/project-mirai/mirai-api-http/blob/master/docs/adapter/HttpAdapter.md
*/
class Mirai
{
  ; Mirai 的变量，存于 base 中 
  static 主机   := "http://127.0.0.1:8080"
  static 设置   := "Charset:UTF-8"
  static 状态码 := {0:   "正常"
                  , 1:   "错误的verify key"
                  , 2:   "指定的Bot不存在"
                  , 3:   "Session失效或不存在"
                  , 4:   "Session未认证(未激活)"
                  , 5:   "发送消息目标不存在(指定的对象不存在)"
                  , 6:   "文件不存在(指定的本地图片不存在)"
                  , 10:  "无操作权限(Bot没有对应操作的权限)"
                  , 20:  "Bot被禁言(Bot无法向指定群发送消息)"
                  , 30:  "消息过长"
                  , 400: "错误的访问(请求参数错误等)"}
  
  ; 每个 Mirai 实例的变量，存于 base 同级
  请求头    := "Content-Type:application/json"
  session   := ""
  qq        := ""
  lastError := ""
  
  __New(verifyKey, qq)
  {
    ; 确保整数
    qq := qq + 0
    
    ; 认证
    session := this.http("/verify", {"verifyKey":verifyKey}, "认证失败").session
    
    ; 绑定
    if (!this.http("/bind", {"sessionKey":session, "qq":qq}, "绑定失败"))
      return
    
    ; 为后面所有需要 session 参数的请求省略此参数
    this.请求头  .= "`nsessionKey: " session
    
    ; 释放时需要指定 sessionKey 和 qq
    this.session := session
    this.qq      := qq
  }
  
  __Delete()
  {
    ; 释放
    this.http("/release", {"sessionKey":this.session, "qq":this.qq}, "释放失败")
  }
  
  获取会话信息()
  {
    return this.http("/sessionInfo", , "获取会话信息失败")
  }
  
  获取队列头部()
  {
    ; 查看队列大小
    队列大小 := this.http("/countMessage", , "查看队列大小失败")
    
    ; 获取队列头部（获取消息并从队列中删除）
    ; 比如别人依次发了3条消息 11 22 33 过来
    ; 那么这里看到的顺序就是 [11,22,33]
    队列 := this.http("/fetchMessage?count=" 队列大小, , "获取队列头部失败")
    
    return this.解析队列(队列)
  }
  
  获取队列尾部()
  {
    ; 查看队列大小
    队列大小 := this.http("/countMessage", , "查看队列大小失败")
    
    ; 获取队列尾部（获取消息并从队列中删除）
    ; 比如别人依次发了3条消息 11 22 33 过来
    ; 那么这里看到的顺序就是 [33,22,11]
    队列 := this.http("/fetchLatestMessage?count=" 队列大小, , "获取队列尾部失败")
    
    return this.解析队列(队列)
  }
  
  查看队列头部()
  {
    ; 查看队列大小
    队列大小 := this.http("/countMessage", , "查看队列大小失败")
    
    ; 查看队列头部（查看消息但不从队列中删除）
    队列 := this.http("/peekMessage?count=" 队列大小, , "查看队列头部失败")
    
    return this.解析队列(队列)
  }
  
  查看队列尾部()
  {
    ; 查看队列大小
    队列大小 := this.http("/countMessage", , "查看队列大小失败")
    
    ; 查看队列尾部（查看消息但不从队列中删除）
    队列 := this.http("/peekLatestMessage?count=" 队列大小, , "查看队列尾部失败")
    
    return this.解析队列(队列)
  }
  
  解析队列(队列)
  {
    if (队列 = "")
      return
    
    ret := []
    for i, v in 队列
    {
      switch v.type
      {
        case "FriendMessage":
          if (v.messageChain.2.type = "Plain")
            ret.Push({"sender": v.sender.id
                    , "text":   v.messageChain.2.text
                    , "time":   int2time(v.messageChain.1.time, 19700101080000)}) ; 转为东八区时间
          else if (v.messageChain.2.type = "Image")
            ret.Push({"sender": v.sender.id
                    , "text":   v.messageChain.2.url
                    , "time":   int2time(v.messageChain.1.time, 19700101080000)})
      }
    }
    return ret
  }
  
  上传图片(filepath, type := "friend")
  {
    if (!FileExist(filepath))
    {
      this.lastError := {Message:"上传图片失败", Extra:"指定图片不存在：" filepath}
      return
    }
    
    URL        := this.主机 "/uploadImage"
    out_Header := this.请求头
    WinHttp.CreateFormData(out_PostData, out_Header, [["img", {"filepath":filepath}], ["type", type]])
    
    try ret := json.load(WinHttp.Download(URL, this.设置, out_Header, out_PostData))
    
    if (ret.url)
    {
      this.lastError := ""
      return ret
    }
    else
    {
      this.lastError := {Message:"上传图片失败", Extra:ret.msg}
      return
    }
  }
  
  ; 可验证 http 服务是否开启
  获取关于()
  {
    return this.http("/about", , "获取关于失败")
  }
  
  ; 可验证 QQ 号是否登录
  获取登录账号(verifyKey := "")
  {
    ; 没有绑定的情况下依然可以获取登录账号
    if (verifyKey)
    {
      session := this.http("/verify", {"verifyKey":verifyKey}, "认证失败").session
      queryString := "?sessionKey=" session
    }
    
    return this.http("/botList" queryString, , "获取登录账号失败")
  }
  
  获取好友资料(target)
  {
    return this.http("/friendProfile?target=" target, , "获取好友资料失败", false)
  }
  
  发送好友消息(target, message*)
  {
    messageChain := []
    for i, msg in message
    {
      if (IsObject(msg) and msg.HasKey("img"))
        messageChain.Push({"type":"Image", "url":msg.img})
      else
        messageChain.Push({"type":"Plain", "text":msg})
    }
    
    return this.http("/sendFriendMessage", {target:target+0, messageChain:messageChain}, "发送好友消息失败")
  }
  
  ; 官方 api 设计的相当随意，返回值总共有3种可能
  ; 1. 不存在状态码
  ; 2. 存在状态码，数据存于 data 中
  ; 3. 存在状态码，数据不存于 data 中，而是直接与状态码同级
  http(interface, 提交数据 := "", 报错信息 := "", 返回值存在状态码 := true)
  {
    URL      := this.主机 interface
    提交数据 := IsObject(提交数据) ? json.dump(提交数据) : 提交数据
    
    try
      ret := json.load(WinHttp.Download(URL, this.设置, this.请求头, 提交数据))
    catch
    {
      this.lastError := {Message:报错信息}
      return
    }
    
    if (返回值存在状态码)
    {
      if (ret.code = 0)
      {
        this.lastError := ""
        
        ; 数据存于 data 中
        if (ret.HasKey("data"))
          return ret.data
        ; 数据不存于 data 中，而是直接与状态码同级
        else
        {
          ret.Delete("code")
          ret.Delete("msg")
          return ret
        }
      }
      else
      {
        this.lastError := {Message:报错信息, Extra:this.状态码(ret.code)}
        return
      }
    }
    else
    {
      this.lastError := ""
      return ret
    }
  }
}

#Include <WinHttp>
#Include <cjson>
#Include <int2time>