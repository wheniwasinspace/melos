;Screen routines
melos_print_string:
    pusha                   ; save state of all registers
    mov     ah,0Eh          ; int10h 0E = print char
.printnextchar:
    lodsb                   ; Get char from string
    cmp     al,0            ; Is the char=null?
    je      .printcomplete  ; Yes, finished printing,bail
    int     10h             ; Otherwise, call BIOS and print char
    jmp     .printnextchar  ; And move on to next char
.printcomplete:
    popa                    ; restore state of all registers
    ret                     ; return
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