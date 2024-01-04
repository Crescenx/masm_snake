.386
.model flat, stdcall
option casemap:none

include main.inc


;#################################函数原型##################################
WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
PaintBoard PROTO :HWND,:DWORD
Setup	PROTO
;#################################代码#####################################

.code

start:
    invoke GetModuleHandle, NULL
    mov    hInstance, eax



	invoke GetCommandLine
	mov		CommandLine,eax
    invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess, eax

WinMain PROC hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG

    ; 使用参数以消除警告
    mov eax, hPrevInst
    mov eax, CmdLine
    mov eax, CmdShow

    ; Register the window class
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    push hInst
    pop wc.hInstance
    mov wc.hbrBackground, COLOR_WINDOW+1
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, OFFSET ClassName
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax
    invoke RegisterClassEx, addr wc

    ; Create the window
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, WS_OVERLAPPEDWINDOW, \
       CW_USEDEFAULT, CW_USEDEFAULT, BG_WIDTH, BG_HEIGHT, NULL, NULL, hInst, NULL

    mov hwnd, eax
    invoke ShowWindow, hwnd, SW_SHOWNORMAL
    invoke UpdateWindow, hwnd

    ; Message loop
    .WHILE TRUE
        invoke GetMessage, ADDR msg, NULL, 0, 0
        .BREAK .IF (!eax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessage, ADDR msg
    .ENDW
    mov     eax, msg.wParam
    ret
WinMain ENDP


;#####################################用于蛇的双向链表操作###########################################
create_node PROC USES ebx edi esi x:DWORD, y:DWORD ; Create a node with the given data
	push ebx
    ; Allocate memory for the node
    invoke GlobalAlloc, GMEM_FIXED, sizeof node

    ; Initialize the node
    mov [eax].node.prev, 0
    mov ebx, x
    mov [eax].node.x, ebx
    mov ebx, y
    mov [eax].node.y, ebx
    mov [eax].node.next, 0
	pop ebx
    ret
create_node ENDP

link_nodes PROC USES ebx ecx edi esi node1:DWORD, node2:DWORD ; Link two nodes
    ; Set the next pointer of node1 to node2
    mov ebx, node2
	mov ecx, node1
    mov [ecx].node.next, ebx

    ; Set the prev pointer of node2 to node1
    mov ebx, node1
	mov ecx, node2
    mov [ecx].node.prev, ebx

    ret
link_nodes ENDP

delete_node PROC USES ecx ebx edi esi n:DWORD ; Delete a node
    LOCAL prev_node:DWORD, next_node:DWORD

    ; Get the previous and next nodes\
	mov ecx,n
    mov ebx, [ecx].node.prev
    mov prev_node, ebx
    mov ebx, [ecx].node.next
    mov next_node, ebx

    ; Update the pointers of the previous and next nodes
    cmp prev_node, 0 ; If the previous node is not NULL
    jz skip_prev
    mov ebx, next_node
	mov ecx, prev_node
    mov [ecx].node.next, ebx
    skip_prev:
    cmp next_node, 0 ; If the next node is not NULL
    jz skip_next
    mov ebx, prev_node
	mov ecx, next_node
    mov [ecx].node.prev, ebx
    skip_next:

    ; Free the memory of the node
    invoke GlobalFree, n

    ret
delete_node ENDP

free_snake PROC USES ecx ebx edi esi n:DWORD
	LOCAL next_node:DWORD
	.if n != 0
		mov ecx,n
		mov ebx, [ecx].node.next
		mov next_node,ebx
		invoke delete_node,n	
		.if next_node != 0
			invoke free_snake,next_node
		.endif
	.endif
	ret
free_snake endp

copy_to_virtual PROC USES ecx ebx edx edi esi
	local v_cur:dword
	local cur:dword

	mov ecx,snake_head_ptr
	invoke create_node,[ecx].node.x,[ecx].node.y
	mov v_snake_head_ptr,eax
	mov ecx,snake_tail_ptr
	invoke create_node,[ecx].node.x,[ecx].node.y
	mov v_snake_tail_ptr,eax
	mov ecx,snake_head_ptr ;ecx，原蛇
	mov ecx,[ecx].node.next ;下一节
	mov ebx,v_snake_head_ptr ;ebx，新蛇上一节
next_loop:
	mov cur,ecx
	cmp ecx,snake_tail_ptr
	je end_loop
	mov ecx,cur
	invoke create_node,[ecx].node.x,[ecx].node.y
	mov v_cur,eax
	invoke link_nodes,ebx,v_cur
	mov ebx,v_cur
	mov ecx,cur
	mov ecx,[ecx].node.next
	jmp next_loop
end_loop:
	invoke link_nodes,ebx,v_snake_tail_ptr
	ret
copy_to_virtual endp


;#####################################文件操作################################################
SaveWall proc uses eax ebx
    LOCAL writtenByte:DWORD
    
	invoke CreateFile,offset wallFile,GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	mov ebx, eax
	invoke WriteFile, ebx, offset board, ROWS*COLUMS*(sizeof DWORD), addr writtenByte, 0
	invoke CloseHandle, ebx
    ret
SaveWall endp

LoadWall proc
    LOCAL readByte

    invoke CreateFile,offset wallFile,GENERIC_READ,0,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
    .if eax
	    mov ebx, eax
	    invoke ReadFile, ebx, offset board, ROWS*COLUMS*(sizeof DWORD), addr readByte, 0
	.endif
	invoke CloseHandle, ebx
    ret

LoadWall endp

;#####################################操作世界数组#############################################  懒得改了
get_item PROC uses ecx ebx edi esi x:DWORD,y:DWORD
	mov eax,y
	mov ecx,COLUMS
	mul ecx
	mov ebx,x
	add ebx,eax
	lea ebx,[ebx*4]
	mov eax,[board+ebx]
	ret 
get_item ENDP

alter_item PROC uses ecx ebx edi esi x:DWORD,y:DWORD,data:DWORD
	mov eax,y
	mov ecx,COLUMS
	mul ecx
	mov ebx,x
	add ebx,eax
	lea ebx,[ebx*4]
	mov ecx,data
	mov [board+ebx],ecx
	ret
alter_item ENDP

v_get_item PROC uses ecx ebx edi esi x:DWORD,y:DWORD
	mov eax,y
	mov ecx,COLUMS
	mul ecx
	mov ebx,x
	add ebx,eax
	lea ebx,[ebx*4]
	mov eax,[board_virtual+ebx]
	ret 
v_get_item ENDP

v_alter_item PROC uses ecx ebx edi esi x:DWORD,y:DWORD,data:DWORD
	mov eax,y
	mov ecx,COLUMS
	mul ecx
	mov ebx,x
	add ebx,eax
	lea ebx,[ebx*4]
	mov ecx,data
	mov [board_virtual+ebx],ecx
	ret
v_alter_item ENDP

get_item_bfs PROC uses ecx ebx edi esi x:DWORD,y:DWORD
	mov eax,y
	mov ecx,COLUMS
	mul ecx
	mov ebx,x
	add ebx,eax
	lea ebx,[ebx*4]
	mov eax,[bfs_map+ebx]
	ret 
get_item_bfs ENDP

alter_item_bfs PROC uses ecx ebx edi esi x:DWORD,y:DWORD,data:DWORD
	mov eax,y
	mov ecx,COLUMS
	mul ecx
	mov ebx,x
	add ebx,eax
	lea ebx,[ebx*4]
	mov ecx,data
	mov [bfs_map+ebx],ecx
	ret
alter_item_bfs ENDP

v_get_item_bfs PROC uses ecx ebx edi esi x:DWORD,y:DWORD
	mov eax,y
	mov ecx,COLUMS
	mul ecx
	mov ebx,x
	add ebx,eax
	lea ebx,[ebx*4]
	mov eax,[v_bfs_map+ebx]
	ret 
v_get_item_bfs ENDP

v_alter_item_bfs PROC uses ecx ebx edi esi x:DWORD,y:DWORD,data:DWORD
	mov eax,y
	mov ecx,COLUMS
	mul ecx
	mov ebx,x
	add ebx,eax
	lea ebx,[ebx*4]
	mov ecx,data
	mov [v_bfs_map+ebx],ecx
	ret
v_alter_item_bfs ENDP

get_item_visited PROC uses ecx ebx edi esi x:DWORD,y:DWORD
	mov eax,y
	mov ecx,COLUMS
	mul ecx
	mov ebx,x
	add ebx,eax
	lea ebx,[ebx*4]
	mov eax,[bfs_visited+ebx]
	ret 
get_item_visited ENDP

alter_item_visited PROC uses ecx ebx edi esi x:DWORD,y:DWORD,data:DWORD
	mov eax,y
	mov ecx,COLUMS
	mul ecx
	mov ebx,x
	add ebx,eax
	lea ebx,[ebx*4]
	mov ecx,data
	mov [bfs_visited+ebx],ecx
	ret
alter_item_visited ENDP

v_get_item_visited PROC uses ecx ebx edi esi x:DWORD,y:DWORD
	mov eax,y
	mov ecx,COLUMS
	mul ecx
	mov ebx,x
	add ebx,eax
	lea ebx,[ebx*4]
	mov eax,[v_bfs_visited+ebx]
	ret 
v_get_item_visited ENDP

v_alter_item_visited PROC uses ecx ebx edi esi x:DWORD,y:DWORD,data:DWORD
	mov eax,y
	mov ecx,COLUMS
	mul ecx
	mov ebx,x
	add ebx,eax
	lea ebx,[ebx*4]
	mov ecx,data
	mov [v_bfs_visited+ebx],ecx
	ret
v_alter_item_visited ENDP


;#######################################生成随机数#############################################
Random PROC uses ecx edx range:DWORD
    mov eax, rseed
    imul eax, eax, 1103515245
    add eax, 12345
    mov rseed, eax

    xor edx, edx          ; 清除edx以准备除法
    div range             ; eax = eax / range, edx = eax % range
    mov eax, edx ; 存储余数，它是我们的随机数
	ret
Random ENDP


;########################################初始化###############################################
Setup proc uses eax
	LOCAL	food_content:DWORD
	push eax
	invoke create_node, 0,7
	mov	snake_head_ptr,eax
	invoke create_node, 0,6
	mov	snake_tail_ptr,eax
	invoke link_nodes, snake_head_ptr,snake_tail_ptr
	invoke alter_item,0,7,3
	invoke alter_item,0,6,3

	;初始化随机数种子
	invoke GetTickCount
	mov rseed,eax

	mov ecx,0 ;标志：尚未找到合适的食物位置
	.while ecx == 0
		invoke Random,ROWS
		mov food_pos_x,eax
		invoke Random,COLUMS
		mov food_pos_y,eax
		invoke get_item,food_pos_x,food_pos_y
		mov food_content,eax
		.if food_content == 0
			mov ecx,1
			invoke alter_item,food_pos_x,food_pos_y,1
		.endif
	.endw
	pop eax
	ret
Setup endp

Setup_board proc uses eax ecx 
	push eax
	mov ecx, sizeof board
    lea edi, board
    xor eax, eax
    rep stosb
	pop eax
	ret
Setup_board endp

Setup_params proc uses ebx 
	mov ebx,0
	mov game_state,ebx
	mov ebx,2
	mov game_score,ebx
	mov ebx,2
	mov snake_dir,ebx
	mov ebx,2
	mov snake_state,ebx
	ret
Setup_params endp

;#####################################打包蛇的移动################################################
mov_snake proc uses eax ebx ecx edx edi esi 
	LOCAL next_x:DWORD
	LOCAL next_y:DWORD
	LOCAL next_item:DWORD
	LOCAL new_head:DWORD
	LOCAL new_tail:DWORD
	LOCAL old_tail_x:DWORD
	LOCAL old_tail_y:DWORD
	LOCAL next_food_pos_x:DWORD
	LOCAL next_food_pos_y:DWORD
	LOCAL next_food_content:DWORD

	mov ecx,snake_head_ptr
	.if snake_dir == 0        ;up
		mov ebx,[ecx].node.x
		mov next_x,ebx
		mov ebx,[ecx].node.y
		.if ebx == 0
			mov ebx,15
		.endif
		add ebx,-1
		mov next_y,ebx
	.endif
	.if snake_dir == 1        ;down
		mov ebx,[ecx].node.x
		mov next_x,ebx
		mov ebx,[ecx].node.y
		add ebx,1
		mov next_y,ebx
	.endif
	.if snake_dir == 2        ;left
		mov ebx,[ecx].node.x
		.if ebx == 0
			mov ebx,15
		.endif
		add ebx,-1
		mov next_x,ebx
		mov ebx,[ecx].node.y
		mov next_y,ebx
	.endif
	.if snake_dir == 3		  ;right 
		mov ebx,[ecx].node.x
		add ebx,1
		mov next_x,ebx
		mov ebx,[ecx].node.y
		mov next_y,ebx
	.endif

	.if next_x > 14
		mov ebx,0
		mov next_x,ebx
	.endif
	.if next_y > 14
		mov ebx,0
		mov next_y,ebx
	.endif

	invoke get_item,next_x,next_y
	mov next_item,eax
	.if next_item == 2 ;撞墙游戏结束
		mov ebx,2
		mov game_state,ebx
		invoke InvalidateRect, hwnd, NULL, TRUE
		invoke free_snake,snake_head_ptr
	.elseif next_item == 3 ;撞自己游戏结束
		mov ebx,2
		mov game_state,ebx
		invoke InvalidateRect, hwnd, NULL, TRUE
		invoke free_snake,snake_head_ptr
	.else
		invoke create_node, next_x,next_y         ;创建头
		mov new_head,eax
		invoke link_nodes, new_head,snake_head_ptr
		mov eax,new_head
		mov snake_head_ptr,eax
		invoke alter_item,next_x,next_y,3
		.if next_item == 1 ;吃到食物
			mov ecx,game_score
			add ecx,1
			mov game_score,ecx
			mov ecx,0 ;标志：尚未找到合适的食物位置
			.while ecx == 0
				invoke Random,ROWS
				mov next_food_pos_x,eax
				invoke Random,COLUMS
				mov next_food_pos_y,eax
				invoke get_item,next_food_pos_x,next_food_pos_y
				mov next_food_content,eax
				.if next_food_content == 0
					mov ecx,1
					invoke alter_item,next_food_pos_x,next_food_pos_y,1
					mov ebx,next_food_pos_x
					mov food_pos_x,ebx
					mov ebx,next_food_pos_y
					mov food_pos_y,ebx
				.endif
			.endw
		.endif
		.if next_item == 0 ;正常走
			mov ecx,snake_tail_ptr
			mov ebx,[ecx].node.prev
			mov new_tail,ebx
			mov ebx,[ecx].node.x
			mov old_tail_x,ebx
			mov ebx,[ecx].node.y
			mov old_tail_y,ebx
			invoke delete_node,snake_tail_ptr
			mov ebx,new_tail
			mov snake_tail_ptr,ebx
			invoke alter_item,old_tail_x,old_tail_y,0
		.endif
	.endif
	ret
mov_snake endp

v_mov_snake proc uses eax ebx ecx edx edi esi 
	LOCAL next_x:DWORD
	LOCAL next_y:DWORD
	LOCAL next_item:DWORD
	LOCAL new_head:DWORD
	LOCAL new_tail:DWORD
	LOCAL old_tail_x:DWORD
	LOCAL old_tail_y:DWORD

	mov ecx,v_snake_head_ptr
	.if v_snake_dir == 0        ;up
		mov ebx,[ecx].node.x
		mov next_x,ebx
		mov ebx,[ecx].node.y
		.if ebx == 0
			mov ebx,15
		.endif
		add ebx,-1
		mov next_y,ebx
	.endif
	.if v_snake_dir == 1        ;down
		mov ebx,[ecx].node.x
		mov next_x,ebx
		mov ebx,[ecx].node.y
		add ebx,1
		mov next_y,ebx
	.endif
	.if v_snake_dir == 2        ;left
		mov ebx,[ecx].node.x
		.if ebx == 0
			mov ebx,15
		.endif
		add ebx,-1
		mov next_x,ebx
		mov ebx,[ecx].node.y
		mov next_y,ebx
	.endif
	.if v_snake_dir == 3		  ;right 
		mov ebx,[ecx].node.x
		add ebx,1
		mov next_x,ebx
		mov ebx,[ecx].node.y
		mov next_y,ebx
	.endif

	.if next_x > 14
		mov ebx,0
		mov next_x,ebx
	.endif
	.if next_y > 14
		mov ebx,0
		mov next_y,ebx
	.endif

	invoke v_get_item,next_x,next_y
	mov next_item,eax
	invoke create_node, next_x,next_y         ;创建头
	mov new_head,eax
	invoke link_nodes, new_head,v_snake_head_ptr
	mov eax,new_head
	mov v_snake_head_ptr,eax
	invoke v_alter_item,next_x,next_y,3
	.if next_item == 1
		mov ebx,1
		mov v_snake_state,ebx
	.endif
	.if next_item == 0 ;正常走
		mov ecx,v_snake_tail_ptr
		mov ebx,[ecx].node.prev
		mov new_tail,ebx
		mov ebx,[ecx].node.x
		mov old_tail_x,ebx
		mov ebx,[ecx].node.y
		mov old_tail_y,ebx
		invoke delete_node,v_snake_tail_ptr
		mov ebx,new_tail
		mov v_snake_tail_ptr,ebx
		invoke v_alter_item,old_tail_x,old_tail_y,0
	.endif
	ret
v_mov_snake endp


;######################################队列操作##################################################
init_queue proc uses eax ebx ecx edx edi esi 
	mov ebx,0
	mov x_head,ebx
	mov y_head,ebx
	mov x_tail,ebx
	mov y_tail,ebx
	mov ecx, sizeof x_queue
    lea edi, x_queue
    xor eax, eax
    rep stosb
	mov ecx, sizeof y_queue
    lea edi, y_queue
    xor eax, eax
    rep stosb
	mov ebx,1
	mov is_empty,ebx
	ret
init_queue endp

push_queue proc uses eax ebx ecx edx edi esi x:DWORD,y:DWORD
	mov ebx,x_tail
	mov ecx,x
	mov [x_queue+ebx*4],ecx
	inc ebx
	.if ebx == 256
		mov ebx,0
	.endif
	mov x_tail,ebx

	mov ebx,y_tail
	mov ecx,y
	mov [y_queue+ebx*4],ecx
	inc ebx
	.if ebx == 256
		mov ebx,0
	.endif
	mov y_tail,ebx
	.if is_empty == 1
		mov ebx,0
		mov is_empty,ebx
	.endif
	ret
push_queue endp

pop_queue proc uses eax ebx ecx edx edi esi
	mov ebx,x_head
	mov ecx,[x_queue+ebx*4]
	mov x_ele,ecx
	inc ebx
	.if ebx == 256
		mov ebx,0
	.endif
	mov x_head,ebx

	mov ebx,y_head
	mov ecx,[y_queue+ebx*4]
	mov y_ele,ecx
	inc ebx
	.if ebx == 256
		mov ebx,0
	.endif
	mov y_head,ebx
	mov ecx,y_tail
	cmp ebx,ecx
	jne skip
	mov ecx,1
	mov is_empty,ecx
skip:
	ret
pop_queue endp

;######################################广搜#####################################################
is_valid proc uses ebx ecx edx edi esi x:dword,y:dword
	local result:dword
	local item:dword
	local visited:dword
	mov eax,1
	mov result,eax
	invoke get_item,x,y
	mov item,eax
	invoke get_item_visited,x,y
	mov visited,eax
	.if visited == 1
		mov eax,0
		mov  result,eax
	.endif
	.if item == 2
		mov eax,0
		mov  result,eax
	.endif
	.if item == 3
		mov eax,0
		mov  result,eax
	.endif
	mov eax,result
	ret
is_valid endp

v_is_valid proc uses ebx ecx edx edi esi x:dword,y:dword
	local result:dword
	local item:dword
	local visited:dword
	mov eax,1
	mov result,eax
	invoke v_get_item,x,y
	mov item,eax
	invoke v_get_item_visited,x,y
	mov visited,eax
	.if visited == 1
		mov eax,0
		mov  result,eax
	.endif
	.if item == 2
		mov eax,0
		mov  result,eax
	.endif
	.if item == 3
		mov eax,0
		mov  result,eax
	.endif
	mov eax,result
	ret
v_is_valid endp

bfs proc uses eax ebx ecx edx edi esi dest_x:dword,dest_y:dword
	local adj_x:dword
	local adj_y:dword
	local valid:dword
	local inc_dist:dword
	; 终点开始，标记已访问
	mov ecx, sizeof bfs_visited
    lea edi, bfs_visited
    xor eax, eax
    rep stosb
	invoke alter_item_visited,dest_x,dest_y,1
	; 全部距离标记为0xffffffff
	mov ecx, sizeof bfs_map
    lea edi, bfs_map
    mov eax, -1
    rep stosb
	; 标记终点距离为0
	invoke alter_item_bfs,dest_x,dest_y,0
	; 初始化队列
	invoke init_queue
	; 终点入队
	invoke push_queue,dest_x,dest_y
	.while is_empty == 0
		invoke pop_queue
		invoke get_item_bfs,x_ele,y_ele
		add eax,1
		mov inc_dist,eax
		;上
		mov ebx,y_ele
		.if ebx == 0
			mov ebx,15
		.endif
		add ebx,-1
		mov adj_y,ebx
		mov ebx,x_ele
		mov adj_x,ebx
		invoke is_valid,adj_x,adj_y
		mov valid,eax
		.if valid == 1
			invoke alter_item_bfs,adj_x,adj_y,inc_dist
			invoke alter_item_visited,adj_x,adj_y,1
			invoke push_queue,adj_x,adj_y
		.endif
		;下
		mov ebx,y_ele
		add ebx,1
		.if ebx == 15
			mov ebx,0
		.endif
		mov adj_y,ebx
		mov ebx,x_ele
		mov adj_x,ebx
		invoke is_valid,adj_x,adj_y
		mov valid,eax
		.if valid == 1
			invoke alter_item_bfs,adj_x,adj_y,inc_dist
			invoke alter_item_visited,adj_x,adj_y,1
			invoke push_queue,adj_x,adj_y
		.endif
		;左
		mov ebx,x_ele
		.if ebx == 0
			mov ebx,15
		.endif
		add ebx,-1
		mov adj_x,ebx
		mov ebx,y_ele
		mov adj_y,ebx
		invoke is_valid,adj_x,adj_y
		mov valid,eax
		.if valid == 1
			invoke alter_item_bfs,adj_x,adj_y,inc_dist
			invoke alter_item_visited,adj_x,adj_y,1
			invoke push_queue,adj_x,adj_y
		.endif
		;右
		mov ebx,x_ele
		add ebx,1
		.if ebx == 15
			mov ebx,0
		.endif
		mov adj_x,ebx
		mov ebx,y_ele
		mov adj_y,ebx
		invoke is_valid,adj_x,adj_y
		mov valid,eax
		.if valid == 1
			invoke alter_item_bfs,adj_x,adj_y,inc_dist
			invoke alter_item_visited,adj_x,adj_y,1
			invoke push_queue,adj_x,adj_y
		.endif
	.endw
	ret
bfs endp

v_bfs proc uses eax ebx ecx edx edi esi dest_x:dword,dest_y:dword
	local adj_x:dword
	local adj_y:dword
	local valid:dword
	local inc_dist:dword
	; 终点开始，标记已访问
	mov ecx, sizeof v_bfs_visited
    lea edi, v_bfs_visited
    xor eax, eax
    rep stosb
	invoke v_alter_item_visited,dest_x,dest_y,1
	; 全部距离标记为0xffffffff
	mov ecx, sizeof v_bfs_map
    lea edi, v_bfs_map
    mov eax, -1
    rep stosb
	; 标记终点距离为0
	invoke v_alter_item_bfs,dest_x,dest_y,0
	; 初始化队列
	invoke init_queue
	; 终点入队
	invoke push_queue,dest_x,dest_y
	.while is_empty == 0
		invoke pop_queue
		invoke v_get_item_bfs,x_ele,y_ele
		add eax,1
		mov inc_dist,eax
		;上
		mov ebx,y_ele
		.if ebx == 0
			mov ebx,15
		.endif
		add ebx,-1
		mov adj_y,ebx
		mov ebx,x_ele
		mov adj_x,ebx
		invoke v_is_valid,adj_x,adj_y
		mov valid,eax
		.if valid == 1
			invoke v_alter_item_bfs,adj_x,adj_y,inc_dist
			invoke v_alter_item_visited,adj_x,adj_y,1
			invoke push_queue,adj_x,adj_y
		.endif
		;下
		mov ebx,y_ele
		add ebx,1
		.if ebx == 15
			mov ebx,0
		.endif
		mov adj_y,ebx
		mov ebx,x_ele
		mov adj_x,ebx
		invoke v_is_valid,adj_x,adj_y
		mov valid,eax
		.if valid == 1
			invoke v_alter_item_bfs,adj_x,adj_y,inc_dist
			invoke v_alter_item_visited,adj_x,adj_y,1
			invoke push_queue,adj_x,adj_y
		.endif
		;左
		mov ebx,x_ele
		.if ebx == 0
			mov ebx,15
		.endif
		add ebx,-1
		mov adj_x,ebx
		mov ebx,y_ele
		mov adj_y,ebx
		invoke v_is_valid,adj_x,adj_y
		mov valid,eax
		.if valid == 1
			invoke v_alter_item_bfs,adj_x,adj_y,inc_dist
			invoke v_alter_item_visited,adj_x,adj_y,1
			invoke push_queue,adj_x,adj_y
		.endif
		;右
		mov ebx,x_ele
		add ebx,1
		.if ebx == 15
			mov ebx,0
		.endif
		mov adj_x,ebx
		mov ebx,y_ele
		mov adj_y,ebx
		invoke v_is_valid,adj_x,adj_y
		mov valid,eax
		.if valid == 1
			invoke v_alter_item_bfs,adj_x,adj_y,inc_dist
			invoke v_alter_item_visited,adj_x,adj_y,1
			invoke push_queue,adj_x,adj_y
		.endif
	.endw
	ret
v_bfs endp


;#######################################工具函数################################################\
;从bfs图表中寻找方向
get_dir_from_bfs_shortest proc uses  ebx ecx edx edi esi x:dword,y:dword
	local min:dword
	local next_ele:dword
	local dir:dword
	local x_next:dword
	local y_next:dword

	mov ebx,-1
	mov min,ebx
	mov ebx,0
	mov dir,ebx
	;上
	mov ebx,y
	.if ebx == 0
		mov ebx,15
	.endif
	add ebx,-1
	mov y_next,ebx
	mov ebx,x
	mov x_next,ebx
	invoke get_item_bfs,x_next,y_next
	cmp eax,min
	ja skip_up
	mov min,eax
	mov ebx,0
	mov dir,ebx
skip_up:
	;下
	mov ebx,y
	add ebx,1
	.if ebx == 15
		mov ebx,0
	.endif
	mov y_next,ebx
	mov ebx,x
	mov x_next,ebx
	invoke get_item_bfs,x_next,y_next
	cmp eax,min
	ja skip_down
	mov min,eax
	mov ebx,1
	mov dir,ebx
skip_down:
	; 左
	mov ebx,x
	.if ebx == 0
		mov ebx,15
	.endif
	add ebx,-1
	mov x_next,ebx
	mov ebx,y
	mov y_next,ebx
	invoke get_item_bfs,x_next,y_next
	cmp eax,min
	ja skip_left
	mov min,eax
	mov ebx,2
	mov dir,ebx
skip_left:
	;右
	mov ebx,x
	add ebx,1
	.if ebx == 15
		mov ebx,0
	.endif
	mov x_next,ebx
	mov ebx,y
	mov y_next,ebx
	invoke get_item_bfs,x_next,y_next
	cmp eax,min
	ja skip_right
	mov min,eax
	mov ebx,3
	mov dir,ebx
skip_right:
	mov eax,dir
	ret
get_dir_from_bfs_shortest endp

get_dir_from_bfs_longest proc uses  ebx ecx edx edi esi x:dword,y:dword
	local max:dword
	local next_ele:dword
	local dir:dword
	local x_next:dword
	local y_next:dword

	mov ebx,0
	mov max,ebx
	mov ebx,0
	mov dir,ebx
	;上
	mov ebx,y
	.if ebx == 0
		mov ebx,15
	.endif
	add ebx,-1
	mov y_next,ebx
	mov ebx,x
	mov x_next,ebx
	invoke get_item_bfs,x_next,y_next
	cmp eax,max
	jb skip_up
	mov max,eax
	mov ebx,0
	mov dir,ebx
skip_up:
	;下
	mov ebx,y
	add ebx,1
	.if ebx == 15
		mov ebx,0
	.endif
	mov y_next,ebx
	mov ebx,x
	mov x_next,ebx
	invoke get_item_bfs,x_next,y_next
	cmp eax,max
	jb skip_down
	mov max,eax
	mov ebx,1
	mov dir,ebx
skip_down:
	; 左
	mov ebx,x
	.if ebx == 0
		mov ebx,15
	.endif
	add ebx,-1
	mov x_next,ebx
	mov ebx,y
	mov y_next,ebx
	invoke get_item_bfs,x_next,y_next
	cmp eax,max
	jb skip_left
	mov max,eax
	mov ebx,2
	mov dir,ebx
skip_left:
	;右
	mov ebx,x
	add ebx,1
	.if ebx == 15
		mov ebx,0
	.endif
	mov x_next,ebx
	mov ebx,y
	mov y_next,ebx
	invoke get_item_bfs,x_next,y_next
	cmp eax,max
	jb skip_right
	mov max,eax
	mov ebx,3
	mov dir,ebx
skip_right:
	mov eax,dir
	ret
get_dir_from_bfs_longest endp

;获得最大曼哈顿距离：太傻呗了，这个地图和甜甜圈是同胚的，不写了
get_wander_dir proc uses  ebx ecx edx edi esi
	local adj_x:dword
	local adj_y:dword
	local next_item:dword
	;上
	mov ecx,snake_head_ptr
	mov ebx,[ecx].node.y
	.if ebx == 0
		mov ebx,15
	.endif
	add ebx,-1
	mov adj_y,ebx
	mov ecx,snake_head_ptr
	mov ebx,[ecx].node.x
	mov adj_x,ebx
	invoke get_item,adj_x,adj_y
	mov next_item,eax
	.if next_item == 0
		mov eax,0
		ret
	.endif
	.if next_item == 1
		mov eax,0
		ret
	.endif
	;下
	mov ecx,snake_head_ptr
	mov ebx,[ecx].node.y
	add ebx,1
	.if ebx == 15
		mov ebx,0
	.endif
	mov adj_y,ebx
	mov ecx,snake_head_ptr
	mov ebx,[ecx].node.x
	mov adj_x,ebx
	invoke get_item,adj_x,adj_y
	mov next_item,eax
	.if next_item == 0
		mov eax,1
		ret
	.endif
	.if next_item == 1
		mov eax,1
		ret
	.endif
	;左
	mov ecx,snake_head_ptr
	mov ebx,[ecx].node.x
	.if ebx == 0
		mov ebx,15
	.endif
	add ebx,-1
	mov adj_x,ebx
	mov ecx,snake_head_ptr
	mov ebx,[ecx].node.y
	mov adj_y,ebx
	invoke get_item,adj_x,adj_y
	mov next_item,eax
	.if next_item == 0
		mov eax,2
		ret
	.endif
	.if next_item == 1
		mov eax,2
		ret
	.endif
	;右
	mov ecx,snake_head_ptr
	mov ebx,[ecx].node.x
	add ebx,1
	.if ebx == 15
		mov ebx,0
	.endif
	mov adj_x,ebx
	mov ecx,snake_head_ptr
	mov ebx,[ecx].node.y
	mov adj_y,ebx
	invoke get_item,adj_x,adj_y
	mov next_item,eax
	.if next_item == 0
		mov eax,3
		ret
	.endif
	.if next_item == 1
		mov eax,3
		ret
	.endif
	mov eax,0
	ret
get_wander_dir endp

;######################################定时回调函数###############################################
SnakeTimerProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	.if game_state == 1
		invoke mov_snake
		invoke InvalidateRect, hwnd, NULL, TRUE
	.endif
	ret
SnakeTimerProc endp

DrawTimerProc proc uses ebx hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	.if game_state == 4
		.if draw_state == 0
			mov ebx,select_y
			.if ebx == 0
				mov ebx,15
			.endif
			add ebx,-1
			mov select_y,ebx
		.endif
		.if draw_state == 1
			mov ebx,select_y
			add ebx,1
			.if ebx == 15
				mov ebx,0
			.endif
			mov select_y,ebx
		.endif
		.if draw_state == 2
			mov ebx,select_x
			.if ebx == 0
				mov ebx,15
			.endif
			add ebx,-1
			mov select_x,ebx
		.endif
		.if draw_state == 3
			mov ebx,select_x
			add ebx,1
			.if ebx == 15
				mov ebx,0
			.endif
			mov select_x,ebx
		.endif
		.if draw_state == 4
			invoke alter_item,select_x,select_y,2
		.endif
		.if draw_state == 5
			invoke SaveWall
			mov ebx,0
			mov game_state,ebx
		.endif
		mov ebx,6
		mov draw_state,ebx
		invoke InvalidateRect, hwnd, NULL, TRUE
	.endif
	ret
DrawTimerProc endp

RunAutoProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	local dir1:dword
	local dir2:dword
	local dir3:dword
	local select_state:dword ;1234对应选择dir1234
	local v_bfs_item:dword
	.if game_state == 5
		; bfs判断食物是否可达
		mov ecx,snake_head_ptr
		invoke alter_item,[ecx].node.x,[ecx].node.y,0 ;先设置蛇头为可达
		invoke bfs,food_pos_x,food_pos_y
		invoke alter_item,[ecx].node.x,[ecx].node.y,3 ;做完bfs恢复
		mov ecx,snake_head_ptr
		invoke get_dir_from_bfs_shortest,[ecx].node.x,[ecx].node.y
		mov dir1,eax
		mov ecx,snake_head_ptr
		invoke get_item_bfs,[ecx].node.x,[ecx].node.y
		cmp eax,-1
		jae test_tail ;不可达，追尾吧
		;虚拟蛇
		mov ebx,0
		mov v_snake_state,ebx ;初始化状态
		invoke copy_to_virtual ;拷贝蛇
		mov ecx, ROWS*COLUMS ; Set up loop counter
		lea esi, board ; Load the address of array1 into ESI
		lea edi, board_virtual ; Load the address of array2 into EDI
		cld ; Clear the direction flag to increment ESI and EDI
		rep movsd ; Repeat MOVSD ECX times
		.while v_snake_state == 0
			mov	ecx,v_snake_head_ptr
			invoke get_dir_from_bfs_shortest,[ecx].node.x,[ecx].node.y
			mov v_snake_dir,eax
			invoke v_mov_snake
		.endw
		;判断虚拟蛇尾
		mov ecx,v_snake_head_ptr
		invoke v_alter_item,[ecx].node.x,[ecx].node.y,0 ;先设置蛇头为可达
		mov ecx,v_snake_tail_ptr
		invoke v_bfs,[ecx].node.x,[ecx].node.y
		mov ecx,v_snake_head_ptr
		invoke v_get_item_bfs,[ecx].node.x,[ecx].node.y
		mov v_bfs_item,eax
		invoke free_snake,v_snake_head_ptr ;释放虚拟蛇
		mov ebx,v_bfs_item
		cmp ebx,-1
		jb end_test_food
test_tail:
		mov ecx,snake_head_ptr
		invoke alter_item,[ecx].node.x,[ecx].node.y,0 ;先设置蛇头为可达
		mov ecx,snake_tail_ptr
		invoke bfs,[ecx].node.x,[ecx].node.y
		mov ecx,snake_head_ptr
		invoke get_dir_from_bfs_longest,[ecx].node.x,[ecx].node.y
		mov dir2,eax
		mov ecx,snake_head_ptr
		invoke get_item_bfs,[ecx].node.x,[ecx].node.y
		cmp eax,-1
		jb end_test_tail
wander:
		invoke get_wander_dir
		mov dir3,eax
		mov ebx,3
		mov select_state,ebx
		jmp end_select
end_test_tail:
		mov ebx,2
		mov select_state,ebx
		jmp end_select
end_test_food:
		mov ebx,1
		mov select_state,ebx
end_select:
		.if select_state == 1
			mov ebx,dir1
		.endif
		.if select_state == 2
			mov ebx,dir2
		.endif
		.if select_state == 3
			mov ebx,dir3
		.endif
		mov snake_dir,ebx
		invoke mov_snake
		invoke InvalidateRect, hwnd, NULL, TRUE
	.endif
	ret
RunAutoProc endp
;########################################画图函数############################################
Draw_snake proc  uses edx ecx ebx esi, hWin:HWND,hDC:HDC
	LOCAL mDC:HDC
	LOCAL current_node:DWORD
	LOCAL current_color:DWORD
	LOCAL current_brush:DWORD
	LOCAL x1:DWORD
	LOCAL x2:DWORD
	LOCAL y1:DWORD
	LOCAL y2:DWORD
	LOCAL buffer[32]:BYTE
	LOCAL wRect:RECT
	LOCAL select_pos_x:DWORD
	LOCAL select_pos_y:DWORD
	LOCAL while_x:DWORD
	LOCAL while_y:DWORD
	LOCAL wall_x:DWORD
	LOCAL wall_y:DWORD
	LOCAL item:DWORD

	; 准备双缓冲
	invoke CreateCompatibleDC,hDC
	mov		mDC,eax
	invoke CreateCompatibleBitmap,hDC,900,900
	invoke SelectObject,mDC,eax
	push	eax

	;画背景
	invoke SelectObject,mDC, blockBrush
    invoke Rectangle, mDC, 0, 0, 900, 900

	;画墙
	mov edx,0
	mov while_y,edx
	.while while_y != ROWS
		mov eax,60
		mul while_y
		mov wall_y,eax
		mov ecx,0
		mov while_x,ecx
		.while while_x != COLUMS
			mov eax,60
			mul while_x
			mov wall_x,eax
			
			invoke get_item,while_x,while_y
			mov item,eax
			.if item == 2
				invoke ImageList_Draw, wall_bmp, 0, mDC, wall_x, wall_y, ILD_TRANSPARENT
			.endif
			mov ecx,while_x
			add ecx,1
			mov while_x,ecx
		.endw
		mov edx,while_y
		add edx,1
		mov while_y,edx
	.endw

	.if game_state == 0 ;未开始，画开始界面
		invoke ImageList_Draw, start_bmp, 0, mDC, 0, 0, ILD_TRANSPARENT
	.elseif game_state == 2 ;死掉了
		invoke ImageList_Draw, over_bmp, 0, mDC, 0, 0, ILD_TRANSPARENT
		mov wRect.left,0
		mov wRect.top,450
		mov wRect.right,900
		mov wRect.bottom,650
		invoke SetBkMode,mDC,TRANSPARENT
		invoke SetTextColor,mDC,0ffffffh
		invoke wsprintfA,addr buffer,offset scoreFmtStr,game_score
		invoke DrawText,mDC,addr buffer,-1,addr wRect,DT_CENTER
	.elseif game_state == 4 ;画地图
		;画选择框
		mov eax,60
		mul select_x
		mov select_pos_x,eax
		mov eax,60
		mul select_y
		mov select_pos_y,eax
		invoke ImageList_Draw, select_bmp, 0, mDC, select_pos_x, select_pos_y, ILD_TRANSPARENT
		;画墙
		mov edx,0
		mov while_y,edx
		.while while_y != ROWS
			mov eax,60
			mul while_y
			mov wall_y,eax
			mov ecx,0
			mov while_x,ecx
			.while while_x != COLUMS
				mov eax,60
				mul while_x
				mov wall_x,eax
				
				invoke get_item,while_x,while_y
				mov item,eax
				.if item == 2
					invoke ImageList_Draw, wall_bmp, 0, mDC, wall_x, wall_y, ILD_TRANSPARENT
				.endif
				mov ecx,while_x
				add ecx,1
				mov while_x,ecx
			.endw
			mov edx,while_y
			add edx,1
			mov while_y,edx
		.endw
	.else
		;画蛇
		mov ebx,7CFC00h
		mov current_color,ebx
		mov ebx, snake_head_ptr
		mov current_node, ebx
		.WHILE current_node != 0
			invoke CreateSolidBrush,current_color
			mov current_brush,eax
			invoke SelectObject, mDC, current_brush
			mov ecx,current_node
			mov eax,60
			mul [ecx].node.x
			mov x1,eax
			add eax,60
			mov x2,eax
			mov eax,60
			mul [ecx].node.y
			mov y1,eax
			add eax,60
			mov y2,eax
			invoke Rectangle, mDC, x1, y1, x2, y2
			invoke SelectObject,mDC,eax
			invoke DeleteObject,eax
		
			; Move to the next node
			mov ecx,current_node
			mov ebx, [ecx].node.next
			mov current_node, ebx

			; change the color a littile
			mov ebx,current_color
			sub ebx,000500h
			mov current_color,ebx
		.ENDW
	
		; 画食物
		mov ebx,food_pos_x
		mov x1,ebx
		mov ebx,food_pos_y
		mov y1,ebx
		mov eax,60
		mul x1
		mov x1,eax
		add eax,60
		mov x2,eax
		mov eax,60
		mul y1
		mov y1,eax
		add eax,60
		mov y2,eax
		invoke SelectObject, mDC, foodBrush
		invoke Rectangle, mDC, x1, y1, x2, y2
	.endif
	

	invoke BitBlt,hDC, 0, 0, 900, 900, mDC, 0, 0, SRCCOPY
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	invoke DeleteDC,mDC
	ret
Draw_snake endp





;################################消息处理#####################################
WndProc proc hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL	hBmp:DWORD
	LOCAL	ps:PAINTSTRUCT
	LOCAL   hDC:DWORD
	
	.IF uMsg == WM_CREATE
		; Load block
		invoke LoadBitmap,hInstance,IDB_BLOCK
		mov		hBmp,eax
		invoke CreatePatternBrush,hBmp
		mov     blockBrush,eax

		; Load food
		invoke LoadBitmap,hInstance,IDB_FOOD
		mov		hBmp,eax
		invoke CreatePatternBrush,hBmp
		mov     foodBrush,eax

		; Load Wall
		invoke ImageList_Create,60,60,ILC_COLOR16 or ILC_MASK,1,0
		mov		wall_bmp,eax
		invoke LoadBitmap,hInstance,IDB_WALL
		mov		hBmp,eax
		invoke ImageList_AddMasked,wall_bmp,hBmp,0
		invoke DeleteObject,hBmp

		; Load start scene
		invoke ImageList_Create,900,900,ILC_COLOR16 or ILC_MASK,1,0
		mov		start_bmp,eax
		invoke LoadBitmap,hInstance,IDB_START
		mov		hBmp,eax
		invoke ImageList_AddMasked,start_bmp,hBmp,0
		invoke DeleteObject,hBmp

		; Load game-over scene
		invoke ImageList_Create,900,900,ILC_COLOR16 or ILC_MASK,1,0
		mov		over_bmp,eax
		invoke LoadBitmap,hInstance,IDB_OVER
		mov		hBmp,eax
		invoke ImageList_AddMasked,over_bmp,hBmp,0
		invoke DeleteObject,hBmp

		; Load select square
		invoke ImageList_Create,60,60,ILC_COLOR16 or ILC_MASK,1,0
		mov		select_bmp,eax
		invoke LoadBitmap,hInstance,IDB_SELECT
		mov		hBmp,eax
		invoke ImageList_AddMasked,select_bmp,hBmp,0
		invoke DeleteObject,hBmp
		
		; Innitialize
		invoke Setup_board
		invoke Setup_params

		; set timer
		invoke SetTimer,hWin,SNAKE_TIMER_ID,SNAKE_TIMER_GAP,offset SnakeTimerProc
		invoke SetTimer,hWin,DRAW_TIMER_ID,DRAW_TIMER_GAP,offset DrawTimerProc
		invoke SetTimer,hWin,AUTO_TIMER_ID,AUTO_TIMER_GAP,offset RunAutoProc
	.ELSEIF uMsg == WM_DESTROY
        invoke PostQuitMessage, 0
    .ELSEIF uMsg == WM_PAINT
        ; 处理绘制消息
        invoke BeginPaint,hWin,ADDR ps
        mov hDC, eax
		invoke Draw_snake, hWin,hDC
        invoke EndPaint,hWin,ADDR ps
	.ELSEIF uMsg == WM_KEYDOWN
		.if wParam == VK_S
			.if game_state == 0
				invoke LoadWall
				invoke Setup
				mov ebx,1
				mov game_state,ebx
			.endif
		.endif
		.if wParam == VK_D
			.if game_state == 0
				mov ebx,4
				mov game_state,ebx
			.endif
		.endif
		.if wParam == VK_T
			.if game_state == 0
				invoke LoadWall
				invoke Setup
				mov ebx,5
				mov game_state,ebx
			.endif
		.endif
		.if wParam == VK_UP
			mov eax,0
			.if snake_dir == 2
				mov snake_dir,eax
			.endif
			.if snake_dir == 3
				mov snake_dir,eax
			.endif
			.if game_state == 4
				mov draw_state,eax
			.endif
		.endif
		.if wParam == VK_DOWN
			mov eax,1
			.if snake_dir == 2
				mov snake_dir,eax
			.endif
			.if snake_dir == 3
				mov snake_dir,eax
			.endif
			.if game_state == 4
				mov draw_state,eax
			.endif
		.endif
		.if wParam == VK_LEFT
			mov eax,2
			.if snake_dir == 0
				mov snake_dir,eax
			.endif
			.if snake_dir == 1
				mov snake_dir,eax
			.endif
			.if game_state == 4
				mov draw_state,eax
			.endif
		.endif
		.if wParam == VK_RIGHT
			mov eax,3
			.if snake_dir == 0
				mov snake_dir,eax
			.endif
			.if snake_dir == 1
				mov snake_dir,eax
			.endif
			.if game_state == 4
				mov draw_state,eax
			.endif
		.endif
		.if wParam == VK_SPACE
			mov eax,4
			.if game_state == 4
				mov draw_state,eax
			.endif
		.endif
		.if wParam == VK_RETURN
			.if game_state == 4
				mov eax,5
				mov draw_state,eax
			.endif
			.if game_state == 2
				mov eax,0
				mov game_state,eax
				invoke InvalidateRect, hwnd, NULL, TRUE
			.endif
		.endif
    .ELSE
        invoke DefWindowProc, hWin, uMsg, wParam, lParam
        ret
    .ENDIF
    xor eax, eax
    ret
WndProc endp

end start




