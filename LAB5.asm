;------------------------------------------------------------------------------
; FILE: LAB5.asm
; DESC: Experiment 1 - RGB cycle w/Motor interrupts on TMR0 
; DATE: 03-03-20
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
 CLRF State ; clear current state variable
 CLRF RGBticker ; clear RGBticker variable
 CLRF m2Tick
 CLRF PORTA ; Initialize PORTA
 CLRF PORTB ; Initialize PORTB
 MOVLW 0x7F
 MOVWF ADCON1 ; Configure PortA<0:7> Digital and PortA<> Analog
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
 BSF INTCON, GIE ; enable interrupts globally
 
 BSF PORTB,2 ; Red led initialized
 MOVLW .3 ; set # to check RGBticker against to 3
MainL: ; Main loop
 CPFSEQ RGBticker ; @3(1.5 sec) change the RGB settings
 BRA MainL
; CLEAR TICKER & SWITCH LED COLOR
 CLRF RGBticker
 BTFSS PORTB,2 ; SKIP next if==isRed
 BRA GreenBlue
 BSF PORTA,3 ; Green ON
 BCF PORTB,2 ; Red OFF
 BRA MainL
GreenBlue: ; Green to blue
 BTFSS PORTA,3 ; SKIP next if==isGreen
 BRA BlueRed
 BSF PORTB,5 ; Blue ON
 BCF PORTA,3 ; Green OFF
 BRA MainL
BlueRed: ; Blue to red
 BSF PORTB,2 ; Red ON
 BCF PORTB,5 ; Blue OFF
 BRA MainL
    
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
 ; Increment 8-bit 2 msec ticker
 INCF m2Tick
 MOVLW .250
 CPFSEQ m2Tick
 BRA checkState
 ; Increment state every 0.5 sec (250 x 2 msec = 0.5 sec)
 CLRF m2Tick
 MOVLW .8
 CPFSLT State
 CLRF State
 INCF RGBticker
 INCF State
checkState:
 MOVLW .8
 CPFSLT State
 BRA TMR0Step8
 MOVLW .7
 CPFSLT State
 BRA TMR0Step7
 MOVLW .6
 CPFSLT State
 BRA TMR0Step6
 MOVLW .5
 CPFSLT State
 BRA TMR0Step5
 MOVLW .4
 CPFSLT State
 BRA TMR0Step4
 MOVLW .3
 CPFSLT State
 BRA TMR0Step3
 MOVLW .2
 CPFSLT State
 BRA TMR0Step2
TMR0Step1:
 BCF PORTA,7
 BSF PORTA,6 ; 1. Right motor forward at 100% power
 BRA INTHIdone
TMR0Step2:
 BTG PORTA,6 ; 2. Reduce power to 50%
 BRA INTHIdone
TMR0Step3:
 BCF PORTA,6
 BSF PORTB,3 ; 3. Left motor backward at 100% power
 BRA INTHIdone
TMR0Step4:
 BTG PORTB,3 ; 4. Reduce power to 50%
 BRA INTHIdone
TMR0Step5:
 BCF PORTB,3
 BSF PORTB,4 ; 5. Left motor forward at 100% power
 BRA INTHIdone
TMR0Step6:
 BTG PORTB,4 ; 6. Reduce power to 50%
 BRA INTHIdone
TMR0Step7:
 BCF PORTB,4
 BSF PORTA,7 ; 7. Right motor backward at 100% power
 BRA INTHIdone
TMR0Step8:
 BTG PORTA,7 ; 8. Reduce power to 50%
 BRA INTHIdone

 end ; end program
