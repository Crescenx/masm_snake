;####################################.inc##############################

include windows.inc
include user32.inc
include kernel32.inc
include shell32.inc
include comctl32.inc
include gdi32.inc
include comdlg32.inc
include	masm32.inc 

;####################################.lib##############################

includelib user32.lib
includelib kernel32.lib
includelib shell32.lib
includelib comctl32.lib
includelib gdi32.lib
includelib comdlg32.lib
includelib masm32.lib


;####################################常量声明##############################

IDB_BOARD			EQU	       100            ;棋盘资源
BOARD_WIDTH         EQU        561
BOARD_HEIGHT        EQU        626

IDB_RED             EQU        101            ;红方棋子	
IDB_BLACK			EQU        102            ;黑方棋子
CHESS_WIDTH         EQU        50
CHESS_HEIGHT        EQU        50

BG_WIDTH            EQU        900              ;窗口数据
BG_HEIGHT           EQU        900

ROWS				EQU        15				;15*15背景
COLUMS				EQU		   15

IDB_START           EQU        101
IDB_OVER			EQU        102
IDB_BLOCK			EQU        1001
IDB_WALL			EQU        1002
IDB_FOOD            EQU        1003
IDB_SELECT          EQU        1004

SNAKE_TIMER_GAP           EQU        150                ;计时器
SNAKE_TIMER_ID            EQU        100
DRAW_TIMER_GAP            EQU        25
DRAW_TIMER_ID             EQU        101
AUTO_TIMER_GAP           EQU        100
AUTO_TIMER_ID            EQU        102

ACTION_SIZE				  EQU        3

TES=4*************5



COR struct
	x		dd	?	;位置
	y       dd  ?
COR ends


node STRUCT
    prev    DWORD   ? ; Pointer to the previous node
    x       DWORD   ? ; Data element
	y       DWORD   ? ; Data element
    next    DWORD   ? ; Pointer to the next node
node ENDS




;####################################初始化数据##############################

.data
ClassName	db "GameWindowClass", 0
AppName		db "My Game", 0
snakefile	db "snake.txt", 0
intformat	db "%d %d %d %d",0
mode		db "r", 0
intbuffer	dd 4 dup(?)

scoreFmtStr  db 'Score: %lu', 0
wallFile	 db	'wall.model', 0



;####################################待化数据##############################

.data?
hInstance			HINSTANCE ?
CommandLine			LPSTR ?
hwnd				HWND ?

;随机数种子
rseed					dd ?

start_bmp               DD ?
over_bmp                DD ?
block_bmp				DD ?
select_bmp				DD ?
wall_bmp				DD ?

board				    DWORD ROWS*COLUMS		dup(0)    ;表征世界 0空地1食物2墙3蛇
snake_head_ptr			DWORD					?         ;蛇头指针
snake_tail_ptr			DWORD                   ?         ;蛇尾指针


blockBrush				dd						?
foodBrush				dd						?


game_state				DD  1				;0未开始，1游戏，2游戏死亡，3制作地图前提示，4制作地图中,5自动寻路

game_score			    dd	2
snake_dir				dd  2               ;0,1,2,3 上下左右
snake_state				dd  0				 ;0正常，1吃果子，2死

food_pos_x				dd  ?
food_pos_y				dd  ?
	
; 画地图阶段
draw_state              dd  ?			; ,0123上下左右移动，4标记为墙，5保存并退出,6啥都不干
select_x                dd  ?
select_y				dd  ?

; Greedy Algorithm
board_virtual           DWORD ROWS*COLUMS		dup(0)    ;表征世界 0空地1食物2墙3蛇
v_snake_head_ptr			DWORD					?         ;蛇头指针
v_snake_tail_ptr			DWORD                   ?         ;蛇尾指针
v_snake_dir				    dd  2  
v_snake_state				dd  ?                             ;0巡游1停止
x_queue						dd 256 dup(?)
y_queue						dd 256 dup(?)
x_head						dd ?
x_tail						dd ?
y_head						dd ?
y_tail						dd ?
x_ele						dd ?
y_ele						dd ?
is_empty					dd ?
bfs_map						dd ROWS*COLUMS dup(?)
v_bfs_map					dd ROWS*COLUMS dup(?)
bfs_visited					dd ROWS*COLUMS dup(?)
v_bfs_visited				dd ROWS*COLUMS dup(?)

