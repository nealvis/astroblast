//////////////////////////////////////////////////////////////////////////////
// astro_help_code.asm
// Copyright(c) 2021 Neal Smith.
// License: MIT. See LICENSE file in root directory.
//////////////////////////////////////////////////////////////////////////////
// The following subroutines should be called from the main engine
// as follows
// HelpStart: call to show help screen.  it will not return until the 
//             help screen is done.
//////////////////////////////////////////////////////////////////////////////

#importonce 
#import "../nv_c64_util/nv_c64_util_macs_and_data.asm"
#import "astro_vars_data.asm"
#import "astro_starfield_code.asm"
#import "astro_keyboard_macs.asm"
#import "astro_sound.asm"
#import "astro_stream_processor_code.asm"
#import "astro_ships_code.asm"

.const HELP_KEY_COOL_DURATION = $08

astro_help_01_str: .text @"           --astroblast help--\$00"
astro_help_02_str: .text @"\$00"
astro_help_03_str: .text @"general\$00"
astro_help_04_str: .text @"score by steering into asteroids\$00"
astro_help_05_str: .text @"ships always move left to right\$00" 
astro_help_06_str: .text @"joystick 1 controls top ship\$00"
astro_help_07_str: .text @"joystick 2 controls bottom ship\$00"
astro_help_08_str: .text @"\$00"
astro_help_09_str: .text @"controls\$00"
astro_help_10_str: .text @"joystick left  slows down ship\$00" 
astro_help_11_str: .text @"joystick right speeds up ship\$00"
astro_help_12_str: .text @"joystick down  shields ship\$00"
astro_help_13_str: .text @"joystick fire  fires armed turret\$00"
astro_help_14_str: .text @"\$00"
astro_help_15_str: .text @"turrrets\$00"
astro_help_16_str: .text @"two turrets are on right of screen\$00"
astro_help_17_str: .text @"turrets can only fire when armed\$00"
astro_help_18_str: .text @"turrets will glow when armed\$00"
astro_help_19_str: .text @"turrets will autofire if not shot\$00"
astro_help_20_str: .text @"\$00"
astro_help_21_str: .text @"winning\$00"
astro_help_22_str: .text @"win with most points when game ends\$00"
astro_help_23_str: .text @"game ends based on time or score\$00"
astro_help_24_str: .text @"set to score or time via title screen\$00"

astro_help_done_flag: .byte $00

//////////////////////////////////////////////////////////////////////////////
// call to bring up the help screen
HelpStart:
{
    nv_screen_clear()

    nv_xfer8x_immed_mem(0, astro_help_done_flag)
    nv_xfer8x_immed_mem(0, key_cool_counter)

    .const TITLE_COLOR =  NV_COLOR_LITE_GREEN
    .const SUBHEAD_COLOR = NV_COLOR_CYAN
    .const TEXT_COLOR = NV_COLOR_WHITE

    .var poke_row = 0
    .var title_col = 13
    .var text_col = 0
    nv_screen_poke_color_str(poke_row++, text_col, TITLE_COLOR, astro_help_01_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_02_str)
    nv_screen_poke_color_str(poke_row++, text_col, SUBHEAD_COLOR, astro_help_03_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_04_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_05_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_06_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_07_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_08_str)
    nv_screen_poke_color_str(poke_row++, text_col, SUBHEAD_COLOR, astro_help_09_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_10_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_11_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_12_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_13_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_14_str)
    nv_screen_poke_color_str(poke_row++, text_col, SUBHEAD_COLOR, astro_help_15_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_16_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_17_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_18_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_19_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_20_str)
    nv_screen_poke_color_str(poke_row++, text_col, SUBHEAD_COLOR, astro_help_21_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_22_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_23_str)
    nv_screen_poke_color_str(poke_row++, text_col, TEXT_COLOR, astro_help_24_str)



HelpLoop:
    nv_sprite_wait_last_scanline()         // wait for particular scanline.
    SoundDoStep()

    jsr HelpDoKeyboard

    nv_beq8_immed(astro_help_done_flag, $00, HelpLoop)

    //jsr NvKeyWaitNoKey
    //nv_key_wait_no_key()
    nv_screen_clear()
    rts
}
// HelpStart end
//////////////////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////////////////
// subroutine to do all the keyboard stuff
HelpDoKeyboard: 
{
    nv_key_scan()

    lda key_cool_counter
    beq HelpNotInCoolDown          // not in keyboard cooldown, go scan
    dec key_cool_counter           // in keyboard cooldown, dec the cntr
    jmp HelpDoneKeys               // and jmp to skip rest of routine

HelpNotInCoolDown:
    nv_key_get_last_pressed_a()    // get key pressed in accum
    nv_beq8_immed_a(NV_KEY_NO_KEY, HelpDoneKeys)

HelpHaveKey:
    ldy #HELP_KEY_COOL_DURATION    // had a key, start cooldown counter        
    sty key_cool_counter


//////
// no repeat key presses handled here, only transition keys below this line
// if its a repeat key press then we'll ignore it.
TryTransitionKeys:
    nv_key_get_prev_pressed_y() // previous key pressed to Y reg
    sty scratch_byte            // then to scratch reg to compare with accum
    nv_beq8_a(scratch_byte, HelpDoneKeys) // if prev key == last key then done

HelpNotDoneKeys:

//TryQuit:
//    nv_bne8_immed_a(KEY_QUIT, HelpDoneKeys)
//WasQuit:
    nv_xfer8x_immed_mem(1, astro_help_done_flag)
    // fall through to HelpDoneKeys

HelpDoneKeys:
    rts
}
// HelpDoKeyboard - end
//////////////////////////////////////////////////////////////////////////////
