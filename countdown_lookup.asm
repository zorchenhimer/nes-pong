DoCountdown:
    lda start_count
    asl a
    tax
    lda CountdownData_Table, x
    sta CountdownDataAddress

    lda CountdownData_Table+1, x
    sta CountdownDataAddress+1

    ; low byte first
    lda #$00
    sta dcQueuePointer

    lda #$03
    sta dcQueuePointer+1

    ldy #0
dcOuterLoop:
    ; length of packet
    lda [CountdownDataAddress], Y
    sta dcPacketLength
    sta [dcQueuePointer], Y

    bne dcContinue
    rts

dcContinue:
    ; Next two are PPU address
    iny
    lda [CountdownDataAddress], Y
    sta [dcQueuePointer], Y

    iny
    lda [CountdownDataAddress], Y
    sta [dcQueuePointer], Y

    ; flags
    iny
    lda [CountdownDataAddress], Y
    sta [dcQueuePointer], Y
    sta dcFlags
    bit dcFlags
    bmi dcRunlength

dcDataLoop:
    iny
    lda [CountdownDataAddress], Y
    sta [dcQueuePointer], Y
    dec dcPacketLength
    bne dcDataLoop
    jmp dcOuterLoop

dcRunlength:
    iny
    lda [CountdownDataAddress], Y
    sta [dcQueuePointer], Y

    ; update queue pointer
    tya ; queue pointer
    clc
    adc #5  ; packet header
    adc dcQueuePointer
    sta dcQueuePointer

    ; add carry to high bytes
    lda dcQueuePointer+1
    adc #0  ; add the carry, if it exists
    sta dcQueuePointer+1
    jmp dcOuterLoop

