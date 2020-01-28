;-------------------------------------------------------------------------------------
; FILE: Intro.asm
; DESC: Experiment 1 – Simple Counter
; DATE: 5-18-06
; AUTH: Class
; DEVICE: PICmicro (PIC18F1220)
;-------------------------------------------------------------------------------------
 list p=18F1220 ; Set processor type
 radix hex ; Sets the default radix for data exp.
 config WDT=OFF, LVP=OFF, OSC = INTIO2 ; Disable Watchdog timer, Low V. Prog, and RA6 as a clock
#define WREG 0xFE8
#define PORTA 0xF80
#define PORTB 0xF81
#define TRISA 0xF92
#define TRISB 0xF93
#define ADCON1 0xFC1
IN1 equ 0x080
IN2 equ 0x081
LASTIN equ 0x082
 org 0x000 ; Set the program origin (start) to absolute 0x000
; Initialize all I/O ports
 CLRF PORTA ; Initialize PORTA
 CLRF PORTB ; Initialize PORTB
 MOVLW 0x7F ; Set all A/D Converter Pins as
 MOVWF ADCON1 ; digital I/O pins
 MOVLW 0x1F ; Value used to initialize data direction
 MOVWF TRISB ; Set Port B RB<7:0> as outputs
 MOVLW 0xFF ; Value used to initialize data direction
 MOVWF TRISA ; Set Port A RA<7:0> as inputs
 MOVLW 0x00 ; W = 0
 MOVWF LASTIN ; LASTIN = WREG
Loop:
 ; CHECK FOR CHANGE
 MOVF PORTB, 0 ; WREG = PORTB
 ANDLW 0x0F ; PRESERVES ONLY R0-R3 BITS
 XORWF LASTIN, 0 ; CHECKS IF ANY BITS BETWEEN R0-R3 HAVE CHANGED SINCE LAST LOOP
 BZ Loop ; RUTURNS TO TOP IF NO CHANGE OCCURRED
 ; RESET IN1 & IN2 TO 0000 0011
 MOVLW 0x03 ; WREG = 0000 0011
 MOVWF IN1 ; IN1 = WREG
 MOVWF IN2 ; IN2 = WREG
 ; SET IN1 TO 0000 00_RB1_RB0 && SET IN2 TO 0000 00_RB3_RB2
 MOVF PORTB, 0 ; WREG = PORTB
 ANDLW 0x0F ; PRESERVES ONLY R0-R3 BITS
 MOVWF LASTIN ; SAVES LATEST INPUT CHANGE
 ANDWF IN1 ; SET IN1<1:0> = WREG<1:0>
 RRNCF WREG ; SHIFT WREG BITS RIGHT ONCE
 RRNCF WREG ; SHIFT WREG BITS RIGHT ONCE
 ANDWF IN2 ; SET IN2<1:0> = WREG<1:0>(WHAT USED TO BE WREG<3:2>)
 ; ADD IN1 TO IN2 && SET TO WREG
 MOVF IN1, 0 ; WREG = IN1
 ADDWF IN2, 0 ; WREG = IN1+IN2
 ; SHIFTS BITS TO CORRECT PLACE, THEN OUTPUTS
 RRNCF WREG ; SHIFT WREG BITS RIGHT ONCE
 RRNCF WREG ; SHIFT WREG BITS RIGHT ONCE
 RRNCF WREG ; SHIFT WREG BITS RIGHT ONCE
 MOVWF PORTB ; PORTB = WREG
GOTO Loop ; LOOPS *INFINITY
 end ; Indicates the end of the program. 


