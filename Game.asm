[org 0x100]
    jmp start

row:   dw 0
col:   dw 40
count: dw 0
flag:   dw 0
colState: dw 0
rowState: dw 0
playerA: dw 0
playerB: dw 0
playerA_Scroe: db 0
playerB_Scroe: db 0

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
    
    mov ax, 0x7020
    mov cx, 20
    mov di, 3840
    rep stosw
	
    mov di, 0
    mov cx, 20
    rep stosw
	
	mov ah, 0x02
	mov byte al, [playerA_Scroe]
	add al, 0x30
	mov di, 316
	mov [es:di], ax
	
	mov byte al, [playerB_Scroe]
	add al, 0x30
	mov di, 3836
	mov [es:di], ax
	
    pop cx
    pop di
    pop ax
    pop es
    ret

printBall:
    call clrscr
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


timer:
    push ax
    push ds
    
    mov ax, cs
    mov ds, ax
    
    inc word [count]
    cmp word [count], 1 
    jne done
    call printBall
    mov word [count], 0

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
    cmp word [colState],0
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
	add byte [playerB_Scroe], 1
    mov word [rowState], 0
    jmp done

incRow:
    inc word [row]
    cmp word [row], 24
    jne done
    mov word [rowState], 1
	add byte [playerA_Scroe], 1

done:
    mov al, 0x20            
    out 0x20, al
    
    pop ds
    pop ax
    iret

start:
	mov byte [playerA_Scroe], 0
	mov byte [playerB_Scroe], 0
    call clrscr
    xor ax, ax
    mov es, ax
    cli
    mov word [es:8*4], timer
    mov word [es:8*4+2], cs
    sti
	
    jmp $
terminate:
	mov ax, 0x4c00
	int 21h
