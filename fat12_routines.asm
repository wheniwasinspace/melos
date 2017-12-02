;------------------------    
melos_readsectortobuffer:
;------------------------
;IN es:bx 512k buffer
;   cl=which sector to read
;OUT nothing
    pusha
    ;mov dword [es:bx],'PROV'
    xor     ah,ah   ;floppy
    int     0x13    ;reset floppy
    
    mov     ah,0x2  ;BIOS function: read sector
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
    
    mov     ah,0x01
    mov     dl,0x0
    int     0x13
    cmp     ah,0x09
    jne     tmploop
    mov si,myTempError
    call melos_print_string
    
    popa
tmploop:
    jmp tmploop
ret
    
txt_IOError db 'IO Error',10,13,0
myTempError db 'this is the error',10,13,0