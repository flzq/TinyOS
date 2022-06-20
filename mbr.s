%include "boot.inc"
section mbr vstart=0x7c00

; 初始化寄存器
mov ax, cs ; 启动计算机时,cs初始化为0x0
mov ds, ax
mov es, ax
mov fs, ax
mov ss, ax
mov sp, 0x7c00 ; 0x7c00之前的一段内存可以作为栈空间

; 使用BIOS 0x06中断清屏
mov ax, 0x600
mov bx, 0x700
mov cx, 0
mov dx, 0x184f ; VGA文本模式中, 一行只能容纳80个字符, 一共25行, 下标从0开始
int 0x10

; 表示正在执行mbr的代码
; 显示 "MBRStart" 字符串
mov ax, 0xb800 ; 显存从0xb8000开始
mov gs, ax ; 设置用于访问显存的段基址寄存器
mov byte [gs:0x00], 'M'
mov byte [gs:0x01], 0000_1001b 
mov byte [gs:0x02], 'B'
mov byte [gs:0x03], 0000_1001b 
mov byte [gs:0x04], 'R'
mov byte [gs:0x05], 0000_1001b 
mov byte [gs:0x06], 'S'
mov byte [gs:0x07], 0000_1001b 
mov byte [gs:0x08], 't'
mov byte [gs:0x09], 0000_1001b 
mov byte [gs:0x0a], 'a'
mov byte [gs:0x0b], 0000_1001b 
mov byte [gs:0x0c], 'r'
mov byte [gs:0x0d], 0000_1001b 
mov byte [gs:0x0e], 't'
mov byte [gs:0x0f], 0000_1001b 

; 读取磁盘中存储的loader代码到物理内存0x900处, 之后跳转到该处继续运行
mov eax, LOADER_START_SECTOR ; loader程序起始扇区的lba地址
mov bx, LOADER_BASE_ADDR ; 将loader程序加载到该物理内存中
mov cx, 1 ; 读取1个扇区
call rd_disk_m_16

; 已经执行完了mbr的代码
; 显示 "MBREnd" 字符串
mov ax, 0xb800 ; 显存从0xb8000开始
mov gs, ax ; 设置用于访问显存的段基址寄存器
mov byte [gs:0xA0], 'M'
mov byte [gs:0xA1], 0000_1001b 
mov byte [gs:0xA2], 'B'
mov byte [gs:0xA3], 0000_1001b 
mov byte [gs:0xA4], 'R'
mov byte [gs:0xA5], 0000_1001b 
mov byte [gs:0xA6], 'E'
mov byte [gs:0xA7], 0000_1001b 
mov byte [gs:0xA8], 'n'
mov byte [gs:0xA9], 0000_1001b 
mov byte [gs:0xAa], 'd'
mov byte [gs:0xAb], 0000_1001b 

jmp LOADER_BASE_ADDR ; 跳转到物理地址0x900处, 执行loader代码

;-------------------------------------------------------------------------------
;功能:读取硬盘n个扇区
; 该代码为<<操作系统真象还原>> 3.6.1节P130页 中的代码
rd_disk_m_16:	   
;-------------------------------------------------------------------------------
				       ; eax=LBA扇区号
				       ; ebx=将数据写入的内存地址
				       ; ecx=读入的扇区数
      mov esi,eax	  ;备份eax
      mov di,cx		  ;备份cx
;读写硬盘:
;第1步：设置要读取的扇区数
      mov dx,0x1f2
      mov al,cl
      out dx,al            ;读取的扇区数

      mov eax,esi	   ;恢复ax

;第2步：将LBA地址存入0x1f3 ~ 0x1f6

      ;LBA地址7~0位写入端口0x1f3
      mov dx,0x1f3                       
      out dx,al                          

      ;LBA地址15~8位写入端口0x1f4
      mov cl,8
      shr eax,cl
      mov dx,0x1f4
      out dx,al

      ;LBA地址23~16位写入端口0x1f5
      shr eax,cl
      mov dx,0x1f5
      out dx,al

      shr eax,cl
      and al,0x0f	   ;lba第24~27位
      or al,0xe0	   ; 设置7～4位为1110,表示lba模式
      mov dx,0x1f6
      out dx,al

;第3步：向0x1f7端口写入读命令，0x20 
      mov dx,0x1f7
      mov al,0x20                        
      out dx,al

;第4步：检测硬盘状态
  .not_ready:
      ;同一端口，写时表示写入命令字，读时表示读入硬盘状态
      nop
      in al,dx
      and al,0x88	   ;第4位为1表示硬盘控制器已准备好数据传输，第7位为1表示硬盘忙
      cmp al,0x08
      jnz .not_ready	   ;若未准备好，继续等。

;第5步：从0x1f0端口读数据
      mov ax, di
      mov dx, 256
      mul dx
      mov cx, ax	   ; di为要读取的扇区数，一个扇区有512字节，每次读入一个字，
			   ; 共需di*512/2次，所以di*256
      mov dx, 0x1f0
  .go_on_read:
      in ax,dx
      mov [bx],ax
      add bx,2		  
      loop .go_on_read
      ret


times 510-($-$$) db 0x0

db 0x55, 0xaa
