section .text
BITS 16
disk_buffer     equ 24576       ;why is this?

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
    ;cs+ds?!?
    
    mov     [bootdisk],dl   ; save the drive num boot disk
    
    
    cld
    
  
    ; Clear screen
    mov     bh,0x30
    call    melos_clearscreen
    
    ; Present the loading screen
    mov     si,txt_loadingkernel
    call    melos_print_string


;     mov     cx,0
;repeat14:
;    mov     bx,myBuffer
;    mov     dl,128
;    mov     ax,cx
;    pusha
;    mov     si,txt_debug_kernel1
;    call    melos_print_string
;    popa
;    call    debug_print_ax_dec
;    call    debug_print_newline
;    call    melos_readsectortobuffer
;    call    debug_print_dashline
;    mov     bx,512
;    mov     si,myBuffer
;    call    melos_printnchars
;    call    melos_print_newline
;    call    debug_print_dashline
;    call    debug_freeze1
;    inc     cx
;    cmp     cx,1
;    jl      repeat14
    
;    mov     bx,myBuffer
;    mov     dl,128                      ; hardcoded for testing. change!
;    mov     ax,0
;    call    melos_readsectortobuffer
    
;   mov     si,txt_reservedforboot
;    call    melos_print_string
;    xor     ax,ax
;    mov     ax,word [myBuffer+14]
;    call    debug_print_ax_dec
;    call    melos_print_newline
    

;    mov     si,txt_partitiontype
;    call    melos_print_string
;    mov     si,myBuffer+53
;    mov     bx,8
;    call    melos_printnchars
;    call    melos_print_newline

    mov     si,txt_checkingFS
    call    melos_print_string

    mov     dl,0h
checknextfloppy:    
    mov     si,txt_debug_kernel1    ;debug
    call    melos_print_string

    xor     ax,ax
    mov     ah,15h
    int     13h
    jc      nomorefloppys
    mov     si,txt_foundfloppy
    call    melos_print_string
    shr     ax,8
    call    debug_print_ax_dec
    call    melos_print_newline

    mov     si,txt_debug_kernel2    ;debug
    call    melos_print_string
    
    inc     dl
    jmp     checknextfloppy
nomorefloppys:
    mov     dl,80h
checknextHD:    
    xor     ax,ax
    mov     ah,15h
    int     13h
    jc      nomoreHDs
    mov     si,txt_foundHD
    call    melos_print_string
    shr     ax,8
    call    debug_print_ax_dec
    call    melos_print_newline
    inc     dl
    jmp     checknextHD
nomoreHDs:



    mov     si,txt_loadingok
    call    melos_print_string
infiniteloop:
    jmp     infiniteloop
    


%INCLUDE "debugfunctions.asm"
%INCLUDE "screen_routines.asm"
%INCLUDE "fat12_routines.asm"


txt_loadingkernel   db 'Loading Ker(b)nel...',10,13,0
txt_loadingok       db 'Kernel loaded OK!',10,13,0
txt_partitiontype   db 'found partition type: ',0
txt_reservedforboot db 'Sectors reserved for boot: ',0
txt_debug_kernel1   db 'DEBUG 1',10,13,0
txt_debug_kernel2   db 'DEBUG 2',10,13,0
txt_checkingFS      db 'Identifying file systems...',10,13,0
txt_foundfloppy     db 'Found floppy. Drive #',0
txt_foundHD         db 'Found HD. Drive #',0

bootdisk            db 0

times 1017-($-$$) db 0	; Pad remainder of kernel with 0s
db 'MELIEND'		; The end marker of kernel

section .bss
myBuffer    resb 512