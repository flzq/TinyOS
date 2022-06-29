%include "boot.inc"

section loader vstart=LOADER_BASE_ADDR

; 调用print_str_real打印
mov cx, loader_end - loader_start ; 字符串长度
mov bp, loader_start ; 字符串起始位置
mov dh, 0x2 ; 在第2行打印字符
mov dl, 0x0 ; 从第0列开始打印字符
call print_str_real

; 阻塞
jmp $

; 实模式下通过BIOS int 0x10 中断的子功能0x13写字符串
; cx: 字符串长度
; bp: 字符串起始位置
; dh: 坐标行(一共25行, 标号0-24)
; dl: 坐标列
print_str_real:
    ; ah: 0x13 子功能号
    ; al: 0x01 字符串中只含显示字符，其显示属性在BL中。显示后，光标位置改变
    mov ax, 0x1301 ; 子功能号, 打印字符
    mov bx, 0x0009 ; bh:页号为0, bl:设置字符颜色
.next:
    int 0x10
    ret


; 设置全局描述符表
; 段描述符采用平坦模式, 粒度为4KB
; 存储全局描述符表位置, 用于lgdt命令加载GDT的信息至GDTR寄存器中
GDT_PTR:
    dw GDT_END - GDT_BASE - 1 ; 前2字节存储GDT的界限(即GDT的长度-1)
    dd GDT_BASE ; 后4字节存储GDT的起始地址
; 定义全局描述符表
GDT_BASE: ; 第0个段描述符: NULL描述符
	dd 0, 0 ; 第0个段描述符中的数据必须全为0
GDT_CODE: ; 代码段描述符
    dw 0xffff ; 段界限0-15位全为1
    dw 0 ; 采用平坦模式, 段基址0-15位全为0
    db 0 ; 采用平坦模式, 段基址16-23位全为0
    ; P-DPL-S-TYPE字段: P:1存在内存中-DPL:0特权级为0-S:1非系统段-TYPE:代码段/非一致性/可读/未访问1010
    db 1_00_1_1010b
    ; G-D/B-L-AVL-段界限: G(1)4K粒度-32位(1)-32位代码(0)-AVL(0)-段界限16至19位(1111)
    db 1_1_0_0_1111b
    db 0; 采用平坦模式, 段基址24-31位全为0
GDT_DATA: ; 数据段描述符
    dw 0xffff ; 段界限0-15位全为1
    dw 0 ; 采用平坦模式, 段基址0-15位全为0
    db 0 ; 采用平坦模式, 段基址16-23位全为0
    ; P-DPL-S-TYPE字段: P:1存在内存中-DPL:0特权级为0-S:1非系统段-TYPE:数据段(0)/向上扩展(0)/可写(1)/未访问(0)1010
    db 1_00_1_0010b
    ; G-D/B-L-AVL-段界限: G(1)4K粒度-32位(1)-32位代码(0)-AVL(0)-段界限16至19位(1111)
    db 1_1_0_0_1111b
    db 0; 采用平坦模式, 段基址24-31位全为0
GDT_END:

loader_start:
    db 'loader start...'
loader_end: