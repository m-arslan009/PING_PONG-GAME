[org 0x100]
    jmp start

row:   dw 0
col:   dw 40
oldRow: dw 0
oldCol: dw 0
count: dw 0
flag:   dw 0
colState: dw 0
rowState: dw 0
playerA: dw 0
playerB: dw 0
playerA_Score: db 0
playerB_Score: db 0
msgRowLoc: dw 13
msgColLoc: dw 30
oldIsr: dd 0
msg1: db "player A WIN", 0
msg2: db "player B WIN", 0

clrscr:
    push es
    push ax
    push di
    push cx
    
    mov ax, 0xb800
    mov es, ax
    mov ax, 0x0720
    mov di, 0
    mov cx, 4000
    rep stosw
    
    pop cx
    pop di
    pop ax
    pop es
    ret

clrPrev:
    pusha
    mov ax, [oldRow]
    mov bx, 80
    mul bx
    add ax, [oldCol]
    shl ax, 1
    mov di, ax
    mov ax, 0xb800
    mov es, ax
    mov ax, 0x0720
    stosw
    
    popa
    ret

printScore:
    pusha
    mov ax, 0xb800
    mov es, ax
    
    mov ah, 0x02
    mov byte al, [playerA_Score]
    add al, 0x30
    mov di, 316
    mov [es:di], ax
    
    mov byte al, [playerB_Score]
    add al, 0x30
    mov di, 3836
    mov [es:di], ax
    
    popa
    ret

printBall:
    call clrPrev
    pusha
    mov ax, [row]
    mov bx, 80
    mul bx
    add ax, [col]
    shl ax, 1
    mov di, ax
    mov ax, 0xb800
    mov es, ax
    mov ax, 0x072A
    stosw
    popa
    ret

printBar:
    pusha
    mov ax, 0xb800
    mov es, ax
    
    mov ax, 0x7020
    mov cx, 20
    mov di, 3840
    rep stosw
    
    mov di, 0
    mov cx, 20
    rep stosw
    
    popa
    ret

printMsg:
    push bp
    mov bp, sp
    pusha
    
    mov ax, 0xb800
    mov es, ax

    mov si, [bp + 4]
    xor ax, ax
    mov ax, [msgRowLoc]
    mov bx, 80
    mul bx
    add ax, [msgColLoc]
    shl ax, 1
	mov di, ax
    mov ah, 0xF4
printMessage:
    lodsb
    cmp al, 0
    je terminatePrinting
    stosw
    jmp printMessage

terminatePrinting:
    popa
    pop bp
    ret
    
timer:
    push ax
    push ds
    push bx
    
    mov ax, cs
    mov ds, ax
    
    inc word [count]
    cmp word [count], 1 
    jne done
    call printBar
    call printBall
    mov word [count], 0
    
    mov bx, [row]
    mov [oldRow], bx
    mov bx, [col]
    mov [oldCol], bx
    
    cmp byte [playerA_Score], 5
    je playerAWin
    cmp byte [playerB_Score], 5
    je playerBWin

checkLowerPaddle:
    mov ax, [row]
    inc ax
    mov bx, 80
    mul bx
    mov bx, [col]
    dec bx
    add ax, bx
    shl ax, 1
    mov di, ax
    mov ax, 0xb800
    mov es, ax
    cmp word [es:di], 0x7020
    jne checkUpperPaddle
    cmp word [rowState], 0
    je setRowOne
    mov word [rowState], 0
setRowOne:
    mov word [rowState], 1

checkUpperPaddle:
    mov ax, [row]
    dec ax
    mov bx, 80
    mul bx
    mov bx, [col]
    dec bx
    add ax, bx
    shl ax, 1
    mov di, ax
    mov ax, 0xb800
    mov es, ax
    cmp word [es:di], 0x7020
    jne continue
    cmp word [rowState], 1
    je setRowZero
    mov word [rowState], 1
setRowZero:
    mov word [rowState], 0

continue:
    cmp word [colState], 0
    je incCol
    dec word [col]
    cmp word [col], 0
    jne checkRow
    
    mov word [colState], 0
    jmp checkRow
incCol:
    inc word [col]
    cmp word [col], 78
    jne checkRow
    mov word [colState], 1

checkRow:
    cmp word [rowState], 0
    je incRow
    
    dec word [row]
    cmp word [row], 0
    jne done
    add byte [playerB_Score], 1
    mov word [rowState], 0
    jmp done

incRow:
    inc word [row]
    cmp word [row], 24
    jne done
    mov word [rowState], 1
    add byte [playerA_Score], 1

done:
    call printScore
    mov al, 0x20            
    out 0x20, al
    
    pop bx
    pop ds
    pop ax
    iret

playerAWin:
    push word msg1
    call printMsg
    jmp terminate

playerBWin:
    push word msg2
    call printMsg
    jmp terminate

start:
    mov byte [playerA_Score], 0
    mov byte [playerB_Score], 0
    call clrscr
    mov ax, [row]
    mov [oldRow], ax
    mov ax, [col]
    mov [oldCol], ax
    xor ax, ax
    mov es, ax
    mov ax, [es:8*4]
    mov [oldIsr], ax
    mov ax, [es:8*4 + 2]
    mov [oldIsr + 2], ax
    xor ax, ax
    cli
    mov word [es:8*4], timer
    mov word [es:8*4+2], cs
    sti
    
    jmp $

terminate:
    ; Restore the original ISR
    mov ax, [oldIsr]
    mov [es:8*4], ax
    mov ax, [oldIsr + 2]
    mov [es:8*4 + 2], ax
    
    ; Terminate the program
    mov ax, 0x4c00
    int 21h
