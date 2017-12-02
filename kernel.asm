

section .text
BITS 16
disk_buffer     equ 24576       ;vad ska den här vara?

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

    cld                     ; clear direction flag

    mov     ax,2000h        ; ax=adress where kernel is loaded
    mov     ds,ax           ; Set start of data segment
    mov     es,ax           ; and extra segment
    mov     fs,ax           ; new general segment register #1
    mov     gs,ax           ; new general segment register #2
    ;cs+ds?!?

    mov     bh,0x30
    call    melos_clearscreen
    
    mov     si,txt_loadingkernel
    call    melos_print_string
    
 debug_here:
    mov     ax,2000h
    mov     es,ax
    mov     bx,myBuffer
    mov     cl,19
    call    melos_readsectortobuffer
    mov     si,myBuffer
    call    melos_print_string
    
    mov     si,txt_loadingok
    call    melos_print_string


infiniteloop:
    jmp     infiniteloop


%INCLUDE "screen_routines.asm"
%INCLUDE "fat12_routines.asm"


txt_loadingkernel   db 'Loading Ker(b)nel...',10,13,0
txt_loadingok       db 'Kernel loaded OK!',10,13,0

times 1017-($-$$) db 0	; Pad remainder of kernel with 0s
db 'MELIEND'		; The end marker of kernel

section .bss
myBuffer    resb 512