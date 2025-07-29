; version: 2025.07.30
/* 示例1：
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
*/
/* 示例2：
	使用自定义事件处理函数覆盖默认的事件处理函数
	可以实现实时接收消息、好友请求通知等各种 qq 信息
	自定义事件处理函数务必要尽快返回，不应在里面直接进行耗时很长或阻塞型操作
	
	; 使用自定义函数 test() 处理 bot_on_message 事件
	x := new NapCat(,,, {"bot_on_message": "test"})       ; 连接已启动的 bot
	test(data, ws)
	{
		; 在这里可以实时收到 qq 消息
		ToolTip % data.message.1.data.text
		return
	}
	
	; 使用自定义函数 test() 处理 bot_on_message 事件
	x := new NapCat(,,, {"bot_on_message": Func("test")}) ; 连接已启动的 bot
	test(this, data, ws)                                  ; 传 Func 过去会导致函数多接收1个参数 this
	{
		; 在这里可以实时收到 qq 消息
		ToolTip % data.message.1.data.text
		return
	}
*/
#NoEnv

class NapCat
{
	; 为了方便外部读取以下3个存于 ws 实例中的变量，特将它们设为了本实例的属性
	; 之所以必须将它们存于 ws 实例中，是因为它们产生时来自于 ws 的回调函数例如 ws_on_message()
	; 而在 ws_on_message() 中， this 值指向 ws 实例，所以它们也就只能被存于产生时的 ws 实例中了
	bot_id[]
	{
		get
		{
			return this.ws.bot_id
		}
		set
		{
			return this.ws.bot_id := value
		}
	}
	
	bot_online[]
	{
		get
		{
			return this.ws.bot_online
		}
		set
		{
			return this.ws.bot_online := value
		}
	}
	
	ws_online[]
	{
		get
		{
			return this.ws.ws_online
		}
		set
		{
			return this.ws.ws_online := value
		}
	}
	
	; 不指定 path 则会尝试直接连接已启动的 bot
	__New(path := "", url := "ws://127.0.0.1:3001", token := "", bot_events := "")
	{
		if (path != "")
		{
			; 获取日志文件目录
			; X:\NapCatQQ\versions\9.9.19-34740\resources\app\napcat\logs
			loop Files, %path%\..\versions\*, D
			{
				SplitPath A_LoopFileLongPath, ver
				
				if (ver ~= "[\d\.\-]")
				{
					log_file_dir := Format("{}\..\versions\{}\resources\app\napcat\logs", path, ver)
					break
				}
			}
			
			; 删除现有全部日志
			FileRecycle %log_file_dir%\*.log
			
			; 启动 NapCatQQ 进程
			Run %path%, %path%\..\, , PID
			this.PID := PID
			
			; 读取最新日志内容
			loop
			{
				Sleep 2000
				
				loop Files, %log_file_dir%\*.log
				{
					FileRead OutputVar, *p65001 %A_LoopFileLongPath%
					
					arr := StrSplit(OutputVar, "`n", "`r")
					loop % arr.MaxIndex()
					{
						; 从最后1行逐行往前
						line := arr[arr.MaxIndex() - A_Index + 1]
						
						; 成功自动登录
						if (InStr(line, "[Core] [Packet] 自动选择"))
							break 3
						
						; 需要手动登录
						if (InStr(line, "[warn] 二维码已保存到"))
						{
							RunWait %log_file_dir%\..\cache\qrcode.png
							break 2
						}
					}
				}
			}
		}
		
		ws_events := {"message": this.ws_on_message, "error": this.ws_on_error, "close": this.ws_on_close}
		
		this.ws := new WebSocket(url, ws_events, , "Authorization: Bearer " token)
		
		; 默认的 bot 事件处理函数，可在 new 时传参 bot_events 进行覆盖
		this.ws.bot_events := { "bot_on_meta_event": this.bot_on_meta_event
													, "bot_on_request": this.bot_on_request
													, "bot_on_notice": this.bot_on_notice
													, "bot_on_message": this.bot_on_message
													, "bot_on_message_sent": this.bot_on_message_sent }
		
		; 用自定义 bot 事件处理函数覆盖默认的 bot 事件处理函数
		for k, v in bot_events
			this.ws.bot_events[k] := IsFunc(v) ? v : Func(v)
		
		; 以下3个变量可通过外部读取，获取状态
		this.ws.bot_id     := 0  ; 机器人 qq 号
		this.ws.bot_online := 0  ; 机器人状态 0离线 1在线
		this.ws.ws_online  := 0  ; ws 协议连接状态 0断开 1连接 -1触发了 onerror
		
		; 以下3个是内部变量，不要在外部直接读写它们
		this.ws.echo       := 0  ; ws 发出请求时的标记，方便识别请求对应响应，内部变量
		this.ws.响应队列   := {} ; ws 发出请求后收到的全部响应，内部变量
		this.ws.消息队列   := [] ; 收到的全部消息，内部变量
		
		if (this.发送命令("get_login_info").status = "ok")
			this.bot_online := 1
	}
	
	发送好友消息(user_id, message*)
  {
    messageChain := []
		
    for i, msg in message
    {
      if (IsObject(msg) and msg.HasKey("img"))
        messageChain.Push({"type": "image", "data": {"file": msg.img}})
      else
        messageChain.Push({"type": "text", "data": {"text": msg}})
    }
		
		message := {"user_id": user_id, "message": messageChain}
		
		return this.发送命令("send_private_msg", message)
	}
	
  获取队列头部()
  {
    ; 获取队列头部（获取消息并从队列中删除）
    ; 比如别人依次发了3条消息 11 22 33 过来
    ; 那么这里看到的顺序就是 [11,22,33]
		this.发送命令("_mark_all_as_read")
		return this.ws.消息队列, this.ws.消息队列 := []
  }
  
  查看队列头部()
  {
    ; 查看队列头部（查看消息但不从队列中删除）
    return this.ws.消息队列
  }
	
	发送命令(action, params := "")
	{
		this.ws.echo += 1
		echo         := this.ws.echo
		
		if (params = "")
			template := {"action": action, "echo": echo}
		else
			template := {"action": action, "params": params, "echo": echo}
		
		this.ws.Send(json.dump(template))
		
		; 等待响应队列返回值，超过30秒则强制退出等待
		loop 3000
		{
			Sleep 10
			
			if (this.ws.响应队列.HasKey(echo))
				return this.ws.响应队列.Delete(echo)
		}
	}
	
	ws_on_message(Event)
	{
		data := json.load(Event.data)
		
		; 事件
		if (data.post_type)
		{
			; bot 事件虽然都是从 ws_on_message() 跳转过去的
			; 但 bot 事件中的 this 指向变量 this.ws.bot_events 而不是 ws ，所以需要单独传 ws 过去
			switch data.post_type
			{
				case "meta_event":
					this.bot_events.bot_on_meta_event(data, this)
				case "request":
					this.bot_events.bot_on_request(data, this)
				case "notice":
					this.bot_events.bot_on_notice(data, this)
				case "message":
					this.bot_events.bot_on_message(data, this)
				case "message_sent":
					this.bot_events.bot_on_message_sent(data, this)
			}
		}
		; 发送命令的响应
		else if (data.echo)
		{
			this.响应队列[data.echo] := data
		}
	}
	
	; 元事件是 ws 协议相关的事件，如心跳、生命周期等
	bot_on_meta_event(data, ws)
	{
		if (data.meta_event_type = "lifecycle") ; 生命周期
			switch data.sub_type
			{
				case "connect", "enable":
					ws.bot_id := data.self_id
				case "disable":
					ws.bot_id := 0
			}
		
		if (data.meta_event_type = "heartbeat") ; 心跳
			ws.ws_online := data.status.online
	}
	
	; 请求事件是处理各类需要回应的请求，如好友请求、加群请求等
	bot_on_request(data, ws)
	{
		return
	}
	
	; 通知事件是接收各类通知，如好友添加、群组变动、消息撤回、机器人离线等
	bot_on_notice(data, ws)
	{
		if (data.notice_type = "bot_offline") ; 机器人离线
			ws.bot_online := 0
	}
	
	; 消息事件是接收各类消息，包括私聊和群聊消息
	bot_on_message(data, ws)
	{
		if (data.message_type = "private" and data.sub_type = "friend") ; 好友私聊消息
		{
			template := { "sender": data.user_id
									, "text"  : ""
									, "time"  : int2time(data.time, 19700101080000) } ; 转为东八区时间
			
			for i, v in data.message
			{
				switch v.type
				{
					case "text":
						template.text := v.data.text
					case "image":
						template.text := v.data.url
				}
				
				ws.消息队列.Push(template)
			}
		}
	}
	
	; 消息发送事件是发送各类消息，包括私聊和群聊消息
	bot_on_message_sent(data, ws)
	{
		return
	}
	
	ws_on_error(Event)
	{
		this.ws_online := -1
	}
	
	ws_on_close(Event)
	{
		this.ws_online := 0
	}
}

#Include %A_LineFile%\..\WebSocket.ahk
#Include %A_LineFile%\..\cjson.ahk
#Include %A_LineFile%\..\int2time.ahk