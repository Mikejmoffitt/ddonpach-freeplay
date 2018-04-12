; AS configuration and original binary file to patch over
	CPU 68000
	PADDING OFF
	ORG		$000000
	BINCLUDE	"prg.orig"

; Free space to put new routines
ROM_FREE = $097C00

; Port definitions and useful RAM values
INPUT_P1 = $101254
INPUT_P2 = $101256

; 0x3 for 1P free play, 0xC for 2P free play
COINAGE_CFG = $101297

; # credits inserted; CRED_COUNT+2 shadows it to detect changes
CRED_COUNT = $1013AA

; Routine to draw a metasprite
SPRITE_PUT = $05A7DC

; Game state tables
SC_STATE = $1017A6

; State table values match ESP Ra.De. exactly
S_INIT        = $0
S_TITLE       = $1
S_HISCORE     = $2
S_DEMOSTART   = $3
S_TITLE_START = $4
S_DEMO        = $5
S_INGAME_P2   = $6
S_INGAME_P1   = $7
S_CONTINUE    = $8
S_CHARSEL     = $B
S_CAVESC      = $C
S_ATLUSSC     = $D

; ============================================================================
; Patches for my board with defective Layer 2 VRAM mirroring
; ============================================================================

; Write the logo to the mirror at $704000 instead of $700000
cave_logo_vram_fix:
	ORG	$04C088
	lea	($704000).l, a0

hiscore_vram_fix:
	ORG	$057C24
	andi.w	#$7F00, d4
	ORG	$057C06
	jmp	hiscore_vram_fix_a0_patch
	ORG	$058686
	andi.w	#$7F00, d4

title_vram_fix:
	ORG	$0578B8
	andi.w	#$7F00, d1

; Remove the AND that brings the lower half of each letter to 700000
license_vram_fix:
	ORG	$0579C4
	andi.w	#$7F00, d1

; ============================================================================
; Patches to skip stuff and other meta whatever
; ============================================================================

; Unlike esprade, ddonpach checks ROM
skip_rom_chksum:
	ORG	$005404
	bra.s	$005412

skip_license:
	ORG	$57988
;	rts

license_speedup:
	ORG	$0579DC
	moveq	#0, d0

version_string:
	ORG	$06BCC7
#	dc.b	" 1997 2/5 MASTER VER.\\"
	dc.b	" 180411 MOFFITT VER.\\"

; ============================================================================
; Free play related changes
; ============================================================================

; Prevent the game from subtracting credits on start when in free play
game_start_subtract_from_title_hook:
	ORG	$0045DE
	jmp	game_start_subtract_from_title

game_start_subtract_pre_join_hook:
	ORG	$004F36
	jmp	game_start_subtract_pre_join

game_start_subtract_join_hook:
	ORG	$004BD6
	jmp	game_start_subtract_join

game_start_join_entry_hook:
	ORG	$004BBC
	jmp	game_start_join_entry

title_press_start_hook:
	ORG	$003D98
	jmp	title_press_start

; TODO: Might obsolete the subtract_join_hook_function by putting 0 in d7
charsel_join_entry_hook:
	ORG	$004EDE
	jmp	charsel_join_entry

; Change the setup menu text for free play
freeplay_option_text:
	ORG	$06BFD1
	dc.b	"          FREE PLAY \\"
	ORG	$06C0AD
	dc.b	"          FREE PLAY \\"

; Ignore the credit count to transition to press start screen
credit_count_ignore_hook:
	ORG	$002070
	jmp	credit_count_ignore

charsel_hide_credit_count_hook:
	ORG	$047E86
	jmp charsel_hide_credit_count

; Hide "CREDIT - 0"
credit_hide_demo_hook:
	ORG	$057672
	jmp	credit_hide_demo

credit_hide_intro_hook:
	ORG	$0575F4
	jmp	credit_hide_intro

credit_hide_title_hook:
	ORG	$0040B0
	jmp	credit_hide_title

; ============================================================================
; New Routines
; ============================================================================
	ORG	ROM_FREE

game_start_subtract_from_title:
	move.l	d0, -(sp)
	move.b	(COINAGE_CFG).l, d0
	andi.b	#$F0, d0
	cmpi.b	#$30, d0
	beq	.freeplay_en
	cmpi.b	#$C0, d0
	beq	.freeplay_en
	cmpi.b	#$F0, d0
	beq	.freeplay_en
.normal:
	subq	#$1, (CRED_COUNT).l
	btst	#0, ($101297).l
	beq	.end
	subq	#$1, (CRED_COUNT).l
.freeplay_en:
.end:
	move.l	(sp)+, d0
	jmp	($0045F4).l

game_start_subtract_pre_join:
	move.l	d0, -(sp)
	move.b	(COINAGE_CFG).l, d0
	andi.b	#$F0, d0
	cmpi.b	#$30, d0
	beq	.freeplay_en
	cmpi.b	#$C0, d0
	beq	.freeplay_en
	cmpi.b	#$F0, d0
	beq	.freeplay_en

.normal:
	sub.w	d7, (CRED_COUNT).l

.freeplay_en:
	move.l	(sp)+, d0
	jmp	($004F3C).l

game_start_subtract_join:
	move.w	(a1), (CRED_COUNT+2).l
	move.l	d0, -(sp)
	move.b	(COINAGE_CFG).l, d0
	andi.b	#$F0, d0
	cmpi.b	#$30, d0
	beq	.freeplay_en
	cmpi.b	#$C0, d0
	beq	.freeplay_en
	cmpi.b	#$F0, d0
	beq	.freeplay_en

.normal:
	sub.w	d1, (a1)

.freeplay_en:
	move.l	(sp)+, d0
	jmp	($004BDE).l

title_press_start:
	move.w	d0, -(sp)
	move.b	(COINAGE_CFG).l, d0
	andi.b	#$F0, d0
	cmpi.b	#$30, d0
	beq	.freeplay_en
	cmpi.b	#$C0, d0
	beq	.freeplay_en
	cmpi.b	#$F0, d0
	beq	.freeplay_en

.normal:
	move.w	(sp)+, d0

	cmp.w	(CRED_COUNT).l, d1
	bhi.s	.no_creds
	bra.s	.have_creds
.no_creds:
	jmp	($003DAA).l

.freeplay_en:
	move.w	(sp)+, d0

.have_creds:
	jmp	($003DA0).l

credit_count_ignore:
	move.w	d0, -(sp)
	move.b	(COINAGE_CFG).l, d0
	andi.b	#$F0, d0
	cmpi.b	#$30, d0
	beq	.freeplay_en
	cmpi.b	#$C0, d0
	beq	.freeplay_en
	cmpi.b	#$F0, d0
	beq	.freeplay_en

.normal:
	move.w	(sp)+, d0
	tst.w	d1
	beq.w	.no_credits
	jmp	($002076).l
.no_credits:
	jmp	($002156).l

.freeplay_en:
	move.w	(sp)+, d0
	jmp	($002076).l

game_start_join_entry:
	move.w	d0, -(sp)
	move.b	(COINAGE_CFG).l, d0
	andi.b	#$F0, d0
	cmpi.b	#$30, d0
	beq	.freeplay_en
	cmpi.b	#$C0, d0
	beq	.freeplay_en
	cmpi.b	#$F0, d0
	beq	.freeplay_en
.normal:
	move.w	(sp)+, d0
	cmp.w	(a1), d1
	bls.s	.have_coins
	jmp	($0586EC).l
.freeplay_en:
	move.w	(sp)+, d0
.have_coins:
	jmp	($004BC6).l

charsel_join_entry:
	move.b	(COINAGE_CFG).l, d7
	andi.b	#$F0, d7
	cmpi.b	#$30, d7
	beq	.freeplay_en
	cmpi.b	#$C0, d7
	beq	.freeplay_en
	cmpi.b	#$F0, d7
	beq	.freeplay_en
.normal:
	moveq	#1, d7
	btst	#0, ($101297).l
	beq	.end
	moveq	#2, d7
.end:
	jmp	($004EEE).l

.freeplay_en:
	moveq	#$0, d7
	jmp	($004EEE).l

charsel_hide_credit_count:
	move.w	d0, -(sp)
	move.b	(COINAGE_CFG).l, d0
	andi.b	#$F0, d0
	cmpi.b	#$30, d0
	beq	.freeplay_en
	cmpi.b	#$C0, d0
	beq	.freeplay_en
	cmpi.b	#$F0, d0
	beq	.freeplay_en
.normal:
	move.w	(sp)+, d0
	jsr	(SPRITE_PUT).l
	jmp	($047E8C).l
.freeplay_en:
	move.w	(sp)+, d0
	jmp	($047EB8).l

credit_hide_title:
	move.b	(COINAGE_CFG).l, d1
	andi.b	#$F0, d1
	cmpi.b	#$30, d1
	beq	.freeplay_en
	cmpi.b	#$C0, d1
	beq	.freeplay_en
	cmpi.b	#$F0, d1
	beq	.freeplay_en
.normal:
	move.w	#0, ($1013AE).l
	jmp	($0040B8).l
.freeplay_en:
	rts

credit_hide_intro:
	move.b	(COINAGE_CFG).l, d0
	andi.b	#$F0, d0
	cmpi.b	#$30, d0
	beq	.freeplay_en
	cmpi.b	#$C0, d0
	beq	.freeplay_en
	cmpi.b	#$F0, d0
	beq	.freeplay_en
.normal:
	move.w	#1, ($1013AE).l
	jmp	($0575FC).l
	
.freeplay_en:
	rts

credit_hide_demo:
	move.b	(COINAGE_CFG).l, d0
	andi.b	#$F0, d0
	cmpi.b	#$30, d0
	beq	.freeplay_en
	cmpi.b	#$C0, d0
	beq	.freeplay_en
	cmpi.b	#$F0, d0
	beq	.freeplay_en
.normal:
	move.w	#1, ($1013AE).l
	jmp	($05767A).l
	
.freeplay_en:
	rts

hiscore_vram_fix_a0_patch:
	move.w	d2, d0
	andi.w	#$F, d0
	move.l	a0, d4
	ori.w	#$4000, d4
	move.l	d4, a0
	jmp	($057C0C).l
