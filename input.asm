;
; Player and computer input
;

ReadControllers:
    lda controller1
    sta controller1Old

    lda controller2
    sta controller2Old

    ; Freeze input
    lda #1
    sta $4016
    lda #0
    sta $4016

    LDX #$08
ReadJoy1:
    lda $4016
    lsr A           ; Bit0 -> Carry
    rol controller1 ; Bit0 <- Carry
    dex
    bne ReadJoy1

    ldx #$08
ReadJoy2:
    lda $4017
    lsr A           ; Bit0 -> Carry
    rol controller2 ; Bit0 <- Carry
    dex
    bne ReadJoy2

    ; two player or vs computer?
    lda TitleSelected
    cmp #0
    bne readJoy_done
    jmp Computer_Move

readJoy_done:
    rts

;
; Computer input
;
ComputerOdd:
    ; repeat last frame's button presses
    lda compController
    sta controller2

    inc frameOdd
    rts

Computer_Move:
; Move p2's paddle
;   if ball is moving right
;       if ball y < p2_paddle y
;           press "UP" button (mimic the controller)
;       else if ball y > p2_paddle_bottom y
;           press "DOWN" button

    ; Hold inputs for this many frames
    lda frameOdd
    cmp #5
    bne ComputerOdd

    ; Clear controller input
    lda #$00
    sta controller2
    sta compController

    ; Ball moving right?
    lda #1
    cmp BallLeft
    beq Computer_Done

    ; ball past half of screen?
    lda BallX
    cmp #$88
    bcc Computer_Done

    ; if ball y < p2_paddle y
    ; use the inner two sprites to determine movement
    lda P2_TOP
    ;SEC
    ;SBC #8
    cmp BallY
    bcc Computer_MoveDown

    lda P2_BOTTOM
    ;CLC
    ;ADC #8
    cmp BallY
    bcs Computer_MoveUp
    jmp Computer_Done

; Don't move the paddle directly, just press the buttons
Computer_MoveUp:
    lda #BUTTON_UP
    sta controller2
    sta compController
    jmp Computer_Done

Computer_MoveDown:
    lda #BUTTON_DOWN
    sta controller2
    sta compController

Computer_Done:
    ;dec frameOdd
    lda #0
    sta frameOdd
    rts
