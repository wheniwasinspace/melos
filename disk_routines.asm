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
    push    bx
        mov     ax,0
        call    melos_readsectortobuffer    ;read sector 0 to buffer
        add     bx,54                       ;index of FS info
        mov     si, bx                      ;si=pointer to read buffer
        mov     cx,8                        ;we want to copy 8 bytes
        rep movsb                           ;copy in buffer -> out buffer
    pop     bx
    pop     cx
    pop     si
    pop     ax
ret

;----------------------------
melos_getFixedDiskFileSystem:
;----------------------------
;INPUT dl=drive es:bx = 512K buffer
;OUTPUT al=result typ as int
;es:si = 8 byte identifier
    push    cx;
        push    ax
            mov     ax,0                        ;read sector 0
            call    melos_readsectortobuffer    ;read sector 0 to buffer
        pop     ax
         add     bx,450                    ;index of FS info
        mov     al, byte [bx]
    pop     cx
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
        call    l2hts                       ; convert logic sector -> header,track,sector
        mov     ah,02h                      ; func #2 of int 13h = read from disk
        mov     al,1                        ; n sectors to read
        int     13h                         ; call BIOS
        jc      melos_IOError
    popa
ret

melos_IOError:
    pusha
    print_char 'E'              ;DEBUG REMOVE
    print_string txt_IOError
    
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

;---------------------------
melos_test:
;---------------------------
pusha
    mov     ah,0x42
    mov     dl,0x80
    mov     si,bajsDAP
    mov     [BufferOffset],word myBuffer
    mov     [BufferSegment],word ds
    int     0x13
    jc      melos_IOError
    call debug_print_dashline
    print_nchars myBuffer,512
    call debug_print_dashline
popa
ret
;---------------------------
melos_readlbasectortobuffer:
;---------------------------
;reads one sector from an LBA drive into memory
;INPUT dl=drive ax=sector to read bx=pointer to buffer
;OUTPUT
pusha
    mov     si,DAP
;    mov     [dap_startsector], qword 0 ;store sector to read in DAP
    mov     [dap_offset],word myBuffer
    mov     [dap_segment],word ds
    mov     ah,42h      ;INT 13h AH=42h: Extended Read Sectors From Drive
    mov     dl,80h      ;REMOVE, THIS SHOULD NOT BE HARDCODED
    int     13h
    
    jc melos_IOError
        pusha;DEBUG
            call melos_print_newline
            call debug_print_dashline
            print_nchars myBuffer,512
            call melos_print_newline
            call debug_print_dashline
        popa
            pusha
            xor ax,ax
            mov al,[myBuffer+454]
            call melos_print_ax_dec
            popa
popa
ret
    
txt_IOError db 'IO Error',10,13,0
myTempError db 'Drive timed out, assumed not ready',10,13,0
txt_debug1  db 'DEBUG #1',10,13,0
SectorsPerTrack		dw 18		; Sectors per track (36/cylinder)
Sides			dw 2		; Number of sides/heads
DAP:
dap_size        db 0x10      ;size of DAP (10h for a short DAP)      1
dap_reserved    db 0x0        ;unused, should be                      1
dap_nsectors    dw 1        ;n sectors to read                      2
dap_offset      dw 0     ;                                       4
dap_segment     dw 0
dap_startsector dq 249        ;starting segment to read(8bytes)       8


;00h    BYTE    size of packet (10h or 18h)
;01h    BYTE    reserved (0)
;02h    WORD    number of blocks to transfer (max 007Fh for Phoenix EDD)
;04h    DWORD   -> transfer buffer
;08h    QWORD   starting absolute block number

bajsDAP:
size            db 0x10
reserved        db 0x0
sectorcount     dw 1
BufferOffset    dw 0
BufferSegment   dw 0
LBA             dq 0