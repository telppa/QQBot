; 使用自定义事件处理函数覆盖默认的事件处理函数
; 可以实现实时接收消息、好友请求通知等各种 qq 信息
; 自定义事件处理函数务必要尽快返回，不应在里面直接进行耗时很长或阻塞型操作

; 使用自定义函数 test() 处理 bot_on_message 事件
x := new NapCat(,,, {"bot_on_message": "test"})       ; 连接已启动的 bot
test(data, ws)
{
  ; 在这里可以实时收到 qq 消息
  ToolTip % data.message.1.data.text
  return
}

#Include Lib\NapCat.ahk