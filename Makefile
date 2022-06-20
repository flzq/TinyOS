.PHONY: build write clean

mbr_source=mbr.s 
mbr_target=mbr.bin
loader_source=loader.s 
loader_target=loader.bin
hard_disk=os.img

build:
	nasm -f bin $(mbr_source) -o $(mbr_target)
	
write:
	dd if=$(mbr_target) of=$(hard_disk) bs=512 count=1 conv=notrunc
	
clean:
	rm $(mbr_target)