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


;####################################��������##############################

IDB_BOARD			EQU	       100            ;������Դ
BOARD_WIDTH         EQU        561
BOARD_HEIGHT        EQU        626

IDB_RED             EQU        101            ;�췽����	
IDB_BLACK			EQU        102            ;�ڷ�����
CHESS_WIDTH         EQU        50
CHESS_HEIGHT        EQU        50

BG_WIDTH            EQU        900              ;��������
BG_HEIGHT           EQU        900

ROWS				EQU        15				;15*15����
COLUMS				EQU		   15

IDB_START           EQU        101
IDB_OVER			EQU        102
IDB_BLOCK			EQU        1001
IDB_WALL			EQU        1002
IDB_FOOD            EQU        1003
IDB_SELECT          EQU        1004

SNAKE_TIMER_GAP           EQU        150                ;��ʱ��
SNAKE_TIMER_ID            EQU        100
DRAW_TIMER_GAP            EQU        25
DRAW_TIMER_ID             EQU        101
AUTO_TIMER_GAP           EQU        100
AUTO_TIMER_ID            EQU        102

ACTION_SIZE				  EQU        3

TES=4*************5



COR struct
	x		dd	?	;λ��
	y       dd  ?
COR ends


node STRUCT
    prev    DWORD   ? ; Pointer to the previous node
    x       DWORD   ? ; Data element
	y       DWORD   ? ; Data element
    next    DWORD   ? ; Pointer to the next node
node ENDS




;####################################��ʼ������##############################

.data
ClassName	db "GameWindowClass", 0
AppName		db "My Game", 0
snakefile	db "snake.txt", 0
intformat	db "%d %d %d %d",0
mode		db "r", 0
intbuffer	dd 4 dup(?)

scoreFmtStr  db 'Score: %lu', 0
wallFile	 db	'wall.model', 0



;####################################��������##############################

.data?
hInstance			HINSTANCE ?
CommandLine			LPSTR ?
hwnd				HWND ?

;���������
rseed					dd ?

start_bmp               DD ?
over_bmp                DD ?
block_bmp				DD ?
select_bmp				DD ?
wall_bmp				DD ?

board				    DWORD ROWS*COLUMS		dup(0)    ;�������� 0�յ�1ʳ��2ǽ3��
snake_head_ptr			DWORD					?         ;��ͷָ��
snake_tail_ptr			DWORD                   ?         ;��βָ��


blockBrush				dd						?
foodBrush				dd						?


game_state				DD  1				;0δ��ʼ��1��Ϸ��2��Ϸ������3������ͼǰ��ʾ��4������ͼ��,5�Զ�Ѱ·

game_score			    dd	2
snake_dir				dd  2               ;0,1,2,3 ��������
snake_state				dd  0				 ;0������1�Թ��ӣ�2��

food_pos_x				dd  ?
food_pos_y				dd  ?
	
; ����ͼ�׶�
draw_state              dd  ?			; ,0123���������ƶ���4���Ϊǽ��5���沢�˳�,6ɶ������
select_x                dd  ?
select_y				dd  ?

; Greedy Algorithm
board_virtual           DWORD ROWS*COLUMS		dup(0)    ;�������� 0�յ�1ʳ��2ǽ3��
v_snake_head_ptr			DWORD					?         ;��ͷָ��
v_snake_tail_ptr			DWORD                   ?         ;��βָ��
v_snake_dir				    dd  2  
v_snake_state				dd  ?                             ;0Ѳ��1ֹͣ
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
