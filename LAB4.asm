;-------------------------------------------------------------------------------------
; FILE: LAB4.asm
; DESC: Experiment 1 - RGB cycle w/Motor interrupts 
; DATE: 02-20-20
; AUTH: Brady Stassens && Amethyst Skye
; DEVICE: PICmicro (PIC18F1220)
;-------------------------------------------------------------------------------------

 list p=18F1220 ;processor type
 radix hex ;default radix for data
 config WDT=OFF,LVP=OFF,OSC=INTIO2

#include p18F1220.inc ;header file

#define dCount 0x80
#define dCountInner 0x81

 org 0x000
 GOTO START
 org 0x008
 GOTO INTHI
 org 0x018
 GOTO INTLO
 
 org 0x020
INTHI:
 BTG PORTA,7 ; FORWARD Right Motor TOGGLE
 BCF INTCON,INT0IF
 RETFIE
 
INTLO:
 BTG PORTB,3 ; Forward Left Motor TOGGLE
 BCF INTCON3,INT1IF
 RETFIE
 
START:
 ; initialize all I/O ports
 CLRF PORTA ; Initialize PORTA
 CLRF PORTB ; Initialize PORTB
 MOVLW 0x7F
 MOVWF ADCON1 ; Configure PortA<0:7> Digital and PortA<> Analog
 MOVLW 0x35
 MOVWF TRISA ; Set Port A direction Per EDbot Micro Spec.
 MOVLW 0xC3
 MOVWF TRISB ; Set Port A direction Per EDbot Micro Spec.
 MOVLW 0xD0
 MOVWF INTCON ; GIE,PEIE,INT0IE
 CLRF INTCON3
 BSF INTCON3,INT1IE
 BSF RCON,IPEN
 
 MOVLW 5 ; PRELOAD 5 IN WREG TO CALL DELAY FOR HALF SECOND DELAYS
MAIN:
 BSF PORTA,3 ; Step 1 - Turn on green LED
 CALL DELAY
 BCF PORTA,3 ; Turn off green LED
 BSF PORTB,5 ; Step 2 - Turn on blue LED
 CALL DELAY
 BCF PORTB,5 ; Turn off Blue LED
 BSF PORTB,2 ; Step 3 -Turn on red LED
 CALL DELAY
 BCF PORTB,2 ; Step 3 -Turn off red LED
 BRA MAIN

; DELAY function will delay by (Wreg/10) seconds
DELAY:
 MOVWF dCount
DELAYLoop:
 CALL DELAYOnce
 DECF dCount
 BNZ DELAYLoop
 RETURN
DELAYOnce:
 CLRF dCountInner ; Internal delay loop
DELAYOnceLoop:
 NOP
 INCF dCountInner
 BNZ DELAYOnceLoop
 RETURN ; DELAY Function
    
end ; code end


