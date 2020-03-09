;------------------------------------------------------------------------------
; FILE: LAB6.asm
; DESC: Experiment 1 - Sensor and A/D Converter 
; DATE: 03-09-20
; AUTH: Brady Stassens && Amethyst Skye
; DEVICE: PICmicro (PIC18F1220)
;------------------------------------------------------------------------------
 list p=18F1220 ;processor type
 radix hex ;default radix for data
 ; Disable Watchdog timer, Low V. Prog, and RA6 as I/O
 config WDT=OFF,LVP=OFF,OSC=INTIO2

 #include p18F1220.inc ;header file
 #define dCount 0x80
 #define dCountInner 0x81
 #define LastValue 0x82
 #define State 0x83 ; State variable is 8 bit and increments
 #define WregBack 0x84
 #define RGBticker 0x85
 #define m2Tick 0x86
 #define IRdata 0x87 ; last IR input read

 org 0x000 ; Executes after reset
 BSF OSCCON,6 ; Ramp up to 1 MHZ (time elapsed=32 usec)
 BSF OSCCON,5 ; Ramp up to 4 MHZ (time elapsed=33 usec)
 BSF OSCCON,4 ; Ramp up to 8 MHZ (time elapsed=33.25 usec)
 BRA StartL

 org 0x008 ; Executes after high priority interrupt
 GOTO INTHI

 org 0x20 ; Code start here 
StartL:
 ; initialize all I/O ports
 CLRF IRdata ; Clear IR reading
 CLRF State ; clear current state variable
 CLRF RGBticker ; clear RGBticker variable
 CLRF m2Tick
 CLRF PORTA ; Initialize PORTA
 CLRF PORTB ; Initialize PORTB
 MOVLW 0x7E
 MOVWF ADCON1 ; Configure PortA<1:7> Digital and PortA<0> Analog
 MOVLW 0x35
 MOVWF TRISA ; Set Port A direction Per EDbot Micro Spec.
 MOVLW 0xC3
 MOVWF TRISB ; Set Port A direction Per EDbot Micro Spec.
  ; Enable TMR0
 BSF INTCON, PEIE ; enable all peripheral interrupts
 BSF INTCON, TMR0IE ; enable Timer 0 Interrupt
 BSF INTCON2, TMR0IP ; Set Timer 0 Interrupt to High priroity
 BSF RCON, IPEN ; enable priority levels on interrupts
 BCF INTCON, TMR0IF ; clear Timer 0 Interruplt flag
 MOVLW 0x83 ; delay of 2 msec
 MOVWF TMR0L ;
 MOVLW 0xC4 ; TMR0-ON, 8-bit, internal clock, 1:32 scale
 MOVWF T0CON ; Timer 0 tick is 2 msec (1 sec/8MHZ*4*32=16 usec/tick)
  ; Wait until INT0 Button is pressed (include SW Debounce)
 Call Int0Press
 BSF INTCON, GIE ; enable interrupts globally
MainL: ; Main loop
 CALL IRread
 MOVLW 0xE6
 CPFSLT IRdata
 BRA Circle ; Circle
 MOVLW 0xC0
 CPFSLT IRdata
 BRA Mgreen ; Forward
 MOVLW 0x80
 CPFSLT IRdata
 BRA Mblue ; Stop
 BRA Mred ; Reverse
Circle:
 BCF PORTA,3 ;Green
 BCF PORTB,5 ;Blue
 BCF PORTB,2 ;Red
 MOVLW .0
 MOVWF State
 BRA MainL
Mgreen: ; Forward
 BSF PORTA,3 ;Green
 BCF PORTB,5 ;Blue
 BCF PORTB,2 ;Red
 MOVLW .1
 MOVWF State
 BRA MainL
Mblue: ; Stop
 BCF PORTA,3 ;Green
 BSF PORTB,5 ;Blue
 BCF PORTB,2 ;Red
 MOVLW .2
 MOVWF State
 BRA MainL
Mred: ; Reverse
 BCF PORTA,3 ;Green
 BCF PORTB,5 ;Blue
 BSF PORTB,2 ;Red
 MOVLW .3
 MOVWF State
 BRA MainL
; Returns the IR reading in IRdata
IRread:
 BSF PORTA,1 ; Turn on IR Transmitter
 BCF ADCON2,7 ; Left Adjusted reading
 MOVLW 0x03
 MOVWF ADCON0 ; Turn on ADC
WaitNdone:
 BTFSC ADCON0,1
 BRA WaitNdone ; wait until AD conversion has completed
 MOVFF ADRESH,IRdata
 BCF PORTA,1 ; Turn off IR Transmitter
 RETURN

; Delay function waits for (Wreg/10) seconds before returning
Delay:
 MOVWF dCount
DelayLoop:
 CALL DelayOnce
 DECF dCount
 BNZ DelayLoop
 RETURN
DelayOnce:
 CLRF dCountInner ; Internal delay loop
DelayOnceLoop:
 NOP
 INCF dCountInner
 BNZ DelayOnceLoop
 RETURN ; Delay Function
; Wait until INT0 Button is pressed (include SW Debounce)
Int0Press:
 MOVLW .1 
  CALL Delay
 MOVF PORTB,0
 ANDLW 0x01
 BZ Int0Press ; wait for button to be released
Int0PressZ:
 MOVLW .1
 CALL Delay
 MOVF PORTB,0
 ANDLW 0x01
 BNZ Int0PressZ ; wait for buton to be pressed
 RETURN ; Int0Press Function
 
 ; Interrupt Handeling Section 
INTHI: ; High priority interrupts including Timer 0 Int.
 MOVWF WregBack ; Save Wreg.
 BTFSC INTCON, TMR0IF ; Check for Timer 0 high priority Interrupt
 BRA TMR0int
INTHIdone: ; code to clean up and return from interrupt
 MOVF WregBack,0 ; Recover Wreg.
 BCF INTCON, TMR0IF ; Clear Timer 0 interrupt Flag
 RETFIE
 
TMR0int: ; handel Timer 0 Interrupt
 ; Check da' State(forwards/backwards are switched on EDbot)
 MOVLW .3
 CPFSLT State
 BRA TMR0Step1
 MOVLW .2
 CPFSLT State
 BRA TMR0Step2
 MOVLW .1
 CPFSLT State
 BRA TMR0Step3
TMR0Step0: ; Search Circle
 BCF PORTA,7 ; Right motor backward at 100% power
 BCF PORTB,3 ; Left motor backward at 100% power
 BTG PORTA,6 ; Right motor forward at 100% power
 BSF PORTB,4 ; Left motor forward at 100% power 
 BRA INTHIdone
TMR0Step1: ; Forwards
 BCF PORTA,7 ; Right motor backward at 100% power
 BCF PORTB,3 ; Left motor backward at 100% power
 BSF PORTA,6 ; Right motor forward at 100% power
 BSF PORTB,4 ; Left motor forward at 100% power
 BRA INTHIdone
TMR0Step2: ; STOP
 BSF PORTA,7 ; Right motor backward at 100% power
 BSF PORTB,3 ; Left motor backward at 100% power
 BSF PORTA,6 ; Right motor forward at 100% power
 BSF PORTB,4 ; Left motor forward at 100% power
 BRA INTHIdone
TMR0Step3: ; Reverse
 BSF PORTA,7 ; Right motor backward at 100% power
 BSF PORTB,3 ; Left motor backward at 100% power
 BCF PORTA,6 ; Right motor forward at 100% power
 BCF PORTB,4 ; Left motor forward at 100% power
 BRA INTHIdone

 end ; end program 
