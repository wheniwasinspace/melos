;-----------------
debug_print_ax_dec:
;-----------------
;prints the content of AX as decimal integer
;IN ds:si=buffer to write to AX=integer to print
    pusha
    mov     bx,0            ;pointer to digit in buffer
    mov     cx,10000        ;10-base for highets digit
btoaloop:
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
    jne     writedigit      ;no. So it's not a trailing 0, continue to write
    cmp     ax,'0'          ;yes. Is it also the digit 0?
    je      btoaanowrite    ;yes. So this is a trailing 0. Jump away and do not prin.
writedigit:    
    mov     [si+bx], ax     ;writes digit to buffer
    inc     bx;             ;move to next byte in buffer
btoaanowrite:    
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
    jae     btoaloop        ;no. then rinse and repeat

    ;convertion completed, now let's write a null char to end of buffer
    mov     [si+bx], byte 0x0
  
    call    debug_print_string       
    popa
ret    

debug_print_string:
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
    
debug_print_newline:
    pusha
    mov     ah,0Eh
    mov     al,10
    int     10h
    mov     al,13
    int     10h
    popa
    ret
    
debug_print_dashline:
    pusha
        mov     bx,80
debug_printdashagain:        
        mov     ah,0Eh
        mov     al,'-'
        int     10h
        dec     bx
        cmp     bx,0
        ja      debug_printdashagain
    popa
ret   

debug_freeze1:
    pusha
        mov     cx,0xF                  ; 1...
        mov     dx,0x4240               ; ...seconds
        mov     ah,86h                  ;timer interupt
        int     15h                     ;call BIOS   
    popa
ret

debug_freeze3:
    pusha
        mov     cx,0x2d                 ; 3...
        mov     dx,0xc6c0               ; ...seconds
        mov     ah,86h                  ;timer interupt
        int     15h                     ;call BIOS   
    popa
ret