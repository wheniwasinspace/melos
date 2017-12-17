;---------------------------
melos_fat16_getRootDirStart:
;---------------------------
;INPUT
;dl=drive
;bx=pointer to 512 byte buffer
;OUTPUT ax=start sector of ROOT_DIR
    push    bx
    push    cx
    push    dx
        mov     cx,1                                ;PUSH IT OUR MAKE INPUT
        call    melos_getFixedDiskStartOfPartition
        call    melos_readlbasectortobuffer
        mov     ax,word[bx+0x0e]            ;n Sectors reserved for boot
        mov     cx,ax
        mov     ah,0                        ;clear fist byte
        mov     al,byte[bx+0x10]            ;numbers of FATs
        mov     dx,ax
        mov     ax,word[bx+0x16]            ;size of 1 FAT
        mul dx
        add ax,cx                           ;nFats*FATsize+reserved for boot
    pop     dx
    pop     cx
    pop     bx
ret
