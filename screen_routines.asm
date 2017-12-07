;Screen routines
melos_print_string:
    pusha                   ; save state of all registers
    mov     ah,0Eh          ; int10h 0E = print char
.printnextchar:
    lodsb                   ; Get char from string (DS:SI)
    cmp     al,0            ; Is the char=null?
    je      .printcomplete  ; Yes, finished printing,bail
    int     10h             ; Otherwise, call BIOS and print char
    jmp     .printnextchar  ; And move on to next char
.printcomplete:
    popa                    ; restore state of all registers
    ret                     ; return
    
;----------------
melos_print_char:
;----------------
;INPUT al = char to print
    pusha
        mov     ah,0Eh
        int     10h
    popa
ret    
    
melos_print_nchars:
;INPUT DS:SI=string bx=size of string
;print a fixed length string
    pusha                   ; save state of all registers
    mov     ah,0Eh          ; int10h 0E = print char
.printnextchar:
    lodsb                   ; Get char from string (DS:SI)
    cmp     bx,0            ; Have we printed everything yet?
    je      .printcomplete  ; Yes, finished printing,bail
    int     10h             ; Otherwise, call BIOS and print char
    dec     bx              ; One less char to print now
    jmp     .printnextchar  ; And move on to next char
.printcomplete:
    popa                    ; restore state of all registers
    ret                     ; return    
    
melos_print_newline:
    pusha
    mov     ah,0Eh
    mov     al,10
    int     10h
    mov     al,13
    int     10h
    popa
    ret

        
    
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
    
;-----------------
melos_print_ax_dec:
;-----------------
;prints the content of AX as decimal integer
;IN ds:si=buffer to write to AX=integer to print
pusha
    cmp     ax,0            ;is the number 0?
    jne     print_ax_dec_notzero
    mov     [si], byte '0'
    mov     bx,1
    jmp     print_ax_dec_nullterminatebuffer    
    print_ax_dec_notzero:
    mov     bx,0            ;pointer to digit in buffer
    mov     cx,10000        ;10-base for highets digit
    print_ax_dec_loop:
    push    ax;             ;save to stack
        mov     dx,0            ;clear dividend
        div     cx              ;ax=ax/bx (overwrites ax). ax now holds binary value of one digit
        push    ax              ;save the single digit on stack
        mul     cx              ;ax=ax*bx (ax=amount to remove from total)
        mov     dx,ax           ;dx=ax(see line above)
        pop     ax              ;restore ax (the single digit)
        add     ax,'0'          ;convert binary to ascii of the digit
    
        ;only write to output buffer if digit is not a trailing 0
        cmp     bx,0            ;is this the first digit we are printing?
        jne     print_ax_dec_writedigit   ;no. So it's not a trailing 0, continue to write
        cmp     ax,'0'          ;yes. Is it also the digit 0?
        je      print_ax_dec_btoaanowrite    ;yes. So this is a trailing 0. Jump away and do not prin.
        print_ax_dec_writedigit:    
        mov     [si+bx], ax     ;writes digit to buffer
        inc     bx;             ;move to next byte in buffer
        print_ax_dec_btoaanowrite:    
    pop     ax;             ;restore eax from stack (the binary representation)
    sub     ax,dx           ;ax=ax-dx (remove the divided value from the binary representation)
    push    ax;             ;save new binary representation to stack
    
        ;lets prepare 10-base for next digit
        mov     dx,0            ;clear dividend
        mov     ax,cx           ;move current 10-base to dividend
        mov     cx,10           ;we want to lower it by 10
        div     cx              ;divide 10-base by 10 (overwrites eax again)
        mov     cx,ax           ;bx= new 10-base for next lap
        pop     ax;             ;restore ax from stack (the remaining binary representation to convert)
    cmp     cx,1            ;are we doing the last digit?
    jae     print_ax_dec_loop        ;no. then rinse and repeat
    print_ax_dec_nullterminatebuffer:
    ;convertion completed, now let's write a null char to end of buffer
    mov     [si+bx], byte 0x0
  
    call    melos_print_string       
    popa
ret