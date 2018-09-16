; Load background from RAM into PPU
UpdateBackground:
    bit bgUpdateFlags   ; do not set this in NMI
    bpl ubPPUOn

    ; TODO: use a constant for this
    lda #PPU_OFF
    sta $2001

ubPPUOn:
    bit $2002   ; reset high/low latch

    ; if %0100 0000, don't read from queue
    bit bgUpdateFlags
    bvs ubLoop

    lda #$00
    sta bgPointer

    lda #$04
    sta bgPointer+1

ubLoop:
    lda #0
    sta bgUpdateFlags

    ldy #$00    ; byte in the packet

    ; Packet length
    lda [bgPointer], y
    sta bgLength
    bne ub_ok

    ; TODO: use a constant for this
    lda #PPU_ON
    sta $2001
    rts

ub_ok:
    iny
    lda [bgPointer], y
    sta bgFlags
    bit bgFlags
    bvs ubSkipAddr

    ; PPU Address
    iny
    lda [bgPointer], y
    sta $2006

    iny
    lda [bgPointer], y
    sta $2006

ubSkipAddr:
    bit bgFlags
    bmi ubRunLength

ubDataLoop:
    iny
    lda [bgPointer], y
    sta $2007
    dec bgLength
    bne ubDataLoop

    jmp ubNextPacket

ubRunLength:
    iny
    lda [bgPointer], y

ubRunLengthLoop:
    sta $2007
    dec bgLength
    bne ubRunLengthLoop

ubNextPacket:
    ; Update pointer to next packet
    tya
    clc
    adc #$01
    adc bgPointer
    sta bgPointer

    lda bgPointer+1
    adc #0
    sta bgPointer+1

    jmp ubLoop

; Load data into RAM
LoadBackgroundData:
    ; reset queue address
    ;lda bgQueue
    ;beq lbLoop
    ;dec bgQueue

    lda #$00
    sta bgQueue
    lda #$04
    sta bgQueue+1

lbLoop:
    ; bgPointer needs to be set before calling this
    ldy #0

    ; Packet length
    lda [bgPointer], y
    sta bgLength
    sta [bgQueue], y
    bne lb_ok

    ; reset queue pointer
    ;lda #$00
    ;sta bgQueue
    ;lda #$04
    ;sta bgQueue+1
    ; return
    rts

lb_ok:
    iny
    lda [bgPointer], y
    sta bgFlags
    sta [bgQueue], y
    bit bgFlags
    bvs lbSkipAddr

    ; PPU Address
    iny
    lda [bgPointer], y
    sta [bgQueue], y

    iny
    lda [bgPointer], y
    sta [bgQueue], y

lbSkipAddr:
    bit bgFlags
    bmi lbRunLength

lbDataLoop:
    iny
    lda [bgPointer], y
    sta [bgQueue], y
    dec bgLength
    bne lbDataLoop

    jmp lbNextPacket

lbRunLength:
    iny
    lda [bgPointer], y
    sta [bgQueue], y

lbNextPacket:
    ; Update pointer and queue to next packet
    tya
    clc
    adc #1
    adc bgPointer
    sta bgPointer

    lda bgPointer+1
    adc #0
    sta bgPointer+1

    ; update queue pointer
    tya
    clc
    adc #1
    adc bgQueue
    sta bgQueue

    lda bgQueue+1
    adc #0
    sta bgQueue+1
    jmp lbLoop

