;---------------------------
melos_fat16_getRootDirStart:
;---------------------------
;INPUT
;dl=drive
;bx=pointer to 512 byte buffer
;OUTPUT
    push    ax
    push    bx
        mov     ax,0                            ;read sector 0=boot sector
        call    melos_readlbasectortobuffer
        print_string txt_debug_nbytespblock
        add     bx,0x0b
        mov     ax,word[bx]
        print_ax_dec
        call    melos_print_newline    
    pop     bx
    pop     ax
ret

txt_debug_nbytespblock  db 'Number of bytes per block: ',0
txt_debug_nblockpalloc  db 'Number of blocks per allocation unit: ',0
txt_debug_nrootdirs     db 'Number of root directory entries: ',0