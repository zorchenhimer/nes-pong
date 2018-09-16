
DoFrame:
    jsr ReadControllers
    lda GameState
    cmp #GS_GAME
    bcc frameGameOver
    beq frameGameplay

frameTitle:
    jsr UpdateTitle
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

