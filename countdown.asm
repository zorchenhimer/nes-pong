; ---------------------------
; Draw the countdown on
; screen
; ---------------------------
; TODO: read the packets from CountdownData labels
DoCountdown:
    LDA start_count
    asl a
    tax
    lda Countdown_Table+1, x

    pha
    lda Countdown_Table, x
    pha
    rts

; clear the text off screen, we're running already
cd_reset:
    ; data length
    LDA #$05
    STA BG_QUEUE

    ; PPU address
    LDA #$20
    STA BG_QUEUE+1
    LDA #$AE
    STA BG_QUEUE+2

    ; flags
    LDA #%10000000
    STA BG_QUEUE+3

    LDA #$00
    STA BG_QUEUE+4

    LDA #$00
    STA BG_QUEUE+5

    LDA #ST_RUNNING
    STA start_count
    jmp update_ball_start_check
    rts

; "start" text
cd_00:
    LDA start_ticks
    CMP #1
    BEQ cd_reset

    ; data length
    LDA #$05
    STA BG_QUEUE

    ; PPU address
    LDA #$20
    STA BG_QUEUE+1
    LDA #$AE
    STA BG_QUEUE+2

    ; flags
    LDA #$00
    STA BG_QUEUE+3

    ; the text "03"
    LDA #'S'
    STA BG_QUEUE+4
    LDA #'T'
    STA BG_QUEUE+5
    LDA #'A'
    STA BG_QUEUE+6
    LDA #'R'
    STA BG_QUEUE+7
    LDA #'T'
    STA BG_QUEUE+8
    LDA #'!'
    STA BG_QUEUE+9

    LDA #0
    STA BG_QUEUE+10

    DEC start_ticks
    LDA start_ticks
    cmp #0
    BNE cd_00_nochange

    LDA #ST_LENGTH
    STA start_ticks
    LDA #ST_RUNNING
    STA start_count

cd_00_nochange:
    jmp update_ball_start_check
    ;rts

; "01" text
cd_01:
    ; data length
    LDA #$02
    STA BG_QUEUE

    ; PPU address
    LDA #$20
    STA BG_QUEUE+1
    LDA #$AE
    STA BG_QUEUE+2

    ; flags
    LDA #$00
    STA BG_QUEUE+3

    ; the text "03"
    LDA #'0'
    STA BG_QUEUE+4
    LDA #'1'
    STA BG_QUEUE+5

    LDA #0
    STA BG_QUEUE+6

    DEC start_ticks
    LDA start_ticks
    cmp #0
    BNE cd_01_nochange

    LDA #ST_LENGTH
    STA start_ticks
    LDA #ST_0
    STA start_count

cd_01_nochange:
    rts

; "02" text
cd_02:
    ; data length
    LDA #$02
    STA BG_QUEUE

    ; PPU address
    LDA #$20
    STA BG_QUEUE+1
    LDA #$AE
    STA BG_QUEUE+2

    ; flags
    LDA #$00
    STA BG_QUEUE+3

    ; the text "03"
    LDA #'0'
    STA BG_QUEUE+4
    LDA #'2'
    STA BG_QUEUE+5

    LDA #0
    STA BG_QUEUE+6

    DEC start_ticks
    LDA start_ticks
    cmp #0
    BNE cd_02_nochange

    LDA #ST_LENGTH
    STA start_ticks
    LDA #ST_1
    STA start_count

cd_02_nochange:
    rts

; "03" text
cd_03:
    ; data length
    LDA #$02
    STA BG_QUEUE

    ; PPU address
    LDA #$20
    STA BG_QUEUE+1
    LDA #$AE
    STA BG_QUEUE+2

    ; flags
    LDA #$00
    STA BG_QUEUE+3

    ; the text "03"
    LDA #'0'
    STA BG_QUEUE+4
    LDA #'3'
    STA BG_QUEUE+5

    LDA #0
    STA BG_QUEUE+6

    DEC start_ticks
    LDA start_ticks
    cmp #0
    BNE cd_03_nochange

    LDA #ST_LENGTH
    STA start_ticks
    LDA #ST_2
    STA start_count

cd_03_nochange:
    rts
