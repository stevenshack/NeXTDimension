/*
 *         INTEL CORPORATION PROPRIETARY INFORMATION
 *
 *    This software is supplied under the terms of a license 
 *    agreement or nondisclosure agreement with Intel Corpo-
 *    ration and may not be copied or disclosed except in
 *    accordance with the terms of that agreement.
 */

/*
 * Location of the users' stored registers relative to TOS
 * Usage is u.u_ar0[XX].
 */

#define R0	(0+4)
#define R1	(1+4)
#define SP	(2+4)
#define FP	(3+4)
#define R4	(4+4)
#define R5	(5+4)
#define R6	(6+4)
#define R7	(7+4)
#define R8	(8+4)
#define R9	(9+4)
#define R10	(10+4)
#define R11	(11+4)
#define R12	(12+4)
#define R13	(13+4)
#define R14	(14+4)
#define R15	(15+4)
#define R16	(16+4)
#define R17	(17+4)
#define R18	(18+4)
#define R19	(19+4)
#define R20	(20+4)
#define R21	(21+4)
#define R22	(22+4)
#define R23	(23+4)
#define R24	(24+4)
#define R25	(25+4)
#define R26	(26+4)
#define R27	(27+4)
#define R28	(28+4)
#define R29	(29+4)
#define R30	(30+4)
#define R31	(31+4)

#define DB	(3)
#define TRAPNO	(2)
#define PC	(1)
#define PSR	(0)

#define FREGS	(32+4)
#define PSTATE	(FREGS+32)
#define SPREGS	(PSTATE+24)

#define PSV_M1		(PSTATE+0)
#define PSV_M2		(PSTATE+2)
#define PSV_M3		(PSTATE+4)
#define PSV_A1		(PSTATE+6)
#define PSV_A2		(PSTATE+8)
#define PSV_A3		(PSTATE+10)
#define PSV_L1		(PSTATE+12)
#define PSV_L2		(PSTATE+14)
#define PSV_L3		(PSTATE+16)
#define PSV_I1		(PSTATE+18)
#define PSV_FSR1	(PSTATE+20)
#define PSV_FSR2	(PSTATE+21)
#define PSV_FSR		(PSTATE+22)

#define SPC_KI		(SPREGS+0)
#define SPC_KR		(SPREGS+2)
#define SPC_T		(SPREGS+4)
#define SPC_MERGE 	(SPREGS+6)
