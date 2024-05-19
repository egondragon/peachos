[BITS 16]
[ORG 0x7c00]

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

_start:
    jmp start
    nop

    times 3 + 59 db 0
    dw 0xaa55

start:
    jmp 0:step2

step2:
    cli ; Clear Interrupts
    mov ax, 0x00
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

.load_protected:
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:load32

; Global Descriptor Table (GDT)
gdt_start:
gdt_null:
    dd 0x0
    dd 0x0

gdt_code:
    dw 0xffff   ; Segment limit first 0 - 15 bits
    dw 0        ; Base first 0 - 15 bits
    db 0        ; Base 16-23 bits
    db 10011010b ; Access byte (present, ring 0, code segment, executable, readable)
    db 11001111b ; Flags (granularity, 32-bit, limit 16-19)
    db 0        ; Base 24-31 bits

gdt_data:
    dw 0xffff   ; Segment limit first 0 - 15 bits
    dw 0        ; Base first 0 - 15 bits
    db 0        ; Base 16 - 23 bits
    db 10010010b ; Access byte (present, ring 0, data segment, writable)
    db 11001111b ; Flags (granularity, 32-bit, limit 16-19)
    db 0        ; Base 24-31 bits

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

[BITS 32]
load32:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Setup stack
    mov ebp, 0x90000
    mov esp, ebp

    ; Load kernel from disk
    mov eax, 1          ; LBA start sector
    mov ecx, 1          ; Number of sectors to read
    mov edi, 0x100000   ; Load address
    call ata_lba_read

    ; Jump to loaded kernel
    jmp CODE_SEG:0x100000

ata_lba_read:
    pushad
    mov ebx, eax ; Backup LBA
    shr eax, 24
    or al, 0xe0 ; Select the master drive
    mov dx, 0x1f6
    out dx, al
    mov eax, ecx ; Send the number of sectors to read
    mov dx, 0x1f2
    out dx, al
    mov eax, ebx ; Send the LBA
    mov dx, 0x1f3
    out dx, al
    shr eax, 8
    mov dx, 0x1f4
    out dx, al
    shr eax, 8
    mov dx, 0x1f5
    out dx, al
    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

.next_sector:
    push ecx
.try_again:
    mov dx, 0x1f7
    in al, dx
    test al, 8
    jz .try_again
    mov ecx, 256
    mov dx, 0x1f0
    rep insw
    pop ecx
    loop .next_sector
    popad
    ret

times 510-($ - $$) db 0
dw 0xAA55
