//////////////////////////////////////////////////////////////////////////////
// astro_sound_macs.asm
// Copyright(c) 2021 Neal Smith.
// License: MIT. See LICENSE file in root directory.
//////////////////////////////////////////////////////////////////////////////
// consts and macros related to astro_sound
//////////////////////////////////////////////////////////////////////////////

#importonce 
//#import "../nv_c64_util/nv_c64_util_macs.asm"

// load accum with these before init to play 
// the subtune desired when stepping.
.const ASTRO_SOUND_MAIN_TUNE = $00
.const ASTRO_SOUND_WIN_TUNE = $01
.const ASTRO_SOUND_TITLE_TUNE = $02