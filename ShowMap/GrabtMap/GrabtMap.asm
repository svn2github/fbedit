.386
.model flat,stdcall
option casemap:none

include GrabtMap.inc

.code

SaveDIB32 proc uses ebx esi edi,hBmp:HBITMAP,hFile:HANDLE
	LOCAL	cbWrite:DWORD
	LOCAL	dibs:BITMAP
	LOCAL	pBMI:DWORD
	LOCAL	DataSize:DWORD
	LOCAL	pBFH:DWORD

	invoke GetObject,hBmp,SIZEOF BITMAP,addr dibs
	;Calculate Data size
	mov		eax,dibs.bmHeight
	shl		eax,2
	mul 	dibs.bmWidth
	mov		DataSize,eax
	;Create a memory buffer
	xor		eax,eax
	add		eax,sizeof BITMAPINFOHEADER
	add		eax,sizeof BITMAPFILEHEADER
	add		eax,DataSize
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
	mov		pBFH,eax
	add		eax,sizeof BITMAPFILEHEADER
	mov 	pBMI,eax
	;Bitmap header is address sensitive do not pass through generic routine
	mov		edi,pBMI
	mov		[edi].BITMAPINFO.bmiHeader.biXPelsPerMeter,0
	mov		[edi].BITMAPINFO.bmiHeader.biYPelsPerMeter,0
	mov		[edi].BITMAPINFO.bmiHeader.biClrUsed,0
	mov		[edi].BITMAPINFO.bmiHeader.biClrImportant,0
	mov		[edi].BITMAPINFO.bmiHeader.biSize,sizeof BITMAPINFOHEADER
	mov		eax,dibs.bmWidth
	mov		[edi].BITMAPINFO.bmiHeader.biWidth,eax
	mov		eax,dibs.bmHeight
	mov		[edi].BITMAPINFO.bmiHeader.biHeight,eax
	mov		[edi].BITMAPINFO.bmiHeader.biPlanes,1
	mov		[edi].BITMAPINFO.bmiHeader.biCompression,BI_RGB
	mov		[edi].BITMAPINFO.bmiHeader.biBitCount,32
	mov		eax,DataSize
	mov		[edi].BITMAPINFO.bmiHeader.biSizeImage,eax

	mov		esi,pBFH
	mov		[esi].BITMAPFILEHEADER.bfType,"MB"
	mov		eax,DataSize
	add		eax,sizeof BITMAPINFOHEADER + sizeof BITMAPFILEHEADER
	mov		[esi].BITMAPFILEHEADER.bfSize,eax
	mov		[esi].BITMAPFILEHEADER.bfReserved1,0
	mov		[esi].BITMAPFILEHEADER.bfReserved2,0
	mov		eax,sizeof BITMAPFILEHEADER
	add		eax,sizeof BITMAPINFOHEADER	
	mov		[esi].BITMAPFILEHEADER.bfOffBits,eax
	mov		ecx,sizeof BITMAPFILEHEADER
	add		ecx,sizeof BITMAPINFOHEADER
	push	ecx
	invoke WriteFile,hFile,pBFH,ecx,addr cbWrite,NULL
	pop		ebx
	add		ebx,pBFH
	invoke GetBitmapBits,hBmp,DataSize,ebx
	call	Flip
	invoke WriteFile,hFile,ebx,DataSize,addr cbWrite,NULL
	invoke GlobalFree,ebx
	invoke GlobalFree,pBFH
	mov		eax,hFile
	ret

Flip:
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,DataSize
	push	eax
	mov		edi,eax
	mov		esi,ebx
	add		esi,DataSize
	mov		eax,dibs.bmWidth
	shl		eax,2
	mov		ebx,eax
	mov		edx,dibs.bmHeight
	.while edx
		push	edx
		sub		esi,ebx
		push	esi
		mov		ecx,ebx
		rep		movsb
		pop		esi
		pop		edx
		dec		edx
	.endw
	pop		ebx
	retn

SaveDIB32 endp

GrabScreen proc py:DWORD,px:DWORD
	LOCAL	hdcScreen:HDC
	LOCAL	hdcCompatible:HDC
	LOCAL	hbmScreen:HBITMAP
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	rect:RECT

	invoke GetWindowRect,hWeb,addr rect
	invoke CreateDC,addr szDisplayDC,NULL,NULL,NULL
	mov		hdcScreen,eax
	invoke CreateCompatibleDC,hdcScreen
	mov		hdcCompatible,eax
	invoke CreateCompatibleBitmap,hdcScreen,PICWT,PICHT
	mov		hbmScreen,eax
	invoke SelectObject,hdcCompatible,hbmScreen
	push	eax
	mov		eax,rect.left
	add		eax,PICX
	mov		edx,rect.top
	add		edx,PICY
	invoke BitBlt,hdcCompatible,0,0,PICWT,PICHT,hdcScreen,eax,edx,SRCCOPY
	invoke wsprintf,addr buffer,addr szfilename,py,px
	invoke CreateFile,addr buffer,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
	invoke SaveDIB32,hbmScreen,eax
	invoke CloseHandle,eax
	pop		eax
	invoke SelectObject,hdcCompatible,eax
	invoke DeleteObject,hbmScreen
	invoke DeleteDC,hdcCompatible
	invoke DeleteDC,hdcScreen
	invoke SetWindowText,hWnd,addr buffer
	ret

GrabScreen endp

SendMouse proc uses ebx esi,lpmi:DWORD,nSleep:DWORD

	mov		esi,lpmi
	xor		ebx,ebx
	.while ebx<5
		invoke SendInput,1,esi,sizeof INPUT
		invoke Sleep,250
		inc		ebx
		lea		esi,[esi+sizeof INPUT]
	.endw
	invoke Sleep,nSleep
	ret

SendMouse endp

TestRight proc uses ebx esi,Param:DWORD

	invoke Sleep,3000
	mov		esi,mapx
	dec		esi
	xor		ebx,ebx
	.while ebx<esi
		invoke SendMouse,addr mapright,500
		inc		ebx
	.endw
	ret

TestRight endp

TestDown proc uses ebx esi,Param:DWORD

	invoke Sleep,5000
	mov		esi,mapy
	dec		esi
	xor		ebx,ebx
	.while ebx<esi
		invoke SendMouse,addr mapdown,500
		inc		ebx
	.endw
	ret

TestDown endp

GrabMap proc uses ebx esi edi,Param:DWORD
	LOCAL	x:DWORD
	LOCAL	y:DWORD

	mov		eax,mapx
	dec		eax
	mov		x,eax
	mov		eax,mapy
	dec		eax
	mov		y,eax
	invoke Sleep,5000
	xor		edi,edi
	.while edi<y
		xor		esi,esi
		.while esi<x
			invoke GrabScreen,edi,esi
			invoke SendMouse,addr mapright,500
			inc		esi
		.endw
		invoke GrabScreen,edi,esi
		invoke SendMouse,addr mapdown,500
		inc		edi
		.while esi
			invoke GrabScreen,edi,esi
			invoke SendMouse,addr mapleft,500
			dec		esi
		.endw
		invoke GrabScreen,edi,esi
		invoke SendMouse,addr mapdown,500
		inc		edi
	.endw
	ret

GrabMap endp

ShowRect proc
	LOCAL	wrect:RECT
	LOCAL	hDC:HDC
	LOCAL	rect:RECT

	invoke GetWindowRect,hWeb,addr wrect
	mov		eax,wrect.left
	add		eax,PICX-1
	mov		rect.left,eax
	add		eax,512+2
	mov		rect.right,eax
	mov		eax,wrect.top
	add		eax,PICY-1
	mov		rect.top,eax
	add		eax,512+2
	mov		rect.bottom,eax
	invoke GetDC,NULL
	mov		hDC,eax
	invoke CreateSolidBrush,0
	push	eax
	invoke FrameRect,hDC,addr rect,eax
	pop		eax
	invoke DeleteObject,eax
	invoke ReleaseDC,NULL,hDC
	ret

ShowRect endp

SetupMouseMove proc
	LOCAL	rect:RECT

	invoke GetWindowRect,hWeb,addr rect

	mov		eax,rect.left
	add		eax,PICX+512
	mov		maprightmov.dwdx,eax
	mov		eax,rect.top
	add		eax,PICY
	mov		maprightmov.dwdy,eax

	mov		eax,rect.left
	add		eax,PICX
	mov		mapleftmov.dwdx,eax
	mov		eax,rect.top
	add		eax,PICY
	mov		mapleftmov.dwdy,eax

	mov		eax,rect.left
	add		eax,PICX
	mov		mapdownmov.dwdx,eax
	mov		eax,rect.top
	add		eax,PICY+512
	mov		mapdownmov.dwdy,eax

	mov		eax,rect.left
	add		eax,PICX
	mov		mapupmov.dwdx,eax
	mov		eax,rect.top
	add		eax,PICY+512
	mov		mapupmov.dwdy,eax

	ret

SetupMouseMove endp

SetupProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SetDlgItemText,hWin,IDC_EDTURLLAND,addr szUrlLand
		invoke SetDlgItemText,hWin,IDC_EDTURLSEA,addr szUrlSea
		invoke SetDlgItemInt,hWin,IDC_EDTMAPTILESX,mapx,FALSE
		invoke SetDlgItemInt,hWin,IDC_EDTMAPTILESY,mapy,FALSE
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke GetDlgItemText,hWin,IDC_EDTURLLAND,addr szUrlLand,sizeof szUrlLand
				invoke GetDlgItemText,hWin,IDC_EDTURLSEA,addr szUrlSea,sizeof szUrlSea
				invoke GetDlgItemInt,hWin,IDC_EDTMAPTILESX,NULL,FALSE
				mov		mapx,eax
				invoke GetDlgItemInt,hWin,IDC_EDTMAPTILESY,NULL,FALSE
				mov		mapy,eax
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,lParam
		invoke SetFocus,hWnd
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

SetupProc endp

WndProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	tid:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		push	hWin
		pop		hWnd
		invoke lstrcpy,addr szUrlLand,addr szDefUrlLand
		invoke lstrcpy,addr szUrlSea,addr szDefUrlSea
		mov		mapx,32
		mov		mapy,32
		invoke lstrcpy,addr szurl,addr szUrlLand
		invoke lstrcpy,addr szfilename,addr szFileNameLand
		invoke GetDlgItem,hWin,IDC_MAP
		mov		hWeb,eax
		invoke SendMessage,hWeb,WBM_NAVIGATE,0,addr szurl
		invoke SetTimer,hWin,1000,500,NULL
	.elseif eax==WM_TIMER
		invoke ShowRect
	.elseif eax==WM_COMMAND
		mov		eax,wParam
		and		eax,0FFFFh
		.if eax==IDM_FILE_EXIT
			invoke SendMessage,hWin,WM_CLOSE,0,0
		.elseif eax==IDM_FILE_MOVRIGHT
			invoke SendMouse,addr mapright,100
		.elseif eax==IDM_FILE_MOVLEFT
			invoke SendMouse,addr mapleft,500
		.elseif eax==IDM_FILE_MOVDOWN
			invoke SendMouse,addr mapdown,500
		.elseif eax==IDM_FILE_MOVUP
			invoke SendMouse,addr mapup,500
		.elseif eax==IDM_SETUP_LAND
			invoke lstrcpy,addr szurl,addr szUrlLand
			invoke lstrcpy,addr szfilename,addr szFileNameLand
			invoke SendMessage,hWeb,WBM_NAVIGATE,0,addr szurl
		.elseif eax==IDM_SETUP_SEA
			invoke lstrcpy,addr szurl,addr szUrlSea
			invoke lstrcpy,addr szfilename,addr szFileNameSea
			invoke SendMessage,hWeb,WBM_NAVIGATE,0,addr szurl
		.elseif eax==IDM_SETUP_TILES
			invoke DialogBoxParam,hInstance,IDD_DLGSETUP,hWin,addr SetupProc,0
		.elseif eax==IDM_FILE_RIGHT
			invoke CreateThread,NULL,NULL,addr TestRight,0,NORMAL_PRIORITY_CLASS,addr tid
		.elseif eax==IDM_FILE_DOWN
			invoke CreateThread,NULL,NULL,addr TestDown,0,NORMAL_PRIORITY_CLASS,addr tid
		.elseif eax==IDM_FILE_START
			invoke CreateThread,NULL,NULL,addr GrabMap,0,NORMAL_PRIORITY_CLASS,addr tid
		.endif
	.elseif eax==WM_SIZE
		invoke GetClientRect,hWin,addr rect
		invoke MoveWindow,hWeb,0,0,rect.right,rect.bottom,TRUE
		invoke SetupMouseMove
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
	.elseif uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

WndProc endp

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL	wc:WNDCLASSEX
	LOCAL	msg:MSG

	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset WndProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,DLGWINDOWEXTRA
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,IDM_MENU
	mov		wc.lpszClassName,offset ClassName
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	invoke CreateDialogParam,hInstance,IDD_DLGMAIN,NULL,addr WndProc,NULL
	invoke ShowWindow,hWnd,SW_SHOWMAXIMIZED
	invoke UpdateWindow,hWnd
	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .BREAK .if !eax
		invoke TranslateMessage,addr msg
		invoke DispatchMessage,addr msg
	.endw
	mov		eax,msg.wParam
	ret

WinMain endp

start:

	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	invoke GetCommandLine
	mov		CommandLine,eax
	invoke InitCommonControls
	invoke LoadLibrary,addr szwb
	.if eax
		mov		hLib,eax
		invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
		invoke FreeLibrary,hLib
	.endif
	invoke ExitProcess,eax

end start
