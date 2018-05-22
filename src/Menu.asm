// Menu.asm
if !{defined __MENU__} {
define __MENU__()

include "Global.asm"
include "Joypad.asm"
include "OS.asm"
include "Overlay.asm"

scope Menu {

    constant ROW_HEIGHT(000010)

    texture_background:
    Overlay.texture(320, 240)
    insert "../textures/background.rgba5551"

    selection:
    dw 0x00000000

    macro entry(title, next) {
        dw 0x00000000                       // 0x0000 - is_enabled
        dw {next}                           // 0x0004 - next_entry
        db {title}                          // 0x0008 - title
        OS.align(4)
    }

    macro toggle_guard(entry_address) {
        addiu   sp, sp,-0x0008              // allocate stack space
        sw      at, 0x0004(sp)              // save at
        li      at, {entry_address}         // ~
        lw      at, 0x0000(at)              // at = is_enabled
        bnez    at, pc() + 24               // if (is_enabled), _continue
        nop

        // _end:
        lw      at, 0x0004(sp)              // restore at
        addiu   sp, sp, 0x0008              // deallocate stack space
        jr      ra
        nop

        // _continue:
        lw      at, 0x0004(sp)              // restore at
        addiu   sp, sp, 0x0008              // deallocate stack space
    }

    // @ Description 
    // This patch disables the menu init on the debug screen 80371414
    OS.patch_start(0x001AC1E8, 0x80369D78)    
    jr      ra
    nop
    OS.patch_end()

    // @ Description
    // This patch changes  the VS. Options screen from loading to the "Exit\n<Stage>" Debug Screen 
    OS.patch_start(0x0012471C, 0x80133D6C)
    lli     t4, 0x0002                      // original - lli t4, 0x000A
    OS.patch_end()

    // @ Description
    // This function will chnage the currently loaded SSB screen
    // @ Arguments
    // a0 - int next_screen
    scope change_screen_: {
        addiu   sp, sp,-0x0010              // allocate stack space
        sw      t0, 0x0004(sp)              // ~
        sw      t1, 0x0008(sp)              // save registers

        li      t0, Global.current_screen   // ~
        lb      t1, 0x0000(t0)              // t1 = current_screen
        sb      t1, 0x0001(t0)              // update previous_screen to current_screen
        sb      a0, 0x0000(t0)              // update current_screen to next_screen
        li      t0, Global.screen_interrupt // ~
        lli     t1, 0x0001                  // ~
        sw      t1, 0x0000(t0)              // generate screen_interrupt

        lw      t0, 0x0004(sp)              // ~
        lw      t1, 0x0008(sp)              // restore registers
        addiu   sp, sp, 0x0010              // allocate stack space
        jr      ra                          // return
        nop
    }

    scope run_: {
        addiu   sp, sp,-0x0008              // allocate stack space
        sw      ra, 0x0004(sp)              // save ra

        // draw background
        lli     a0, 0x0000                  // a0 - ulx
        lli     a1, 0x0000                  // a1 - uly
        li      a2, texture_background      // a2 - address of texture struct 
        jal     Overlay.draw_texture_big_
        nop

        // draw menu
        li      a0, entry_disable_cinematic_camera
        jal     draw_menu_                  // draw menu
        nop

        lli     a0, Joypad.B                // a0 - button_mask
        lli     a1, 0x0000                  // a1 - player
        jal     Joypad.was_pressed_         // check if B pressed
        nop 
        beqz    v0, _end                    // nop
        nop
        lli     a0, Color.low.RED           // a0 = rgba5551 red
        jal     Overlay.set_color_
        nop
        lli     a0, 100                     // a0 - ulx
        lli     a1, 100                     // a1 - uly
        lli     a2, 20                      // a2 - width 
        lli     a3, 20                      // a3 - hgith
        jal     Overlay.draw_rectangle_
        nop
        lli     a0, 0x0010                  // a0 - screen_id
        jal     change_screen_
        nop

        _end:
        lw      ra, 0x0004(sp)              // restore ra
        addiu   sp, sp, 0x0008              // deallocate stack space
        jr      ra
        nop
    }

    // @ Description
    // Draw a menu entry (title, on/off)
    // @ Arguments
    // a0 - entry
    // a1 - ulx (= 20)
    // a2 - uly
    scope draw_entry_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      s0, 0x0004(sp)              // ~
        sw      s1, 0x0008(sp)              // ~
        sw      s2, 0x000C(sp)              // ~
        sw      t0, 0x0010(sp)              // ~
        sw      ra, 0x0014(sp)              // save registers

        or      s0, a0, r0                  // ~
        or      s1, a2, r0                  // ~
        or      s2, a0, r0                  // sx = ax

        lli     a0, 000028                  // a0 - ulx = 0 + 20 + (sizeof(char), the '>') = 28
        or      a1, s1, r0                  // a1 - uly
        addiu   a2, s0, 0x0008              // a2 - address of string
        jal     Overlay.draw_string_
        nop

        lw      t0, 0x0000(s0)              // t0 = is_enabled
        bnez    t0, _on                     // if (is_enabled), skip
        nop

        _off:
        lli     a0, 000266                  // a0 - ulx = 320 - 20 - (3 * 8) = 276
        or      a1, s1, r0                  // a1 - uly
        li      a2, off                     // a0 - address of string
        jal     Overlay.draw_string_
        nop
        b       _end                        // skip _on
        nop

        _on:
        lli     a0, 000284                  // a0 - ulx = 320 - 20 - (2 * 8) = 284
        or      a1, s1, r0                  // a1 - uly
        li      a2, on                      // a0 - address of string
        jal     Overlay.draw_string_
        nop

        _end:
        lw      s0, 0x0004(sp)              // ~
        lw      s1, 0x0008(sp)              // ~
        lw      s2, 0x000C(sp)              // ~
        lw      t0, 0x0010(sp)              // ~
        lw      ra, 0x0014(sp)              // restore registers
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra
        nop

        on:
        db "ON", 0x00
        OS.align(4)

        off:
        db "OFF", 0x00
        OS.align(4)
    }

    // @ Description
    // Draw linked list of menu entries
    // @ Arguments
    // a0 - head_entry
    scope draw_menu_: {
        addiu   sp, sp,-0x0010              // allocate stack space
        sw      s0, 0x0004(sp)              // ~
        sw      t0, 0x0008(sp)              // ~
        sw      ra, 0x000C(sp)              // save registers

        // draw first entry
        or      s0, a0, r0                  // s0 = copy of a0
        lli     t0, 20                      // t0 = uly
        or      a2, t0, r0                  // a2 = uly
        jal     draw_entry_                 // draw first entry
        nop

        // draw following entries
        _loop:
        lw      s0, 0x0004(s0)              // s0 = entry->next
        beqz    s0, _end                    // if (entry->next == NULL), end
        nop
        addiu   t0, t0, ROW_HEIGHT          // increment height
        or      a0, s0, r0                  // a0 = entry
        or      a2, t0, r0                  // a2 = uly
        jal     draw_entry_
        nop
        b       _loop
        nop

        _end:
        // draw ">"
        li      t0, selection               // ~
        lw      t0, 0x0000(t0)              // t0 = selection
        addiu   t0, t0, 0x0002              // t0 = selection + 2
        lli     s0, ROW_HEIGHT              // ~
        mult    t0, s0                      // ~
        mflo    a1                          // s0 = height of row

        lli     a0, 000020                  // a0 - ulx
//      or      a1, a1, r0                  // a1 - uly
        lli     a2, '>'                     // a2 - char
        jal     Overlay.draw_char_          // draw '>'
        nop

        lw      s0, 0x0004(sp)              // ~
        lw      t0, 0x0008(sp)              // ~
        lw      ra, 0x000C(sp)              // restore registers
        addiu   sp, sp, 0x0010              // deallocate stack space
        jr      ra                          // return
        nop
    }


    entry_disable_cinematic_camera:
    entry("DISABLE CINEMATIC CAMERA", entry_flash_on_z_cancel)

    entry_flash_on_z_cancel:
    entry("FLASH ON Z CANCEL", entry_hold_to_pause)

    entry_hold_to_pause:
    entry("HOLD TO PAUSE", entry_improved_combo_meter)

    entry_improved_combo_meter:
    entry("IMPROVED COMBO METER", entry_improved_ai)

    entry_improved_ai:
    entry("IMPROVED AI", entry_neutral_spawns)

    entry_neutral_spawns:
    entry("NEUTRAL SPAWNS", entry_random_music)

    entry_random_music:
    entry("RANDOM MUSIC", entry_skip_results_screen)

    entry_skip_results_screen:
    entry("SKIP RESULTS SCREEN", entry_stock_handicap)

    entry_stock_handicap:
    entry("STOCK HANDICAP", entry_salty_runback)

    entry_salty_runback:
    entry("SALTY RUNBACK", entry_widescreen)

    entry_widescreen:
    entry("WIDESCREEN", OS.NULL)






}

}