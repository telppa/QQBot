# QQBot
QQ机器人，可以收发个人或群消息。


## 准备
1. 运行 `mirai\mcl.cmd` 。
	- 如果用沙盒运行 mcl.cmd ，那么需要在运行前删除 mirai\plugins\mirai-login-solver-xxxxxx.jar 。
2. 在控制台界面找到并记录 `running with verifyKey: xxxxxxxx` 。
3. 在控制台界面输入命令 `login 123456 password IPAD` 回车。
	- 上述命令的意思是用密码 password 登录 qq 123456 的 IPAD 端；
	- 登录 IPAD 端的好处是不会把你手机和电脑的挤下线；
	- 登录过程中可能需要验证，照着做就行了。
4. 控制台出现绿字 `Bot login successful` 代表登录成功了。


## 用法
登录成功后，将下面的 verifyKey 和 qq 改为你自己的，然后就能用代码收发 QQ 消息了。
```AutoHotkey
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
```


## 其它
1. 退出控制台官方说要使用命令 `stop` ，直接关闭控制台可能丢数据。
2. 如果想运行 mcl.cmd 后就自动登录指定 qq ，可以使用命令 `autoLogin` 。
3. 建议机器人用小号，因为号可能会被风控（风控后一般可自助解封）。
4. 目前只封装了部分私聊功能，暂不包含任何群聊功能。
5. 更多官方说明：
	- https://github.com/mamoe/mirai/blob/dev/docs/ConsoleTerminal.md
