
DoFrame:
    ; reset the background queue pointer
    lda #$00
    sta bgQueue
    lda #$04
    sta bgQueue+1

    lda #0
    sta bgWrites

    jsr ReadControllers
    lda GameState
    cmp #GS_CREDITS
    beq frameCredits

    lda GameState
    cmp #GS_GAME
    bcc frameGameOver
    beq frameGameplay

frameTitle:
    jsr UpdateTitle
    jmp frameEnd

frameCredits:
    lda #BUTTON_A
    sta btnPressedMask
    jsr ButtonPressedP1
    beq .crB
    jmp .creditsEnd

.crB:
    lda #BUTTON_B
    sta btnPressedMask
    jsr ButtonPressedP1
    beq .crSt
    jmp .creditsEnd

.crSt:
    lda #BUTTON_START
    sta btnPressedMask
    jsr ButtonPressedP1
    beq frameEnd
    jmp .creditsEnd

.creditsEnd:
    lda #GS_TITLE
    sta GameState
    inc GSUpdateNeeded
    jmp frameEnd

frameGameplay:
    lda GamePaused
    bne framePaused

    jsr UpdatePlayers
    jsr UpdateBall
    jmp frameEnd

framePaused:
    jsr CheckPause
    jmp frameEnd

frameGameOver:
    jsr ClearSprites

    lda #BUTTON_START
    sta btnPressedMask

    jsr ButtonPressedP1
    beq frameEnd

    lda #GS_TITLE
    sta GameState

    inc GSUpdateNeeded
    jmp frameEnd

frameEnd:
    lda GSUpdateNeeded
    beq WaitFrame
    jsr UpdateGameState

; Wait for next VBlank to be done
WaitFrame:
    INC sleeping
WaitLoop:
    lda sleeping
    bne WaitLoop
    jmp DoFrame

