	.file	"_negdf2.c"
// ccom  -O -X22 -X74 -X80 -X83 -X247 -X254 -X266 -X278 -X325 -X350 -X383 -X422
//	 -X424 -X501 -X523 -X524 -X525

	.text
	.align	4
___negdf2:
//	    .bf
//	    .ef
	bri	r1
	 fsub.dd	f0,f8,f8
	.align	4
	.data
.L5:

//_a	f8	local

	.text
	.data
//_target_flags	_target_flags	import
	.globl	___negdf2

	.text
