;------------------------    
melos_readsectortobuffer:
;------------------------
;IN es:bx 512k buffer
;   cl=which sector to read
;OUT nothing
    pusha
    xor     ah,ah   ;floppy
    int     0x13    ;reset floppy
    mov     ah,0x1  ;BIOS function: read sector
    mov     al,1    ;n sectors to read
    mov     ch,0    ;low 8 bits of cylinder number
    mov     dh,0    ;head number
    mov     dl,0    ;drive number
    int     0x13    ;call BIOS
    jc      melos_IOError ;
    popa
ret

melos_IOError:
    pusha
    mov     si,txt_IOError
    call    melos_print_string
    popa
    jmp infiniteloop
ret
    
txt_IOError db 'IO Error',10,13,0