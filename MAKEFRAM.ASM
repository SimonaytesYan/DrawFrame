.model tiny
.code
org 100h

Start:	mov ax, 0b800h
	mov es, ax
	
	xor bx, bx	;bx - offset
	mov bx, 160d*4d + 80d
	mov bp, 5d	;height
	mov sp, 1d	;weight
	mov dh, 07eh	;color atr
	
	xor di, di	;y offset
	xor si, si	;x offset
	
	mov dl, frame		   ;left upper corner
	mov word ptr es:[bx], dx
	add bx, 2
	
	mov dl, frame[4]	;horisontal border

	next_top: 				;draw top
		mov word ptr es:[bx], dx

		inc si
		add bx, 2
		cmp si, sp
		jl next_top
	
	mov dl, frame[1]		;right top corner
	mov word ptr es:[bx], dx

	add bx, 160d			;new line
	mov dl, frame[5]		;vertical border

	next_right: 			;draw right
		mov word ptr es:[bx], dx

		inc di
		add bx, 160d
		cmp di, bp
		jl next_right
	
	mov dl, frame[3]		;right bottom corner
	mov word ptr es:[bx], dx
	sub bx, 2d

	mov dl, frame[4]
	
	next_bottom:			;draw bottom
		mov word ptr es:[bx], dx

		dec si
		sub bx, 2d
		cmp si, 0
		ja next_bottom
	
	mov dl, frame[2]		;left bottom corner
	mov word ptr es:[bx], dx
	sub bx, 160d

	mov dl, frame[5]		;vertical border

	next_left:				;draw left
		mov word ptr es:[bx], dx

		dec di
		sub bx, 160d
		cmp di, 0
		ja next_left
	
	mov ax, 4c00h
	int 21h

.data 
frame db 0c9h, 0bbh, 0c8h, 0bch, 0cdh, 0bah
;     _ _   |_   _|  =   ||
;    |   |

end Start