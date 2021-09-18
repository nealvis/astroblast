//////////////////////////////////////////////////////////////////////////////
// astro_ship_shield_code.asm
// Copyright(c) 2021 Neal Smith.
// License: MIT. See LICENSE file in root directory.
//////////////////////////////////////////////////////////////////////////////
// The following subroutines should be called from the main engine
// as follows
// ShipShieldInit: Call once before main loop
// ShipShieldStep: Call once every raster frame through the main loop
// ShipShieldStart: Call to start the effect
// ShipShieldForceStop: Call to force effect to stop if it is active
// ShipShieldCleanup: Call at end of program after main loop to clean up
//////////////////////////////////////////////////////////////////////////////
#importonce

#import "astro_ship_shield_data.asm"
#import "astro_ships_code.asm"

//////////////////////////////////////////////////////////////////////////////
// Call once before main loop
ShipShieldInit: 
{
    lda #$00
    sta ship_1_shield_count
    sta ship_2_shield_count
    rts
}
// ShipShieldInit end
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// Call once every raster frame through the main loop.
// will step each ship that is dead
ShipShieldStep: 
{
ShipShieldStepTryShip1:    
    lda ship_1_shield_count
    beq ShipShieldStepTryShip2
    jsr Ship1ShieldStep
    
 ShipShieldStepTryShip2:   
    lda ship_2_shield_count
    beq ShipShieldStepDone
    jsr Ship2ShieldStep

ShipShieldStepDone:
    rts

}
// end - ShipShieldStep 
//////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////
//
Ship1ShieldStep:
{
    lda ship_1_shield_count
    bne ShipShielding
    rts

ShipShielding:
    // get zero based frame number into y reg
    // then multiply by two to get the index 
    // into our sprite data ptr address table
    lda #SHIP_SHIELD_FRAMES
    sec
    sbc ship_1_shield_count
    cmp #SHIP_SHIELD_ANIMATION_FRAMES
    bcs ShieldOnAnimationDone
    asl
    tay         
    // y reg now holds zero based index into table of the
    // byte that has the LSB of the sprite data ptr

    // LSB of sprite's data ptr to x and
    // MSB to Accum so we can call the SetDataPtr
    ldx shield_sprite_data_ptr_table, y
    iny 
    lda shield_sprite_data_ptr_table, y
    jsr ship_1.SetDataPtr
ShieldOnAnimationDone:

ShipShieldDecCount:
    dec ship_1_shield_count
    bne ShipShieldCountContinues

ShipShieldDone:
    // do shield done stuff here
    ldx #<sprite_ship
    lda #>sprite_ship
    jsr ship_1.SetDataPtr
    
ShipShieldCountContinues:
    rts
}
// Ship1ShieldStep end   
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
//
Ship2ShieldStep:
{
    lda ship_2_shield_count
    bne ShipShielding
    rts

ShipShielding:
    // get zero based frame number into y reg
    // then multiply by two to get the index 
    // into our sprite data ptr address table
    lda #SHIP_SHIELD_FRAMES
    sec
    sbc ship_2_shield_count
    cmp #SHIP_SHIELD_ANIMATION_FRAMES
    bcs ShieldOnAnimationDone
    asl
    tay         
    // y reg now holds zero based index into table of the
    // byte that has the LSB of the sprite data ptr

    // LSB of sprite's data ptr to x and
    // MSB to Accum so we can call the SetDataPtr
    ldx shield_sprite_data_ptr_table, y
    iny 
    lda shield_sprite_data_ptr_table, y
    jsr ship_2.SetDataPtr
ShieldOnAnimationDone:

ShipShieldDecCount:
    dec ship_2_shield_count
    bne ShipShieldCountContinues

ShipShieldDone:
    // do shield done stuff here
    ldx #<sprite_ship
    lda #>sprite_ship
    jsr ship_2.SetDataPtr
    
ShipShieldCountContinues:
    rts
}
// Ship1ShieldStep end   
//////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////
// Call to start the effect
// params:
//   accum: set to 1 or 2 for ship 1 or ship 2
ShipShieldStart: 
{
ShipShieldStartTryShip1:
    cmp #1
    bne ShipShieldStartTryShip2
    lda #SHIP_SHIELD_FRAMES
    sta ship_1_shield_count
    rts

ShipShieldStartTryShip2:
    cmp #2
    bne ShipShieldStartDone
    lda #SHIP_SHIELD_FRAMES
    sta ship_2_shield_count
ShipShieldStartDone:
    rts
}
// ShipShieldStart end subroutine
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// Call check if shield is active for specified ship
// subroutine params:
//   accum: pass 1 for ship 1, or 2 for ship 2
// Accum: upon return will have a zero if shield not active or nonzero if is
// X Reg: unchanged
// Y Reg: unchanged
ShipShieldIsActive:
{
TryShip1:
    pha
    and #$01
    beq TryShip2
    pla
    lda ship_1_shield_count
    rts
    
TryShip2:
    pla
    and #$02
    beq Done
    lda ship_2_shield_count

Done:
    rts

}
//
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// Call to force effect to stop if it is active
// load accum with 1 for ship 1, or 2 for ship 2 or 3 for both ships
ShipShieldForceStop: 
{
TryShip1:
    pha
    and #$01
    beq TryShip2
    ldx #$00
    stx ship_1_shield_count
    // LSB of sprite's data ptr to x and
    // MSB to Accum so we can call the SetDataPtr
    ldx #<sprite_ship
    lda #>sprite_ship    
    jsr ship_1.SetDataPtr
    // fall through and try ship 2

TryShip2:
    pla
    and #$02
    beq Done
    ldx #$00
    sta ship_2_shield_count

    // LSB of sprite's data ptr to x and
    // MSB to Accum so we can call the SetDataPtr
    ldx #<sprite_ship
    lda #>sprite_ship
    jsr ship_2.SetDataPtr

Done:
    rts
}
// ShipShieldForceStop end
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// Call at end of program after main loop to clean up
ShipShieldCleanup: 
{
    lda #3
    jsr ShipShieldForceStop
    rts
}
// ShipShieldCleanup end
//////////////////////////////////////////////////////////////////////////////