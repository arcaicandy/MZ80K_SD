;2021.12.12 Fix for garbled characters in FDP and FDM on MZ-700
;2022. 1.23 Fix bug in 04D8H MONITOR read information alternative processing
;2022. 1.24 Moved processing to fix trailing 20h padding in filename to 0dh from Arduino side to MZ-80K side
;2022. 1.25 Removed 8255 initialization from 0475H MONITOR write data alternative processing and 04F8H MONITOR read data alternative processing
;2022. 1.26 Removed restriction that only file type code 0x01 was loadable via FD command
;2022. 1.29 Removed interrupt enable (EI) on RETURN from CMT alternative processing
;2022. 1.31 Fix for machines/apps where app operation freezes after FD command execution
;2022. 1.31 FDL command spec change: for FDL x, compare first character of filename and output only matches
;           B key to display previous 20 entries
;2022. 2. 8 FDL command spec change: for FDL x, extended to match first 1 to 32 characters of filename
;2022. 2.10 Fixed to allow FDL command to be used from within 04D8H MONITOR read information alternative processing
;           Made FDL command processing into a subroutine
;2022. 2.11 Fixed bug where FDL command called from within 04D8H MONITOR read information alternative processing could not be used under MZ-700 MONITOR 1Z-009A, 1Z-009B environment

GETL				EQU		0003H
LETLN				EQU		0006H
NEWLIN			EQU		0009H
PRNTS				EQU		000CH
MSGPR				EQU		0015H
PLIST				EQU		0018H
GETKEY			EQU		001BH
TIMST				EQU		0033H
PRTWRD			EQU		03BAH
PRTBYT			EQU		03C3H
HLHEX				EQU		0410H
TWOHEX			EQU		041FH
ADCN				EQU		0BB9H
DISPCH			EQU		0DB5H
DPCT				EQU		0DDCH
IBUFE				EQU		10F0H
FNAME				EQU		10F1H
EADRS				EQU		1102H
FSIZE				EQU		1102H
SADRS				EQU		1104H
EXEAD				EQU		1106H
DSPX				EQU		1171H
LBUF				EQU		11A3H
MBUF				EQU		11AEH
MONITOR_80K	EQU		0082H
MONITOR_700	EQU		00ADH
;0D8H PORTA transmit data (lower 4 bits)
;0D9H PORTB receive data (8 bits)
;
;0DAH PORTC Bit
;7 IN  CHK
;6 IN
;5 IN
;4 IN 
;3 OUT
;2 OUT FLG
;1 OUT
;0 OUT
;
;0DBH Control register

    ORG		0F000H

		NOP                   ;ROM identification code
		JP		START
;******************** MONITOR CMT routine alternative *************************************
ENT1:	JP		MSHED
ENT2:	JP		MSDAT
ENT3:	JP		MLHED
ENT4:	JP		MLDAT
ENT5:	JP		MVRFY
		
START:	CALL	INIT
		LD		DE,LBUF     ;Startup command unified to '*FD' for both MZ-80K and MZ-700
		LD		A,(DE)
		CP		'*'
		JP		NZ,MON
		INC 	DE
		LD		A,(DE)
		CP		'F'
		JP		NZ,MON
		INC		DE
		LD		A,(DE)
		CP		'D'
		JP		NZ,MON
		
		INC		DE          ;Move to character after FD
STT2:	LD		A,(DE)
		CP		20H         ;If there is 1 space after FD, load the rest as filename (filename up to 32 chars)
		JR		Z,SDLOAD
		CP		'/'         ;If '/' follows FD, load the rest as filename but do not execute (filename up to 32 chars)
		JR		Z,SDLOAD
		CP		0DH         ;If FD alone followed by newline, load DEFNAME string as filename
		JR		NZ,STETC    ;If no match, check other commands
STT3:	PUSH	DE          ;Transfer configured filename (0000.mzt)
		LD		HL,DEFNAME
		INC		DE
		LD		BC,NEND-DEFNAME
		LDIR
		POP		DE
		JR		SDLOAD      ;Go to LOAD processing
STETC:
		CP		'S'         ;FDS: go to SAVE processing
		JP		Z,STSV
		CP		'A'					;FDA: go to auto-start file setting processing
		JP		Z,STAS
		CP		'L'         ;FDL: file list display
		JP		Z,STLT
		CP		'D'         ;FDD: DELETE
		JP		Z,STDE
		CP		'R'         ;FDR: RENAME
		JP		Z,STRN
		CP		'P'         ;FDP: DUMP
		JP		Z,STPR
		CP		'C'         ;FDC: COPY
		JP		Z,STCP
		CP		'M'         ;FDM: MEMORY DUMP
		JP		Z,STMD
		CP		'W'         ;FDW: MEMORY WRITE
		JP		Z,STMW
		CP		'Z'         ;FDZ: MZ-700 PATCH START
		JP		Z,STMZ
		CP		'U'         ;FDU: MZ-700 shadow RAM START
		JP		Z,STURA
		JP		CMDERR

;**** 8255 initialization ****
;PORTC lower bits OUTPUT, upper bits INPUT, PORTB INPUT, PORTA OUTPUT
INIT:	LD		A,8AH
		OUT		(0DBH),A
;Reset output bits
INIT2:	LD		A,00H      ;PORTA <- 0
		OUT		(0D8H),A
		OUT		(0DAH),A   ;PORTC <- 0
		RET

;**** LOAD ****
;Set received header information and execute LOAD from SD card
SDLOAD:	LD		A,81H  ;LOAD command 81H
		CALL	STCMD
		CALL	HDRCV      ;Receive header information
		CALL	DBRCV      ;Receive data
		LD		A,(LBUF+3)
		CP		'/'        ;If '*FD/', return to MONITOR command prompt without jumping to execution address
		JP		Z,MON
; Fix for machines/apps where app operation freezes after FD command execution
		LD		A,00H
		LD		DE,0000H
		CALL	TIMST
		
		LD		HL,(EXEAD)
		JP		(HL)

;Receive header
HDRCV:	LD		HL,FNAME
		LD		B,11H
HDRC1:	CALL	RCVBYTE    ;Receive filename
		LD		(HL),A
		INC		HL
		DEC		B
		JR		NZ,HDRC1
		LD		DE,MSG_LD  ;Display filename LOADING
		CALL	MSGPR
		LD		DE,FNAME
		CALL	MSGPR
		CALL	LETLN
		LD		HL,SADRS  ;Get SADRS
		CALL	RCVBYTE
		LD		(HL),A
		INC		HL
		CALL	RCVBYTE
		LD		(HL),A
		LD		HL,FSIZE   ;Get FSIZE
		CALL	RCVBYTE
		LD		(HL),A
		INC		HL
		CALL	RCVBYTE
		LD		(HL),A
		LD		HL,EXEAD   ;Get EXEAD
		CALL	RCVBYTE
		LD		(HL),A
		INC		HL
		CALL	RCVBYTE
		LD		(HL),A
		RET

;Receive data
DBRCV:	LD		DE,(FSIZE)
		LD		HL,(SADRS)
DBRLOP:	CALL	RCVBYTE
		LD		(HL),A
		DEC		DE
		LD		A,D
		OR		E
		INC		HL
		JR		NZ,DBRLOP   ;LOOP until DE=0
		RET

;**** SAVE ****
STSV:	INC		DE
		INC		DE
		PUSH	DE
		CALL	HLHEX       ;If 4-digit hex follows 1 space, set to SADRS and continue
		JR		C,STSV1
		LD		(SADRS),HL      ;Save SADRS
		POP		DE
		INC		DE
		INC		DE
		INC		DE
		INC		DE
		INC		DE
		PUSH	DE          ;Advance 5 chars, if 4-digit hex, set to EADRS and continue
		CALL	HLHEX
		JR		C,STSV1
		PUSH	HL
		LD		BC,(SADRS)
		SBC		HL,BC       ;Error if EADRS is not greater than SADRS
		POP		HL
		JR		Z,STSV1
		JR		C,STSV1

		LD		(EADRS),HL      ;Save EADRS
		POP		DE
		INC		DE
		INC		DE
		INC		DE
		INC		DE
		INC		DE          ;Advance 5 chars, if 4-digit hex, set to EXEAD and continue
		PUSH	DE
		CALL	HLHEX
		JR		C,STSV1
		
		LD		(EXEAD),HL      ;Save EXEAD
		POP		DE
		INC		DE
		INC		DE
		INC		DE
		INC		DE
		INC		DE			;Advance 5 chars, continue if filename present
		LD		A,(DE)
		CP		31H
		JR		C,STSV2
		EX		DE,HL
		JR		SDSAVE      ;Go to SAVE processing
STSV1:                      ;Failed to get 4-digit hex or EADRS not greater than SADRS
		LD		DE,MSG_AD
		JR		ERRMSG
STSV2:                      ;Failed to get filename
		LD		DE,MSG_FNAME
		JR		ERRMSG
CMDERR:                     ;Command error
		LD		DE,MSG_CMD
		JR		ERRMSG

;Set transmit header information and execute SAVE to SD card
SDSAVE:	LD		A,80H      ;SAVE command 80H
		CALL	STCD
		AND		A          ;ERROR if not 00
		JP		NZ,SVERR
		CALL	HDSEND     ;Send header information
		CALL	RCVBYTE    ;Get status (00H=OK)
		AND		A          ;ERROR if not 00
		JR		NZ,SVERR
		CALL	DBSEND     ;Send data
		LD		DE,MSG_SV
		JR		ERRMSG

SVER0:
		POP		DE         ;Discard CALL source STACK
SVERR:
		CP		0F0H
		JR		NZ,ERR3
		LD		DE,MSG_F0  ;SD-CARD INITIALIZE ERROR
		JR		ERRMSG
;Removed restriction that only file type code 0x01 was loadable via FD command
;ERR2:	CP		0F2H
;		JR		NZ,ERR3
;		LD		DE,MSG_F2  ;NOT OBJECT FILE
;		JR		ERRMSG
ERR3:	CP		0F1H
		JR		NZ,ERR4
		LD		DE,MSG_F1  ;NOT FIND FILE
		JR		ERRMSG
ERR4:	CP		0F3H
		JR		NZ,ERR5
		LD		DE,MSG_F3  ;FILE EXIST
		JR		ERRMSG
ERR5:	CP		0F4H
		JR		NZ,ERR99
		LD		DE,MSG_CMD
		JR		ERRMSG
ERR99:	CALL	PRTBYT
		LD		DE,MSG99   ;Other ERROR
ERRMSG:	CALL	MSGPR
		CALL	LETLN
MON:	LD		HL,014EH
		LD		A,(HL)
		CP		'P'             ;If 014EH is 'P' then MZ-80K
		JP		Z,MONITOR_80K
		CP		'N'             ;If 014EH is 'N' then FN-700
		JP		Z,MONITOR_80K
		LD		HL,06EBH
		LD		A,(HL)
		CP		'M'             ;If 06EBH is 'M' then MZ-700
		JP		Z,MONITOR_700
		JP		0000H           ;If unidentified, jump to 0000H

;Send header
HDSEND:	PUSH	HL
		LD		B,20H
SS1:	LD		A,(HL)     ;Send FNAME
		CALL	SNDBYTE
		INC		HL
		DEC		B
		JR		NZ,SS1
		LD		A,0DH
		CALL	SNDBYTE
		POP		HL
		LD		B,10H
SS2:	LD		A,(HL)     ;Send PNAME
		CALL	SNDBYTE
		INC		HL
		DEC		B
		JR		NZ,SS2
		LD		A,0DH
		CALL	SNDBYTE
		LD		HL,SADRS   ;Send SADRS
		LD		A,(HL)
		CALL	SNDBYTE
		INC		HL
		LD		A,(HL)
		CALL	SNDBYTE
		LD		HL,EADRS   ;Send EADRS
		LD		A,(HL)
		CALL	SNDBYTE
		INC		HL
		LD		A,(HL)
		CALL	SNDBYTE
		LD		HL,EXEAD   ;Send EXEAD
		LD		A,(HL)
		CALL	SNDBYTE
		INC		HL
		LD		A,(HL)
		CALL	SNDBYTE
		RET

;Send data
;Transmit from SADRS to EADRS
DBSEND:	LD		HL,(EADRS)
		EX		DE,HL
		LD		HL,(SADRS)
DBSLOP:	LD		A,(HL)
		CALL	SNDBYTE
		LD		A,H
		CP		D
		JR		NZ,DBSLP1
		LD		A,L
		CP		E
		JR		Z,DBSLP2   ;LOOP until HL = DE
DBSLP1:	INC		HL
		JR		DBSLOP
DBSLP2:	RET

;**** AUTO START SET ****
STAS:	LD		A,82H      ;AUTO START SET command 82H
		CALL	STCMD
		LD		DE,MSG_AS
		JP		ERRMSG


;**** DIRLIST ****
STLT:	INC		DE
		LD		HL,DEFDIR         ;Prefix '*FD ' to allow cursor movement and execution with RETURN
		LD		BC,DEND-DEFDIR
		CALL	DIRLIST
		AND		A                 ;ERROR if not 00
		JP		NZ,SVERR
		JP		MON


;**** DIRLIST main body (HL=start address of prefix string, BC=length of prefix string) ****
;****                    Return value: A=error code ****
DIRLIST:
		LD		A,83H      ;Send DIRLIST command 83H
		CALL	STCD       ;Send command code
		AND		A          ;ERROR if not 00
		JP		NZ,DLRET
		
		PUSH	BC
		LD		B,21H
STLT1:	LD		A,(DE)
		CP		0DH
		JR		NZ,STLT2
		LD		A,00H
STLT2:	CALL	SNDBYTE           ;Send page indication
		INC		DE
		DEC		B
		JR		NZ,STLT1
		POP		BC
DL1:
		PUSH	HL
		PUSH	BC
;		LD		HL,DEFDIR         ;Prefix '*FD ' to allow cursor movement and execution with RETURN
		LD		DE,LBUF
;		LD		BC,DEND-DEFDIR
		LDIR
		EX		DE,HL
DL2:	CALL	RCVBYTE           ;One line ends when '00H' is received
		CP		00H
		JR		Z,DL3
		CP		0FFH              ;End when '0FFH' is received
		JR		Z,DL4
		CP		0FEH              ;Pause and wait for one character input when '0FEH' is received
		JR		Z,DL5
		LD		(HL),A
		INC		HL
		JR		DL2
DL3:	LD		DE,LBUF           ;Display one line and newline when '00H' is received
		CALL	MSGPR
		CALL	LETLN
		POP		BC
		POP		HL
		JR		DL1
DL4:	CALL	RCVBYTE           ;Get status (00H=OK)
		POP		BC
		POP		HL
		JR		DLRET

DL5:	LD		DE,MSG_KEY1        ;Display HIT ANY KEY
		CALL	MSGPR
		LD		A,0C2H
		CALL	DISPCH
		LD		DE,MSG_KEY2        ;Display HIT ANY KEY
		CALL	MSGPR
		CALL	LETLN
DL6:	CALL	GETKEY            ;Wait for one character input
		CP		00H
		JR		Z,DL6
		CP		64H               ;Abort with SHIFT+BREAK
		JR		Z,DL7
		CP		12H               ;Abort with cursor UP
		JR		Z,DL9
		CP		42H               ;'B' for previous page
		JR		Z,DL8
		LD		A,00H             ;Continue with any other key
		JR		DL8
DL9:	LD		A,0C2H            ;Move cursor 2 lines up when aborted with cursor UP
		CALL	DPCT
		LD		A,0C2H
		CALL	DPCT
DL7:	LD		A,0FFH            ;Send 0FFH abort code
DL8:	CALL	SNDBYTE
		CALL	LETLN
		JR		DL2
		
DLRET:		
		RET


;**** FILE DELETE ****
STDE:	LD		A,84H      ;FILE DELETE command 84H
		CALL	STCMD

		LD		DE,MSG_DELQ ;Display 'DELETE?'
		CALL	MSGPR
		CALL	LETLN
STDE3:	CALL	GETKEY
		CP		00H
		JR		Z,STDE3
		CP		59H         ;If 'Y', send 00H as OK
		JR		NZ,STDE4
		LD		A,00H
		JR		STDE5
STDE4:	LD		A,0FFH      ;If not 'Y', send 0FFH as CANCEL
STDE5:	CALL	SNDBYTE
		CALL	RCVBYTE
		CP		00H         ;If 00H received, DELETE complete
		JR		NZ,STDE6
		LD		DE,MSG_DELY ;Display 'DELETE OK'
		JR		STDE8
STDE6:	CP		01H         ;If 01H received, CANCEL complete
		JR		NZ,STDE7
		LD		DE,MSG_DELN ;Display 'DELETE CANCEL'
		JR		STDE8
STDE7:	JP		SVERR
STDE8:	JP		ERRMSG

;**** FILE RENAME ****
STRN:	LD		A,85H      ;FILE RENAME command 85H
		CALL	STCMD

		LD		DE,MSG_REN ;Display 'NEW NAME:'
		CALL	MSGPR
		
		LD		A,09H
		LD		(DSPX),A  ;Move cursor to next position after 'NEW NAME:'
		LD		DE,LBUF    ;Get NEW FILE NAME
		CALL	GETL
		LD		DE,LBUF+8  ;Send NEW FILE NAME
		CALL	STFN
		CALL	STFS
		
		CALL	RCVBYTE
		CP		00H         ;If 00H received, RENAME complete
		JP		NZ,SVERR
		LD		DE,MSG_RENY
		JP		ERRMSG

;**** FILE DUMP ****
STPR:	LD		A,86H      ;FILE DUMP command 86H
		CALL	STCMD

;		LD		A,0C6H     ;Clear screen
;		CALL	DPCT
STPR6:	LD		HL,SADRS   ;Get SADRS
		CALL	RCVBYTE
		LD		(HL),A
		INC		HL
		CALL	RCVBYTE
		LD		(HL),A
		LD		HL,(SADRS)
		LD		A,H
		CP		0FFH        ;If 0FFFFH is sent as ADRS, end DUMP processing
		JR		NZ,STPR7
		LD		A,L
		CP		0FFH
		JR		NZ,STPR7
		JP		STPR8
STPR7:	LD		DE,MSG_AD1 ;Display DUMP TITLE
		CALL	MSGPR
		CALL	LETLN
		LD		C,10H      ;Display 16 rows (128 bytes)
STPR0:	PUSH	BC
		LD		B,08H      ;Receive one row (8 bytes)
		LD		HL,LBUF
STPR1:	CALL	RCVBYTE
		LD		(HL),A
		INC		HL
		DEC		B
		JR		NZ,STPR1

		LD		HL,(SADRS) ;Display address
		CALL	PRTWRD
		LD		DE,0008H   ;Self-increment address since not received during one screen (128 bytes)
		ADD		HL,DE
		LD		(SADRS),HL
		
		LD		B,08H      ;Display one row (8 bytes) of data in hex
		LD		DE,LBUF
STPR2:	CALL	PRNTS
		LD		A,(DE)
		CALL	PRTBYT
		INC		DE
		DEC		B
		JR		NZ,STPR2
		
		CALL	PRNTS
		LD		DE,LBUF    ;Display one row (8 bytes) of data as characters
		LD		B,08H
STPR9:	LD		A,(DE)
		CP		10H        ;Fix for garbled characters on MZ-700
		JR		NC,STPRA
		LD		A,20H
STPRA:	CALL	ADCN
		CALL	DISPCH
		INC		DE
		DEC		B
		JR		NZ,STPR9

		CALL	LETLN
		POP		BC
		DEC		C
		JR		NZ,STPR0
		
		LD		DE,MSG_AD2        ;Display input wait message
		CALL	MSGPR
		CALL	LETLN
		CALL	LETLN
STPR3:	CALL	GETKEY            ;Wait for one character input
		CP		00H
		JR		Z,STPR3
		CP		64H               ;Abort with SHIFT+BREAK
		JR		Z,STPR4
		CALL	SNDBYTE           ;Send ASCII code as-is for other keys, Arduino side handles 'B'
		JP		STPR6
STPR4:	LD		A,0FFH            ;Send 0FFH abort code
STPR5:	CALL	SNDBYTE
		CALL	RCVBYTE           ;Discard received ADRS '0FFFFH' and status code on SHIFT+BREAK abort
		CALL	RCVBYTE
STPR8:	CALL	RCVBYTE
		JP		MON

;**** FILE COPY ****
STCP:	LD		A,87H      ;FILE COPY command 87H
		CALL	STCMD
		LD		DE,MSG_REN ;Display 'NEW NAME:'
		CALL	MSGPR
		
		LD		A,09H
		LD		(DSPX),A    ;Move cursor to next position after 'NEW NAME:'
		LD		DE,LBUF      ;Get NEW FILE NAME
		CALL	GETL
		LD		DE,LBUF+8    ;Send NEW FILE NAME
		CALL	STFN
		CALL	STFS
		
		CALL	RCVBYTE
		CP		00H         ;If 00H received, RENAME complete
		JP		NZ,SVERR
		LD		DE,MSG_CPY
		JP		ERRMSG

;**** MEMORY DUMP ****
STMD:	INC		DE
		INC		DE
		CALL	HLHEX       ;If 4-digit hex follows 1 space, set to SADRS and continue
		JP		C,STSV1
		LD		(SADRS),HL      ;Save SADRS

STMD6:	LD		DE,MSG_AD1 ;Display DUMP TITLE
		CALL	MSGPR
		CALL	LETLN
		LD		C,10H      ;Display 16 rows (128 bytes)
STMD7:	LD		HL,(SADRS) ;Display address
		CALL	PRTWRD
		CALL	PRNTS
		

		LD		B,08H      ;Display one row (8 bytes) of data in hex
STMD0:	LD		A,(HL)
		CALL	PRTBYT
		CALL	PRNTS
		CALL	GETKEY
		CP		64H
		JR		Z,STMD4
		INC		HL
		DEC		B
		JR		NZ,STMD0

		LD		HL,(SADRS)
		LD		B,08H      ;Display one row (8 bytes) of data as characters
STMD2:	LD		A,(HL)
		CP		10H        ;Fix for garbled characters on MZ-700
		JR		NC,STMD8
		LD		A,20H
STMD8:	CALL	ADCN
		CALL	DISPCH
		CALL	GETKEY
		CP		64H        ;Abort with SHIFT+BREAK even during display
		JR		Z,STMD4
		INC		HL
		DEC		B
		JR		NZ,STMD2

		LD		(SADRS),HL
		CALL	LETLN

		DEC		C
		JR		NZ,STMD7
		
		LD		DE,MSG_AD2        ;Display input wait message
		CALL	MSGPR
		CALL	LETLN
		CALL	LETLN
STMD3:	CALL	GETKEY            ;Wait for one character input
		CP		00H
		JR		Z,STMD3
		CP		64H               ;Abort with SHIFT+BREAK
		JR		Z,STMD4
		CP		42H
		JR		NZ,STMD5
		LD		HL,(SADRS)
		LD		DE,0100H
		SBC		HL,DE
		LD		(SADRS),HL
STMD5:	JP		STMD6
STMD4:	JP		MON

;**** MEMORY WRITE ****
STMW:	INC		DE
		INC		DE
		CALL	HLHEX       ;If 4-digit hex follows 1 space, set to HL and continue
		JP		C,STSV1

		INC		DE
		INC		DE
		INC		DE
		INC		DE
STSP1:	LD		A,(DE)
		CP		0DH
		JR		Z,STMW9     ;If address only, end
		CP		20H
		JR		NZ,STMW1
		INC		DE          ;Skip spaces
		JR		STSP1

STMW1:
		CALL	TWOHEX
		JR		C,STMW8
		LD		(HL),A      ;If 2-digit hex present, write to (HL)
		INC		HL

STSP2:	LD		A,(DE)
		CP		0DH         ;End of line
		JR		Z,STMW8
		CP		20H
		JR		NZ,STMW1
		INC		DE          ;Skip spaces
		JR		STSP2

STMW8:	
		LD		DE,MSG_FDW  ;'*FDW ' at line start
		CALL	MSGPR
		CALL	PRTWRD      ;Display address
		CALL	PRNTS
		LD		DE,LBUF     ;Input one line
		CALL	GETL
		LD		DE,LBUF
		LD		A,(DE)
		CP		1BH
		JR		Z,STMW9     ;Discard and end with SHIFT+BREAK
		LD		DE,LBUF+3
		JR		STMW
STMW9:	JP		MON

;**** MZ-700 PATCH START ****
STMZ:	DI
		LD		HL,0000H      ;Copy ROM to 2000H
		LD		DE,2000H
		LD		BC,1000H
		LDIR
		OUT		(0E0H),A      ;Shadow RAM ON
		LD		HL,2000H      ;Copy ROM contents to shadow RAM
		LD		DE,0000H
		LD		BC,1000H
		LDIR
		LD		HL,STMZ2      ;Rewrite addresses
		LD		DE,STMZ3      ;Rewrite data
		LD		B,0FH
STMZ1:	PUSH	BC
		LD		C,(HL)
		INC		HL
		LD		B,(HL)
		LD		A,(DE)
		LD		(BC),A
		POP		BC
		INC		DE
		INC		HL
		DEC		B
		JR		NZ,STMZ1
		LD		HL,00ADH
		LD		A,(HL)
		CP		0CDH
		JP		NZ,0000H         ;If cannot identify as MZ-700, start from 0000H
		LD		DE,MSG_ST
		CALL	MSGPR
		CALL	LETLN
		JP		MONITOR_700      ;If identified as MZ-700, start from 00ADH

STMZ2:	DW		0437H,0438H,0439H
		DW		0476H,0477H,0478H
		DW		04D9H,04DAH,04DBH
		DW		04F9H,04FAH,04FBH
		DW		0589H,058AH,058BH

STMZ3:	DB		0C3H
		DW		ENT1
		DB		0C3H
		DW		ENT2
		DB		0C3H
		DW		ENT3
		DB		0C3H
		DW		ENT4
		DB		0C3H
		DW		ENT5

;**** MZ-700 shadow RAM START ****
STURA:	OUT		(0E0H),A      ;Shadow RAM ON
		LD		HL,00ADH
		LD		A,(HL)
		CP		0CDH
		JP		NZ,0000H         ;If not 0CDH, assume NZ-700 etc. and start from 0000H
		LD		DE,MSG_ST
		CALL	MSGPR
		CALL	LETLN
		JP		MONITOR_700      ;If (00ADH) is 0CDH, assume patched MONITOR of 1Z-009A or 1Z-009B and start from 00ADH

;**** Receive 1 BYTE ****
;Set received DATA in A register and return
RCVBYTE:
		CALL	F1CHK      ;LOOP until PORTC BIT7 becomes 1
		IN		A,(0D9h)   ;PORTB -> A
		PUSH 	AF
		LD		A,05H
		OUT		(0DBH),A    ;PORTC BIT2 <- 1
		CALL	F2CHK      ;LOOP until PORTC BIT7 becomes 0
		LD		A,04H
		OUT		(0DBH),A    ;PORTC BIT2 <- 0
		POP 	AF
		RET
		
;**** Send 1 BYTE ****
;Send contents of A register to PORTA lower 4 bits, 4 bits at a time
SNDBYTE:
		PUSH	AF
		RRA
		RRA
		RRA
		RRA
		AND		0FH
		CALL	SND4BIT
		POP		AF
		AND		0FH
		CALL	SND4BIT
		RET

;**** Send 4 BITS ****
;Send lower 4 bits of A register
SND4BIT:
		OUT		(0D8H),A
		LD		A,05H
		OUT		(0DBH),A    ;PORTC BIT2 <- 1
		CALL	F1CHK      ;LOOP until PORTC BIT7 becomes 1
		LD		A,04H
		OUT		(0DBH),A    ;PORTC BIT2 <- 0
		CALL	F2CHK
		RET
		
;**** Check BUSY (1) ****
; Loop until 82H BIT7 becomes 1
F1CHK:	IN		A,(0DAH)
		AND		80H        ;PORTC BIT7 = 1?
		JR		Z,F1CHK
		RET

;**** Check BUSY (0) ****
; Loop until 82H BIT7 becomes 0
F2CHK:	IN		A,(0DAH)
		AND		80H        ;PORTC BIT7 = 0?
		JR		NZ,F2CHK
		RET

;****** Get FILE NAME (IN: DE next character after command, OUT: HL start of filename) *********
STFN:	PUSH	AF
STFN1:	INC		DE         ;Skip spaces up to filename
		LD		A,(DE)
		CP		20H
		JR		Z,STFN1
		CP		30H        ;Error if character is not '0' or higher
		JP		C,STSV2
		EX		DE,HL
		POP		AF
		RET

;**** Send command (IN: A command code) ****
STCD:	CALL	SNDBYTE    ;Send command code in A register
		CALL	RCVBYTE    ;Get status (00H=OK)
		RET

;**** Send filename (IN: HL start of filename) ******
STFS:	LD		B,20H
STFS1:	LD		A,(HL)     ;Send FNAME
		CALL	SNDBYTE
		INC		HL
		DEC		B
		JR		NZ,STFS1
		LD		A,0DH
		CALL	SNDBYTE
		CALL	RCVBYTE    ;Get status (00H=OK)
		RET

;**** Send command and filename (IN: A command code, HL: start of filename) ****
STCMD:	CALL	STFN       ;Get filename
		PUSH	HL
		CALL	STCD       ;Send command code
		POP		HL
		AND		A          ;ERROR if not 00
		JP		NZ,SVER0
		CALL	STFS       ;Send filename
		AND		A          ;ERROR if not 00
		JP		NZ,SVER0
		RET

;******** MESSAGE DATA ********************
MSG_LD:
		DB		16H
		DB		'LOADING '
		DB		0DH

WRMSG:
		DB		'WRITING '
		DB		0DH

MSG_SV:
		DB		'SAVE FINISHED!'
		DB		0DH
		
MSG_AS:
		DB		'ASTART FINISHED!'
		DB		0DH
		
MSG_ST:
		DB		'PATCHED MONITOR START!'
		DB		0DH
		
MSG_AD:
		DB		'ADDRESS FAILED!'
		DB		0DH
		
MSG_FNAME:
		DB		'FILE NAME FAILED!'
		DB		0DH
		
MSG_CMD:
		DB		'COMMAND FAILED!'
		DB		0DH
		
MSG_F0:
		DB		'SD-CARD INITIALIZE ERROR'
		DB		0DH
		
MSG_F1:
		DB		'FILE NOT FOUND'
		DB		0DH
		
;MSG_F2:
;		DB		'NOT OBJECT FILE'
;		DB		0DH
		
MSG_F3:
		DB		'FILE EXISTS'
		DB		0DH
		
MSG_KEY1:
		DB		'NEXT:ANY BACK:B BREAK:'
		DB		0DH
MSG_KEY2:
		DB		' OR SHIFT+BREAK'
		DB		0DH
		
MSG_DELQ:
		DB		'FILE DELETE? (Y:OK ELSE:CANCEL)'
		DB		0DH
		
MSG_DELY:
		DB		'DELETE OK'
		DB		0DH
		
MSG_DELN:
		DB		'DELETE CANSEL'
		DB		0DH
		
MSG_REN:
		DB		'NEW NAME:                            '
		DB		0DH
		
MSG_DNAME:
		DB		'DOS FILE:'
MSG_DNAMEEND:
		DB		'                            '
		DB		0DH
		
MSG_RENY:
		DB		'RENAME OK'
		DB		0DH
		
MSG_AD1:
		DB		'ADRS +0 +1 +2 +3 +4 +5 +6 +7 01234567'
		DB		0DH
		
MSG_AD2:
		DB		'NEXT:ANY BACK:B BREAK:SHIFT+BREAK'
		DB		0DH
		
MSG_CPY:
		DB		'COPY OK'
		DB		0DH
		
MSG_FDW:
		DB		'*FDW '
		DB		0DH

MSG99:
		DB		' ERROR'
		DB		0DH
		
DEFNAME:
		DB		'0000'
		DB		0DH
NEND:

DEFDIR:
		DB		'*FD  '
DEND:

;*********************** 0436H MONITOR write information alternative processing ************
MSHED:
		DI
		PUSH	DE
		PUSH	BC
		PUSH	HL
		CALL	INIT
		LD		A,91H      ;HEADER SAVE command 91H
		CALL	MCMD       ;Send command code
		AND		A          ;ERROR if not 00
		JP		NZ,MERR

;S-OS SWORD and 8080 text editor & assembler pad the end of filename with 20h, so fix to 0dh
		LD		B,11H
		LD		HL,FNAME+10H     ;Filename
		LD		A,0DH            ;Always set 0DH at 17th character
		LD		(HL),A
MSH0:	LD		A,(HL)
		CP		0DH              ;If 0DH, check previous character
		JR		Z,MSH1
		CP		20H              ;If 20H, set 0DH and check previous character
		JR		NZ,MSH2          ;If neither 0DH nor 20H, end
		LD		A,0DH
		LD		(HL),A
		
MSH1:	DEC		HL
		DEC		B
		JR		NZ,MSH0

MSH2:	CALL	LETLN
		LD		DE,WRMSG   ;'WRITING '
		CALL	MSGPR        ;Display message
		LD		DE,FNAME     ;Filename
		CALL	MSGPR       ;Display message

		LD		HL,IBUFE
		LD		B,80H
MSH3:	LD		A,(HL)     ;Send information block
		CALL	SNDBYTE
		INC		HL
		DEC		B
		JR		NZ,MSH3

		CALL	RCVBYTE    ;Get status (00H=OK)
		AND		A          ;ERROR if not 00
		JP		NZ,MERR

		JP		MRET       ;Normal RETURN

;******************** 0475H MONITOR write data alternative processing **********************
MSDAT:
		DI
		PUSH	DE
		PUSH	BC
		PUSH	HL
		LD		A,92H      ;DATA SAVE command 92H
		CALL	MCMD       ;Send command code
		AND		A          ;ERROR if not 00
		JP		NZ,MERR

		LD		HL,FSIZE   ;Send FSIZE
		LD		A,(HL)
		CALL	SNDBYTE
		INC		HL
		LD		A,(HL)
		CALL	SNDBYTE

		CALL	RCVBYTE    ;Get status (00H=OK)
		AND		A          ;ERROR if not 00
		JP		NZ,MERR

		LD		DE,(FSIZE)
		LD		HL,(SADRS)
MSD1:	LD		A,(HL)
		CALL	SNDBYTE      ;Send FSIZE bytes from SADRS. For split save, 0475H is called 256 bytes at a time targeting the file opened by 0436H immediately prior.
		DEC		DE
		LD		A,D
		OR		E
		INC		HL
		JR		NZ,MSD1
		
		JP		MRET       ;Normal RETURN

;************************** 04D8H MONITOR read information alternative processing *****************
MLHED:
		DI
		PUSH	DE
		PUSH	BC
		PUSH	HL
		CALL	INIT

		LD		A,00H
		LD		DE,0000H
		CALL	TIMST

		LD		B,08H      ;Fill LBUF with 0DH to indicate no filename specified
		LD		DE,LBUF
		LD		A,0DH
MLH0:	LD		(DE),A
		INC		DE
		DEC		B
		JR		NZ,MLH0

		LD		A,03H          ;Delete 3 characters to clear one line, output 37 characters
		LD		(DSPX),A
		LD		A,0C7H
		CALL	DPCT
		CALL	DPCT
		CALL	DPCT
MLH6:	LD		DE,MSG_DNAME   ;'DOS FILE:'
		CALL	MSGPR
		LD		A,09H          ;Return cursor to 9th character position
		LD		(DSPX),A

		LD		DE,MBUF    ;Workaround for specifying filename. As LOAD command, input newline with no filename, then shift line buffer position to enter DOS filename.
		CALL	GETL
		
		LD		DE,MBUF+9
		
		LD		A,(DE)
;**** If first character of filename is '*', proceed to extended command processing ****
		CP		'*'
		JR		Z,MLHCMD

		LD		A,93H      ;HEADER LOAD command 93H
		CALL	MCMD       ;Send command code
		AND		A          ;ERROR if not 00
		JP		NZ,MERR

MLH1:
		LD		A,(DE)
		CP		20H                 ;Skip leading spaces up to filename
		JR		NZ,MLH2
		INC		DE
		JR		MLH1

MLH2:	LD		B,20H
MLH4:	LD		A,(DE)     ;Send FNAME
		CALL	SNDBYTE
		INC		DE
		DEC		B
		JR		NZ,MLH4
		LD		A,0DH
		CALL	SNDBYTE
		
		CALL	RCVBYTE    ;Get status (00H=OK)
		AND		A          ;ERROR if not 00
		JP		NZ,MERR

		CALL	RCVBYTE    ;Get status (00H=OK)
		AND		A          ;ERROR if not 00
		JP		NZ,MERR

		LD		HL,IBUFE
		LD		B,80H
MLH5:	CALL	RCVBYTE    ;Receive the read information block
		LD		(HL),A
		INC		HL
		DEC		B
		JR		NZ,MLH5

		CALL	RCVBYTE    ;Get status (00H=OK)
		AND		A          ;ERROR if not 00
		JP		NZ,MERR

		JP		MRET       ;Normal RETURN

;**************************** In-application SD-CARD operation processing **********************
MLHCMD:
;**** Save HL, DE, BC registers ****
		PUSH	HL
		PUSH	DE
		PUSH	BC
		INC		DE
		LD		B,03H
;**** FDL command ****
		LD		HL,CMD1
		CALL	CMPSTR
		JR		Z,MLHCMD2
		POP		BC
		POP		DE
		POP		HL
;**** Return to filename input ****
		JR		MLH6

MLHCMD2:
		INC		DE
		INC		DE
		INC		DE
		LD		HL,MSG_DNAME         ;Prefix 'DOS FILE:' to allow cursor movement and execution with RETURN
		LD		BC,MSG_DNAMEEND-MSG_DNAME
;**** Call FDL command ****
		CALL	DIRLIST
		AND		A          ;ERROR if not 00
		JR		NZ,SERR
		POP		BC
		POP		DE
		POP		HL
;**** Return to filename input ****
		JP		MLH6

;******* Error processing for in-application SD-CARD operation **************
SERR:
		CP		0F0H
		JR		NZ,SERR3
		LD		DE,MSG_F0
		JR		SERRMSG
		
SERR3:	CP		0F1H
		JR		NZ,SERR99
		LD		DE,MSG_F1
		JR		SERRMSG
		
SERR99:	CALL	PRTBYT
		LD		DE,MSG99
		
SERRMSG:
		CALL	MSGPR
		CALL	LETLN
		POP		BC
		POP		DE
		POP		HL
;**** Return to filename input ****
		JP		MLH6

;**** Command string comparison ****
CMPSTR:
		PUSH	BC
		PUSH	DE
CMP1:	LD		A,(DE)
		CP		(HL)
		JR		NZ,CMP2
		DEC		B
		JR		Z,CMP2
		CP		0Dh
		JR		Z,CMP2
		INC		DE
		INC		HL
		JR		CMP1
CMP2:	POP		DE
		POP		BC
		RET

;**** Command list ****
; Reserved for future expansion
CMD1:	DB		'FDL',0DH


;**************************** 04F8H MONITOR read data alternative processing ********************
MLDAT:
		DI
		PUSH	DE
		PUSH	BC
		PUSH	HL
		LD		A,94H      ;DATA LOAD command 94H
		CALL	MCMD       ;Send command code
		AND		A          ;ERROR if not 00
		JP		NZ,MERR

		CALL	RCVBYTE    ;Get status (00H=OK)
		AND		A          ;ERROR if not 00
		JP		NZ,MERR

		CALL	RCVBYTE    ;Get status (00H=OK)
		AND		A          ;ERROR if not 00
		JP		NZ,MERR

		LD		DE,FSIZE   ;Send FSIZE
		LD		A,(DE)
		CALL	SNDBYTE
		INC		DE
		LD		A,(DE)
		CALL	SNDBYTE
		CALL	DBRCV      ;Receive FSIZE bytes of data and store from SADRS. For split load, 04F8H is called 256 bytes at a time with SADRS incremented, targeting the file opened by 0436H immediately prior.

		CALL	RCVBYTE    ;Get status (00H=OK)
		AND		A          ;ERROR if not 00
		JP		NZ,MERR

		JR		MRET       ;Normal RETURN

;************************** 0588H VRFY CMT verify alternative processing *******************
MVRFY:
		DI
		XOR		A          ;Normal completion flag
;		EI

		RET

;******* Send command code for alternative processing (IN: A command code) **********
MCMD:
;		PUSH	AF
;		CALL	INIT
;		POP		AF
		CALL	SNDBYTE    ;Send command code
		CALL	RCVBYTE    ;Get status (00H=OK)
		RET

;****** Normal RETURN processing for alternative processing **********
MRET:	POP		HL
		POP		BC
		POP		DE
		XOR		A          ;Normal completion flag
;		EI
		
		RET

;******* Error processing for alternative processing **************
MERR:
		CP		0F0H
		JR		NZ,MERR3
		LD		DE,MSG_F0
		JR		MERRMSG
;No file type code check in alternative processing
;MERR2:	CP		0F2H
;		JR		NZ,MERR3
;		LD		DE,MSG_F2
;		JR		MERRMSG
		
MERR3:	CP		0F1H
		JR		NZ,MERR99
		LD		DE,MSG_F1
		JR		MERRMSG
		
MERR99:	CALL	PRTBYT
		LD		DE,MSG99
		
MERRMSG:
		CALL	MSGPR
		CALL	LETLN
		POP		HL
		POP		BC
		POP		DE
		LD		A,02H
		SCF
;		EI

		RET

		END
    