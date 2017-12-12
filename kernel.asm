section .text
BITS 16

%macro print_char 1
    push    ax
    mov     al,%1
    call    melos_print_char
    pop     ax
%endmacro

%macro print_string 1
    mov     si,%1
    call    melos_print_string
%endmacro

%macro print_nchars 2
    push    si
    push    bx
        mov     si,%1
        mov     bx,%2
        call    melos_print_nchars
    pop     bx
    pop     si
%endmacro

%macro print_ax_dec 0
push    si
    mov     si,tmp6byteBuffer
    call    melos_print_ax_dec    
pop     si
%endmacro


os_call_vectors:
    jmp     os_main                 ; 0000h -- Called from bootloader
    jmp     melos_print_string      ; 0003h
    jmp     melos_clearscreen       ; 0006h

; ------------
; Kernel start
; ------------
os_main:
    cli                     ; Clear interrupts
    mov     ax,0
    mov     ss,ax           ; Set stack segment
    mov     sp,0FFFFh       ; Set stack pointer to end of segment
    sti                     ; Restore interrupts


    mov     ax,2000h        ; ax=adress where kernel is loaded
    mov     ds,ax           ; Set start of data segment
    mov     es,ax           ; and extra segment
    mov     fs,ax           ; general segment register #1
    mov     gs,ax           ; general segment register #2
    ;cs?!?
    
    mov     [bootdisk],dl   ; save the drive num boot disk
    
    
    cld     ;normal string operations = forward in mem
    
  
    ; Clear screen
    mov     bh,0x30
    call    melos_clearscreen
    
    ; Present the loading screen
    mov     si,txt_loadingkernel
    call    melos_print_string
 
    mov     si,txt_checkingFS
    call    melos_print_string
   
   xor     dx,dx                    ; dl=0h + wipe dh
checknextfloppy:
    xor     ax,ax
    mov     ah,0x15                 ;BIOS func: get disk type
    push    dx                      ;gets destroyed by int0x13
        int     0x13                ;call BIOS
        jc      nomorefloppys
    pop     dx
    
    print_string txt_foundfloppy
    mov     ax,dx
    print_ax_dec
    ;let's check what file system this floppy has
    print_char '('
    mov     bx,myBuffer
    mov     di,resb_filesystem
    call    melos_disk_isDiskReady  ;check if this is working and make a jump if not ready
    call    melos_getFloppyFileSystem
    print_nchars resb_filesystem,8
    print_char ')'
    
    call    melos_print_newline
    inc     dl
    jmp     checknextfloppy
nomorefloppys:
    mov dl,80h
    mov ax,0
    mov bx,myBuffer
    call melos_readlbasectortobuffer

    ;retrieve the number of fixed disks
    xor     ax,ax
    call    melos_diskop_getnfixeddisks
    add     al,80h  ;al=max drive number
    xor     dx,dx
    mov     dl,80h  ;dl=first drive number
checknextHD:
    cmp     dl,al
    jae     nomoreHDs   ;jump above or equal, ie if we've done all disks
    print_string txt_foundHD
    mov     ax,dx
    print_ax_dec
    call    melos_canBIOShandleLBA
    cmp     ah,0xFF
    je      noLBA
    print_string txt_LBAenabled
    jmp     checkFS
noLBA:
    print_string txt_LBAnotEnabled
checkFS:
    mov     di,resb_filesystem
    mov     bx,myBuffer
    call    melos_getFixedDiskFileSystem
    print_char '('
    print_nchars resb_filesystem,8
    print_char ')'

    call    melos_print_newline
    inc     dl
    jmp     checknextHD
nomoreHDs:
    print_string txt_loadingok
    

    mov     dl,0x80 ;HARDCODED FOR TESTING
    mov     bx,myBuffer
    call    melos_fat16_getRootDirStart

    
infiniteloop:
    jmp     infiniteloop
    


%INCLUDE "debugfunctions.asm"
%INCLUDE "screen_routines.asm"
%INCLUDE "disk_routines.asm"
%INCLUDE "fat12_routines.asm"
%INCLUDE "fat16_routines.asm"



txt_loadingkernel   db 'Loading Ker(b)nel...',10,13,0
txt_loadingok       db 'Kernel loaded OK!',10,13,0
txt_partitiontype   db 'found partition type: ',0
txt_reservedforboot db 'Sectors reserved for boot: ',0
txt_debug_kernel1   db 'DEBUG 1',10,13,0
txt_debug_kernel2   db 'DEBUG 2',10,13,0
txt_checkingFS      db 'Identifying file systems...',10,13,0
txt_foundfloppy     db 'Found floppy. Drive #',0
txt_foundHD         db 'Found HD. Drive #',0
txt_nfixeddisks     db 'Number of fixed disks installed: ',0
txt_LBAenabled      db ' LBA mode ',0
txt_LBAnotEnabled   db ' CHS mode ',0


bootdisk            db 0

Low6bits            db 00111111b        ; bitmask to get 6 lowest bit of a byte

times 2553-($-$$) db 0	; Pad remainder of kernel with 0s 5 sectors need to match this in bootloader
db 'MELIEND'		; The end marker of kernel

section .bss
resb_filesystem resb 8
tmp6byteBuffer  resb 6
myBuffer        resb 512