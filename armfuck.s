// armfuck - lightweight-ish brainfuck interpreter written in ARM
// registers
// X0-2 scratch registers
// X3: current BF program counter
// X4: current BF stack counter
// W5: current BF char
// W6: current BF stack char
// W7: temporary depth of []
// X8 reserved for linux
/*
  NOTES:
	- uses a depth counter - no jump table included. this might make it slower but the (practically) infinite nesting with absolutely no memory footprint makes it worth it
	- NOTE2SELF: NEED to make memory safe
*/
.global _start

_start:
	ldr	x3, =bfstr
	ldr	x4, =bfstack
_loop:	// main loop
	ldrb	w5, [x3], #1 // store current program char and increment pointer
	ldrb	w6, [x4]

	// effectively a switch statement
	cmp	w5, #'>'
	B.eq	bf_pointr
	cmp	w5, #'<'
	B.eq	bf_pointl
	cmp	w5, #'+'
	B.eq	bf_add
	cmp	w5, #'-'
	B.eq	bf_sub
	cmp	w5, #'['
	B.eq	bf_brackl
	cmp	w5, #']'
	B.eq	bf_brackr
	cmp	w5, #'.'
	B.eq	bf_write

	B	_cont // break off to ensure no fallthrough

// brainfuck functions
bf_pointr:
	// '>'
	add	x4, x4, #1
	B	_cont
bf_pointl:
	// '<'
	sub	x4, x4, #1
	B	_cont
bf_add:
	// '+'
	add	w6, w6, #1
	and	w6, w6, #0xFF
	strb	w6, [x4]
	B	_cont
bf_sub:
	// '-'
	sub	w6, w6, #1
	and	w6, w6, #0xFF
	strb	w6, [x4]
	B	_cont
bf_write:
	// '.'
	mov	x0, #1  // stdout
	ldr	x1, =scratchstr
	strb	w6, [x1]
	mov	x2, #1
	mov	x8, #64 // write
	svc	#0
	B	_cont
bf_brackl:
	// '['
	cmp	w6, #0
	B.ne	_cont
	mov	x7, #1
_brackl_loop:
	// if depth <= 0 then exit loop
	cmp	x7, #0
	B.le	_brackl_cont
	// if at eof then exit loop
	cmp	w5, #0
	B.eq	_brackl_cont
	ldrb	w5, [x3], #1
	cmp	w5, #0
	B.eq	_brackl_cont

	cmp	w5, #'['
	B.eq	_brackl_loopl
	cmp	w5, #']'
	B.eq	_brackl_loopr
	B	_brackl_loop
_brackl_loopl:
	add	x7, x7, #1
	B	_brackl_loop
_brackl_loopr:
	sub	x7, x7, #1
	B	_brackl_loop

_brackl_cont:
	B	_cont

bf_brackr:
	// ']'
	cmp	w6, #0
	B.eq	_cont
	mov	x7, #1
	ldr	x1, =bfstr
	sub	x3, x3, #1
_brackr_loop:
	// if depth <= 0 then exit loop
	cmp	x7, #0
	B.le	_brackr_cont
	cmp	x3, x1
	B.le	_brackr_cont

	ldrb	w5, [x3, #-1]!

	cmp	w5, #'['
	B.eq	_brackr_loopl
	cmp	w5, #']'
	B.eq	_brackr_loopr
	B	_brackr_loop
_brackr_loopl:
	sub	x7, x7, #1
	B	_brackr_loop
_brackr_loopr:
	add	x7, x7, #1
	B	_brackr_loop
_brackr_cont:
	B	_cont

_cont:
	// if no null terminator reached, loop
	cmp	w5, #0
	B.ne	_loop

_exit:
	// tell Linux to exit
	mov 	x8, #93 // exit routine
	svc 	#0
.data
bfstr: .asciz "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
//bfstr: .asciz "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++." // prints W
//bfstr: .asciz "++[+-++]"
bfstack: .fill 255, 1, 0
scratchstr: .fill 1, 1, 0
