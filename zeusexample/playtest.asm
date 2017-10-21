; -Sound effects player test------------------------------------;
;                                                               ;
; A test program that uses the Minimal ayFX player.             ;
; Plays effects on the regular AY; If there is a second AY      ;
; using the NedoPC scheme, you can turn this on and play        ;
; music on it.                                                  ;
; Keys 1-0,Q-P,A-L,Z-M,SS,CS play the effects 0..38             ;
; (You can download a bank with fewer effects),                 ;
; The 'space' key turns the music in the second AY on / off.    ;
;                                                               ;
; --------------------------------------------------------------;

zeusemulate             "128K"
sfxBankAd               equ $a000                       ; Effects Bank Address
musInitAd               equ $c000                       ; Compiled music address (PT3)
musPlayAd               equ musInitAd+5
musShutAd               equ musInitAd+8
im2Ad                   equ $bdbd
im2Table                equ $be00
Start                   equ $6200
Stack                   equ Start-1
Zeus_PC                 equ Start
zoSupportStringEscapes  = false
StartSpectaculator      equ false//true

                        org Start

Main                    proc
                        di
                        ld sp, Stack
                        ld a, ($5B5C)
                        ld bc, $7FFD
                        out (c), a


                        call Cls
                        ld a, 2                         ; Open upper screen channel for printing
                        call 5633
                        Print(TextChAny, TextChAny.Len)
                        ld a, 3
                        ld (Channel), a

                        ld hl, sfxBankAd                ; Initializing the effects player
                        call AFX.Init


                        call musInitAd                  ; Music initialization

                        xor a                           ; Music is off by default
                        ld (intProc.enableMusic), a

                        ld hl, intProc                  ; Move the interrupt handler to $bdbd
                        ld de, im2Ad
                        ld bc, intProc.End-intProc
                        ldir

                        ld hl, im2Table                 ; Interrupt table for address $bdbd
                        ld de, im2Table+1
                        ld bc, $0100
                        ld a, h
                        ld i, a
                        ld (hl), high(im2Ad)
                        ldir
                        im 2
                        ei
mainLoop:
                        halt                            ; Basic cycle

                        ld b, 4                         ; Key polling cycle
                        ld hl, tblRowNum
keyLoop:
                        push bc

                        ld b, (hl)                      ; Check the left side of the current row
                        ld c, $fe
                        inc hl
                        in a, (c)
                        ld b, 5
                        ld c, (hl)
                        inc hl
keyRowL:
                        rra
                        call nc, playSfx
                        inc c
                        djnz keyRowL

                        ld b, (hl)                      ; Check the right side of the current row
                        ld c, $fe
                        inc hl
                        in a, (c)
                        ld b, 5
                        ld c, (hl)
                        inc hl
keyRowR:
                        rra
                        call nc, playSfx
                        dec c
                        djnz keyRowR

                        pop bc
                        djnz keyLoop

                        jr mainLoop
pend



playSfx                 proc                            ; Start the effect
                        push af
                        push bc
                        push hl

                        ld a, 39
                        cp c
                        jr z, ChA
                        dec a
                        cp c
                        jr z, ChB
                        dec a
                        cp c
                        jr z, ChC
                        dec a
                        cp c
                        jr z, ChAny

                        jp playSfx0

ChA:
                        Print(TextA, TextA.Len)
                        xor a
                        ld (Channel), a
                        jp playSfx2
ChB:
                        Print(TextB, TextB.Len)
                        ld a, 1
                        ld (Channel), a
                        jp playSfx2
ChC:
                        Print(TextC, TextC.Len)
                        ld a, 2
                        ld (Channel), a
                        jp playSfx2
ChAny:
                        Print(TextAny, TextAny.Len)
                        ld a, 3
                        ld (Channel), a
                        jp playSfx2
playSfx0:
                        ld a, (sfxBankAd)               ; Check for effect in the bank
                        dec a
                        cp c
                        jr c, playSfx2                  ; Jump if the bank doesn't have this many effects

                        ld a, (Channel)
                        cp 3
                        ld e, a                         ; Channel is in e
                        ld a, c                         ; Actually launch the effect
                        jp nz, PlayChannel
                        call AFX.Play
playSfx1:
                        halt                            ; Delay after pressing a key
                        halt
                        halt
                        halt
playSfx2:
                        pop hl
                        pop bc
                        pop af
                        ret
PlayChannel:
                        call AFX.PlayChannel
                        jp playSfx1
pend



aySelChip               proc                            ; Procedure for selecting the chosen AY
                        ld bc, $fffd
                        xor b
                        out (c), a
                        ret
pend



include                 "ayfxplay.asm"                  ; Include the source of the effects player



; A table for polling the keyboard
; First byte  - high byte of the port address
; Second byte - the starting number of the effect

tblRowNum:
                        DB $f7, $00, $ef, $09, $fb, $0a, $df, $13
                        DB $fd, $14, $bf, $1d, $fe, $1e, $7f, $27

CodeSize                equ $-Start


Cls                     proc
                        ld a, $38
                        ld (23693), a
                        call 3503
                        ret
pend

At                      equ 22

TextA                   proc
                        db At, 0, 9, "A   "
   Len                  equ $-TextA
pend

TextB                   proc
                        db At, 0, 9, "B   "
   Len                  equ $-TextB
pend

TextC                   proc
                        db At, 0, 9, "C   "
   Len                  equ $-TextC
pend

TextAny                 proc
                        db At, 0, 9, "Free"
   Len                  equ $-TextAny
pend

TextChAny               proc
                        db At, 0, 0, "Channel: Free", 13
                        db "________________________________"
                        db 13, 13, "KEYS:", 13, 13
                        db "SPACE:  Lock to channel A", 13
                        db "SYMBOL: Lock to channel B", 13
                        db "M:      Lock to channel C", 13
                        db "N:      Any free channel", 13, 13
                        db "OTHER:  Play FX sound (0-36)"
   Len                  equ $-TextChAny
pend

Print                   macro(PrintAddr, PrintLen)
                        push af
                        push bc
                        push de
                        push hl
                        ld de, PrintAddr
                        ld bc, PrintLen
                        call 8252
                        pop hl
                        pop de
                        pop bc
                        pop af
mend

Channel:                db 3                            ; 0=A, 1=B, 2=C, 3=Any


org sfxBankAd
import_bin "playtest.afb"
sfxBankSize = $-sfxBankAd



org im2Ad

intProc                 proc                            ; Interrupt handler
                        push af
                        push bc
                        push de
                        push hl

enableMusic equ $+1:    ld a, 0                         ; Music on?
                        and 1
                        jr z, noMusic

                        ld a, 1                         ; Choose the second AY
                        call aySelChip
                        call musPlayAd                  ; Play music
noMusic:
                        xor a                           ; Choose the first AY
                        call aySelChip
                        call AFX.Frame                  ; Lose the effects

                        pop hl
                        pop de
                        pop bc
                        pop af
                        ei
                        ret
End:
Size = $-intProc
pend

org musInitAd
//import_bin "..\music\music.pt3"
                        ret                             ; Stub routines
org musPlayAd
                        ret
org musShutAd
                        ret
musicSize = $-musInitAd

if (StartSpectaculator)
  zeusinvoke "spectaculator.bat"
endif

output_z80 "ayfxtest.z80", Stack, Start
output_szx "ayfxtest.szx", $0000, Start
output_tzx "ayfxtest.tzx", "ayfxtest", "(c) Shiru 2006-2017", Start, CodeSize, 3
output_tzx_block "ayfxtest.tzx", sfxBankAd, sfxBankSize
output_tzx_block "ayfxtest.tzx", intProc,   intProc.Size
output_tzx_block "ayfxtest.tzx", musInitAd, musicSize
output_tap "ayfxtest.tap", "ayfxtest", "(c) Shiru 2006-2017", Start, CodeSize, 3
output_tap_block "ayfxtest.tap", sfxBankAd, sfxBankSize
output_tap_block "ayfxtest.tap", intProc,   intProc.Size
output_tap_block "ayfxtest.tap", musInitAd, musicSize
//zeusdatabreakpoint 11, "zeusprinthex(addr>=Test1 && addr<=Test2, addr), addr>=Test1 && addr<=Test2", $4000, $C000

