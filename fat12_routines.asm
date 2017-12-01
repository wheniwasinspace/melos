;-----------------    
melos_clearscreen:
;-----------------
;IN bh=color attribute
;OUT nothing
    pusha

    mov     ah,0x06         ;BIOS: scroll screen (CLS)
    mov     al,0x00         ;entire screen
    mov     cx,0            ;row,column upper left
    mov     dh,24;
    mov     dl,79;
    int     10h
    
    mov     ah,02h          ;BIOS: set cursor position
    mov     bh,0            ;page=0
    mov     dh,0            ;row
    mov     dl,0            ;column
    int     10h             ;call BIOS    
    
    popa
    ret