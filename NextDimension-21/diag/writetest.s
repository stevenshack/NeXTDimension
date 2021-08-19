//
//	Global registers
//
#define AddrMask	r12
#define SlotAddr	r13

#define Rw		r11
#define Rx		r5
#define Ry		r6
#define Rz		r7
#define R_save_r1	r8
#define R_save_psr	r9
#define R_save_fsr	r10

	.data
_sdata:	.globl _sdata
	.blkb	4096			// must be 1 page in size (gets swapped later)
df_stack:	.globl df_stack
intstack:	.globl intstack		// Starting top of interrupt stack, process 0

_bad:		.globl _bad
	.blkb	8192			// Trashable 8K band for flush()
.text
	PSR_IM = 0x10
	EPSR_BE = 0x0080	// High half of EPSR
	
//
//	Host interface addresses.  The Slot portion of the address is ORed in later.
//
	END_ADDR_PORT = 0x0800FFFC
	START_ADDR_PORT = 0x0800FFF8
	TESTINFO_PORT = 0x0800FFF4
	BAD_DATAHIGH_PORT = 0x0800FFF0
	BAD_DATALOW_PORT = 0x0800FFEC
	BAD_ADDR_PORT =	0x0800FFE8

	ADDR_MASK = 0x0FFFFFFF	// mask out high nibble, for slot address
	
	ND_SLOTID = 0xFF800030	// Address of MC reg holding our Slot ID

	
	TEST_BYTE = 1
	TEST_SHORT = 2
	TEST_WORD = 4
	TEST_LONG = 8
	FSR_BITS = 1		// Flush zero, no traps, round nearest

_start::
	// mask all interrupts
	ld.c	psr,r16
	andnot	PSR_IM,r16,r16
	st.c	r16,psr
	ld.c	fir,r0		// Init FIR per PRM 7.8, para 2
	
	// Switch to big-endian mode
	ld.c	epsr,r16
	orh	EPSR_BE,r16,r16
	st.c	r16,epsr
	nop
	
	// Set up address twiddling registers
	orh	h%ADDR_MASK, r0, AddrMask
	or	l%ADDR_MASK, AddrMask, AddrMask

	orh	ha%ND_SLOTID, r0, r16
	ld.l	l%ND_SLOTID(r16), SlotAddr	// I hope this works...
	shl	28, SlotAddr, SlotAddr

	// Flush the data cache
	call	_flush
	nop

	ld.c	dirbase,r16
	or	0x20,r16,r16	// Set ITI to nuke instruction and AT caches
	st.c	r16,dirbase

	// Load registers up:
	// 	r16 holds start addr
	//	r17 holds end addr
	//	r20 holds count
	//	r21 holds a -1
	
	orh	h%START_ADDR_PORT,SlotAddr,r30
	or	l%START_ADDR_PORT,r30,r30
	ld.l	0(r30),r16
	orh	h%END_ADDR_PORT,SlotAddr,r30
	or	l%END_ADDR_PORT,r30,r30
	ld.l	0(r30),r17
	
	subu	r17,r16,r20
	adds	-1,r0,r21
	
	// Decide which test we should run
	orh	h%TESTINFO_PORT,SlotAddr,r30
	or	l%TESTINFO_PORT,r30,r30
	ld.l	0(r30),r18
	and	TEST_BYTE,r18,r0
	nop
	bnc	test_byte
	and	TEST_SHORT,r18,r0
	nop
	bnc	test_short
	and	TEST_WORD,r18,r0
	nop
	bnc	test_word
	and	TEST_LONG,r18,r0
	nop
	bnc	test_long
	// We should never get here.  hah...
	br done
	nop

test_byte:
	bte	r16,r17,done
	st.b	r16,0(r16)
	br	test_byte
	    adds 1,r16,r16

	

test_short:
	andnot	1,r16,r16
	andnot	1,r17,r17
loop_short:
	bte	r16,r17,done
	st.s	r16,0(r16)
	br	loop_short
	    adds 2,r16,r16

test_word:
	andnot	3,r16,r16
	andnot	3,r17,r17
loop_word:
	bte	r16,r17,done
	st.l	r16,0(r16)
	br	loop_word
	    adds 4,r16,r16

test_long:
	andnot	7,r16,r16
	andnot	7,r17,r17
loop_long:
	ixfr	r16,f9		// Address in low half
	xor	r16,r21,r22	// XOR against FFFFFFFF (-1)
	ixfr	r22,f8		// and store complement in high half
	bte	r16,r17,done
	fst.d	f8,0(r16)
	br	loop_long
	    adds 8,r16,r16



//
//	Completed our side of the test
//	Poke a zero in the test data port.  The host is waiting for this
//	
done:
	orh	h%TESTINFO_PORT,SlotAddr,r30
	or	l%TESTINFO_PORT,r30,r30
	st.l	r0,0(r30)
	call	_flush
	nop
	br	done
	nop
		
   
//
// flush():
//
//	Flush the contents of the cache to memory.
//	See Intel i860 PRM page 5-15, example 5-2 for 'details'
//
//	I don't know why it works.  It just does...
//
//	NOTE:  Other code assumes that r28, r29, and r30 are untouched here.
//
//	CHIP BUG: Step B2, Bug 23.  Code in this module assumes that it is aligned
//		on a 32 bit boundry.  Therefore, rather than being compiled
//		independently, this module is #included into locore.s. Bletch
//
//
//	flush()
//
_flush:	.globl _flush
	mov	r1, R_save_r1
//	Disable traps and interrupts during flush
	ld.c	psr, R_save_psr
	andnot	PSR_IM,R_save_psr,Rz
	st.c	Rz, psr
	nop
	ld.c	fsr, R_save_fsr
	or	FSR_BITS,r0,Rz
	st.c	Rz, fsr
//	The flush code, from the book.
	ld.c	dirbase,	Rz
	or	0x800,	Rz,	Rz	// RC <-- 0b10 (assuming was 00)
	adds	-1,	r0,	Rx	// Rx <-- -1 (loop increment)
	call	D_FLUSH
	st.c	Rz,	dirbase		// Replace in block 0
	or	0x900,	Rz,	Rz	// RB <-- 0b01
	call	D_FLUSH
	st.c	Rz,	dirbase
	xor	0x900,	Rz,	Rz	// Clear RC and RB
//	Change DTB, ATE, or ITI fields here, if necessary.
	st.c	Rz,	dirbase
//	End of cribbed code.
//	Restore traps and interrupts
	st.c	R_save_fsr, fsr
	st.c	R_save_psr, psr
	nop
	bri	R_save_r1
	nop
	
D_FLUSH:
	orh	h%(_bad-32), r0, Rw	// Rw <-- address - 32
	or	l%(_bad-32), Rw, Rw	//  of flush area.
	and	AddrMask, Rw, Rw	//  Convert linked address to a
	or	SlotAddr, Rw, Rw	//  physical memory address
	or	127,	r0,	Ry	// Ry <-- loop count
	ld.l	32(Rw),	r31		// CHIP BUG: Step B2, Bug 23
	ld.l	32(Rw),	r31		// Clear any pending bus writes
	shl	0,	r31,	r31	// Wait until load finishes
	bla	Rx, Ry, D_FLUSH_LOOP	// One time to initialize LCC
	nop
	.align 32			// CHIP BUG: Step B2, Bug 23
D_FLUSH_LOOP:
	ixfr	r0,	f0		// CHIP BUG: Step B2, Bug 23
	bla	Rx, Ry, D_FLUSH_LOOP	// Loop: execute next insn for 128
	    flush	32(Rw)++	// lines in cache block
	ixfr	r0,f0			// CHIP BUG Step B2, C0, Mystery Bug
					// (Intel says add this)
	bri	r1			// Return after next insn
	ld.l	-512(Rw),	r0	// Load from flush area to clear pending
					// writes.  A hit is guaranteed.
