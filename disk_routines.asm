SEGMENT_BIOS                EQU 0040h
OFFSET_BIOS_FIXED_DRIVES    EQU 0075h
;---------------------------
melos_diskop_getnfixeddisks:
;---------------------------
;INPUT none
;OUTPUT al=number of fixed disks detected by BIOS
    push    bx
    push    es
        mov     bx,SEGMENT_BIOS
        mov     es,bx
        mov     al, [es:OFFSET_BIOS_FIXED_DRIVES]
    pop     es
    pop     bx
ret


;-------------------------
melos_getFloppyFileSystem:
;-------------------------
;INPUT dl=drive es:bx=512k buffer 
;OUTPUT result in es:di buffer(8)
    push    ax
    push    si
    push    cx
        mov     ax,0
        call    melos_readsectortobuffer    ;read sector 0 to buffer
        add     bx,54                       ;index of FS info
        mov     si, bx                      ;si=pointer to read buffer
        mov     cx,8                        ;we want to copy 8 bytes
        rep movsb                           ;copy in buffer -> out buffer
    pop     cx
    pop     si
    pop     ax
ret

;----------------------------
melos_getFixedDiskFileSystem:
;----------------------------
;INPUT dl=drive es:bx = 512K buffer
;OUTPUT result in al
    push    ax
    push    cx;
        mov     ax,0
        call    melos_readsectortobuffer    ;read sector 0 to buffer
            pusha
            mov si,bx
            mov bx,512
            call melos_print_nchars
            popa
        add     bx,460                      ;index of FS info
        mov     al, byte [bx]
    pop     cx
    pop     ax
ret
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
