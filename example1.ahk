qqbot := new NapCat("X:\NapCatQQ\napcat.quick.bat")                         ; 启动 bot 并连接
ret   := qqbot.发送好友消息(对方qq号, "测试", {img:图片地址或网址}, "通过") ; 发送一条消息（文字+图片+文字）
loop 5
{
  收到的消息 := qqbot.获取队列头部()                                        ; 获取收到的消息
  ToolTip % 收到的消息.1.text
  Sleep 5000
}
qqbot := ""                                                                 ; 释放资源
ExitApp

#Include Lib\NapCat.ahk