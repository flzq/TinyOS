; mbr.s和loader.s的配置文件
LOADER_START_SECTOR equ 0x02 ; 加载器(loader)所在磁盘扇区的起始扇区lba地址
LOADER_BASE_ADDR equ 0x900 ; 将loader代码加载到物理内存0x900处