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
ShipShieldDecCount:
    dec ship_1_shield_count
    bne ShipShieldCountContinues
ShipShieldDone:
    // do shield done stuff here

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
ShipShieldDecCount:
    dec ship_2_shield_count
    bne ShipShieldCountContinues
ShipShieldDone:
    // do shield done stuff here

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
// Call to force effect to stop if it is active
ShipShieldForceStop: 
{
    lda #$00
    sta ship_1_shield_count
    sta ship_2_shield_count
    rts
}
// ShipShieldForceStop end
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// Call at end of program after main loop to clean up
ShipShieldCleanup: 
{
    rts
}
// ShipShieldCleanup end
//////////////////////////////////////////////////////////////////////////////