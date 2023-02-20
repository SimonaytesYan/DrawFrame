.model tiny
.code
org 100h

locals __

Start:
    mov ax, 0b800h
    mov es, ax
    mov si, 82h             ;pointer to cml arguments

                                ;<----------------------|
    mov cx, 4                   ;number of number arg   |
    __next:                     ;                       |
        call GetDecNumFromMem   ;get argument           | Get arguments from cml
        push ax                 ;                       |
        inc si                  ;                       |
        loop __next             ;<----------------------|
    
    call GetDecNumFromMem   ;get frame type
    inc si

    cmp ax, 1   ;frame type in ax now      ;<-|
    je fst_type                            ;  |
    cmp ax, 2                              ;  |
    je snd_type                            ;  |
                                           ;  |
    user_type:  mov di, si                 ;  |
                add si, 10d     ;skip symbls  |
                jmp skip                   ;  |put in di addres of array symbols for frame
                                           ;  |
    fst_type:   lea di, single_frame       ;  |
                jmp skip                   ;  |
                                           ;  |
    snd_type:   lea di, double_frame       ;  |
                jmp skip                   ;<-|
skip:

    inc si                  ;skip first "
    push si                 ;save start of label to ouput
    dec si
    __skip_text:
        inc si
        cmp byte ptr [si], "'"
        jne __skip_text
    mov byte ptr [si], 0    ;replace last " to '\0'

    add si, 2

    call GetHexNumFromMem   ;get color atr
    mov cx, ax      ;save color atribute in cx

    mov si, di      ;put in si addres of array symbols for frame
    pop di          ;save pointer to text

    pop dx          ;
    shl dx, 8       ;dh - height of frame
    pop ax          ;dl - weight of frame
    add dx, ax

    pop bp          ;put x in bp

    pop ax          ;put y in ax

    push dx         ;<------------|
    push di         ;<--|         |
                    ;   |         |
    mov di, 160d    ;   |save di  |
    mul di          ;   |         |save dx
                    ;   |         |
    pop di          ;<--|         |
    pop dx          ;<------------|

    add bp, ax      ;make from x and y arguments memory offset in bp

    mov ax, cx      ;put color atribute to ax
    shl ax, 8
    
    push bp
    push di
    push dx
    call DrawFrame

    pop dx          ;size of frame
    pop di          ;pointer to text

    push cs
    pop es          ;set es to this segment
    push ax
    push di
    call StrLen     ;in ax - length of string
    pop si          ;pointer to text

    pop cx          ;color atr in ch
    xor cl, cl
    pop bx          ;pointer to left up corner of the frame

    mov bp, ax      ;save str length to bp

    shr dh, 1       ;height/=2
    mov ax, 160d    ;
    mul dh

    add bx, ax      ;set bx right y coord to write text

    xor dh, dh      ;dx = dl

    mov ax, bp      ;ax = length
    shr ax, 1       ;ax/=2
    shl ax, 1

    shr dx, 1       ;weight/=2
    shl dx, 1

    add bx, dx
    sub bx, ax      ;set bx right x coord to write text

    mov ax, 0b800h
    mov es, ax      ;es -> videomem

    call OutputStr
    ret
;-------------------------------------------
;GetDecimalNumberFromMemory
;-------------------------------------------
;EXPECTS:   None
;INPUTS:	si - pointer to place in memory which from number will be taken
;
;OUTPUTS:	ax - number
;           si - pointer to byte after end of number
;
;DESTROYS:	dx, di
;
;-------------------------------------------
GetDecNumFromMem   proc
    xor ax, ax
    xor dx, dx
	mov di, 10d
	
	__next:
        cmp byte ptr [si], 13d
        je __break

        mul di              ;ax = ax*10
		mov dl, [si]        ;put in dl next simbol
		sub dl, '0'			;convert simbol to number
		
		add ax, dx		    ;ax += dh
		
		inc si
        cmp byte ptr [si], ' '
		jne __next          ;while(*si != ' ')
    __break:

    ret
                endp

;-------------------------------------------
;GetHexNumberFromMemory
;-------------------------------------------
;EXPECTS:   None
;INPUTS:	si - pointer to place in memory which from number will be taken
;
;OUTPUTS:	ax - number
;           si - pointer to byte after end of number
;
;DESTROYS:	dx
;
;-------------------------------------------
GetHexNumFromMem   proc
    xor ax, ax
    xor dx, dx
	
	__next:
        cmp byte ptr [si], 13d
        je __break

        shl ax, 4           ;ax = ax*16
		mov dl, [si]        ;put in dl next simbol
		sub dl, '0'			;convert simbol to number

        cmp dl, 9
        jl  __les10         ;if [si] - letter
            sub dl, 7       ;dl -= 7
    __les10:

		add ax, dx		    ;ax += dh
		
		inc si
        cmp byte ptr [si], ' '
		jne __next          ;while(*si != ' ')
    __break:

    ret
                endp

;--------------------------------
;EXPECTS:   es->videomemory
;INPUTS:    bp - offset in vmem
;		    dh - height of frame
;		    dl - weight of frame
;		    ah - color atr
;           si - pointer to array with 9 symbols to draw frame in format:
;           0:[left  up   corner]
;           1:[up         border]
;           2:[right up   corner]
;           3:[left       border]
;           4:[simbol to fill frame]
;           5:[right      border]
;           6:[left  down corner]
;           7:[bottom     border]
;           8:[right down corner]
;
;OUTPUTS:   None
;DESTROYS:  bx, cx, di, bp, al, dx
;--------------------------------
DrawFrame   proc
    sub dl, 2           ;now we don`t consider the 1-st and the last symbol, because them we will put without loops
    sub dh, 2           ;the same reason

    mov di, bp
    mov al, [si + 0]
    mov bl, [si + 1]
    mov bh, [si + 2]
    xor cx, cx          ;
    mov cl, dl          ;cx = dl
    call PutFrameLine   ;draw the first line

    add bp, 160d        ;go to the next line

    mov bl, [si + 4]
    mov bh, [si + 5]
    __next:
        mov di, bp
        mov al, [si + 3]    ;rewrite in the loop because in PutFrameLine al destroys
        xor cx, cx          ;
        mov cl, dl          ;cx = dl
        call PutFrameLine   ;draw all middle lines
        add bp, 160d        ;go to the next line

        dec dh              ;dh--
        cmp dh, 0
        jne __next          ;while(dh!=0)

    mov di, bp
    mov al, [si + 6]
    mov bl, [si + 7]
    mov bh, [si + 8]
    xor cx, cx          ;
    mov cl, dl          ;cx = dl
    call PutFrameLine   ;draw the first line

    ret
            endp

;--------------------------------
;PutFrameLine
;--------------------------------
;EXPECTS:   es -> videomemory segment
;INPUTS:    di - offset in videomemory
;           ah - color atr of the symbols
;           al - ASCII code of the 1-st symbol
;           bl - ASCII code of cx middle symbols
;           bh - ASCII code of the last symbol
;           cx - numbers of middle symbols
;
;OUTPUTS:   None
;DESTROYS:  di, al, cx
;--------------------------------
PutFrameLine    proc
    cld
    stosw       ;put the fisrt symbol

    mov al, bl  ;change putting simdol to middle symbol
    rep stosw   ;put all middle symbols

    mov al, bh  ;change putting simdol to the last symbol
    stosw

    ret
                endp
;--------------------------------

.data
;           0:[left  up   corner]
;           1:[up         border]
;           2:[right up   corner]
;           3:[left       border]
;           4:[simbol to fill frame]
;           5:[right      border]
;           6:[left  down corner]
;           7:[bottom     border]
;           8:[right down corner] 

single_frame db 0dah, 0c4h, 0bfh, '|',  ' ', '|',  0c0h, '_',  0d9h

double_frame db 0c9h, 0cdh, 0bbh, 0bah, ' ', 0bah, 0c8h, 0cdh, 0bch

.code
;------------------------------------------------
;Put text form var in vmem
;------------------------------------------------
;EXPECTS: es->videomem
;
;INPUTS: bx - offset
;		 ch - color atribut
;		 si - pointer to variable with text
;		 bp - length of string in var
;
;OUTPUTS: None
;
;Destroys: si, bx, bp, cl
;------------------------------------------------

OutputStr	proc

	add bp, si
	__next:										;
		mov cl, [si]							;
		mov word ptr es:[bx], cx				;
		add bx, 2								;
		inc si									;

		cmp si, bp   							;
		jne __next								;

	ret
	endp
;------------------------------------------------

include STRFUNC.ASM

end Start