;------------------------    
melos_readsectortobuffer:
;------------------------
;INPUT
;es:bx 512k buffer
;dl=drive
;ax=which logical sector to read
;OUT nothing
    pusha
        push ax
    
            ;start by reseting drive
            mov     ah,0    ;bios function=reset drive
            int     0x13    ;call bios
        pop ax
        jc      melos_IOError
                   
    ;read one sector
    ;mov     ax,1                        ; sector to start reading
    call    l2hts                       ; convert logic sector -> header,track,sector
   
    mov     dl,128
    mov     ah,02h                      ; func #2 of int 13h = read from disk
    mov     al,1                        ; n sectors to read
    int     13h                         ; call BIOS
    
   

    jc      melos_IOError

    popa
ret

melos_IOError:
    pusha
    mov     si,txt_IOError
    call    melos_print_string
    
    mov     ah,0x01
    mov     dl,0x0
    int     0x13
    cmp     ah,0x80
    je     tmploop
    mov si,myTempError
    call melos_print_string
    
    popa
tmploop:
    jmp tmploop
ret

l2hts:
; Calculate head, track and sector settings for int 13h
; INPUT AX=logical sector
; OUTPUT: correct registers for int 13h

    push    bx
    push    ax
        push    dx

            mov     bx,ax                       ; Save logical sector
            mov     dx,0                        ; First the sector
            div     word [SectorsPerTrack]
            add     dl,01h                      ; Physical sectors start at 1
            mov     cl,dl                       ; Sectors belong in CL for int 13h
            mov     ax,bx

            mov     dx,0                        ; Now calculate the head
            div     word [SectorsPerTrack]
            mov     dx,0
            div     word [Sides]
            mov     dh,dl                       ; Head/side
            mov     ch,al                       ; Track

        pop ax
        mov dl,al
    pop ax
    pop bx
ret    
    
txt_IOError db 'IO Error',10,13,0
myTempError db 'Drive timed out, assumed not ready',10,13,0
txt_debug1  db 'DEBUG #1',10,13,0
SectorsPerTrack		dw 18		; Sectors per track (36/cylinder)
Sides			dw 2		; Number of sides/heads
