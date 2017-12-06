my_segment  EQU 0040h
my_offset   EQU 0075h
;---------------------------
melos_diskop_getnfixeddisks:
;---------------------------
;INPUT none
;OUTPUT al=number of fixed disks detected by BIOS
    push    bx
    push    es
        mov     bx,my_segment
        mov     al, [es:my_offset]
    pop     es
    pop     bx
ret


