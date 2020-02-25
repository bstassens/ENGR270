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
 MOVLW 0xC2 ;
 CLRF TMR0H ; (0x10000-0xC2F7=0x3D09 or 15625 ticks)
 MOVLW 0xF7 ; delay of .5 sec / 15625 ticks = 32 usec/tick
 CLRF TMR0L ;
 MOVLW 0x85 ; TMR0-ON, 16-bit, internal clock, 1:64 scale
 MOVWF T0CON ; Timer 0 tick is .5 sec (1 sec/8MHZ*4*64=32 usec/tick)
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
 ; Increment 8-bit variable state every .5 sec
 INCF State
 INCF RGBticker
 ; Start of code to be executed after every TMR 0 Int.
 MOVLW .1
 CPFSEQ State
 BRA TMR0Step2
 BCF PORTA,7
  ; Missing data to vari the motor speed
 BSF PORTA,6 ; 1. Right motor forward at 100% power
 BRA INTHIdone
TMR0Step2:
 MOVLW .2
 CPFSEQ State
 BRA TMR0Step3
 ; 2. Reduce power to 50%
 BRA INTHIdone
TMR0Step3:
 MOVLW .3
 CPFSEQ State
 BRA TMR0Step4
 BCF PORTB,4
  ; Missing data to vari the motor speed
 BSF PORTB,3 ; 3. Left motor backward at 100% power
 BRA INTHIdone
TMR0Step4:
 MOVLW .4
 CPFSEQ State
 BRA TMR0Step5
 ; 4. Reduce power to 50%
 BRA INTHIdone
TMR0Step5:
 MOVLW .5
 CPFSEQ State
 BRA TMR0Step6
 BCF PORTB,3
 ; Missing data to vari the motor speed
 BSF PORTB,4 ; 5. Left motor forward at 100% power
 BRA INTHIdone
TMR0Step6:
 MOVLW .6
 CPFSEQ State
 BRA TMR0Step7
 ; 6. Reduce power to 50%
 BRA INTHIdone
TMR0Step7:
 MOVLW .7
 CPFSEQ State
 BRA TMR0Step8
 BCF PORTA,6
 ; Missing data to vari the motor speed
 BSF PORTA,7 ; 7. Right motor backward at 100% power
 BRA INTHIdone
TMR0Step8:
 ; 8. Reduce power to 50%
 CLRF State ; 9. Go to step 1
 BRA INTHIdone

 end ; end program
