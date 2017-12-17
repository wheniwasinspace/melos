;---------------------------
melos_fat12_getRootDirStart:
;---------------------------
;INPUT
;dl=drive
;bx=pointer to 512 byte buffer
;OUTPUT ax=start sector of ROOT_DIR
    push    bx
    push    cx
    push    dx
        mov     ax,0    
        mov     cx,1                                ;PUSH IT OUR MAKE INPUT
        call    melos_readsectortobuffer
        mov     ax,word[bx+0x0e]                    ;n Sectors reserved for boot
        mov     cx,ax
        ;--
        pusha
            print_string txt_debug_reservedsectors
            print_ax_dec
            call melos_print_newline
            
        popa
        ;--
        mov     ah,0                        ;clear fist byte
        mov     al,byte[bx+0x10]            ;numbers of FATs
        ;--
        pusha
            print_string txt_debug_nFATs
            print_ax_dec
            call melos_print_newline
            
        popa
        ;--        
        mov     dx,ax
        mov     ax,word[bx+0x16]            ;size of 1 FAT
        ;--
        pusha
            print_string txt_debug_FATsize
            print_ax_dec
            call melos_print_newline
        popa
        ;--        
        mul dx
        add ax,cx                           ;nFats*FATsize+reserved for boot
    pop     dx
    pop     cx
    pop     bx
ret
txt_debug_fat12getrootdir        db 'in melos_fat12_getRootDirStart',10,13,0