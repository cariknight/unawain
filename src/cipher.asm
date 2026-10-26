; Programmer 2 - Encryption - RICA
; Module: CIPHER
; Included by gamelogic.asm (same folder). Do not add .model, PUBLIC, or END here.

; EncryptMsg
;   IN : SI = plaintext ('$' terminated), DI = output buffer, CL = shift (1..25)
;   OUT: Encrypted string at DI, '$' terminated
;   Shifts A-Z forward by CL; all other characters are copied unchanged.

EncryptMsg proc
    push bx
    push cx
    
    mov bl, cl
en_normalize:
    cmp bl, 26
    jb en_loop
    sub bl, 26
    jmp en_normalize
en_loop:
    mov al, [si]
    cmp al, '$'
    je en_done
    
    cmp al, 'A'
    jb en_copy
    cmp al, 'Z'
    ja en_copy
    
    sub al, 'A'
    add al, cl
    
    cmp al, 26
    jb en_ok
    sub al, 26
    
en_ok:
    add al, 'A'  
    
en_copy:
    mov [di], al
    inc si
    inc di
    jmp en_loop 
    
en_done:
    mov byte ptr [di], '$'
    
    pop cx
    pop bx
    ret
EncryptMsg endp

