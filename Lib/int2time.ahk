﻿; 将距 1970年1月1日0时0分0秒 的秒数或毫秒数转换为时间
; 例如值 “1318238100” 就被转换为时间 “2011-10-10 09:15:00”
; 将 timeBegin 设置为一个偏移值，例如 19700101080000 即可实现带时区（东八区）的转换
; MsgBox % int2time(1318238100)                                      ; 20111010091500
; MsgBox % int2time(1318238100123,,, "ms")                           ; 20111010091500123
; MsgBox % int2time(1318238100,, "yyyy-MM-dd HH:mm:ss.fff")          ; 2011-10-10 09:15:00
; MsgBox % int2time(1318238100123,, "yyyy-MM-dd HH:mm:ss.fff", "ms") ; 2011-10-10 09:15:00.123
int2time(int, timeBegin := 1970, timeFormat := "yyyyMMddHHmmssfff", intType := "s")
{
	if      (intType = "s")
		; 去掉 “HH:mm:ss.fff yyyy-MM-dd” 中的 “.fff”
		timeFormat := RegExReplace(timeFormat, "([[:punct:] ]*)fff")
	else if (intType = "ms")
	{
		; 传入了带毫秒的时间，提取毫秒数与主时间
		mSec := SubStr(int, -2, 3) ; 末3位
		int  := SubStr(int, 1, -3) ; 除去末3位
		
		; 将 “HH:mm:ss.fff yyyy-MM-dd” 分成3段
		StartingPos := 1
		while (RegExMatch(timeFormat, "O)([[:punct:] ]*)(fff)", OutputVar, StartingPos))
		{
			; fff 是被单引号包裹的原义 fff
			if (_is_fff_literal(OutputVar.Pos(2), OutputVar.Pos(2) + OutputVar.Len(2) - 1, timeFormat))
				StartingPos := OutputVar.Pos(2) + OutputVar.Len(2)
			; fff 需要被转换
			else
			{
				timeFormat_part1 := SubStr(timeFormat, 1, OutputVar.Pos - 1)          ; 段1 “HH:mm:ss”
				timeFormat_part2 := OutputVar.Value                                   ; 段2 “.fff”
				timeFormat_part3 := SubStr(timeFormat, OutputVar.Pos + OutputVar.Len) ; 段3 “ yyyy-MM-dd”
				
				; fff 转换为具体值 例如 “ .fff” 将转换为 “ .123”
				timeFormat_part2 := StrReplace(timeFormat_part2, "fff", mSec)
				; 合并出新的 timeFormat
				timeFormat       := timeFormat_part1 timeFormat_part2 timeFormat_part3
			}
		}
	}
	else
		int := ""
	
	; 此处 int 不是数值就会返回空
	EnvAdd timeBegin, %int%, Seconds
	if (timeBegin = "")
		return
	
	FormatTime ret, %timebegin%, %timeFormat%
	
	return ret
}

_is_fff_literal(fff_start_pos, fff_end_pos, str)
{
	for k, v in _get_literal_range(str)
		if (fff_start_pos>=v.1 and fff_end_pos<=v.2)
			return true
}

_get_literal_range(str)
{
	literal_range := []
	open_starting_pos := 1
	; 找到开单引号
	while(open_pos := InStr(str, "'", , open_starting_pos))
	{
		close_starting_pos := open_pos + 1
		loop
		{
			; 找到闭单引号群 即 “yyyy'-'''MM” 中的 “'''”
			if (close_pos := InStr(str, "'", , close_starting_pos))
			{
				RegExMatch(SubStr(str, close_pos), "O)^'+", OutputVar)
        
				; 闭单引号群是单数 此处单引号可以闭合
				if (Mod(OutputVar.Len, 2))
				{
					close_pos := close_pos + OutputVar.Len - 1
					open_starting_pos := close_pos + 1
					literal_range.Push([open_pos, close_pos])
					break
				}
				; 闭单引号群是双数 此处单引号不能闭合 跳过此处
				else
					close_starting_pos := close_pos + OutputVar.Len
			}
			; 没找到闭单引号群则使用文末坐标作为闭单引号坐标
			else
			{
				close_pos := StrLen(str) + 1
				open_starting_pos := close_pos + 1
				literal_range.Push([open_pos, close_pos])
				break
			}
		}
	}
  
  return literal_range
}