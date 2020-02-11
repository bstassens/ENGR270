;-------------------------------------------------------------------------------------
; FILE: LAB3.asm
; DESC: Experiment 2 ELLIPSE DRIVING
; DATE: 02-10-20
; AUTH: Brady Stassens && Amethyst Skye
; DEVICE: PICmicro (PIC18F1220)
;-------------------------------------------------------------------------------------

 list p=18F1220 ;processor type
 radix hex ;default radix for data
 config WDT=OFF,LVP=OFF,OSC=INTIO2

#include p18F1220.inc ;header file

#define dCount 0x80
#define dCountInner 0x81
#define LastValue 0x82
#define COUNT 0x83

 org 0x000 ; Set program origin to absolute 0x000
 ; initialize all I/O ports
 CLRF PORTA ; Initialize PORTA
 CLRF PORTB ; Initialize PORTB
 MOVLW 0x7F
 MOVWF ADCON1 ; Configure PortA<0:7> Digital and PortA<> Analog
 MOVLW 0x35
 MOVWF TRISA ; Set Port A direction Per EDbot Micro Spec.
 MOVLW 0xC3
 MOVWF TRISB ; Set Port A direction Per EDbot Micro Spec.

 ; Use INT0 switch to click through all functionality
MAIN:
 BSF PORTA,3 ; Step 1 - Turn on green LED
 CALL Int0Press
 CALL ELLIPSE1
 BCF PORTA,3 ; Turn off green LED
 BSF PORTB,5 ; Step 2 - Turn on blue LED
 CALL Int0Press
 CALL ELLIPSE2
 BCF PORTB,5 ; Turn off Blue LED
 BSF PORTB,2 ; Step 3 -Turn on red LED
 CALL Int0Press
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

; Wait until INT0 Button is pressed (include SW Debounce)
Int0Press:
 MOVLW .1
 CALL DELAY
 MOVF PORTB,0
 ANDLW 0x01
 BZ Int0Press ; wait for button to be released
Int0PressZ:
 MOVLW .1
 CALL DELAY
 MOVF PORTB,0
 ANDLW 0x01
 BNZ Int0PressZ ; wait for buton to be pressed
 RETURN ; Int1Press Function
 
ELLIPSE1:
    MOVLW .10
    MOVWF COUNT
    BSF PORTB,3 ; Forward Left Motor
    BSF PORTA,7 ; FORWARD Right Motor
ELOOP1:
    MOVLW .5
    CALL DELAY
    BCF PORTA,7
    MOVLW .1
    CALL DELAY
    BSF PORTA,7
    DECF COUNT
    BNZ ELOOP1
    BCF PORTB,3
    BCF PORTA,7
 return
 
ELLIPSE2:
    MOVLW .10
    MOVWF COUNT
    BSF PORTB,4 ; Forward Left Motor
    BSF PORTA,6 ; FORWARD Right Motor
ELOOP2:
    MOVLW .5
    CALL DELAY
    BCF PORTB,4
    MOVLW .1
    CALL DELAY
    BSF PORTB,4
    DECF COUNT
    BNZ ELOOP2
    BCF PORTB,4
    BCF PORTA,6
 return
    
end ; code end
