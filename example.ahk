verifyKey := "xxxxxxxx"                                                   ; 步骤2记录下的 verifyKey
qq        := 123456                                                       ; 步骤3登录的 qq 号
qqbot     := new mirai(verifyKey, qq)                                     ; 连接 bot
会话信息  := qqbot.获取会话信息()                                         ; 获取 bot 信息
图片网址  := qqbot.上传图片("d:\test.jpg").url                            ; 上传图片并得到 url
ret       := qqbot.发送好友消息(对方qq号, "测试", {img:图片网址}, "通过") ; 发送一条消息（文字+图片+文字）

loop 5
{
  收到的消息 := qqbot.获取队列头部()                                      ; 获取收到的消息
  Sleep 5000
}

qqbot := ""                                                               ; 释放资源
ExitApp

#Include Mirai.ahk