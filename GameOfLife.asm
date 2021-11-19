.386
.Model Flat, StdCall
Option Casemap :None

include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc
include msvcrt.inc

 
includelib msvcrt.lib
includelib gdi32.lib
includeLib user32.lib
includeLib kernel32.lib
include macro.asm
	
	WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
	WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
	
.DATA
; 
	szClassName db "GameOfLife",0
	biaoti db "GameOfLife",0
	str1		db "%d,%d",0ah,0
	hwnd dd 0
	
; 
	;x dd 0
	;y dd 0
	;i dd 0
	;j dd 0
	tempX dd 0
	tempY dd 0
	directSize dd 0
	blockSize dd 0
	eraseSize dd 0
	height dd 0
	width_ dd 0
	death dd 0
	r dd 0
	updateflag dd 0

; 
	TIMER_ID equ 42
	iniName db "/GameOfLife.ini",0

	themeText db "GameOfLife",0
	deathText db "Death",0
	widthText db "Width",0
	heightText db "Height",0
	blockSizeText db "BlockSize",0
	pTempX dd 1024 dup(0)
	pTempY dd 1024 dup(0)
	pData dd 1024 dup(0)
	tmp dd 0
	live dd 512 dup(0)

.DATA?
; 
	hInstance	dd ?
; 
	buffer	db MAX_PATH dup(?)
;

.CODE
; ========  start ==============
;void clearRect(HDC hDC, int x, int y, int w, int h)
;{
;    RECT rect;
;    rect.left = x;
;    rect.top = y;
 ;   rect.right = x + w;
;    rect.bottom = y + h;
;    FillSolidRect(hDC, &rect, RGB(255, 255, 255));
;}
;void fillRect(HDC hDC, int x, int y, int w, int h)
;{
;    RECT rect;
;    rect.left = x;
;    rect.top = y;
;    rect.right = x + w;
;    rect.bottom = y + h;
;    FillSolidRect(hDC, &rect, RGB(0, 0, 0));
;}
FillSolidRect proc c hdc:dword, lprect:dword,clr:Dword
invoke SetBkColor,hdc,clr
invoke ExtTextOut,hdc,0,0,ETO_CLIPPED,lprect,0,0,0
ret
FillSolidRect endp

clearRect proc c hdc:dword, x:dword, y:dword, w:dword, h:dword
local rect:RECT
mov eax,x
mov rect.left,eax
mov eax,y
mov rect.top,eax
mov eax,x
add eax,w
mov rect.right,eax
mov eax,y
add eax,h 
mov rect.left,eax
invoke FillSolidRect,hdc,addr rect,0ffffffh
clearRect endp

fillRect proc c hdc:dword, x:dword, y:dword, w:dword, h:dword
local rect:RECT
mov eax,x
mov rect.left,eax
mov eax,y
mov rect.top,eax
mov eax,x
add eax,w
mov rect.right,eax
mov eax,y
add eax,h 
mov rect.left,eax
invoke FillSolidRect,hdc,addr rect,0
fillRect endp

blockState proc c x:dword,y:dword
mov eax,x
cdq
idiv width_
imul edx,height
mov ecx,edx
mov eax,y
cdq
idiv height
add ecx, edx
lea eax, pData
mov edx, [eax + ecx * 4]
and edx,1
mov eax,edx
ret
blockState endp
; ========  end ==============

; ======  start ======
init	proc C
	local path[512]:BYTE
	local n:DWORD, m:DWORD, l:DWORD, i:DWORD
	invoke GetCurrentDirectory, sizeof path, addr path
	invoke crt_strcat, addr path, offset iniName
	invoke GetPrivateProfileInt, offset themeText, offset deathText, 80, addr path
	mov death, eax
	invoke GetPrivateProfileInt, offset themeText, offset widthText, 120, addr path
	mov width_, eax
	invoke GetPrivateProfileInt, offset themeText, offset heightText, 100, addr path
	mov height, eax
	invoke GetPrivateProfileInt, offset themeText, offset blockSizeText, 5, addr path
	mov blockSize, eax
	mov eax, blockSize
	add eax, 1
	mov directSize, eax
	add eax, 1
	mov eraseSize, eax
	mov edx, width_
	mov eax, height
	imul eax, edx
	shl eax, 2
	mov tmp, eax
	;invoke VirtualAlloc, 0, tmp, MEM_COMMIT, PAGE_READWRITE
	;mov pTempX, eax
	;mov edx, width_
	;mov eax, height
	;imul eax, edx
	;shl eax, 2
	;mov tmp, eax
	;invoke VirtualAlloc, 0, tmp, MEM_COMMIT, PAGE_READWRITE
	;mov pTempY, eax
	;mov edx, width_
	;mov eax, height
	;imul eax, edx
	;shl eax, 2
	;mov tmp, eax
	;invoke VirtualAlloc, 0, tmp, MEM_COMMIT, PAGE_READWRITE
	;mov pData, eax
	mov n, 0
	mov m, 0
	mov l, 0
	.while n < 512
		mov eax, n
		sar eax, 8
		and eax, 1
		add m, eax
		mov eax, n
		sar eax, 7
		and eax, 1
		add m, eax
		mov eax, n
		sar eax, 6
		and eax, 1
		add m, eax
		mov eax, n
		sar eax, 5
		and eax, 1
		add m, eax
		mov eax, n
		sar eax, 4
		and eax, 1
		add m, eax
		mov eax, n
		sar eax, 3
		and eax, 1
		add m, eax
		
		;mov eax, n
		;sar eax, 2
		;and eax, 1
		;add m, eax
		
		mov eax, n
		sar eax, 2
		and eax, 1
		add m, eax
		mov eax, n
		sar eax, 1
		and eax, 1
		add m, eax
		.if (m==3)&&(l==0)||(m != 2)&&(m != 3)&&(l == 1)
			mov edx, n
			shl edx, 2
			lea ebx, live
			mov DWORD ptr [ebx+edx], 1
		.else
			mov edx, n
			shl edx, 2
			lea ebx, live
			mov DWORD ptr [ebx+edx], 0
		.endif
		inc n
		mov eax, n
		; add eax, 1
		and eax, 1
		mov l, eax
		mov m, 0
	.endw
	mov edx, width_
	mov eax, height
	imul eax, edx
	sub eax, 1
	mov i, eax
	.while i >= 0
		mov edx, i
		mov eax, 0
		mov [pData+edx*4], eax
		mov [pTempX+edx*4], eax
		mov [pTempY+edx*4], eax
		sub i, 1
	.endw
	ret
init	endp

;===  end ===

; ======  start =====
draw	proc	C hDC:DWORD
local x:dword
local y:dword
	mov x,0
	loopx:
	mov y,0
	loopy:
	invoke blockState,x,y
	cmp eax,0
	je lpdraw
	mov ebx,x
	mov eax,directSize
	mul ebx
	inc eax
	mov ecx,eax
	mov ebx,y
	mov eax,directSize
	mul ebx
	inc eax
	mov ebx,eax
	invoke fillRect,hDC,ecx,ebx,blockSize,blockSize
	lpdraw:
	mov ebx,x
	mov eax,directSize
	mul ebx
	mov ecx,eax
	mov ebx,y
	mov eax,directSize
	mul ebx
	mov ebx,eax
	invoke clearRect,hDC,ecx,ebx,eraseSize,eraseSize
	inc y
	mov ebx,y
	cmp ebx,height
	jne loopy
	inc x
	mov ebx,x
	cmp ebx,width_
	jne loopx
	ret
draw	endp

blockChange	proc	C x:DWORD, y:DWORD
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov edx,0
	mov eax,x
	mov ebx,width_
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	mov eax,height
	mul ebx
	mov ecx,eax
	mov edx,0
	mov eax,y
	mov ebx,height
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	add ebx,ecx
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push ebp
	dec x
	dec y
	lea ebp,pData
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov edx,0
	mov eax,x
	mov ebx,width_
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	mov eax,height
	mul ebx
	mov ecx,eax
	mov edx,0
	mov eax,y
	mov ebx,height
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	add ebx,ecx
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ecx,[ebp+ebx]
	xor ecx,256
	mov [ebp+ebx],ecx
	inc x
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov edx,0
	mov eax,x
	mov ebx,width_
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	mov eax,height
	mul ebx
	mov ecx,eax
	mov edx,0
	mov eax,y
	mov ebx,height
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	add ebx,ecx
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ecx,[ebp+ebx]
	xor ecx,128
	mov [ebp+ebx],ecx
	inc x
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov edx,0
	mov eax,x
	mov ebx,width_
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	mov eax,height
	mul ebx
	mov ecx,eax
	mov edx,0
	mov eax,y
	mov ebx,height
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	add ebx,ecx
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ecx,[ebp+ebx]
	xor ecx,64
	mov [ebp+ebx],ecx
	inc y
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov edx,0
	mov eax,x
	mov ebx,width_
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	mov eax,height
	mul ebx
	mov ecx,eax
	mov edx,0
	mov eax,y
	mov ebx,height
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	add ebx,ecx
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ecx,[ebp+ebx]
	xor ecx,32
	mov [ebp+ebx],ecx
	inc y
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov edx,0
	mov eax,x
	mov ebx,width_
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	mov eax,height
	mul ebx
	mov ecx,eax
	mov edx,0
	mov eax,y
	mov ebx,height
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	add ebx,ecx
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ecx,[ebp+ebx]
	xor ecx,16
	mov [ebp+ebx],ecx
	dec x
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov edx,0
	mov eax,x
	mov ebx,width_
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	mov eax,height
	mul ebx
	mov ecx,eax
	mov edx,0
	mov eax,y
	mov ebx,height
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	add ebx,ecx
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ecx,[ebp+ebx]
	xor ecx,8
	mov [ebp+ebx],ecx
	dec x
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov edx,0
	mov eax,x
	mov ebx,width_
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	mov eax,height
	mul ebx
	mov ecx,eax
	mov edx,0
	mov eax,y
	mov ebx,height
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	add ebx,ecx
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ecx,[ebp+ebx]
	xor ecx,4
	mov [ebp+ebx],ecx
	dec y
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov edx,0
	mov eax,x
	mov ebx,width_
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	mov eax,height
	mul ebx
	mov ecx,eax
	mov edx,0
	mov eax,y
	mov ebx,height
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	add ebx,ecx
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ecx,[ebp+ebx]
	xor ecx,2
	mov [ebp+ebx],ecx
	inc x
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov edx,0
	mov eax,x
	mov ebx,width_
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	mov eax,height
	mul ebx
	mov ecx,eax
	mov edx,0
	mov eax,y
	mov ebx,height
	div ebx
	mul ebx
	mov ebx,x
	sub ebx,eax
	add ebx,ecx
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ecx,[ebp+ebx]
	xor ecx,1
	mov [ebp+ebx],ecx
	pop ebp
	ret
blockChange	endp


randomize	proc
local i:dword
local j:dword
	mov eax,width_
	mov i,eax
	looprani:
	mov eax,height
	mov j,eax
	loopranj:
	invoke crt_rand
	mov ecx,eax
	mov ebx,100
	mov edx,0
	div ebx
	mul ebx
	sub ecx,eax
	push ecx
	invoke blockState,i,j
	mov ebx,death
	xor ebx,eax
	pop ecx
	cmp ecx,ebx
	jle state_end
	invoke blockChange,i,j
	state_end:
	dec j
	cmp j,0
	jne loopranj
	dec i
	cmp i,0
	jne looprani
	invoke InvalidateRect,hwnd,NULL,TRUE
	ret
randomize endp


clean proc
local i:dword
local j:dword
	mov eax,width_
	mov i,eax
	loopcli:
	mov eax,height
	;mov j,height
	mov j,eax
	loopclj:
	invoke blockState,i,j
	cmp eax,0
	je clend
	invoke blockChange,i,j
	clend:
	dec j
	cmp j,0
	jne loopclj
	dec i
	cmp i,0
	jne loopcli
	invoke InvalidateRect,hwnd,NULL,TRUE
	ret
clean endp

update proc
local i:dword
local j:dword
	push ebp
	mov r,0
	mov eax,width_
	mov i,eax
	loopupi:
	mov eax,height
	mov j,eax
	loopupj:
	mov eax,i
	mov edx,0
	mov ebx,width_
	div ebx
	mul ebx
	mov ebx,i
	sub ebx,eax
	mov eax,ebx
	mov ebx,height
	mul ebx
	mov ecx,eax
	mov eax,j
	mov edx,0
	mov ebx,height
	div ebx
	mul ebx
	mov ebx,j
	sub ebx,eax
	add ebx,ecx
	lea ebp,pData
	mov ecx,[ebp+ebx]
	lea ebp,live
	mov ebx,[ebp+ecx]
	cmp ebx,0
	je up_end
	mov ebx,r
	lea ebp,tempX
	mov ecx,i
	mov [ebp+ebx],ecx
	lea ebp,tempY
	mov ecx,j
	mov [ebp+ebx],ecx
	inc r
	up_end:
	dec j
	cmp j,0
	jne loopupj
	dec i
	cmp i,0
	jne loopupi
	loopupr:
	dec r
	cmp r,0
	jl up_out
	mov ebx,r
	lea ebp,tempX
	mov ecx,i
	mov eax,[ebp+ebx]
	push eax
	lea ebp,tempY
	mov ecx,j
	mov edx,[ebp+ebx]
	pop eax
	invoke blockChange,eax,edx
	jmp loopupr
	up_out:
	invoke InvalidateRect,hwnd,NULL,TRUE
	pop ebp
	ret
update endp

do_update proc h:DWORD,m :DWORD,p :DWORD,d :DWORD
	invoke update
	ret
do_update endp

autoupdate proc C
	cmp updateflag,0
	jne auto_end
	invoke SetTimer,hwnd,TIMER_ID,100, offset do_update
	mov updateflag,1
	auto_end:
	ret
autoupdate endp

stopautoupdate proc C
	cmp updateflag,0
	je stpauto_end
	invoke KillTimer,hwnd,TIMER_ID
	mov updateflag,0
	stpauto_end:
	ret
stopautoupdate endp

onleftclick proc C x:DWORD,y:DWORD
	invoke blockChange,x,y
	invoke InvalidateRect,hwnd,NULL,TRUE
	ret
onleftclick endp
;   ======  end ====

; ========  start ==============

START:
start proc
	invoke GetModuleHandle,NULL
	mov hInstance,eax
	invoke WinMain,hInstance,NULL,NULL,SW_SHOWDEFAULT
	invoke ExitProcess,0
start endp

WinMain proc hInst:DWORD,hPrevInst:DWORD,CmdLine:DWORD,CmdShow:DWORD
	LOCAL wc   :WNDCLASSEX
	LOCAL msg  :MSG
	local hWnd :HWND
	invoke init
	mov wc.cbSize,sizeof WNDCLASSEX
	mov wc.style, 0
	mov wc.lpfnWndProc,offset WndProc
	mov wc.cbClsExtra,NULL
	mov wc.cbWndExtra,NULL
	mov eax, hInst
	mov eax, wc.hInstance
	mov wc.hbrBackground, 0
	mov wc.lpszMenuName, 0
	mov wc.lpszClassName, offset szClassName
	invoke LoadCursor,NULL,IDC_ARROW
	mov wc.hCursor,eax
	mov wc.hIconSm,0
	
	invoke RegisterClassEx, addr wc
	invoke CreateWindowEx,NULL,addr szClassName, offset biaoti,WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,NULL,NULL,hInst,NULL
	mov hWnd,eax
	invoke ShowWindow,hWnd,SW_SHOWNORMAL
	invoke UpdateWindow,hWnd
	
	StartLoop:
		invoke GetMessage,ADDR msg,NULL,0,0
			cmp eax, 0
			je ExitLoop
				invoke TranslateMessage, ADDR msg
				invoke DispatchMessage, ADDR msg
			jmp StartLoop
	ExitLoop:
	mov eax,msg.wParam
	ret
WinMain endp

 ; draw	typedef proto C :DWORD

WndProc proc hWin:DWORD,uMsg:DWORD,wParam :DWORD,lParam :DWORD
	local ps:PAINTSTRUCT
	local hdc:DWORD
	local w:DWORD
	local h:DWORD
	local memdc:DWORD
	local membmp:DWORD
	.if uMsg == WM_CREATE
		
	.elseif uMsg == WM_LBUTTONDOWN
		
	.elseif uMsg == WM_LBUTTONUP
	
	.elseif uMsg == WM_MOUSEMOVE
	.elseif uMsg == WM_KEYDOWN
	.elseif uMsg == WM_PAINT
		invoke BeginPaint,hwnd,addr ps
		mov hdc,eax
		
		mov eax,ps.rcPaint.left
		sub eax,ps.rcPaint.top
		mov w, eax
		mov eax,ps.rcPaint.bottom
		sub eax,ps.rcPaint.top
		mov h,eax
		invoke CreateCompatibleDC,hdc
		mov memdc,eax
		invoke CreateCompatibleBitmap,hdc,w,h
		mov membmp,eax
		invoke SelectObject,memdc,membmp
		invoke FillRect,memdc,addr ps.rcPaint,6 ; magic number COLOR_WINDOW + 1
		invoke draw,memdc
		invoke BitBlt,hdc,ps.rcPaint.left,ps.rcPaint.top,w,h,memdc,0,0,0CC0020h ; magic number SRCCOPY
		invoke DeleteDC,memdc
		invoke DeleteObject,memdc
		invoke EndPaint,hwnd,addr ps
	.elseif uMsg == WM_DESTROY
		invoke PostQuitMessage,NULL
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
	.endif
	ret
WndProc endp
; ======== end ==============



END START
