//////////////////////////////////////////////////////////////////////////////
// astro_title_code.asm
// Copyright(c) 2021 Neal Smith.
// License: MIT. See LICENSE file in root directory.
//////////////////////////////////////////////////////////////////////////////
// The following subroutines should be called from the main engine
// as follows
// TitleStart: call to show title screen.  it will not return until the 
//             title screen is done.
//////////////////////////////////////////////////////////////////////////////

#importonce 
#import "../nv_c64_util/nv_c64_util_macs_and_data.asm"
#import "astro_vars_data.asm"
#import "astro_keyboard_macs.asm"
#import "astro_sound.asm"
#import "astro_stream_processor_code.asm"
#import "astro_ships_code.asm"
#import "astro_help_code.asm"

//////////////////////////////////////////////////////////////////////////////
// macro to allocate a string of underline chars in place
// macro params:
//   len: the number of underline chars
//   null_term: pass true to add a null terminator to the end of string
//              or false not to.
.macro UnderlineStr(len, null_term)
{
    .var index = 0
    .for(index = 0; index<len; index=index+1)
    {
        .text @"\$44"
    }
    .if (null_term)
    {
        .text @"\$00"
    }
} 

//////////////////////////////////////////////////////////////////////////////
// macro to allocate a string of space chars in place
// macro params:
//   len: the number of space chars
//   null_term: pass true to add a null terminator to the end of string
//              or false not to.
.macro SpaceStr(len, null_term)
{
    .var index = 0
    .for(index = 0; index<len; index=index+1)
    {
        .text @" "
    }
    .if (null_term)
    {
        .text @"\$00"
    }
} 

//////////////////////////////////////////////////////////////////////////////
// macro to allocate a string of double underline chars in place
// macro params:
//   len: the number of double underline chars
//   null_term: pass true to add a null terminator to the end of string
//              or false not to.

.macro DoubleUnderlineStr(len, null_term)
{
    .var index = 0
    .for(index = 0; index<len; index=index+1)
    {
        .text @"\$78"
    }
    .if (null_term)
    {
        .text @"\$00"
    }
} 

// title screen title text
astro_title_str:      .text @"            astroblast\$00"
astro_titlea_str:     SpaceStr(12, false)
                      DoubleUnderlineStr(10, true)

// number of players menu
title_text_num_players_1_str:  .text @" num players\$00"
title_text_num_players_2_str:  SpaceStr(1, false) 
                               UnderlineStr(11, true) 
title_text_num_players_3_str:  .text @" 1 .. one player\$00"
title_text_num_players_4_str:  .text @" 2 .. two players\$00" 

// general menu
title_text_general_1_str:    .text @"general\$00"
title_text_general_2_str:   UnderlineStr(7, true) 
title_text_general_3_str:    .text @"f1 .. help\$00"
title_text_general_4_str:    .text @"q  .. quit\$00" 
title_text_general_5_str:    .text @"p  .. play\$00"
title_text_general_6_str:    .text @"<  .. vol down\$00"    
title_text_general_7_str:    .text @">  .. vol up\$00"

// game length menu
title_text_game_len_1_str:    .text @" game len \$00"
title_text_game_len_2_str:   SpaceStr(1, false)
                              UnderlineStr(14, true)
title_text_game_len_3_str:    .text @" t .. time based\$00"
title_text_game_len_4_str:    .text @" s .. score based\$00"
title_text_game_len_5_str:    .text @" \$40 .. shorter\$00"
title_text_game_len_6_str:    .text @" \$5b .. longer\$00"

// difficulty menu
title_text_difficulty_1_str:    .text @" difficulty\$00"
title_text_difficulty_2_str: SpaceStr(1, false)  
                             UnderlineStr(10, true)
title_text_difficulty_3_str:    .text @" e .. easy\$00"
title_text_difficulty_4_str:    .text @" m .. medium\$00"
title_text_difficulty_5_str:    .text @" h .. hard\$00"

title_blank4_str:      .text @"    \$00"
play_flag: .byte $00

.const TITLE_KEY_COOL_DURATION = $08
.const TITLE_RECT_WIDTH = 34
.const TITLE_RECT_HEIGHT = 19
.const TITLE_ROW_START = 2
.const TITLE_COL_START = NV_SCREEN_CHARS_PER_ROW/2 -(TITLE_RECT_WIDTH/2) 

.const TRS = TITLE_ROW_START
.const TCS = TITLE_COL_START
.const TCPR = NV_SCREEN_CHARS_PER_ROW
.const TITLE_RECT_TOP_CHAR = 82

.const TITLE_MIN_GAME_LEN = $0010
.const TITLE_MAX_GAME_LEN = $0200
.const TITLE_GAME_LEN_INC_DEC = $0010

.const TITLE_INDICATOR_CHAR = 65
.const TITLE_KEY_EASY         = NV_KEY_E 
.const TITLE_KEY_MED          = NV_KEY_M
.const TITLE_KEY_HARD         = NV_KEY_H
.const TITLE_KEY_TIMED_GAME   = NV_KEY_T
.const TITLE_KEY_SCORED_GAME  = NV_KEY_S
.const TITLE_KEY_PLAY         = NV_KEY_P
.const TITLE_KEY_LONGER_GAME  = NV_KEY_PLUS
.const TITLE_KEY_SHORTER_GAME = NV_KEY_MINUS
.const TITLE_KEY_HELP         = NV_KEY_F1
.const TITLE_KEY_ONE_PLAYER   = NV_KEY_1
.const TITLE_KEY_TWO_PLAYER   = NV_KEY_2

.const TITLE_GENERAL_ROW = 6
.const TITLE_GENERAL_COL = 3

.const TITLE_NUM_PLAYERS_ROW  = 6
.const TITLE_NUM_PLAYERS_COL  = 20

.const TITLE_GAME_LEN_ROW  = 14
.const TITLE_GAME_LEN_COL  = 20

.const TITLE_DIFFICULTY_ROW  = 14
.const TITLE_DIFFICULTY_COL  = 2

.var index

/*
title_rect_top_char_addr_list:
    .for (index = 0; index < TITLE_RECT_WIDTH; index = index+1)
    {
        .word nv_screen_char_addr_from_yx((TRS + 0), TCS + index)
    }
    .word $FFFF

title_rect_bottom_char_addr_list:
    .for (index = 0; index < TITLE_RECT_WIDTH; index = index+1)
    {
        .word nv_screen_char_addr_from_yx((TRS + TITLE_RECT_HEIGHT-1), TCS + index)
    }
    .word $FFFF

.const TITLE_RECT_COLOR_FIRST = nv_screen_color_addr_from_yx((TRS + 0), TCS + 0)
.const TITLE_RECT_COLOR_LAST = nv_screen_color_addr_from_yx((TRS + TITLE_RECT_HEIGHT), TCS + TITLE_RECT_WIDTH)

title_rect_stream:
    // set top rect char
    .word $FFFF
    .byte $01, TITLE_RECT_TOP_CHAR

    // poke the rect top chars
    .word $FFFF
    .byte $03                   // destination list
    .word title_rect_top_char_addr_list

    // poke the rect bottom chars
    .word $FFFF
    .byte $03                   // destination list
    .word title_rect_bottom_char_addr_list

    // poke the colors of the rect
    .word $FFFF
    .byte $01, NV_COLOR_WHITE
  
    .word $FFFF
    .byte $04                               // destination block command
    .word TITLE_RECT_COLOR_FIRST+(NV_SCREEN_CHARS_PER_ROW * 0)
    .word TITLE_RECT_COLOR_FIRST+(NV_SCREEN_CHARS_PER_ROW * 0) + TITLE_RECT_WIDTH

    .word $FFFF
    .byte $04                               // destination block command
    .word TITLE_RECT_COLOR_FIRST+(NV_SCREEN_CHARS_PER_ROW * (TITLE_RECT_HEIGHT-1))
    .word TITLE_RECT_COLOR_FIRST+(NV_SCREEN_CHARS_PER_ROW * (TITLE_RECT_HEIGHT-1)) + TITLE_RECT_WIDTH


    // stream done
    .word $FFFF
    .byte $FF
*/


//////////////////////////////////////////////////////////////////////////////
// call once to initialize variables and stuff
// must call the following before calling this
//   nv_key_init
//   SoundInit
TitleStart:
{
    nv_screen_clear()

    lda #$00
    sta play_flag

    // initialize song 0 so we can hear music during title 
    // so user can adjust volume
    lda #ASTRO_SOUND_TITLE_TUNE
    jsr SoundInit

    //jsr StarInit
    //jsr StarStart

    // set up ship 1 to rotate around the top of the screen
    nv_store16_immed(ship_1.x_loc, 50)
    lda #47
    sta ship_1.y_loc
    lda #0
    sta ship_1.y_vel
    lda #2 
    sta ship_1.x_vel
    jsr ship_1.Enable

    // set up ship 2 to rotate around the bottom of the screen
    nv_store16_immed(ship_2.x_loc, 50)
    lda #232
    sta ship_2.y_loc
    lda #0
    sta ship_2.y_vel
    lda #2 
    sta ship_2.x_vel
    jsr ship_2.SetColorAlive
    jsr ship_2.Enable



TitleLoop:
    nv_sprite_wait_last_scanline()         // wait for particular scanline.
    SoundDoStep()
    jsr ship_1.SetLocationFromExtraData
    jsr ship_2.SetLocationFromExtraData

    //ldx #<title_rect_stream
    //ldy #>title_rect_stream
    //jsr AstroStreamProcessor

    .var poke_row = TITLE_ROW_START + 1
    nv_screen_poke_color_str(poke_row++, TITLE_COL_START, NV_COLOR_WHITE, astro_title_str)
    nv_screen_poke_color_str(poke_row++, TITLE_COL_START, NV_COLOR_WHITE, astro_titlea_str)
    .eval poke_row = poke_row + 9

    // draw each of the menus including any indicators or other dynamic content
    DrawGeneral(TITLE_GENERAL_ROW, TITLE_GENERAL_COL)
    DrawNumPlayers(TITLE_NUM_PLAYERS_ROW, TITLE_NUM_PLAYERS_COL)
    DrawGameLen(TITLE_GAME_LEN_ROW, TITLE_GAME_LEN_COL)
    DrawDifficulty(TITLE_DIFFICULTY_ROW, TITLE_DIFFICULTY_COL)

    // move the ship in its extra data
    jsr ship_1.MoveInExtraData
    jsr ship_2.MoveInExtraData

    jsr TitleDoKeyboard
    lda quit_flag
    beq TitleNoQuit
    jmp TitleDone
TitleNoQuit:
    jmp TitleLoop

TitleDone:
    // copy score to win to astro_game_seconds in case the user selected timed game
    nv_xfer16_mem_mem(astro_score_to_win, astro_game_seconds)

    lda play_flag
    beq QuitGame
PlayGame:
    lda #$00
    sta quit_flag
    lda #$01
    rts
QuitGame:
    lda #$00
    rts
}
// TitleStart end
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// inline macro to draw the general menu items
// macro params:
//   draw_row: the row of the upper left char position for the menu
//   draw_col: the col of the upper left char position for the menu
.macro DrawGeneral(draw_row, draw_col)
{
    .var cur_row = draw_row
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_general_1_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_general_2_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_general_3_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_general_4_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_general_5_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_general_6_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_general_7_str)
}
/////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// inline macro to draw the game length menu items
// macro params:
//   draw_row: the row of the upper left char position for the menu
//   draw_col: the col of the upper left char position for the menu
.macro DrawGameLen(draw_row, draw_col)
{
    .var cur_row = draw_row
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_game_len_1_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_game_len_2_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_game_len_3_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_game_len_4_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_game_len_5_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_game_len_6_str)

    .const TITLE_TIME_BASED_MARK_ROW = draw_row + 2
    .const TITLE_TIME_BASED_MARK_COL = draw_col
    .const TITLE_SCORE_BASED_MARK_ROW = TITLE_TIME_BASED_MARK_ROW + 1
    .const TITLE_SCORE_BASED_MARK_COL = TITLE_TIME_BASED_MARK_COL
    .const TITLE_GAME_LEN_ROW = draw_row
    .const TITLE_GAME_LEN_COL = draw_col + 11

    // print the game length in cyan, first blank out the old value and update color
    nv_screen_poke_color_str(TITLE_GAME_LEN_ROW, TITLE_GAME_LEN_COL, NV_COLOR_CYAN, title_blank4_str)

    // Now poke the game length to the screen.
    // During title screen astro_score_to_win is both seconds and points.
    // when title screen is done it will be copied to astro_game_seconds
    nv_screen_poke_hex_word_mem(TITLE_GAME_LEN_ROW, TITLE_GAME_LEN_COL, astro_score_to_win, false)


    lda #TITLE_INDICATOR_CHAR
    nv_screen_poke_char_a(TITLE_TIME_BASED_MARK_ROW, TITLE_TIME_BASED_MARK_COL)
    nv_screen_poke_char_a(TITLE_SCORE_BASED_MARK_ROW, TITLE_SCORE_BASED_MARK_COL)

    nv_beq8_immed(astro_end_on_seconds, 0, IsScoreBased)
IsTimeBased:
    lda #NV_COLOR_YELLOW
    nv_screen_poke_color_a(TITLE_TIME_BASED_MARK_ROW, TITLE_TIME_BASED_MARK_COL)
    lda #NV_COLOR_BLACK
    nv_screen_poke_color_a(TITLE_SCORE_BASED_MARK_ROW, TITLE_SCORE_BASED_MARK_COL)
    jmp Done

IsScoreBased:
    lda #NV_COLOR_YELLOW
    nv_screen_poke_color_a(TITLE_SCORE_BASED_MARK_ROW, TITLE_SCORE_BASED_MARK_COL)
    lda #NV_COLOR_BLACK
    nv_screen_poke_color_a(TITLE_TIME_BASED_MARK_ROW, TITLE_TIME_BASED_MARK_COL)

Done:
}
//////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////
// inline macro to draw the difficulty menu items
// macro params:
//   draw_row: the row of the upper left char position for the menu
//   draw_col: the col of the upper left char position for the menu
.macro DrawDifficulty(draw_row, draw_col)
{
    .var cur_row = draw_row
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_difficulty_1_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_difficulty_2_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_difficulty_3_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_difficulty_4_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_difficulty_5_str)

    .const TITLE_DIFF_EASY_MARK_ROW = draw_row + 2
    .const TITLE_DIFF_EASY_MARK_COL = draw_col
    .const TITLE_DIFF_MED_MARK_ROW = TITLE_DIFF_EASY_MARK_ROW + 1
    .const TITLE_DIFF_MED_MARK_COL = TITLE_DIFF_EASY_MARK_COL
    .const TITLE_DIFF_HARD_MARK_ROW = TITLE_DIFF_MED_MARK_ROW + 1
    .const TITLE_DIFF_HARD_MARK_COL = TITLE_DIFF_MED_MARK_COL

    lda #TITLE_INDICATOR_CHAR
    nv_screen_poke_char_a(TITLE_DIFF_EASY_MARK_ROW, TITLE_DIFF_EASY_MARK_COL)
    nv_screen_poke_char_a(TITLE_DIFF_MED_MARK_ROW, TITLE_DIFF_MED_MARK_COL)
    nv_screen_poke_char_a(TITLE_DIFF_HARD_MARK_ROW, TITLE_DIFF_HARD_MARK_COL)

TryEasy:
    nv_bne8_immed(astro_diff_mode, ASTRO_DIFF_EASY, TryMed)
IsEasy:
    lda #NV_COLOR_YELLOW
    nv_screen_poke_color_a(TITLE_DIFF_EASY_MARK_ROW, TITLE_DIFF_EASY_MARK_COL)
    lda #NV_COLOR_BLACK
    nv_screen_poke_color_a(TITLE_DIFF_MED_MARK_ROW, TITLE_DIFF_MED_MARK_COL)
    nv_screen_poke_color_a(TITLE_DIFF_HARD_MARK_ROW, TITLE_DIFF_HARD_MARK_COL)
    jmp Done

TryMed:
    nv_bne8_immed(astro_diff_mode, ASTRO_DIFF_MED, TryHard)
IsMed:
    lda #NV_COLOR_YELLOW
    nv_screen_poke_color_a(TITLE_DIFF_MED_MARK_ROW, TITLE_DIFF_MED_MARK_COL)
    lda #NV_COLOR_BLACK
    nv_screen_poke_color_a(TITLE_DIFF_EASY_MARK_ROW, TITLE_DIFF_EASY_MARK_COL)
    nv_screen_poke_color_a(TITLE_DIFF_HARD_MARK_ROW, TITLE_DIFF_HARD_MARK_COL)
    jmp Done

TryHard:
    // assume hard if wasn't easy or medium
    //nv_bne8_immed(astro_diff_mode, ASTRO_DIFF_HARD, Done)
IsHard:
    lda #NV_COLOR_YELLOW
    nv_screen_poke_color_a(TITLE_DIFF_HARD_MARK_ROW, TITLE_DIFF_HARD_MARK_COL)
    lda #NV_COLOR_BLACK
    nv_screen_poke_color_a(TITLE_DIFF_EASY_MARK_ROW, TITLE_DIFF_EASY_MARK_COL)
    nv_screen_poke_color_a(TITLE_DIFF_MED_MARK_ROW, TITLE_DIFF_MED_MARK_COL)
    // fall through to done

Done:
}
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// inline macro to draw the number of players menu items
// macro params:
//   draw_row: the row of the upper left char position for the menu
//   draw_col: the col of the upper left char position for the menu
.macro DrawNumPlayers(draw_row, draw_col)
{
    .var cur_row = draw_row
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_num_players_1_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_num_players_2_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_num_players_3_str)
    nv_screen_poke_color_str(cur_row++, draw_col, NV_COLOR_WHITE, title_text_num_players_4_str)

    .const TITLE_ONE_PLAYER_MARK_ROW = draw_row + 2
    .const TITLE_ONE_PLAYER_MARK_COL = draw_col
    .const TITLE_TWO_PLAYER_MARK_ROW = TITLE_ONE_PLAYER_MARK_ROW + 1
    .const TITLE_TWO_PLAYER_MARK_COL = TITLE_ONE_PLAYER_MARK_COL

    lda #TITLE_INDICATOR_CHAR
    nv_screen_poke_char_a(TITLE_ONE_PLAYER_MARK_ROW, TITLE_ONE_PLAYER_MARK_COL)
    nv_screen_poke_char_a(TITLE_TWO_PLAYER_MARK_ROW, TITLE_TWO_PLAYER_MARK_COL)


    nv_beq8_immed(astro_single_player_flag, 0, IsTwoPlayer)
IsOnePlayer:
    lda #NV_COLOR_YELLOW
    nv_screen_poke_color_a(TITLE_ONE_PLAYER_MARK_ROW, TITLE_ONE_PLAYER_MARK_COL)
    lda #NV_COLOR_BLACK
    nv_screen_poke_color_a(TITLE_TWO_PLAYER_MARK_ROW, TITLE_TWO_PLAYER_MARK_COL)
    jmp Done

IsTwoPlayer:
    lda #NV_COLOR_YELLOW
    nv_screen_poke_color_a(TITLE_TWO_PLAYER_MARK_ROW, TITLE_TWO_PLAYER_MARK_COL)
    lda #NV_COLOR_BLACK
    nv_screen_poke_color_a(TITLE_ONE_PLAYER_MARK_ROW, TITLE_ONE_PLAYER_MARK_COL)

Done:
}
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// subroutine to do all the keyboard stuff
TitleDoKeyboard: 
{
    nv_key_scan()

    lda key_cool_counter
    beq TitleNotInCoolDown          // not in keyboard cooldown, go scan
    dec key_cool_counter            // in keyboard cooldown, dec the cntr
    jmp TitleDoneKeys               // and jmp to skip rest of routine
TitleNotInCoolDown:

    nv_key_get_last_pressed_a()     // get key pressed in accum

    cmp #NV_KEY_NO_KEY              // check if any key hit
    bne TitleHaveKey 
    jmp TitleDoneKeys               // no key hit, skip to end
TitleHaveKey:
    ldy #TITLE_KEY_COOL_DURATION    // had a key, start cooldown counter        
    sty key_cool_counter


//////
// no repeat key presses handled here, only transition keys below this line
// if its a repeat key press then we'll ignore it.
TryTransitionKeys:
    nv_key_get_prev_pressed_y() // previous key pressed to Y reg
    sty scratch_byte            // then to scratch reg to compare with accum
    cmp scratch_byte            // if prev key == last key then done with keys
    bne TitleNotDoneKeys
    jmp TitleDoneKeys 

TitleNotDoneKeys:

TryIncVolume:
    cmp #KEY_INC_VOLUME             
    bne TryDecVolume                           
WasIncVolume:
    jsr SoundVolumeUp
    jmp TitleDoneKeys                // and skip to bottom

TryDecVolume:
    cmp #KEY_DEC_VOLUME             
    bne TryDiffEasy                          
WasDecVolume:
    jsr SoundVolumeDown
    jmp TitleDoneKeys

TryDiffEasy:
    cmp #TITLE_KEY_EASY            
    bne TryDiffMed                          
WasDiffEasy:
    lda #ASTRO_DIFF_EASY
    sta astro_diff_mode
    jmp TitleDoneKeys                // and skip to bottom

TryDiffMed:
    cmp #TITLE_KEY_MED
    bne TryDiffHard
WasDiffMed:
    lda #ASTRO_DIFF_MED
    sta astro_diff_mode
    jmp TitleDoneKeys                // and skip to bottom

TryDiffHard:
    cmp #TITLE_KEY_HARD
    bne TryPlus
WasDiffHard:
    lda #ASTRO_DIFF_HARD
    sta astro_diff_mode
    jmp TitleDoneKeys                // and skip to bottom

TryPlus:
    cmp #TITLE_KEY_LONGER_GAME
    bne TryMinus
WasPlus:
    // increment game length (astro_score_to_win) although might represent seconds
    nv_bge16_immed(astro_score_to_win, TITLE_MAX_GAME_LEN-TITLE_GAME_LEN_INC_DEC, TitleGameLenSkipAdd)
    nv_bcd_adc16_mem_immed(astro_score_to_win, TITLE_GAME_LEN_INC_DEC, astro_score_to_win)
TitleGameLenSkipAdd:
    jmp TitleDoneKeys                // and skip to bottom

TryMinus:
    cmp #TITLE_KEY_SHORTER_GAME
    bne TryTimedGame
WasMinus:
    // decrement game length (astro_score_to_win is used for seconds and points in title screen)
    nv_blt16_immed(astro_score_to_win, TITLE_MIN_GAME_LEN+TITLE_GAME_LEN_INC_DEC, TitleGameLenSkipAdd)
    nv_bcd_sbc16_mem_immed(astro_score_to_win, TITLE_GAME_LEN_INC_DEC, astro_score_to_win)
TitleGameLenSkipSub:
    jmp TitleDoneKeys                // and skip to bottom

TryTimedGame:
    cmp #TITLE_KEY_TIMED_GAME
    bne TryScoredGame
WasTimedGame:
    lda #1
    sta astro_end_on_seconds
    jmp TitleDoneKeys                // and skip to bottom

TryScoredGame:
    cmp #TITLE_KEY_SCORED_GAME
    bne TryOnePlayer
WasScoredGame:
    lda #0
    sta astro_end_on_seconds
    jmp TitleDoneKeys                // and skip to bottom

TryOnePlayer:
    nv_bne8_immed_a(TITLE_KEY_ONE_PLAYER, TryTwoPlayer)
WasOnePlayer:
    lda #1 
    sta astro_single_player_flag

TryTwoPlayer:
    nv_bne8_immed_a(TITLE_KEY_TWO_PLAYER, TryHelp)
WasTwoPlayer:
    lda #0
    sta astro_single_player_flag

TryHelp:
    nv_bne8_immed_a(TITLE_KEY_HELP, TryPlay)
WasHelp:
    jsr TitleDoHelp
    jmp TitleDoneKeys

TryPlay:
    cmp #TITLE_KEY_PLAY               
    bne TryQuit                 
WasPlay:
    lda #1                      
    sta play_flag
    sta quit_flag
    jmp TitleDoneKeys

TryQuit:
    cmp #KEY_QUIT               
    bne TitleDoneKeys           
WasQuit:
    lda #1                      
    sta quit_flag
    // fall throught to TitleDoneKeys

TitleDoneKeys:
    rts
}
// TitleDoKeyboard - end
//////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////
// subroutine to show the help screen.  
TitleDoHelp:
{
    // disable ship sprites
    jsr ship_1.Disable
    jsr ship_2.Disable

    // display the help
    jsr HelpStart

    // re enable the ship sprites
    jsr ship_1.Enable
    jsr ship_2.Enable

    rts
}
//
//////////////////////////////////////////////////////////////////////////////
