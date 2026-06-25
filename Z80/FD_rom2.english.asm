      ORG	0F000H

			DB	0FFH             ;No ROM identification code
			JP		START
;******************** Return to MONITOR CMT routine *************************************
			JP		MSHED
			JP		MSDAT
			JP		MLHED
			JP		MLDAT
			JP		MVRFY
START:							;This process starts when identification code is changed to ROM present (00H) and FD command is enabled
			LD	HL,DATA			;Copy LENGTH bytes from DATA to TRNS and execute from DSTRT
			LD	DE,(TRNS)
			LD	BC,(LENGTH)
			LDIR
			LD	HL,(DSTRT)
			JP	(HL)
LENGTH:
			DW 03C0H
TRNS:
			DW 5A40H
DSTRT:
			DW 5B00H
MSHED:							;Return to jump destination
			PUSH	DE			;PUSH here as substitute since we jumped here by overwriting a PUSH instruction
			PUSH	BC
			PUSH	HL
			JP	043AH
MSDAT:
			PUSH	DE
			PUSH	BC
			PUSH	HL
			JP	0479H
MLHED:
			PUSH	DE
			PUSH	BC
			PUSH	HL
			JP	04DCH
MLDAT:
			PUSH	DE
			PUSH	BC
			PUSH	HL
			JP 04FCH
MVRFY:
			PUSH	DE
			PUSH	BC
			PUSH	HL
			JP	058CH
DATA:							;Expand the program to be launched from here (4023 bytes available)
			END
