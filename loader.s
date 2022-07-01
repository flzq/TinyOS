%include "boot.inc"

section loader vstart=LOADER_BASE_ADDR

; 进入加载器, 调用print_str_real打印
mov cx, loader_start_str_end - loader_start_str_begin ; 字符串长度
mov bp, loader_start_str_begin ; 字符串起始位置
mov dh, 0x2 ; 在第2行打印字符
mov dl, 0x0 ; 从第0列开始打印字符
call print_str_real

; 利用BIOS 0x15中断的0xe820子功能号获取内存布局信息
detect_memory:
    ; es:di初始化为内存布局ards结构体数组位置
    mov ax, 0
    mov es, ax 
    mov di, ards_arr

    xor ebx, ebx ; 先置为0
    mov edx, 0x534d4150 ; 固定签名标记
.next:
    mov eax, 0xe820 ; 0xe820子功能号
    mov ecx, 20 ; 每个ards结构体的大小为20字节
    int 0x15
    jc .error ; 如果CF置位, 表示调用出错

    add di, cx ;将数组指针指向下一个结构体
    inc dword [ards_count] ; ards结构体数量加一

    ; 是否是最后一个结构体
    cmp ebx, 0
    jz .success ; 是最后一个ards, 则跳转
    jmp .next ; 不是最后一个, 继续检测
.error: ; 内存检测出错
    mov cx, detect_memory_error_end - detect_memory_error_begin
    mov bp, detect_memory_error_begin
    mov dh, 0x4 
    mov dl, 0x0
    call print_str_real
    hlt ; 检测出错, cpu暂停
    jmp $ 
.success: ; 内存检测成功
    mov cx, detect_memory_success_end - detect_memory_success_begin
    mov bp, detect_memory_success_begin
    mov dh, 0x4 
    mov dl, 0x0
    call print_str_real

; 进入保护模式
; 打开A20地址线
in al, 0x92
or al, 0000_0010b
out 0x92, al
; gdtr寄存器加载全局描述符表的信息(界限和地址)
lgdt [GDT_PTR]
; 启动保护模式: 将cr0寄存器的PE位置为1
mov eax, cr0
or eax, 0x1 
mov cr0, eax
; 刷新流水线
jmp selector_code:protect_mode


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


[bits 32]
protect_mode:
    ; 用数据段选择子初始化段寄存器
    mov ax, selector_data
    mov ds, ax
    mov es, ax 
    mov fs, ax 
    mov gs, ax
    mov ss, ax 
    mov esp, LOADER_BASE_ADDR ; 修改栈顶

    ; 打印字符串"PM", 表示进入保护模式
    mov byte [gs:0xb8000+480], 'P'
    mov byte [gs:0xb8000+481], 0x09
    mov byte [gs:0xb8000+482], 'M'
    mov byte [gs:0xb8000+483], 0x09

    
; 阻塞
jmp $




; 设置全局描述符表及选择子
; 代码段和数据段选择子
selector_code equ (1 << 3)
selector_data equ (2 << 3)
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

loader_start_str_begin:
    db 'loader start...'
loader_start_str_end:

; 内存检测出错字符串
detect_memory_error_begin:
    dd 'detect memory error'
detect_memory_error_end:
; 内存检测成功字符串
detect_memory_success_begin:
    dd 'detect memory success'
detect_memory_success_end:

; 存储内存相关信息
; 利用BIOS 0x15中断的0xe820子功能号获取内存布局信息
; 内存布局信息以ards结构存储
ards_count: ; ards结构体数量
    dd 0
ards_arr: ;ards结构数组, 存储ards结构的内存布局信息