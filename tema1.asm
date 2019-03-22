%include "io.inc"

%define MAX_INPUT_SIZE 4096

section .bss
	expr: resb MAX_INPUT_SIZE
        n: resd 1

section .DATA
        plus db '+'
        minus db '-'
        divide db '/'
        multiply db '*'
        separator db ' '
        ten dd 10
        minusOne dd -1
section .text

global CMAIN

; Function that uses the values in EDI (the string) and ECX,
; to return a number from a string
charToDec: 
    push ebp
    mov ebp, esp
    
    xor eax, eax
        
forLoop:
    mul dword[ten]
    add al, byte [edi + ecx]        
    sub eax, '0'                    ; Conversion from ASCII to integer
    inc ecx                         ; Move forward throught the string
    xor ebx, ebx
    mov bl, byte [edi + ecx]
    cmp bl, [separator]             ; Loop while we still have digits
    jne forLoop
    
    leave
    ret

CMAIN:
    mov ebp, esp; for correct debugging
    push ebp
    mov ebp, esp

    GET_STRING expr, MAX_INPUT_SIZE
    xor edi, edi
    mov edi, expr
    
    ; calculating the length of the string
    cld                             ; setting DF = 0, moving forward
    mov al, 0x00                    ; null terminator
    repne scasb                     ; when the al is found edi will be at the end of the string
    sub edi, expr
    dec edi                         ; edi has now the value of the string + 1 (the null terminator)
    mov [n], edi                    ; n = stringLength
    
    ; Initialising the registers i use with 0
    xor ecx, ecx
    xor edi, edi
    xor eax, eax

    mov edi, expr 

stringExploit: 
    mov al, byte [edi + ecx]        ; Taking a singler character at a time
    
    cmp al, [plus]
    jne skipPlus                    ; If it's not a '+' we skip the block in which we do the addition
    
    ; PLUS 
    xor ebx, ebx
    xor edx, edx
    pop ebx                         ; Taking operands from stack
    pop edx                         ; Taking operands from stack
    add ebx, edx                    ; Doing the operation
    push ebx                        ; Pusing the result onto stack
    jmp skipPush
    
skipPlus:
    cmp al, [minus]
    jne skipMinus
    
    ; If we find a '-' in may be an operand or an operator
    inc ecx                         ; Skiping '-' to find out if it's an operator or operand
    cmp ecx, [n]                    ; End of string => do operation and end
    je doSubtract 

    mov al,  byte [edi + ecx] 
    cmp al, [separator]             ; Operators will have a ' ' or 0x00 after them
    je doSubtract                   ; Jump if it's an operator
    
    call charToDec
    
    imul dword[minusOne]            ; Making number negative
    push eax                        ; Pushing new number onto stack
    jmp skipPush
    
doSubtract:
    ; MINUS
    xor ebx, ebx
    xor edx, edx
    pop ebx
    pop edx
    sub edx, ebx
    push edx
    jmp skipPush

    
skipMinus:
    cmp al, [multiply]
    jne skipMultiply
    
    ; MULTIPLY
    xor eax, eax
    xor edx, edx
    pop eax
    pop edx
    imul edx
    push eax
    jmp skipPush
    
skipMultiply:
    cmp al, [divide]
    jne skipDivide
    
    ; DIVIDE
    xor eax, eax
    xor edx, edx
    pop ebx
    pop eax
    cdq                             ; Extending eax -> edx (for signed divide)
    idiv ebx
    push eax
    jmp skipPush
    
skipDivide:
    cmp al, [separator]
    je skipPush                     ; If the character is ' ' then skip pushing onto stack
        
    ; PUSH ONTO STACK
    call charToDec
    push eax
    
skipPush: 
    xor eax, eax                    ; Reseting eax 
    inc ecx                         ; Skiping this character
    cmp ecx,[n]                     ; Loop while I still have characters left
    jb stringExploit
	
exit: 
    pop eax
    PRINT_DEC 4, eax
    pop ebp
    ret 
