SEGMENT_BIOS                EQU 0040h
OFFSET_BIOS_FIXED_DRIVES    EQU 0075h
;----------------------
melos_disk_isDiskReady:
;----------------------
;INPUT dl=disk
pusha
push es
    mov ax,0
    mov es,ax
    mov di,0
    mov     ah,8            ;bios function=get drive parameters
    int     0x13            ;call bios
    jc      melos_FatalIOError
pop es
popa
ret
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
;INPUT dl=drive es:bx = 512K buffer,
;di = pointer to buffer for 8 byte identifier
;OUTPUT 
    push    ax
    push    cx
    push    si
    push    bx
        mov     ax,0                            ;read sector 0
        call    melos_readlbasectortobuffer     ;read sector 0 to buffer
        add     bx,454                          ;index partition 1 start
        mov     ax,  [bx]                       ;ax=start sector of filesystem #1
    pop     bx
    push    bx
        call    melos_readlbasectortobuffer     ;read the sector with fs info
        add     bx,54                           ;start of 8 bytes fs descriptor
        mov     si, bx                          ;si=pointer to read buffer
        mov     cx,8                            ;we want to copy 8 bytes
        rep movsb                               ;copy cx chars from si to di
    pop     bx
    pop     si
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
        mov     cx,2                        ;retries left
melos_readsectortobufferTryAgain:        
        call    melos_disk_resetdrive
        ;read one sector
        call    l2hts                       ; convert logic sector -> header,track,sector
        mov     ah,02h                      ; func #2 of int 13h = read from disk
        mov     al,1                        ; n sectors to read
        int     13h                         ; call BIOS
        jnc     melos_readsectortobufferDone
        dec     cx
        cmp     cx,0                        ;this can prob be optimized away?
        jg      melos_readsectortobufferTryAgain 
melos_readsectortobufferDone:
    popa
ret

melos_FatalIOError:
    print_char 'E'
    print_char 'E'
    print_char 'E'
    print_string txt_IOError
    
    mov     ah,0x01
    mov     dl,0x0
    int     0x13
    cmp     ah,0x80
    je      melos_disk_fatalErrorLoop
    mov     si,myTempError
    call    melos_print_string
melos_disk_fatalErrorLoop:
    jmp melos_disk_fatalErrorLoop
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
melos_readlbasectortobuffer:
;---------------------------
;reads one sector from an LBA drive into memory
;INPUT dl=drive ax=sector to read bx=pointer to buffer
;OUTPUT
pusha
    mov     si,DAP
    mov     [dap_startsector], ax ;HOW TO HANDLE LARGER SECTOR NUMBERS?
    mov     [dap_offset],word myBuffer
    mov     [dap_segment],word ds
    mov     cx,2
melos_readlbasectortobufferretry:
    call    melos_disk_resetdrive
    mov     ah,42h      ;INT 13h AH=42h: Extended Read Sectors From Drive
    int     13h
    jnc     melos_readlbasectortobufferdone
    dec     cx
    cmp     cx,0        ;can prob be optimized away?
    jg      melos_readlbasectortobufferretry
melos_readlbasectortobufferdone:
popa
ret

;----------------------
melos_canBIOShandleLBA:
;----------------------
;checks if BIOS can adress hard drives with LBA.
;INPUT none dl=drive to check
;OUTPUT ah=major version of extension.
    mov     ah,0x41      ;BIOS function Extensions - installation check
    mov     bx,0x55AA   ;reversed order after call if extensions ok
    int     0x13        ;call BIOS
    jc      melos_disk_noLBA    ;carry flag=wrong drive number or strange BIOS, bail
    cmp     bx,0xAA55   ;bits reversed?
    jne     melos_disk_noLBA     ;extrensions not OK on this drive, bail
    ;Extensions installed. Yay
ret
melos_disk_noLBA:
    mov     ah,0xFF
ret

;---------------------
melos_disk_resetdrive:
;---------------------
;INPUT dl=drive
;OUTPUT none
    push ax
        ;start by reseting drive
        mov     ah,0    ;bios function=reset drive
        int     0x13    ;call bios
    pop ax
ret

    
    


    
txt_IOError db 'Fatal IO Error. System suspended',10,13,0
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
dap_startsector dq 0        ;starting segment to read(8bytes)       8 test 249=msdos