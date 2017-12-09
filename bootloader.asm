jmp     start
nop
; ------------------------------------------------------------------
; Disk description table, to make it a valid floppy
; Note: some of these values are hard-coded in the source!
; Values are those used by IBM for 1.44 MB, 3.5" diskette


OEM_ID                  db "MELIZZOS"       ; Disk label                                index 3
nBytesPerSector         dw 512              ; Bytes per sector                          index 11
nSectorsPerCluster      db 1                ; Sectors per cluster                       index 13
ReservedForBoot         dw 1                ; Reserved sectors for boot record          index 14
NoOfFats                db 2                ; Number of copies of the FAT               index 16
RootDirEntries          dw 224              ; Number of entries in root dir             index 17
                                            ; (224 * 32 = 7168 = 14 sectors to read)
LogicalSectors          dw 2880             ; Number of logical sectors                 index 18
MediumByte              db 0F0h             ; Medium descriptor byte                    index 21
SectorsPerFat           dw 9                ; Sectors per FAT                           index 22
nSectorsPerTrack        dw 18               ; Sectors per track (36/cylinder)           index 24
Sides                   dw 2                ; Number of sides/heads                     index 26
HiddenSectors           dd 0                ; Number of hidden sectors                  index 28
LargeSectors            dd 0                ; Number of LBA sectors                     index 32
DriveNo                 dw 0                ; Drive No: 0                               index 36
Signature               db 41               ; Drive signature: 41 for floppy            index 38
VolumeID                dd 00000000h        ; Volume ID: any number                     index 39
VolumeLabel             db "MELIZZOS   "    ; Volume Label: any 11 chars                index 43
FileSystem              db "FAT12   "       ; File system type: don't change!           index 54



start:
    mov     ax,07C0h                    ; Set up 4K stack space after this bootloader
    add     ax,288                      ; (4096 + 512) / 16 bytes per paragraph
    mov     ss,ax
    mov     sp,4096

    mov     ax,07C0h                    ; Where we are loaded in memory
    mov     ds,ax                       ; Set data segment 
        
    mov     [disk],dl                   ; disk=identifier of which disk was booted
    
    mov     si,txt_bootloader_welcome1   ; put welcome string in SI
    call    print_string                ; print it...
    
        
    mov     ah,8                        ; 8=get drive parameters for current disk(the one we are booting from)
    int     13h                         ; Call BIOS
    jc      fatal_disk_error            ; if BIOS failed carry flag is set
    and     cx,[Low6bits]               ; get highest sector number
    mov     [nSectorsPerTrack],cx       ; save that to variable
    movzx   dx,dh                       ; Maximum head number
    add     dx,1                        ; +1 since they start at 0
    mov     [Sides],dx                  ; save number of sides to variable

    mov     ax,2000h                    ; Point out to where in mem we want to store the kernel we read from file
    mov     es,ax                       ; put pointer in ES
    mov     bx,0000h                    ; offset = 0

    mov     ax,1                        ; sector to start reading
    call    l2hts                       ; convert logic sector -> header,track,sector
    mov     ah,2                        ; func #2 of int 13h = read from disk
    mov     al,4                        ; n sectors to read
    int     13h                         ; call BIOS
    jc      fatal_disk_error            ; carry flag means BIOS had a problem 
        
    mov     si,read_ok                  ; print msg that copy disk->mem went ok.
    call    print_string
    
    mov     si,txt_startingOS
    call    print_string
    
    ;remove this after beta
;    mov     cx,0x2d                      ; 3...
;    mov     dx,0xc6c0                    ; ...seconds
    mov     cx,0xf                      ;1 sec
    mov     dx,0x4240
    mov     ah,86h                      ;timer interupt
    int     15h                         ;call BIOS

    ;should probably check first thta we really found a valid kernel
    mov     dl,byte[disk]               ; so Kernel knows what disk is booting up
    jmp     2000h:0000h                 ; Kernel loaded from disc to mem, execute it!
          
fatal_disk_error:
    mov     si,disk_error               ; If not, print error message and reboot
    call    print_string                
    jmp     reboot                     
reboot:
    mov     ax,0                        ; 16h 0h = read keyboard input
    int     16h                         ; Call BIOS
    mov     ax,0                        ; 19h 0h = reboot computer
    int     19h                         ; Call BIOS

;Strings
    txt_bootloader_welcome1 db 'MelizzOS(16bit) bootloader 1.0',10,13,0  
    txt_startingOS          db 'Starting the OS...',10,13,0
    disk_error              db 'Can not read the disc :(',10,13,0
    read_ok                 db 'disc->memory OK!',10,13,0
    disk                    db 0        ; Boot device number
    txt_bootingfrom         db 'Booting from device: ',0
    

print_string:
; INPUT SI=pointer to null terminated string
    mov     ah,0Eh                      ; int 10h 0e 'print char' function
.repeat:
    lodsb                               ; get character from string
    cmp     al,0                        ; null char?
    je      .done                       ; yes, bail
    int     10h                         ; Otherwise, call BIOS,print char
    jmp     .repeat
.done:
    ret

l2hts:
; Calculate head, track and sector settings for int 13h
; IN: logical sector in AX
; OUT: correct registers for int 13h
    push    bx
    push    ax

    mov     bx,ax                       ; Save logical sector
    mov     dx,0                        ; First the sector
    div     word [nSectorsPerTrack]
    add     dl,01h                      ; Physical sectors start at 1
    mov     cl,dl                       ; Sectors belong in CL for int 13h
    mov     ax,bx

    mov     dx,0                        ; Now calculate the head
    div     word [nSectorsPerTrack]
    mov     dx,0
    div     word [Sides]
    mov     dh,dl                       ; Head/side
    mov     ch,al                       ; Track

    pop     ax
    pop     bx

    mov     dl, byte [disk]             ; Set correct device

    ret
    
    Low6bits            db 00111111b        ; bitmask to get 6 lowest bit of a byte

    times 510-($-$$) db 0               ; Pad remainder of boot sector with 0s
    dw 0xAA55                           ; The standard PC boot signature