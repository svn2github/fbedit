
.code

FindNextTrigger proc uses ebx esi edi

	.if STM32_Cmd.STM32_Lga.TriggerMask
		mov		edi,transstart
		movzx	eax,STM32_Cmd.STM32_Lga.DataBlocks
		mov		esi,1024
		mul		esi
		mov		esi,eax
		dec		esi
		movzx	edx,STM32_Cmd.STM32_Lga.TriggerMask
		movzx	ecx,STM32_Cmd.STM32_Lga.TriggerValue
		and		ecx,edx
		inc		edi
		.while edi<esi
			movzx	eax,LGA_Data[edi]
			and		eax,edx
			.if eax==ecx
				mov		transstart,edi
				sub		edi,GRIDX*4/2
				.if CARRY?
					xor		edi,edi
				.endif
				mov		lgaxofs,edi
				invoke InvalidateRect,hLGAScrn,NULL,TRUE
				invoke UpdateWindow,hLGAScrn
				.break
			.endif
			inc		edi
		.endw
	.endif
	ret

FindNextTrigger endp

FindPreviousTrigger proc uses ebx esi edi

	.if STM32_Cmd.STM32_Lga.TriggerMask
		mov		edi,transstart
		movzx	edx,STM32_Cmd.STM32_Lga.TriggerMask
		movzx	ecx,STM32_Cmd.STM32_Lga.TriggerValue
		and		ecx,edx
		dec		edi
		.while sdword ptr edi>=0
			movzx	eax,LGA_Data[edi]
			and		eax,edx
			.if eax==ecx
				mov		transstart,edi
				sub		edi,GRIDX*4/2
				.if CARRY?
					xor		edi,edi
				.endif
				mov		lgaxofs,edi
				invoke InvalidateRect,hLGAScrn,NULL,TRUE
				invoke UpdateWindow,hLGAScrn
				.break
			.endif
			dec		edi
		.endw
	.endif
	ret

FindPreviousTrigger endp

LGAChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[64]:BYTE
	LOCAL	xsinf:SCROLLINFO

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SendDlgItemMessage,hWin,IDC_TRBSR,TBM_SETRANGE,FALSE,(MAXLGASAMPLE-1) SHL 16
		invoke SendDlgItemMessage,hWin,IDC_TRBBS,TBM_SETRANGE,FALSE,(MAXLGABUFFER SHL 16)+1
		invoke ImageList_GetIcon,hIml,0,ILD_NORMAL
		mov		ebx,eax
		push	0
		push	IDC_BTNTRGPREVIOUS
		push	IDC_BTNSRDN
		mov		eax,IDC_BTNBSDN
		.while eax
			invoke GetDlgItem,hWin,eax
			mov		edi,eax
			invoke SendMessage,edi,BM_SETIMAGE,IMAGE_ICON,ebx
			invoke SetWindowLong,edi,GWL_WNDPROC,offset ButtonProc
			mov		lpOldButtonProc,eax
			pop		eax
		.endw
		invoke ImageList_GetIcon,hIml,1,ILD_NORMAL
		mov		ebx,eax
		push	0
		push	IDC_BTNTRGNEXT
		push	IDC_BTNSRUP
		mov		eax,IDC_BTNBSUP
		.while eax
			invoke GetDlgItem,hWin,eax
			mov		edi,eax
			invoke SendMessage,edi,BM_SETIMAGE,IMAGE_ICON,ebx
			invoke SetWindowLong,edi,GWL_WNDPROC,offset ButtonProc
			mov		lpOldButtonProc,eax
			pop		eax
		.endw
		call	Update
		xor		edi,edi
		xor		eax,eax
		.while edi<1024
			mov		LGA_Data[edi],al
			inc		eax
			inc		edi
		.endw
		mov		eax,FALSE
		ret
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_CHKLGATRIGALL
				invoke IsDlgButtonChecked,hWin,IDC_CHKLGATRIGALL
				xor		ecx,ecx
				mov		edi,BST_UNCHECKED
				.if eax
					mov		edi,BST_CHECKED
				.endif
				.while ecx<8
					push	ecx
					lea		eax,[ecx+IDC_CHKLGATRIGD0]
					invoke CheckDlgButton,hWin,eax,edi
					pop		ecx
					inc		ecx
				.endw
				call	Update
			.elseif eax==IDC_CHKLGAMASKALL
				invoke IsDlgButtonChecked,hWin,IDC_CHKLGAMASKALL
				xor		ecx,ecx
				mov		edi,BST_UNCHECKED
				.if eax
					mov		edi,BST_CHECKED
				.endif
				.while ecx<8
					push	ecx
					lea		eax,[ecx+IDC_CHKLGAMASKD0]
					invoke CheckDlgButton,hWin,eax,edi
					pop		ecx
					inc		ecx
				.endw
				call	Update
			.elseif eax==IDC_BTNSRDN
				invoke SendDlgItemMessage,hWin,IDC_TRBSR,TBM_GETPOS,0,0
				.if eax
					dec		eax
					invoke SendDlgItemMessage,hWin,IDC_TRBSR,TBM_SETPOS,TRUE,eax
					call	Update
				.endif
			.elseif eax==IDC_BTNSRUP
				invoke SendDlgItemMessage,hWin,IDC_TRBSR,TBM_GETPOS,0,0
				.if eax<MAXLGASAMPLE-1
					inc		eax
					invoke SendDlgItemMessage,hWin,IDC_TRBSR,TBM_SETPOS,TRUE,eax
					call	Update
				.endif
			.elseif eax==IDC_BTNBSDN
				movzx		eax,STM32_Cmd.STM32_Lga.DataBlocks
				.if eax>1
					dec		eax
					mov		STM32_Cmd.STM32_Lga.DataBlocks,al
					invoke SendDlgItemMessage,hWin,IDC_TRBBS,TBM_SETPOS,TRUE,eax
					call	Update
				.endif
			.elseif eax==IDC_BTNBSUP
				movzx		eax,STM32_Cmd.STM32_Lga.DataBlocks
				.if eax<MAXLGABUFFER
					inc		eax
					mov		STM32_Cmd.STM32_Lga.DataBlocks,al
					invoke SendDlgItemMessage,hWin,IDC_TRBBS,TBM_SETPOS,TRUE,eax
					call	Update
				.endif
			.elseif eax==IDC_BTNTRGPREVIOUS
				; Find previous trigger
				invoke FindPreviousTrigger
				mov		xsinf.cbSize,sizeof SCROLLINFO
				mov		xsinf.fMask,SIF_ALL
				invoke GetScrollInfo,hLGAScrn,SB_HORZ,addr xsinf
				mov		eax,lgaxofs
				mov		xsinf.nTrackPos,eax
				invoke SetScrollPos,hLGAScrn,SB_HORZ,eax,TRUE
			.elseif eax==IDC_BTNTRGNEXT
				;Find next trigger
				invoke FindNextTrigger
				mov		xsinf.cbSize,sizeof SCROLLINFO
				mov		xsinf.fMask,SIF_ALL
				invoke GetScrollInfo,hLGAScrn,SB_HORZ,addr xsinf
				mov		eax,lgaxofs
				mov		xsinf.nTrackPos,eax
				invoke SetScrollPos,hLGAScrn,SB_HORZ,eax,TRUE
			.elseif eax==IDC_BTNLGASAMPLE
				xor		eax,eax
				mov		lgaxofs,eax
				mov		transcurpos,eax
				mov		transstart,eax
				mov		transend,eax
				mov		mode,CMD_LGASET
			.else
				call	Update
			.endif
		.endif
	.elseif eax==WM_HSCROLL
		call	Update
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

Update:
	invoke lstrcpy,addr buffer,offset szSampleRate
	invoke SendDlgItemMessage,hWin,IDC_TRBSR,TBM_GETPOS,0,0
	mov		ecx,sizeof LGASAMPLE
	mul		ecx
	mov		ecx,LgaSample.clockdiv[eax]
	.if ecx==199999
		shr	ecx,2
		mov		STM32_Cmd.STM32_Lga.LGASampleRateDiv,3
	.elseif ecx==99999
		shr	ecx,1
		mov		STM32_Cmd.STM32_Lga.LGASampleRateDiv,1
	.else
		mov		STM32_Cmd.STM32_Lga.LGASampleRateDiv,0
	.endif
	mov		STM32_Cmd.STM32_Lga.LGASampleRate,cx
	invoke lstrcat,addr buffer,addr LgaSample.rate[eax]
	invoke SetDlgItemText,hWin,IDC_STCSR,addr buffer
	invoke SendDlgItemMessage,hWin,IDC_TRBBS,TBM_GETPOS,0,0
	mov		STM32_Cmd.STM32_Lga.DataBlocks,al
	invoke wsprintf,addr buffer,offset szBufferSize,eax
	invoke SetDlgItemText,hWin,IDC_STCBS,addr buffer
	xor		ecx,ecx
	xor		ebx,ebx
	mov		edi,0001h
	.while ecx<8
		push	ecx
		lea		eax,[ecx+IDC_CHKLGATRIGD0]
		invoke IsDlgButtonChecked,hWin,eax
		.if eax
			or		ebx,edi
		.endif
		shl		edi,1
		pop		ecx
		inc		ecx
	.endw
	mov		STM32_Cmd.STM32_Lga.TriggerValue,bl
	xor		ecx,ecx
	xor		ebx,ebx
	mov		edi,0001h
	.while ecx<8
		push	ecx
		lea		eax,[ecx+IDC_CHKLGAMASKD0]
		invoke IsDlgButtonChecked,hWin,eax
		.if eax
			or		ebx,edi
		.endif
		shl		edi,1
		pop		ecx
		inc		ecx
	.endw
	mov		STM32_Cmd.STM32_Lga.TriggerMask,bl
	retn

LGAChildProc endp

LGAScrnChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_UDCLGASCRN
		mov		hLGAScrn,eax
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

LGAScrnChildProc endp

ByteToBin proc uses edi,lpBuff:DWORD,nByte:DWORD

	mov		edi,lpBuff
	mov		eax,nByte
	xor		ecx,ecx
	.while ecx<8
		shl		al,1
		.if CARRY?
			mov		ah,'1'
		.else
			mov		ah,'0'
		.endif
		mov		[edi+ecx],ah
		inc		ecx
	.endw
	mov		byte ptr [edi+ecx],0
	ret

ByteToBin endp

LGAProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	lgarect:RECT
	LOCAL	ps:PAINTSTRUCT
	LOCAL	mDC:HDC
	LOCAL	hBmp:HBITMAP
	LOCAL	pt:POINT
	LOCAL	buffer[128]:BYTE
	LOCAL	buffer1[128]:BYTE
	LOCAL	buffer2[128]:BYTE
	LOCAL	lgaoldbit:BYTE
	LOCAL	lgabit:BYTE
	LOCAL	samplesize:DWORD
	LOCAL	xsinf:SCROLLINFO
	LOCAL	yinc:DWORD
	
	mov		eax,uMsg
	.if eax==WM_PAINT
		invoke GetClientRect,hWin,addr rect
		invoke BeginPaint,hWin,addr ps
		invoke CreateCompatibleDC,ps.hdc
		mov		mDC,eax
		invoke CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom
		mov		hBmp,eax
		invoke SelectObject,mDC,eax
		push	eax
		invoke GetStockObject,BLACK_BRUSH
		invoke FillRect,mDC,addr rect,eax
		sub		rect.bottom,TEXTHIGHT
		; Calculate the lga rect
		mov		eax,rect.right
		sub		eax,SCOPEWT
		shr		eax,1
		mov		lgarect.left,eax
		add		eax,SCOPEWT
		inc		eax
		mov		lgarect.right,eax
		mov		eax,rect.bottom
		sub		eax,SCOPEHT
		shr		eax,1
		mov		lgarect.top,eax
		add		eax,SCOPEHT
		inc		eax
		mov		lgarect.bottom,eax
		call	DrawLGABitText
		call	SetLGAText
		invoke SetBkMode,mDC,TRANSPARENT
		invoke SetTextColor,mDC,00FF00h
		invoke lstrlen,addr LGA_Text
		.if eax
			mov		edx,rect.bottom
			add		edx,8
			invoke TextOut,mDC,10,edx,addr LGA_Text,eax
		.endif
		mov		eax,4
		call	GetLGATime
		invoke wsprintf,addr buffer,addr szFmtLGATimeDiv,addr buffer2
		invoke lstrlen,addr buffer
		mov		edx,rect.bottom
		add		edx,24
		invoke TextOut,mDC,10,edx,addr buffer,eax

		;Create a clip region
		invoke CreateRectRgn,lgarect.left,lgarect.top,lgarect.right,lgarect.bottom
		push	eax
		invoke SelectClipRgn,mDC,eax
		pop		eax
		invoke DeleteObject,eax
		;Draw grid
		call	DrawGrid

		;Draw curve
		movzx	eax,STM32_Cmd.STM32_Lga.DataBlocks
		mov		ecx,1024
		mul		ecx
		mov		samplesize,eax
		mov		lgabit,01h
		mov		eax,lgarect.top
		add		eax,GRIDSIZE
		mov		pt.y,eax
		xor		ecx,ecx
		.while ecx<8
			push	ecx
			.if ecx & 1
				mov		eax,0808000h
			.else
				mov		eax,008000h
			.endif
			invoke CreatePen,PS_SOLID,2,eax
			invoke SelectObject,mDC,eax
			push	eax
			call	DrawCurve
			pop		eax
			invoke SelectObject,mDC,eax
			invoke DeleteObject,eax
			mov		eax,GRIDSIZE
			add		pt.y,eax
			shl		lgabit,1
			pop		ecx
			inc		ecx
		.endw

		;Draw transition count lines
		invoke CreatePen,PS_SOLID,0,00FFFFh
		invoke SelectObject,mDC,eax
		push	eax
		mov		edi,transstart
		call	GetXPos
		invoke MoveToEx,mDC,pt.x,lgarect.top,NULL
		invoke LineTo,mDC,pt.x,lgarect.bottom
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		.if LGA_Text
			invoke CreatePen,PS_DOT,0,00FFFFh
			invoke SelectObject,mDC,eax
			push	eax
			mov		edi,transend
			call	GetXPos
			invoke MoveToEx,mDC,pt.x,lgarect.top,NULL
			invoke LineTo,mDC,pt.x,lgarect.bottom
			pop		eax
			invoke SelectObject,mDC,eax
			invoke DeleteObject,eax
		.endif
		invoke SelectClipRgn,mDC,NULL
		add		rect.bottom,TEXTHIGHT
		invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,mDC,0,0,SRCCOPY
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		invoke DeleteDC,mDC
		invoke EndPaint,hWin,addr ps
		xor		eax,eax
	.elseif eax==WM_LBUTTONDOWN
		.if LGA_Text
			mov		eax,transcurpos
			mov		transstart,eax
			invoke InvalidateRect,hWin,0,TRUE
		.endif
	.elseif eax==WM_MOUSEMOVE
		invoke GetCapture
		.if eax==hWin
			invoke GetCursorPos,addr pt
			invoke WindowFromPoint,pt.x,pt.y
			.if eax==hWin
				invoke ScreenToClient,hWin,addr pt
				invoke GetClientRect,hWin,addr rect
				mov		eax,pt.x
				mov		edx,pt.y
				.if eax>rect.right || edx>rect.bottom
					mov		LGA_Text,0
					invoke ReleaseCapture
				.endif
			.else
				mov		LGA_Text,0
				invoke ReleaseCapture
			.endif
			invoke InvalidateRect,hWin,0,TRUE
		.else
			invoke SetCapture,hWin
			invoke InvalidateRect,hWin,0,TRUE
		.endif
	.elseif eax==WM_HSCROLL
		mov		xsinf.cbSize,sizeof SCROLLINFO
		mov		xsinf.fMask,SIF_ALL
		invoke GetScrollInfo,hWin,SB_HORZ,addr xsinf
		mov		eax,wParam
		movzx	eax,ax
		.if eax==SB_THUMBPOSITION
			mov		eax,xsinf.nTrackPos
			mov		lgaxofs,eax
			invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif  eax==SB_THUMBTRACK
			mov		eax,xsinf.nTrackPos
			mov		lgaxofs,eax
			invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif  eax==SB_LINELEFT
			mov		eax,xsinf.nPos
			sub		eax,1
			.if CARRY?
				xor		eax,eax
			.endif
			mov		lgaxofs,eax
			invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif eax==SB_LINERIGHT
			mov		eax,xsinf.nPos
			add		eax,1
			mov		lgaxofs,eax
			invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif eax==SB_PAGELEFT
			mov		eax,xsinf.nPos
			sub		eax,xsinf.nPage
			.if CARRY?
				xor		eax,eax
			.endif
			mov		lgaxofs,eax
			invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif eax==SB_PAGERIGHT
			mov		eax,xsinf.nPos
			add		eax,xsinf.nPage
			mov		lgaxofs,eax
			invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==WM_CREATE
		;Init horizontal scrollbar
		mov		xsinf.cbSize,sizeof SCROLLINFO
		mov		xsinf.fMask,SIF_ALL
		invoke GetScrollInfo,hWin,SB_HORZ,addr xsinf
		mov		xsinf.nMin,0
		mov		xsinf.nMax,1024+23
		mov		xsinf.nPos,0
		mov		xsinf.nPage,GRIDSIZE
		invoke SetScrollInfo,hWin,SB_HORZ,addr xsinf,TRUE
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
	.endif
	ret

GetBitnbr:
	invoke GetCursorPos,addr pt
	invoke ScreenToClient,hWin,addr pt
	mov		eax,lgarect.bottom
	sub		eax,lgarect.top
	shr		eax,3
	mov		yinc,eax
	add		eax,lgarect.top
	xor		edx,edx
	.while eax<pt.y && edx<7
		inc		edx
		add		eax,yinc
	.endw
	mov		transbit,edx
	retn

GetBytenbr:
	mov		ebx,pt.x
	mov		edi,lgaxofs
	call	GetXPos
	.while edi<samplesize
		push	pt.x
		inc		edi
		call	GetXPos
		pop		edx
		.if ebx>=edx && ebx<pt.x
			dec		edi
			retn
		.endif
	.endw
	mov		edi,-1
	retn

DrawGrid:
	; Create gridlines pen
	invoke CreatePen,PS_SOLID,1,404040h
	invoke SelectObject,mDC,eax
	push	eax
	;Draw horizontal lines
	mov		edi,lgarect.top
	xor		ecx,ecx
	.while ecx<GRIDY+1
		push	ecx
		invoke MoveToEx,mDC,lgarect.left,edi,NULL
		invoke LineTo,mDC,lgarect.right,edi
		add		edi,GRIDSIZE
		pop		ecx
		inc		ecx
	.endw
	;Draw vertical lines
	mov		edi,lgarect.left
	xor		ecx,ecx
	.while ecx<GRIDX+1
		push	ecx
		invoke MoveToEx,mDC,edi,lgarect.top,NULL
		invoke LineTo,mDC,edi,lgarect.bottom
		add		edi,GRIDSIZE
		pop		ecx
		inc		ecx
	.endw
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

DrawLGABitText:
	mov		ebx,lgarect.top
	add		ebx,GRIDSIZE-15
	xor		edi,edi
	mov		dword ptr buffer,'D'
	.while edi<8
		mov		eax,edi
		or		eax,30h
		mov		buffer[1],al
		invoke TextOut,mDC,8,ebx,addr buffer,2
		inc		edi
		add		ebx,GRIDSIZE
	.endw
	retn

GetXPos:
	;Get X position
	mov		eax,edi
	sub		eax,lgaxofs
	mov		ecx,GRIDSIZE/4
	mul		ecx
	add		eax,lgarect.left
	mov		pt.x,eax
	retn

DrawCurve:
	mov		esi,offset LGA_Data
	mov		edi,lgaxofs
	call	GetXPos
	invoke MoveToEx,mDC,lgarect.left,pt.y,NULL
	mov		lgaoldbit,0
	mov		ecx,edi
	mov		ebx,pt.y
	.while ecx<samplesize
		push	ecx
		mov		al,[esi+ecx]
		and		al,lgabit
		.if al!=lgaoldbit
			mov		lgaoldbit,al
			.if al
				;Transition from 0 to 1
				sub		ebx,GRIDSIZE/2
			.else
				;Transition from 1 to 0
				add		ebx,GRIDSIZE/2
			.endif
			call	GetXPos
			invoke LineTo,mDC,pt.x,ebx
		.endif
		inc		edi
		call	GetXPos
		invoke LineTo,mDC,pt.x,ebx
		pop		ecx
		mov		eax,pt.x
		.break .if sdword ptr eax>lgarect.right
		inc		ecx
	.endw
	retn

GetTransitions:
	mov		esi,transstart
	mov		edi,transend
	.if sdword ptr esi>edi
		xchg	esi,edi
	.endif
	xor		ebx,ebx
	mov		ecx,transbit
	mov		edx,1
	shl		edx,cl
	mov		ecx,edx
	.if transrisingedge
		mov		edx,ecx
		.while esi<=edi
			movzx	eax,LGA_Data[esi]
			and		eax,ecx
			.if eax!=edx
				.if eax && !edx
					inc		ebx
				.endif
				mov		edx,eax
			.endif
			inc		esi
		.endw
	.else
		xor		edx,edx
		.while esi<=edi
			movzx	eax,LGA_Data[esi]
			and		eax,ecx
			.if eax!=edx
				.if !eax && edx
					inc		ebx
				.endif
				mov		edx,eax
			.endif
			inc		esi
		.endw
	.endif
	mov		transcount,ebx
	retn

GetLGATime:
	push	eax
	mov		eax,STM32_CLOCK/10
	cdq
	movzx	ecx,STM32_Cmd.STM32_Lga.LGASampleRateDiv
	inc		ecx
	div		ecx
	cdq
	movzx	ecx,STM32_Cmd.STM32_Lga.LGASampleRate
	inc		ecx
	div		ecx
	mov		ecx,eax
	mov		eax,1000000000
	cdq
	div		ecx
	pop		ecx
	mul		ecx
	.if eax<10000
		invoke wsprintf,addr buffer2,addr szFmtLGATimens,eax
		invoke lstrlen,addr buffer2
		mov		edx,dword ptr buffer2[eax-3]
		mov		buffer2[eax-3],'.'
		mov		dword ptr buffer2[eax-2],edx
	.elseif eax<10000000
		invoke wsprintf,addr buffer2,addr szFmtLGATimeus,eax
		invoke lstrlen,addr buffer2
		mov		edx,dword ptr buffer2[eax-6]
		mov		ecx,dword ptr buffer2[eax-2]
		mov		buffer2[eax-6],'.'
		mov		dword ptr buffer2[eax-5],edx
		mov		dword ptr buffer2[eax-1],ecx
	.else
		invoke wsprintf,addr buffer2,addr szFmtLGATimems,eax
		invoke lstrlen,addr buffer2
		mov		edx,dword ptr buffer2[eax-9]
		mov		ecx,dword ptr buffer2[eax-5]
		mov		ebx,dword ptr buffer2[eax-1]
		mov		buffer2[eax-9],'.'
		mov		dword ptr buffer2[eax-8],edx
		mov		dword ptr buffer2[eax-4],ecx
		mov		dword ptr buffer2[eax-0],ebx
	.endif
	retn

SetLGAText:
	invoke GetCursorPos,addr pt
	invoke WindowFromPoint,pt.x,pt.y
	push	eax
	invoke ScreenToClient,hWin,addr pt
	mov		eax,pt.x
	mov		edx,pt.y
	pop		ecx
	.if eax>lgarect.right || eax<lgarect.left || edx>lgarect.bottom || edx<lgarect.top || ecx!=hWin
		mov		LGA_Text,0
	.else
		call	GetBytenbr
		.if sdword ptr edi>=0
			mov		transcurpos,edi
			mov		eax,transcurpos
			mov		transend,eax
			call	GetBitnbr
			call	GetTransitions
			mov		edi,transcurpos
			movzx	eax,LGA_Data[edi]
			push	eax
			invoke ByteToBin,addr buffer1,eax
			mov		eax,transend
			sub		eax,transstart
			.if SIGN?
				neg		eax
			.endif
			call	GetLGATime
			pop		edx
			invoke wsprintf,addr buffer,addr szFmtLGA,edx,addr buffer1,edi,transcount,addr buffer2
			invoke lstrcpy,addr LGA_Text,addr buffer
		.else
			mov		LGA_Text,0
		.endif
	.endif
	retn

LGAProc endp
