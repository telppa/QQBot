# QQBot
QQ机器人，可以实时收发个人或群消息等。


## 准备
1. 运行 `NapCat.Shell.Windows.OneKey\NapCatInstaller.exe`
	- 可得到一个无头版 NapCatQQ 机器人。
2. 运行 `NapCat.xxxxx.Shell\napcat.bat`
   	- 使用手机 QQ 扫出现的二维码并登录。
	- 建议在手机上勾选 “下次登录无需手机确认” 。
3. 浏览器打开 `http://127.0.0.1:6099/webui?token=napcat`
	- 在 “网络设置” 中新建一个 “WebSocket 服务器” 。
	- “WebSocket 服务器” 保持默认设置并勾选启用即可。


## 用法
登录且网络设置成功后，将下方代码中的变量 `对方qq号` 和 `图片地址或网址` 改为你自己的，就能用代码收发 QQ 消息了。  
更多用法可参考示例 `example1.ahk` `example2.ahk` 。
```AutoHotkey
qqbot := new NapCat()                                                       ; 连接已启动的 bot
ret   := qqbot.发送好友消息(对方qq号, "测试", {img:图片地址或网址}, "通过") ; 发送一条消息（文字+图片+文字）
loop 5
{
  收到的消息 := qqbot.获取队列头部()                                        ; 获取收到的消息
  ToolTip % 收到的消息.1.text
  Sleep 5000
}
qqbot := ""                                                                 ; 释放资源
ExitApp
```


## 其它
1. 建议机器人用小号，因为号可能会被风控（风控后一般可自助解封）。
2. 目前只封装了部分私聊功能，暂不包含任何群聊功能。
3. 更多官方说明：
	- https://napneko.github.io/guide/start-install
4. 本库最早基于 `Mirai` 项目封装，因其被封杀后已实际不可用，现改用 `NapCat` 项目进行封装。
	- 由于两者 API 有所区别，故新接口不完全兼容旧接口。

