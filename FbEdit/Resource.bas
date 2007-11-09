#define IDD_DLGRESED            1300
#define IDC_TBX1                1301
#define IDC_DLE1                1302
#define IDC_PRJ1                1303
#define IDC_PRP1                1304

Function ResEdProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim rect As RECT
	Dim As Integer nInx,x,y
	Dim pt As Point
	Dim hMnu As HMENU
	Dim hDll As HMODULE
	Dim nBtn As Integer
	Dim tbxwt As Integer
	Dim lpCTLDBLCLICK As CTLDBLCLICK Ptr

	Select Case uMsg
		Case WM_INITDIALOG
			ad.resmem.hResEd=GetDlgItem(hWin,IDC_DLE1)
			ad.resmem.hProject=GetDlgItem(hWin,IDC_PRJ1)
			ad.resmem.hProperty=GetDlgItem(hWin,IDC_PRP1)
			ad.resmem.hToolBox=GetDlgItem(hWin,IDC_TBX1)
			SetDialogOptions(hWin)
			SendMessage(ad.resmem.hResEd,DEM_SETPOSSTATUS,Cast(Integer,ah.hsbr),0)
			nInx=1
			x=0
			While nInx<=32
				GetPrivateProfileString(StrPtr("CustCtrl"),Str(nInx),@szNULL,@buff,260,@ad.IniFile)
				If Len(buff) Then
					hDll=Cast(HMODULE,SendMessage(ad.resmem.hResEd,DEM_ADDCONTROL,0,Cast(Integer,@buff)))
					If hDll Then
						hCustDll(x)=hDll
						x=x+1
					EndIf
				EndIf
				nInx=nInx+1
			Wend
			'
		Case WM_CLOSE
			DestroyWindow(hWin)
			'
		Case WM_DESTROY
			'
		Case WM_SIZE
			GetClientRect(hWin,@rect)
			nBtn=SendMessage(ad.resmem.hResEd,DEM_GETBUTTONCOUNT,0,0)
			tbxwt=53
			If (nBtn+1)/2*26>rect.bottom Then
				tbxwt=53+26
			EndIf
			MoveWindow(ad.resmem.hToolBox,0,0,tbxwt,rect.bottom,TRUE)
			MoveWindow(ad.resmem.hResEd,tbxwt,0,rect.right-180-tbxwt,rect.bottom,TRUE)
			MoveWindow(ad.resmem.hProject,rect.right-180,0,180,rect.bottom/2,TRUE)
			MoveWindow(ad.resmem.hProperty,rect.right-180,rect.bottom/2,180,rect.bottom/2,TRUE)
			'
'		Case EM_GETMODIFY
'			Return SendMessage(ad.resmem.hProject,PRO_GETMODIFY,0,0)
'			'
		Case EM_SETMODIFY
			SendMessage(ad.resmem.hProject,PRO_SETMODIFY,wParam,0)
			'
		Case EM_UNDO
			SendMessage(ad.resmem.hResEd,DEM_UNDO,0,0)
			'
		Case WM_CUT
			SendMessage(ad.resmem.hResEd,DEM_CUT,0,0)
			'
		Case WM_COPY
			SendMessage(ad.resmem.hResEd,DEM_COPY,0,0)
			'
		Case WM_PASTE
			SendMessage(ad.resmem.hResEd,DEM_PASTE,0,0)
			'
		Case WM_CLEAR
			SendMessage(ad.resmem.hResEd,DEM_DELETECONTROLS,0,0)
			'
		Case WM_NOTIFY
			lpCTLDBLCLICK=Cast(CTLDBLCLICK Ptr,lParam)
			If (GetKeyState(VK_LBUTTON) And &H80)=0 Then
				fTimer=1
			EndIf
			If lpCTLDBLCLICK->nmhdr.code=NM_DBLCLK Then
				'TextToOutput(*lpCTLDBLCLICK->lpCtlName)
				'TextToOutput(*lpCTLDBLCLICK->lpDlgName)
				CallAddins(hWin,AIM_CTLDBLCLK,0,lParam,HOOK_CTLDBLCLK)
			EndIf
			'
		Case WM_CONTEXTMENU
			If lParam=-1 Then
				GetWindowRect(hWin,@rect)
				pt.x=rect.left+90
				pt.y=rect.top+90
			Else
				pt.x=lParam And &HFFFF
				pt.y=lParam Shr 16
			EndIf
			hMnu=GetSubMenu(ah.hcontextmenu,4)
			TrackPopupMenu(hMnu,TPM_LEFTALIGN Or TPM_RIGHTBUTTON,pt.x,pt.y,0,ah.hwnd,0)
		Case WM_SHOWWINDOW
			If ah.hfullscreen<>0 And fInUse=FALSE Then
				fInUse=TRUE
				If wParam Then
					If GetParent(hWin)<>ah.hfullscreen Then
						SetFullScreen(hWin)
					EndIf
				Else
					If GetParent(hWin)=ah.hfullscreen Then
						SetParent(hWin,ah.hwnd)
					EndIf
				EndIf
				fInUse=FALSE
			EndIf
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function
