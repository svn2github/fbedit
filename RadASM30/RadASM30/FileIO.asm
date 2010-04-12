.code

StreamInProc proc hFile:DWORD,pBuffer:DWORD,NumBytes:DWORD,pBytesRead:DWORD

	invoke ReadFile,hFile,pBuffer,NumBytes,pBytesRead,0
	xor		eax,1
	ret

StreamInProc endp

StreamOutProc proc hFile:DWORD,pBuffer:DWORD,NumBytes:DWORD,pBytesWritten:DWORD

	invoke WriteFile,hFile,pBuffer,NumBytes,pBytesWritten,0
	xor		eax,1
	ret

StreamOutProc endp

GetTheFileType proc uses esi,lpFileName:DWORD
	LOCAL	ftpe[256]:BYTE

	mov		esi,lpFileName
	invoke strlen,esi
	.while byte ptr [esi+eax]!='.' && eax
		dec		eax
	.endw
	.if byte ptr [esi+eax]=='.'
		invoke strcpy,addr ftpe,addr [esi+eax]
		invoke strcat,addr ftpe,addr szDot
		invoke IsFileType,addr ftpe,addr szCodeFiles
		.if eax
			mov		eax,ID_EDITCODE
			jmp		Ex
		.endif
		invoke IsFileType,addr ftpe,addr szTextFiles
		.if eax
			mov		eax,ID_EDITTEXT
			jmp		Ex
		.endif
		invoke IsFileType,addr ftpe,addr szHexFiles
		.if eax
			mov		eax,ID_EDITHEX
			jmp		Ex
		.endif
		invoke IsFileType,addr ftpe,addr szResourceFiles
		.if eax
			mov		eax,ID_EDITRES
			jmp		Ex
		.endif
		mov		eax,ID_EDITTEXT
	.else
		mov		eax,ID_EDITTEXT
	.endif
  Ex:
	ret

GetTheFileType endp

LoadTextFile proc uses ebx esi,hWin:DWORD,lpFileName:DWORD
    LOCAL   hFile:DWORD
	LOCAL	editstream:EDITSTREAM
	LOCAL	chrg:CHARRANGE

	;Open the file
	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke SendMessage,hWin,WM_SETTEXT,0,addr szNULL
		;stream the text into the RAEdit control
		mov		eax,hFile
		mov		editstream.dwCookie,eax
		mov		editstream.pfnCallback,offset StreamInProc
		invoke SendMessage,hWin,EM_STREAMIN,SF_TEXT,addr editstream
		invoke CloseHandle,hFile
		invoke SendMessage,hWin,EM_SETMODIFY,FALSE,0
		invoke SendMessage,hWin,REM_SETCHANGEDSTATE,FALSE,0
		mov		chrg.cpMin,0
		mov		chrg.cpMax,0
		invoke SendMessage,hWin,EM_EXSETSEL,0,addr chrg
		mov		eax,FALSE
	.else
		invoke strcpy,offset tmpbuff,offset szOpenFileFail
		invoke strcat,offset tmpbuff,lpFileName
		invoke MessageBox,ha.hWnd,offset tmpbuff,offset DisplayName,MB_OK or MB_ICONERROR
		mov		eax,TRUE
	.endif
	ret

LoadTextFile endp

LoadHexFile proc uses ebx esi,hWin:DWORD,lpFileName:DWORD
    LOCAL   hFile:DWORD
	LOCAL	editstream:EDITSTREAM
	LOCAL	chrg:CHARRANGE

	;Open the file
	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		;stream the text into the RAHexEd control
		mov		eax,hFile
		mov		editstream.dwCookie,eax
		mov		editstream.pfnCallback,offset StreamInProc
		invoke SendMessage,hWin,EM_STREAMIN,SF_TEXT,addr editstream
		invoke CloseHandle,hFile
		invoke SendMessage,hWin,EM_SETMODIFY,FALSE,0
		mov		chrg.cpMin,0
		mov		chrg.cpMax,0
		invoke SendMessage,hWin,EM_EXSETSEL,0,addr chrg
		mov		eax,FALSE
	.else
		invoke strcpy,offset tmpbuff,offset szOpenFileFail
		invoke strcat,offset tmpbuff,lpFileName
		invoke MessageBox,ha.hWnd,offset tmpbuff,offset DisplayName,MB_OK or MB_ICONERROR
		mov		eax,TRUE
	.endif
	ret

LoadHexFile endp

LoadResFile proc uses ebx esi,hWin:DWORD,lpFileName:DWORD
    LOCAL   hFile:DWORD
	LOCAL	hMem:DWORD
	LOCAL	dwRead:DWORD

	;Open the file
	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke GetFileSize,hFile,NULL
		push	eax
		inc		eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
		mov     hMem,eax
		invoke GlobalLock,hMem
		pop		edx
		invoke ReadFile,hFile,hMem,edx,addr dwRead,NULL
		invoke CloseHandle,hFile
		invoke SendMessage,hWin,PRO_OPEN,lpFileName,hMem
		mov		eax,FALSE
	.else
		invoke strcpy,offset tmpbuff,offset szOpenFileFail
		invoke strcat,offset tmpbuff,lpFileName
		invoke MessageBox,ha.hWnd,offset tmpbuff,offset DisplayName,MB_OK or MB_ICONERROR
		mov		eax,TRUE
	.endif
	ret

LoadResFile endp

OpenTheFile proc lpFileName:DWORD

	invoke GetTheFileType,lpFileName
	.if eax==ID_EDITCODE
		invoke strcpy,addr da.FileName,lpFileName
		invoke MakeMdiCldWin,addr szEditCldClassName,ID_EDITCODE
		invoke LoadTextFile,ha.hEdt,lpFileName
	.elseif eax==ID_EDITTEXT
		invoke strcpy,addr da.FileName,lpFileName
		invoke MakeMdiCldWin,addr szEditCldClassName,ID_EDITTEXT
		invoke LoadTextFile,ha.hEdt,lpFileName
	.elseif eax==ID_EDITHEX
		invoke strcpy,addr da.FileName,lpFileName
		invoke MakeMdiCldWin,addr szEditCldClassName,ID_EDITHEX
		invoke LoadHexFile,ha.hEdt,lpFileName
	.elseif eax==ID_EDITRES
		invoke UpdateAll,UAM_ISRESOPEN,0
		.if eax==-1
			invoke strcpy,addr da.FileName,lpFileName
			invoke MakeMdiCldWin,addr szEditCldClassName,ID_EDITRES
			invoke LoadResFile,ha.hEdt,lpFileName
		.else
			invoke TabToolGetInx,eax
			invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
			invoke TabToolActivate
			invoke SendMessage,ha.hEdt,PRO_CLOSE,0,0
			invoke LoadResFile,ha.hEdt,lpFileName
		.endif
	.endif
	ret

OpenTheFile endp

OpenEditFile proc
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[MAX_PATH]:BYTE

	;Zero out the ofn struct
	invoke RtlZeroMemory,addr ofn,sizeof ofn
	;Setup the ofn struct
	mov		ofn.lStructSize,sizeof ofn
	push	ha.hWnd
	pop		ofn.hwndOwner
	push	ha.hInstance
	pop		ofn.hInstance
	mov		ofn.lpstrFilter,offset ALLFilterString
	mov		buffer[0],0
	lea		eax,buffer
	mov		ofn.lpstrFile,eax
	mov		ofn.nMaxFile,sizeof buffer
	mov		ofn.lpstrDefExt,NULL
	invoke GetCurrentDirectory,sizeof buffer1,addr buffer1
	lea		eax,buffer1
	mov		ofn.lpstrInitialDir,eax
	mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
	;Show the Open dialog
	invoke GetOpenFileName,addr ofn
	.if eax
		invoke UpdateAll,UAM_ISOPENACTIVATE,addr buffer
		.if eax==-1
			invoke OpenTheFile,addr buffer
		.endif
	.endif
	ret

OpenEditFile endp
