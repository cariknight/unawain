.MODEL SMALL
.STACK 100h

; ============================================================
; UNAWAIN: DECIPHER
; ============================================================

POINTS_CORRECT EQU 10
TIME_BONUS     EQU 15
START_TIME     EQU 191
FAST_LIMIT     EQU 546       ; approximately 30 BIOS ticks/seconds
SUBJ_COUNT     EQU 20
VERB_COUNT     EQU 20
OBJ_COUNT      EQU 20

.DATA
PlainBuf    DB 80 DUP('$')
CipherBuf   DB 80 DUP('$')
WorkBuf     DB 80 DUP('$')
ShiftKeys   DB 10 DUP(0)
PlayerKeys  DB 10 DUP(0)
WordCount   DB 0
TmpWord     DB 20 DUP('$')
EncTmp      DB 20 DUP('$')
Score       DW 0
Round       DW 1
RoundStatus DB 0
TimeLeft    DW START_TIME
Seed        DW 0
GameOver    DB 0
HighScore   DW 0
LastTick    DW 0
TickAccum   DW 0
WordStartTick DW 0
FastAnswer  DB 0
HSFileName  DB 'HISCORE.DAT',0
HSBuffer    DB 2 DUP(0)
HSHandle    DW 0
InputBuf    DB 20,0,20 DUP(0)
InputValue  DW 0
InputBad    DB 0
WordIndex   DB 0
CharTemp    DB 0
OldTime     DW 0
SavedCursor DW 0
SrcPos      DW 0
OutPos      DW 0

title_str DB 13,10,'========================================',13,10
          DB '           UNAWAIN: DECIPHER',13,10
          DB '========================================',13,10,'$'
menu_str  DB 13,10,'1. Start Game',13,10
          DB '2. How to Play (Tutorial)',13,10
          DB '3. High Scores',13,10
          DB '4. Exit',13,10
          DB 'Select option [1-4]: $'
tutorial_str DB 13,10,'HOW TO PLAY',13,10
             DB 'Each word has its own Caesar shift from 1 to 25.',13,10
             DB 'Enter the positive shift used to encrypt each word.',13,10
             DB 'Example: KHOOR encrypted with +3 becomes HELLO',13,10
             DB 'Enter a shift from 1 to 25 for each word.',13,10
             DB 'Stay on a word until it is correct, then move to the next.',13,10
             DB 'U = undo/reset; R = new round; Q = menu.',13,10
             DB 'Each correct word: +10 points and +30 seconds if fast.',13,10
             DB 'Wrong shift: stay on the same word. No time penalty.',13,10
             DB 'Press any key to return to the menu...$'
prompt_shift DB 'Shift for word #$'
prompt_tail  DB ' (1-25; blank Enter=submit; U undo; R restart; Q menu): $'
msg_invalid DB 'Invalid input. Enter a number from 1 to 25.$'
msg_undo DB 13,10,'Answer reset to the original ciphertext.',13,10,'$'
msg_restart DB 13,10,'Starting a new round...',13,10,'$'
msg_correct DB 'CORRECT! +10 points.$'
msg_wrong DB 'Not correct. Stay on this word and try another shift.$'
msg_too_high DB 'Shift is TOO HIGH. Try a lower number.$'
msg_too_low  DB 'Shift is TOO LOW. Try a higher number.$'
msg_bonus DB 'TIME BONUS! +30 SECONDS$'
msg_gameover DB 13,10,'TIME IS UP!',13,10,'$'
msg_cipher DB 13,10,'Ciphertext: $'
msg_work DB 'Your answer: $'
msg_score DB 13,10,'Score: $'
msg_time DB '   Time left: $'
msg_round DB 13,10,'Round: $'
msg_keys DB 13,10,'Word shifts used to create this puzzle (debug): $'
msg_highscore DB 13,10,'High score: $'
msg_newline DB 13,10,'$'
live_time DB 'Time: $'
live_pad  DB '   $'
press_key DB 13,10,'Press any key to continue...$'
msg_playagain DB 13,10,'Play again? Press Y to start a new game, or any other key for the menu: $'
tBonus DB 13,10,'TIME BONUS! +30 SECONDS',13,10,'$'

; Word bank: 20 subjects, 20 verbs, 20 objects
S1 DB 'THE CAT$'
S2 DB 'A DOG$'
S3 DB 'THE TEACHER$'
S4 DB 'MY BROTHER$'
S5 DB 'THE ROBOT$'
S6 DB 'A STUDENT$'
S7 DB 'THE CHEF$'
S8 DB 'OUR NEIGHBOR$'
S9 DB 'A PIRATE$'
S10 DB 'THE DOCTOR$'
S11 DB 'MY SISTER$'
S12 DB 'THE FARMER$'
S13 DB 'A TOURIST$'
S14 DB 'THE WIZARD$'
S15 DB 'THE DRIVER$'
S16 DB 'A SINGER$'
S17 DB 'THE BAKER$'
S18 DB 'MY COUSIN$'
S19 DB 'THE ARTIST$'
S20 DB 'A FISHERMAN$'

V1 DB 'EATS$'
V2 DB 'SEES$'
V3 DB 'BUILDS$'
V4 DB 'FINDS$'
V5 DB 'LIKES$'
V6 DB 'CARRIES$'
V7 DB 'BUYS$'
V8 DB 'DRAWS$'
V9 DB 'HIDES$'
V10 DB 'OPENS$'
V11 DB 'WATCHES$'
V12 DB 'PAINTS$'
V13 DB 'FIXES$'
V14 DB 'CLEANS$'
V15 DB 'STEALS$'
V16 DB 'KEEPS$'
V17 DB 'LOVES$'
V18 DB 'MAKES$'
V19 DB 'SELLS$'
V20 DB 'WRITES$'

O1 DB 'THE APPLE$'
O2 DB 'A BOOK$'
O3 DB 'THE GARDEN$'
O4 DB 'A SECRET MESSAGE$'
O5 DB 'THE TREASURE$'
O6 DB 'A RED BALLOON$'
O7 DB 'THE OLD CAMERA$'
O8 DB 'A HEAVY BOX$'
O9 DB 'THE BIG CAKE$'
O10 DB 'A BROKEN CLOCK$'
O11 DB 'THE GOLDEN KEY$'
O12 DB 'A SMALL BOAT$'
O13 DB 'THE NEW BRIDGE$'
O14 DB 'A COLD DRINK$'
O15 DB 'THE LONG LETTER$'
O16 DB 'A PURPLE UMBRELLA$'
O17 DB 'THE HIDDEN DOOR$'
O18 DB 'A FUNNY STORY$'
O19 DB 'THE LOUD RADIO$'
O20 DB 'A SHINY COIN$'

SubjTbl DW OFFSET S1,OFFSET S2,OFFSET S3,OFFSET S4,OFFSET S5
        DW OFFSET S6,OFFSET S7,OFFSET S8,OFFSET S9,OFFSET S10
        DW OFFSET S11,OFFSET S12,OFFSET S13,OFFSET S14,OFFSET S15
        DW OFFSET S16,OFFSET S17,OFFSET S18,OFFSET S19,OFFSET S20
VerbTbl DW OFFSET V1,OFFSET V2,OFFSET V3,OFFSET V4,OFFSET V5
        DW OFFSET V6,OFFSET V7,OFFSET V8,OFFSET V9,OFFSET V10
        DW OFFSET V11,OFFSET V12,OFFSET V13,OFFSET V14,OFFSET V15
        DW OFFSET V16,OFFSET V17,OFFSET V18,OFFSET V19,OFFSET V20
ObjTbl  DW OFFSET O1,OFFSET O2,OFFSET O3,OFFSET O4,OFFSET O5
        DW OFFSET O6,OFFSET O7,OFFSET O8,OFFSET O9,OFFSET O10
        DW OFFSET O11,OFFSET O12,OFFSET O13,OFFSET O14,OFFSET O15
        DW OFFSET O16,OFFSET O17,OFFSET O18,OFFSET O19,OFFSET O20

.CODE
main PROC
    mov ax, @data
    mov ds, ax
    mov es, ax
    call SeedRandom
    call LoadHighScore

menu_loop:
    call ClearScreen
    lea dx, title_str
    call PrintStr
    lea dx, menu_str
    call PrintStr
    mov ah, 01h
    int 21h
    cmp al, '1'
    je menu_start
    cmp al, '2'
    je menu_tutorial
    cmp al, '3'
    je menu_scores
    cmp al, '4'
    je menu_exit
    jmp menu_loop

menu_start:
    call ClearScreen
    mov Score, 0
    mov Round, 1
    call StartGameTimer
    call NewRound
game_loop:
    call UpdateGameTimer
    cmp GameOver, 1
    je game_over
    call ClearScreen
    call ShowRound
    call StartWordTimer
    call GetPlayerShifts
    cmp GameOver, 1
    je game_over
    cmp al, 1
    je game_menu
    cmp al, 2
    je game_restart
    cmp al, 3
    je game_submit
    jmp game_loop

game_submit:
    ; Per-word score and time were already applied. Next sentence.
    inc Round
    call NewRound
    jmp game_loop

game_restart:
    lea dx, msg_restart
    call PrintStr
    call NewRound
    jmp game_loop

game_menu:
    call SaveHighScore
    jmp menu_loop

game_over:
    lea dx, msg_gameover
    call PrintStr
    call ShowState
    call SaveHighScore
    lea dx, msg_playagain
    call PrintStr
    mov ah, 08h
    int 21h
    and al, 0DFh             ; accept lowercase or uppercase Y
    cmp al, 'Y'
    je play_again
    jmp menu_loop

play_again:
    call ClearScreen
    mov Score, 0
    mov Round, 1
    call StartGameTimer
    call NewRound
    jmp game_loop

menu_tutorial:
    call ClearScreen
    lea dx, tutorial_str
    call PrintStr
    mov ah, 08h
    int 21h
    jmp menu_loop

menu_scores:
    call ClearScreen
    lea dx, msg_highscore
    call PrintStr
    mov ax, HighScore
    call PrintNum
    lea dx, msg_newline
    call PrintStr
    lea dx, press_key
    call PrintStr
    mov ah, 08h
    int 21h
    jmp menu_loop

menu_exit:
    call SaveHighScore
    mov ax, 4C00h
    int 21h
main ENDP

; -------------------- Basic output/input --------------------
PrintStr PROC
    mov ah, 09h
    int 21h
    ret
PrintStr ENDP

PrintNum PROC                  ; AX = unsigned decimal number
    push ax
    push bx
    push cx
    push dx
    mov bx, 10
    xor cx, cx
    cmp ax, 0
    jne pn_div
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp pn_done
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
    mov ah, 02h
    int 21h
    loop pn_out
pn_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintNum ENDP

ClearScreen PROC
    push ax
    push bx
    push cx
    push dx
    mov ax, 0600h
    mov bh, 07h
    mov cx, 0000h
    mov dx, 184Fh
    int 10h
    mov ah, 02h
    mov bh, 00h
    mov dx, 0000h
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ClearScreen ENDP

; DH = row. Fill that row with spaces and leave the cursor at column 0.
GotoClearRow PROC
    push ax
    push bx
    push cx
    push dx
    mov ah, 02h
    mov bh, 00h
    mov dl, 0
    int 10h
    mov ah, 09h
    mov al, ' '
    mov bh, 00h
    mov bl, 07h
    mov cx, 80
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
GotoClearRow ENDP

ReadLine PROC
    ; Poll the keyboard while updating the game timer.
    mov byte ptr InputBuf[1], 0
rl_wait:
    cmp GameOver, 1
    je rl_timeout
    mov ax, TimeLeft
    mov OldTime, ax
    call UpdateGameTimer
    cmp GameOver, 1
    je rl_timeout
    mov ax, TimeLeft
    cmp ax, OldTime
    je rl_keycheck
    call DisplayLiveTime
rl_keycheck:
    mov ah, 01h
    int 16h
    jz rl_wait
    mov ah, 00h
    int 16h
    cmp al, 13
    je rl_enter
    cmp al, 8
    je rl_backspace
    cmp al, ' '
    jb rl_wait
    mov bl, InputBuf[1]
    cmp bl, 19
    jae rl_wait
    xor bh, bh
    mov [InputBuf+2+bx], al
    inc byte ptr InputBuf[1]
    mov dl, al
    mov ah, 02h
    int 21h
    jmp rl_wait
rl_backspace:
    cmp byte ptr InputBuf[1], 0
    je rl_wait
    dec byte ptr InputBuf[1]
    mov dl, 8
    mov ah, 02h
    int 21h
    mov dl, ' '
    int 21h
    mov dl, 8
    int 21h
    jmp rl_wait
rl_enter:
    mov bl, InputBuf[1]
    xor bh, bh
    mov byte ptr [InputBuf+2+bx], 0
    ret
rl_timeout:
    mov byte ptr InputBuf[1], 0
    ret
ReadLine ENDP

DisplayLiveTime PROC
    ; Update the timer without losing the player's input cursor position.
    push ax
    push bx
    push dx
    mov ah, 03h
    mov bh, 0
    int 10h
    mov SavedCursor, dx
    mov ah, 02h
    mov bh, 0
    mov dh, 0
    mov dl, 40
    int 10h
    lea dx, live_time
    call PrintStr
    mov ax, TimeLeft
    call PrintNum
    lea dx, live_pad
    call PrintStr
    mov dx, SavedCursor
    mov ah, 02h
    mov bh, 0
    int 10h
    pop dx
    pop bx
    pop ax
    ret
DisplayLiveTime ENDP

; Parse InputBuf into AX. CF=1 if not a non-negative decimal integer.
ParseNumber PROC
    push bx
    push cx
    push dx
    xor ax, ax
    xor cx, cx
    mov cl, InputBuf[1]
    cmp cl, 0
    je parse_bad
    lea si, InputBuf+2
parse_loop:
    mov bl, [si]
    cmp bl, '0'
    jb parse_bad
    cmp bl, '9'
    ja parse_bad
    sub bl, '0'
    mov dx, 10
    mul dx
    xor bh, bh
    add ax, bx
    inc si
    loop parse_loop
    clc
    jmp parse_done
parse_bad:
    stc
parse_done:
    pop dx
    pop cx
    pop bx
    ret
ParseNumber ENDP

; -------------------- Random number generation --------------------
SeedRandom PROC
    mov ah, 00h
    int 1Ah
    mov Seed, dx
    xor Seed, cx
    ret
SeedRandom ENDP

RandRange PROC                 ; AX=n; returns 0..n-1
    push bx
    push cx
    push dx
    mov cx, ax
    mov ax, Seed
    mov bx, 25173
    mul bx
    add ax, 13849
    mov Seed, ax
    mov al, ah
    xor ah, ah
    xor dx, dx
    div cx
    mov ax, dx
    pop dx
    pop cx
    pop bx
    ret
RandRange ENDP

PickString PROC                ; BX=pointer table, AX=count; returns SI
    push ax
    push bx
    call RandRange
    shl ax, 1
    add bx, ax
    mov si, [bx]
    pop bx
    pop ax
    ret
PickString ENDP

AppendStr PROC                 ; DS:SI '$' string -> ES:DI
append_loop:
    lodsb
    cmp al, '$'
    je append_done
    stosb
    jmp append_loop
append_done:
    ret
AppendStr ENDP

CopyStr PROC                   ; DS:SI to ES:DI, includes '$'
copy_loop:
    lodsb
    stosb
    cmp al, '$'
    jne copy_loop
    ret
CopyStr ENDP

GenSentence PROC
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
GenSentence ENDP

; Encrypt uppercase letters forward by CL; preserve other chars.
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

; Decrypt uppercase letters backward by CL.
DecryptMsg PROC                ; SI=input, DI=output, CL=shift 1..25
    push ax
    push bx
    push cx
    mov bl, cl
dec_loop:
    mov al, [si]
    cmp al, '$'
    je dec_done
    cmp al, 'A'
    jb dec_copy
    cmp al, 'Z'
    ja dec_copy
    sub al, 'A'
    sub al, bl
    jnc dec_letter
    add al, 26
dec_letter:
    add al, 'A'
dec_copy:
    mov [di], al
    inc si
    inc di
    jmp dec_loop
dec_done:
    mov byte ptr [di], '$'
    pop cx
    pop bx
    pop ax
    ret
DecryptMsg ENDP

; Encrypt each word with an independent random shift 1..25.
EncryptPerWord PROC
    lea si, PlainBuf
    lea di, CipherBuf
    mov WordCount, 0
    xor bx, bx
epw_word:
    mov al, [si]
    cmp al, '$'
    je epw_done
    cmp al, ' '
    je epw_space
    mov ax, 25
    call RandRange
    inc al
    mov ShiftKeys[bx], al
    mov cl, al
    mov OutPos, di
    lea di, TmpWord
epw_copy_word:
    mov al, [si]
    cmp al, ' '
    je epw_word_end
    cmp al, '$'
    je epw_word_end
    stosb
    inc si
    jmp epw_copy_word
epw_word_end:
    mov byte ptr [di], '$'
    mov SrcPos, si
    mov di, OutPos
    lea si, TmpWord
    lea di, EncTmp
    call EncryptMsg
    mov si, OFFSET EncTmp
    mov di, OutPos
    call AppendStr
    mov si, SrcPos
    inc bx
    inc WordCount
    jmp epw_word
epw_space:
    mov al, ' '
    stosb
    inc si
    jmp epw_word
epw_done:
    mov al, '$'
    stosb
    ret
EncryptPerWord ENDP

ResetWork PROC
    lea si, CipherBuf
    lea di, WorkBuf
    call CopyStr
    mov byte ptr WordIndex, 0
    mov byte ptr PlayerKeys, 0
    mov byte ptr PlayerKeys+1, 0
    mov byte ptr PlayerKeys+2, 0
    mov byte ptr PlayerKeys+3, 0
    mov byte ptr PlayerKeys+4, 0
    mov byte ptr PlayerKeys+5, 0
    mov byte ptr PlayerKeys+6, 0
    mov byte ptr PlayerKeys+7, 0
    mov byte ptr PlayerKeys+8, 0
    mov byte ptr PlayerKeys+9, 0
    ret
ResetWork ENDP

NewRound PROC
    call GenSentence
    call EncryptPerWord
    call ResetWork
    mov RoundStatus, 0
    ret
NewRound ENDP

; Decrypt the whole ciphertext using PlayerKeys, one key per word.
BuildWork PROC
    lea si, CipherBuf
    lea di, WorkBuf
    xor bx, bx
bw_next:
    mov al, [si]
    cmp al, '$'
    je bw_done
    cmp al, ' '
    je bw_space
    mov cl, PlayerKeys[bx]
    cmp cl, 1
    jb bw_skip_word
    cmp cl, 25
    ja bw_skip_word
    mov OutPos, di
    lea di, TmpWord
bw_copy:
    mov al, [si]
    cmp al, ' '
    je bw_word_end
    cmp al, '$'
    je bw_word_end
    stosb
    inc si
    jmp bw_copy
bw_word_end:
    mov byte ptr [di], '$'
    mov SrcPos, si
    lea si, TmpWord
    lea di, EncTmp
    call DecryptMsg
    mov si, OFFSET EncTmp
    mov di, OutPos
    call AppendStr
    mov si, SrcPos
    inc bx
    jmp bw_next
bw_skip_word:
    ; If no shift has been entered yet, copy this word unchanged.
    mov al, [si]
    cmp al, ' '
    je bw_skip_space
    cmp al, '$'
    je bw_done
    stosb
    inc si
    jmp bw_skip_word
bw_skip_space:
    inc bx
    jmp bw_space
bw_space:
    mov al, ' '
    stosb
    inc si
    jmp bw_next
bw_done:
    mov al, '$'
    stosb
    ret
BuildWork ENDP

CheckAnswer PROC              ; AL=1 if WorkBuf equals PlainBuf, else 0
    lea si, WorkBuf
    lea di, PlainBuf
ca_loop:
    mov al, [si]
    cmp al, [di]
    jne ca_wrong
    cmp al, '$'
    je ca_right
    inc si
    inc di
    jmp ca_loop
ca_right:
    mov al, 1
    ret
ca_wrong:
    xor al, al
    ret
CheckAnswer ENDP

; AL=1 if the word at WordIndex in WorkBuf matches PlainBuf.
; Stay on the current ciphertext word until this succeeds.
CheckCurrentWord PROC
    push bx
    push cx
    push si
    push di
    lea si, WorkBuf
    lea di, PlainBuf
    xor cx, cx
    mov cl, WordIndex
    cmp cl, 0
    je ccw_compare
ccw_skip:
    mov al, [si]
    cmp al, '$'
    je ccw_wrong
    mov ah, [di]
    cmp ah, '$'
    je ccw_wrong
    cmp al, ' '
    je ccw_skip_space
    inc si
    inc di
    jmp ccw_skip
ccw_skip_space:
    inc si
    inc di
    loop ccw_skip
ccw_compare:
    mov al, [si]
    mov ah, [di]
    cmp al, '$'
    je ccw_end
    cmp al, ' '
    je ccw_end
    cmp al, ah
    jne ccw_wrong
    inc si
    inc di
    jmp ccw_compare
ccw_end:
    cmp ah, ' '
    je ccw_right
    cmp ah, '$'
    je ccw_right
ccw_wrong:
    xor al, al
    jmp ccw_done
ccw_right:
    mov al, 1
ccw_done:
    pop di
    pop si
    pop cx
    pop bx
    ret
CheckCurrentWord ENDP

; -------------------- Gameplay --------------------
ShowRound PROC
    lea dx, msg_round
    call PrintStr
    mov ax, Round
    call PrintNum 
    
    lea dx, msg_score
    call PrintStr
    mov ax, Score
    call PrintNum 
    
    lea dx, msg_time
    call PrintStr
    mov ax, TimeLeft
    call PrintNum
    
    lea dx, msg_cipher
    call PrintStr
    lea dx, CipherBuf
    call PrintStr 
    
    ;call BuildWork
    ;lea dx, msg_work
    ;call PrintStr
    ;lea dx, WorkBuf
    ;call PrintStr 
    
    lea dx, msg_newline
    call PrintStr
    ret
ShowRound ENDP

; Reads commands/numbers repeatedly. R or Q are commands.
; A correct word awards score/time; the last correct word finishes the round.
; Return AL: 1=menu, 2=restart round, 3=round complete.
GetPlayerShifts PROC
gps_again:
    cmp GameOver, 1
    je gps_timeout
    call BuildWork
    mov dh, 5
    call GotoClearRow
    lea dx, msg_work
    call PrintStr
    lea dx, WorkBuf
    call PrintStr
    mov dh, 6
    call GotoClearRow
    lea dx, prompt_shift
    call PrintStr
    xor ax, ax
    mov al, WordIndex
    inc ax
    call PrintNum
    lea dx, prompt_tail
    call PrintStr
    mov ah, 00h
    int 1Ah
    mov LastTick, dx
    call ReadLine
    ; Blank Enter finishes the round only after every word is correct.
    cmp byte ptr InputBuf[1], 0
    je gps_submit
    mov al, InputBuf[2]
    and al, 0DFh
    cmp al, 'U'
    je gps_undo
    cmp al, 'R'
    je gps_restart
    cmp al, 'Q'
    je gps_menu
    call ParseNumber
    jc gps_invalid
    cmp ax, 1
    jb gps_invalid
    cmp ax, 25
    ja gps_invalid
    ; Apply the shift to the current word only. Advance after it matches.
    xor bx, bx
    mov bl, WordIndex
    cmp bl, WordCount
    jae gps_invalid
    mov PlayerKeys[bx], al
    call BuildWork
    call CheckCurrentWord
    cmp al, 1
    je gps_word_ok
    xor bx, bx
    mov bl, WordIndex
    mov al, PlayerKeys[bx]
    cmp al, ShiftKeys[bx]
    ja gps_too_high
    jb gps_too_low
    lea dx, msg_wrong
    jmp gps_hint
gps_too_high:
    lea dx, msg_too_high
    jmp gps_hint
gps_too_low:
    lea dx, msg_too_low
gps_hint:
    push dx
    mov dh, 8
    call GotoClearRow
    pop dx
    call PrintStr
    mov dh, 9
    call GotoClearRow
    jmp gps_refresh
gps_word_ok:
    call CheckWordTime
    add Score, POINTS_CORRECT
    mov dh, 8
    call GotoClearRow
    lea dx, msg_correct
    call PrintStr
    cmp FastAnswer, 1
    jne gps_clear_bonus
    add TimeLeft, TIME_BONUS
    mov dh, 9
    call GotoClearRow
    lea dx, msg_bonus
    call PrintStr
    jmp gps_word_next
gps_clear_bonus:
    mov dh, 9
    call GotoClearRow
gps_word_next:
    inc WordIndex
    mov al, WordIndex
    cmp al, WordCount
    jae gps_submit
    call StartWordTimer
    jmp gps_refresh
gps_refresh:
    jmp gps_again
gps_undo:
    call ResetWork
    lea dx, msg_undo
    call PrintStr
    jmp gps_again
gps_restart:
    mov al, 2
    ret
gps_submit:
    ; Blank Enter does not finish the round until every word is correct.
    mov al, WordIndex
    cmp al, WordCount
    jb gps_refresh
    mov al, 3
    ret
gps_menu:
    mov al, 1
    ret
gps_invalid:
    lea dx, msg_invalid
    jmp gps_hint
gps_timeout:
    xor al, al
    ret
GetPlayerShifts ENDP

ShowState PROC
    lea dx, msg_score
    call PrintStr
    mov ax, Score
    call PrintNum
    lea dx, msg_time
    call PrintStr
    mov ax, TimeLeft
    call PrintNum
    lea dx, msg_newline
    call PrintStr
    ret
ShowState ENDP

; -------------------- Timer --------------------
StartGameTimer PROC
    mov TimeLeft, START_TIME
    mov TickAccum, 0
    mov GameOver, 0
    mov ah, 00h
    int 1Ah
    mov LastTick, dx
    ret
StartGameTimer ENDP

UpdateGameTimer PROC
    cmp GameOver, 1
    je ugt_done
    mov ah, 00h
    int 1Ah
    mov ax, dx
    sub ax, LastTick
    mov LastTick, dx
    add TickAccum, ax
ugt_second:
    cmp TickAccum, 18
    jb ugt_done
    sub TickAccum, 18
    cmp TimeLeft, 0
    je ugt_end
    dec TimeLeft
    cmp TimeLeft, 0
    jne ugt_second
ugt_end:
    mov TimeLeft, 0
    mov GameOver, 1
ugt_done:
    ret
UpdateGameTimer ENDP

StartWordTimer PROC
    mov ah, 00h
    int 1Ah
    mov WordStartTick, dx
    mov FastAnswer, 0
    ret
StartWordTimer ENDP

CheckWordTime PROC
    mov ah, 00h
    int 1Ah
    mov ax, dx
    sub ax, WordStartTick
    cmp ax, FAST_LIMIT
    ja cwt_slow
    mov FastAnswer, 1
    ret
cwt_slow:
    mov FastAnswer, 0
    ret
CheckWordTime ENDP

; -------------------- High score file --------------------
LoadHighScore PROC
    mov HighScore, 0
    mov ah, 3Dh
    mov al, 00h
    lea dx, HSFileName
    int 21h
    jc lhs_done
    mov HSHandle, ax
    mov ah, 3Fh
    mov bx, HSHandle
    mov cx, 2
    lea dx, HSBuffer
    int 21h
    cmp ax, 2
    jne lhs_close
    mov ax, word ptr HSBuffer
    mov HighScore, ax
lhs_close:
    mov ah, 3Eh
    mov bx, HSHandle
    int 21h
lhs_done:
    ret
LoadHighScore ENDP

SaveHighScore PROC
    mov ax, Score
    cmp ax, HighScore
    jbe shs_done
    mov HighScore, ax
    mov ah, 3Ch
    mov cx, 0
    lea dx, HSFileName
    int 21h
    jc shs_done
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
shs_done:
    ret
SaveHighScore ENDP

END main
