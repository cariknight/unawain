; Programmer 3 - Puzzle Generation and Scoring - DAN
; Module: GAMELOGIC
; Responsibilities
; Create the word bank and select random words.
; Generate shift keys and construct each puzzle.
; Store the answer key and original ciphertext.
; Compare submitted answers with the correct plaintext.
; Update score, time bonuses, penalties, and round status.
; Code contribution: Random number generation, puzzle selection, answer validation, and scoring procedures.
; Dependencies: Uses Programmer 2s encryption procedure and returns puzzle data to Programmer 1.

; Sections marked "STAND-IN" so this file runs by itself. you can hiram naman if you wants 


.model small
.stack 100h

;CONSTANTS (tune the game here)


POINTS_CORRECT  equ 10      ; score added for a correct answer
TIME_BONUS      equ 30      ; seconds added for a correct answer
TIME_PENALTY    equ 5       ; seconds removed for a wrong answer
START_TIME      equ 60      ; (stand-in; Cleone owns the real start time)
FAST_LIMIT      equ 546     ; 30 seconds

                            ; UPDATE THIS WHEN ADDING WORD
SUBJ_COUNT      equ 20      ; must match number of entries in SubjTbl
VERB_COUNT      equ 20      ; must match VerbTbl
OBJ_COUNT       equ 20      ; must match ObjTbl

.data  
tBonus db 13,10,'TIME BONUS! +30 SECONDS',13,10,'$' ;FOR PLACEHOLDER ONLY| Can remove 

;SHARED GAME STATE 

PlainBuf    db 80 dup('$')  ; ANSWER KEY  (owned by Dan)
CipherBuf   db 80 dup('$')  ; ORIGINAL ciphertext / target shown to player (Dan)
WorkBuf     db 80 dup('$')  ; player's working copy (Dan fills at round start, Rica modifies it, Sam displays it)
                             
ShiftKeys   db 10 dup(0)    ; secret Caesar key 1..25 for EACH word (Dan)
                               
WordCount   db 0            ; number of words in the current sentence (Dan)
TmpWord     db 20 dup('$')  ; scratch: one plaintext word  (Dan, internal)
EncTmp      db 20 dup('$')  ; scratch: one encrypted word  (Dan, internal)
Score       dw 0            ; (Dan updates, Sam displays, Cleone saves)
Round       dw 1            ; (Dan updates)
RoundStatus db 0            ; 0 = in progress, 1 = last submit correct, 2 = wrong
TimeLeft    dw START_TIME   ; seconds (Cleone owns/ticks it, Dan adds/subtracts)
Seed        dw 0            ; random generator state (Dan)  
    
; TIMER
    
GameOver        db 0
HighScore       dw 0

LastTick        dw 0
TickAccum       dw 0

WordStartTick   dw 0
FastAnswer      db 0

HSFileName      db 'HISCORE.DAT', 0
HSBuffer        db 3 dup(0)
HSHandle        dw 0

; WORD BANK (all UPPERCASE, '$' terminated
; 20 of each type 
; Rules para grammatically keri ang lahat ng combo:
;   subjects = singular, verbs = 3rd person singular + transitive,
;   objects  = noun phrases. Hindi sila cohesive, pero tama ang grammar.
;   Keep every single word under 19 letters (TmpWord limit).

; Subjects
S1  db 'THE CAT$'
S2  db 'A DOG$'
S3  db 'THE TEACHER$'
S4  db 'MY BROTHER$'
S5  db 'THE ROBOT$'
S6  db 'A STUDENT$'
S7  db 'THE CHEF$'
S8  db 'OUR NEIGHBOR$'
S9  db 'A PIRATE$'
S10 db 'THE DOCTOR$'
S11 db 'MY SISTER$'
S12 db 'THE FARMER$'
S13 db 'A TOURIST$'
S14 db 'THE WIZARD$'
S15 db 'THE DRIVER$'
S16 db 'A SINGER$'
S17 db 'THE BAKER$'
S18 db 'MY COUSIN$'
S19 db 'THE ARTIST$'
S20 db 'A FISHERMAN$'

; Verbs
V1  db 'EATS$'
V2  db 'SEES$'
V3  db 'BUILDS$'
V4  db 'FINDS$'
V5  db 'LIKES$'
V6  db 'CARRIES$'
V7  db 'BUYS$'
V8  db 'DRAWS$'
V9  db 'HIDES$'
V10 db 'OPENS$'
V11 db 'WATCHES$'
V12 db 'PAINTS$'
V13 db 'FIXES$'
V14 db 'CLEANS$'
V15 db 'STEALS$'
V16 db 'KEEPS$'
V17 db 'LOVES$'
V18 db 'MAKES$'
V19 db 'SELLS$'
V20 db 'WRITES$'

; Objects
O1  db 'THE APPLE$'
O2  db 'A BOOK$'
O3  db 'THE GARDEN$'
O4  db 'A SECRET MESSAGE$'
O5  db 'THE TREASURE$'
O6  db 'A RED BALLOON$'
O7  db 'THE OLD CAMERA$'
O8  db 'A HEAVY BOX$'
O9  db 'THE BIG CAKE$'
O10 db 'A BROKEN CLOCK$'
O11 db 'THE GOLDEN KEY$'
O12 db 'A SMALL BOAT$'
O13 db 'THE NEW BRIDGE$'
O14 db 'A COLD DRINK$'
O15 db 'THE LONG LETTER$'
O16 db 'A PURPLE UMBRELLA$'
O17 db 'THE HIDDEN DOOR$'
O18 db 'A FUNNY STORY$'
O19 db 'THE LOUD RADIO$'
O20 db 'A SHINY COIN$'

; Pointer tables (one word = offset of one string)
SubjTbl dw offset S1,  offset S2,  offset S3,  offset S4,  offset S5
        dw offset S6,  offset S7,  offset S8,  offset S9,  offset S10
        dw offset S11, offset S12, offset S13, offset S14, offset S15
        dw offset S16, offset S17, offset S18, offset S19, offset S20

VerbTbl dw offset V1,  offset V2,  offset V3,  offset V4,  offset V5
        dw offset V6,  offset V7,  offset V8,  offset V9,  offset V10
        dw offset V11, offset V12, offset V13, offset V14, offset V15
        dw offset V16, offset V17, offset V18, offset V19, offset V20

ObjTbl  dw offset O1,  offset O2,  offset O3,  offset O4,  offset O5
        dw offset O6,  offset O7,  offset O8,  offset O9,  offset O10
        dw offset O11, offset O12, offset O13, offset O14, offset O15
        dw offset O16, offset O17, offset O18, offset O19, offset O20

crlf    db 13,10,'$'
tPlain  db 'Plain  : $'
tCipher db 'Cipher : $'
tKey    db 'Keys   : $'
tWrong  db 13,10,'-- submit WRONG (working copy untouched) --',13,10,'$'
tRight  db 13,10,'-- submit CORRECT (working copy = plaintext) --',13,10,'$'
tScore  db 'Score  : $'
tTime   db 'Time   : $'
tNew    db 'New round started, cipher: $'

.code
main:
    mov ax, @data
    mov ds, ax
    mov es, ax      
    
    mov HighScore, 0
    call StartGameTimer        

    call SeedRandom
    call NewRound
                                     
    ; show the round
    lea dx, tPlain
    call PrintStr
    lea dx, PlainBuf
    call PrintStr
    lea dx, crlf
    call PrintStr
    lea dx, tCipher
    call PrintStr
    lea dx, CipherBuf
    call PrintStr
    lea dx, crlf
    call PrintStr
    lea dx, tKey
    call PrintStr
    call PrintKeys
    lea dx, crlf
    call PrintStr        
   
    call DisplayGameTime
    call StartWordTimer   
    
    ; test 1: submit without decrypting 
    ;lea dx, tWrong
    ;call PrintStr
    ;call SubmitAnswer
    ;call ShowState

    ; test 2: player decrypted 
    lea dx, tRight
    call PrintStr
    lea si, PlainBuf
    lea di, WorkBuf
    call CopyStr   
    
    call CheckWordTime
    
    call SubmitAnswer       ; correct -> automatically next round
    
    ; Apply bonus only if the answer was correct and fast (less than 30 sec siya)
    cmp al, 1
    jne main_after_answer

    cmp FastAnswer, 1
    jne main_after_answer

    call ApplyTimeBonus
    call DisplayTimeBonus
    
main_after_answer:     
    call ShowState
    lea dx, tNew
    call PrintStr
    lea dx, CipherBuf
    call PrintStr
    lea dx, crlf
    call PrintStr
    
    call SaveHighScore        ; Saving High-score here, but not yet found in the file hehe just the concept... | not yet tested fully
    
    mov ax, 4C00h
    int 21h        
           
; RANDOM NUMBER GENERATION


; SeedRandom - call ONCE at program start (Sam, sa main mo ito ilagay).
; Seeds from the BIOS clock tick counter (INT 1Ah, AH=0), so every run is different. Kung wala ito, same sentence palag.
SeedRandom proc
    mov ah, 0
    int 1Ah                 
    mov Seed, dx
    xor Seed, cx
    ret
SeedRandom endp

; RandRange
;   IN : AX = n  (n >= 1)
;   OUT: AX = random number 0 .. n-1
;   Linear congruential generator. 
RandRange proc
    push bx
    push cx
    push dx
    mov cx, ax              
    mov ax, Seed
    mov bx, 25173
    mul bx                  ; DX:AX = Seed * 25173
    add ax, 13849
    mov Seed, ax            ; new seed
    mov al, ah              ; use high byte
    xor ah, ah
    xor dx, dx
    div cx                  ; DX = AX mod n
    mov ax, dx
    pop dx
    pop cx
    pop bx
    ret
RandRange endp


;  SENTENCE GENERATOR


; PickString
;   IN : BX = offset of a pointer table, AX = number of entries
;   OUT: SI = offset of the randomly chosen string
PickString proc
    push ax
    push bx
    call RandRange          
    shl ax, 1               
    add bx, ax
    mov si, [bx]
    pop bx
    pop ax
    ret
PickString endp

AppendStr proc
as_next:
    lodsb
    cmp al, '$'
    je as_done
    stosb
    jmp as_next
as_done:
    ret
AppendStr endp

GenSentence proc
    lea di, PlainBuf

    lea bx, SubjTbl
    mov ax, SUBJ_COUNT
    call PickString
    call AppendStr
    mov al, ' '
    stosb

    lea bx, VerbTbl
    mov ax, VERB_COUNT
    call PickString
    call AppendStr
    mov al, ' '
    stosb

    lea bx, ObjTbl
    mov ax, OBJ_COUNT
    call PickString
    call AppendStr

    mov al, '$'
    stosb
    ret
GenSentence endp


;  PUZZLE CONSTRUCTION
CopyStr proc
cp_loop:
    lodsb
    stosb
    cmp al, '$'
    jne cp_loop
    ret
CopyStr endp

; ResetWork - restore the working copy to the original ciphertext.
;   This is our "undo all" para sa mga player na nagkamali ng todo.
;   Sam you can hook it up as a RESET command.    

ResetWork proc
    lea si, CipherBuf
    lea di, WorkBuf
    call CopyStr
    ret
ResetWork endp

; EncryptPerWord - splits PlainBuf at the spaces; every word gets its OWN
;   random key (1..25) stored in ShiftKeys, is encrypted with rica's
;   EncryptMsg (one word at a time), and is appended to CipherBuf.
;   Spaces are copied through unchanged. Sets WordCount.   

EncryptPerWord proc
    lea si, PlainBuf
    lea di, CipherBuf
    mov WordCount, 0
    xor bx, bx              ; BX = word index (0-based)
epw_word:
    mov ax, 25
    call RandRange
    inc al                  ; 1..25 (0 would leave the word unencrypted, sayang)
    mov ShiftKeys[bx], al
    mov cl, al              ; CL = key for this word

 
    push di                 
    lea di, TmpWord
epw_copy:
    mov al, [si]
    cmp al, ' '
    je epw_endw
    cmp al, '$'
    je epw_endw
    mov [di], al
    inc si
    inc di
    jmp epw_copy
epw_endw:
    mov byte ptr [di], '$'
    pop di

    ;encrypt TmpWord -> EncTmp with rica's procedure ---
    push si                 ; protect my pointers/index from her code, just in case
    push di
    push bx
    lea si, TmpWord
    lea di, EncTmp
    call EncryptMsg         ; <-- rica: SI = in, DI = out, CL = shift
    pop bx
    pop di
    lea si, EncTmp
    call AppendStr          ; append encrypted word to CipherBuf (DI advances)
    pop si                  ; back to our position in PlainBuf

    inc bx
    inc WordCount

    mov al, [si]
    cmp al, '$'
    je epw_done
    mov al, ' '             ; it was a space: copy it through
    stosb
    inc si
    jmp epw_word
epw_done:
    mov al, '$'
    stosb
    ret
EncryptPerWord endp

;   FindWord - helper for Rica/Sam: locate word N inside WorkBuf.
;   IN : AL = word number (1-based)
;   OUT: SI = start of that word in WorkBuf, CF = 0
;        CF = 1 if there is no such word (invalid)
FindWord proc
    push bx
    mov bl, al
    cmp bl, 1
    jb fw_fail
    cmp bl, WordCount
    ja fw_fail
    lea si, WorkBuf
fw_skip:
    dec bl
    jz fw_ok
fw_scan:
    lodsb
    cmp al, ' '
    jne fw_scan
    jmp fw_skip
fw_ok:
    pop bx
    clc
    ret
fw_fail:
    pop bx
    stc
    ret
FindWord endp

; NewRound - Sam calls this to start the game and between rounds.
;   1. random sentence -> PlainBuf
;   2. each word gets its own random key -> ShiftKeys, encrypted -> CipherBuf
;   3. WorkBuf = copy of CipherBuf
NewRound proc
    call GenSentence
    call EncryptPerWord
    call ResetWork
    mov RoundStatus, 0
    ret
NewRound endp

;  ANSWER CHECKING + SCORING
;   CheckAnswer - compare WorkBuf with PlainBuf
;   OUT: AL = 1 if equal, 0 if different

CheckAnswer proc
    lea si, WorkBuf
    lea di, PlainBuf
ck_loop:
    mov al, [si]
    cmp al, [di]
    jne ck_wrong
    cmp al, '$'
    je ck_right
    inc si
    inc di
    jmp ck_loop
ck_right:
    mov al, 1
    ret
ck_wrong:
    mov al, 0
    ret
CheckAnswer endp

; ApplyResult
;   IN : AL = 1 correct / 0 wrong
;   Correct: +points, +time, Round++, RoundStatus=1
;   Wrong  : -time (never below 0), RoundStatus=2
ApplyResult proc
    cmp al, 1
    jne ar_wrong
    add Score, POINTS_CORRECT
    inc Round
    mov RoundStatus, 1
    ret
ar_wrong:
    mov RoundStatus, 2
    mov ax, TimeLeft
    cmp ax, TIME_PENALTY
    jbe ar_zero
    sub ax, TIME_PENALTY
    jmp ar_store
ar_zero:
    xor ax, ax              ; clamp at 0, walang negative timedapat
ar_store:
    mov TimeLeft, ax
    ret
ApplyResult endp

; SubmitAnswer - Sam you call this when the player submit an answer.
;   OUT: AL = 1 correct (next round already generated), 0 wrong
;   On wrong, the working copy is kept so the player can keep trying.
SubmitAnswer proc
    call CheckAnswer
    push ax
    call ApplyResult
    pop ax
    cmp al, 1
    jne sa_done
    push ax
    call NewRound           ; correct -> fresh puzzle, RoundStatus reset to 0
    mov RoundStatus, 1      ; keep it at 1 so Sam can still print "Correct!"
    pop ax
sa_done:
    ret
SubmitAnswer endp

; THIS IS FOR TIME BONUSES | if player answers within 30 seconds.
; Call only after a correct answer.
ApplyTimeBonus proc
    cmp FastAnswer, 1
    jne ATB_done

    mov ax, TimeLeft
    add ax, TIME_BONUS
    mov TimeLeft, ax

ATB_done:
    ret
ApplyTimeBonus endp


; Call only after a WRONG answer.
ApplyWrongPenalty proc
    cmp TimeLeft, TIME_PENALTY
    ja AWP_subtract

    mov TimeLeft, 0
    mov GameOver, 1
    ret

AWP_subtract:
    sub TimeLeft, TIME_PENALTY
    ret
ApplyWrongPenalty endp


;  HARNESS HELPERS  (STAND-IN>
PrintStr proc              
    mov ah, 9
    int 21h
    ret
PrintStr endp

PrintNum proc               ; AX = unsigned number, prints decimal
    push bx
    push cx
    push dx
    mov bx, 10
    xor cx, cx
pn_div:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne pn_div
pn_out:
    pop dx
    add dl, '0'
    mov ah, 2
    int 21h
    loop pn_out
    pop dx
    pop cx
    pop bx
    ret
PrintNum endp

PrintKeys proc              ; prints every word's key, e.g. "7 12 3 19 4"
    xor bx, bx
pk_loop:
    cmp bl, WordCount
    jae pk_done
    mov al, ShiftKeys[bx]
    xor ah, ah
    push bx
    call PrintNum
    mov dl, ' '
    mov ah, 2
    int 21h
    pop bx
    inc bx
    jmp pk_loop
pk_done:
    ret
PrintKeys endp

ShowState proc
    lea dx, tScore
    call PrintStr
    mov ax, Score
    call PrintNum
    lea dx, crlf
    call PrintStr
    lea dx, tTime
    call PrintStr
    mov ax, TimeLeft
    call PrintNum
    lea dx, crlf
    call PrintStr
    ret
ShowState endp

DisplayGameTime proc ;FOR PLACEHOLDER
    push ax
    push bx
    push dx

    lea dx, tTime
    call PrintStr

    mov ax, TimeLeft
    call PrintNum

    lea dx, crlf
    call PrintStr

    pop dx
    pop bx
    pop ax
    ret
DisplayGameTime endp   

DisplayTimeBonus proc  ;FOR PLACEHOLDER
    lea dx, tBonus
    call PrintStr
    ret
DisplayTimeBonus endp

;  RICA's encryption module (Programmer 2 - CIPHER)
include cipher.asm


; OVERALL GAME TIMER
StartGameTimer proc
    mov TimeLeft, START_TIME
    mov TickAccum, 0
    mov GameOver, 0

    mov ah, 00h
    int 1Ah
    mov LastTick, dx
    ret
StartGameTimer endp


UpdateGameTimer proc
    cmp GameOver, 1
    je UGT_done

    mov ah, 00h
    int 1Ah

    mov ax, dx
    sub ax, LastTick
    mov LastTick, dx
    add TickAccum, ax

UGT_second:
    cmp TickAccum, 18
    jb UGT_done

    sub TickAccum, 18

    cmp TimeLeft, 0
    je UGT_end

    dec TimeLeft
    cmp TimeLeft, 0
    jne UGT_second

UGT_end:
    mov TimeLeft, 0
    mov GameOver, 1

UGT_done:
    ret
UpdateGameTimer endp
                   

; TIME BONUSES | PER WORD TIMER
StartWordTimer proc
    mov ah, 00h
    int 1Ah
    mov WordStartTick, dx
    mov FastAnswer, 0
    ret
StartWordTimer endp


; THIS IS FOR TIME BONUSES
; Set FastAnswer = 1 if answered within 30 seconds.
CheckWordTime proc
    mov ah, 00h
    int 1Ah

    mov ax, dx
    sub ax, WordStartTick

    cmp ax, FAST_LIMIT
    ja CWT_slow

    mov FastAnswer, 1
    ret

CWT_slow:
    mov FastAnswer, 0
    ret
CheckWordTime endp

;THIS IS FOR HIGHSCORE | If they have existing high score na.
LoadHighScore proc
    mov HighScore, 0

    mov ah, 3Dh
    mov al, 00h
    lea dx, HSFileName
    int 21h
    jc LHS_done       ; If file doesn't exist, use 0

    mov HSHandle, ax

    mov ah, 3Fh
    mov bx, HSHandle
    mov cx, 2
    lea dx, HSBuffer
    int 21h

    cmp ax, 2
    jne LHS_close

    mov ax, word ptr HSBuffer
    mov HighScore, ax

LHS_close:
    mov ah, 3Eh
    mov bx, HSHandle
    int 21h

LHS_done:
    ret
LoadHighScore endp
        

;SAVING NEW HIGH SCORE
SaveHighScore proc
    mov ax, Score
    cmp ax, HighScore
    jbe SHS_done

    ; Update the high score in memory.
    mov HighScore, ax

    ; Create or overwrite the file.
    mov ah, 3Ch
    mov cx, 0
    lea dx, HSFileName
    int 21h
    jc SHS_done

    mov HSHandle, ax

    mov ah, 40h
    mov bx, HSHandle
    mov cx, 2
    lea dx, HighScore
    int 21h

    push ax

    mov ah, 3Eh
    mov bx, HSHandle
    int 21h

    pop ax

    cmp ax, 2
    jne SHS_done

SHS_done:
    ret
SaveHighScore endp
        
end main