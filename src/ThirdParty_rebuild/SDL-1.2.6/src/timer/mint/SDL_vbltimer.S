/*
    SDL - Simple DirectMedia Layer
    Copyright (C) 1997, 1998, 1999, 2000, 2001, 2002  Sam Lantinga

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this library; if not, write to the Free
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    Sam Lantinga
    slouken@libsdl.org
*/

#ifdef SAVE_RCSID
static char rcsid =
 "@(#) $Id: SDL_vbltimer.S,v 1.1 2003/09/16 04:36:49 gmaynard Exp $";
#endif

/*
 *	VBL queue routine
 *
 *	Patrice Mandin
 */

#define _vbl_queue 0x456

	.text

	.globl	_SDL_AtariVblInstall
	.globl	_SDL_AtariVblUninstall

/*--- Vector installer ---*/

_SDL_AtariVblInstall:
	movel	sp@(4),my_vector
	lea		_my_vbl,a0

	clrw	vbl_mutex

	/* Stop interrupts */

	movew	#0x2700,sr

	/* Read vbl_queue pointer */
	movel	_vbl_queue.w,a1

	/* Search a free place */
	moveq	#7,d0
bcl_search_place:
	movel	(a1),d1
	beqs	place_found
	addql	#4,a1
	dbra	d0,bcl_search_place

	/* Not found */
	moveq	#1,d0
	bras	exit_vbl_queue

	/* Then install ourselves */
place_found:
	movel	a0,(a1)
	moveq	#0,d0	

exit_vbl_queue:
	/* Restart interrupts */
	movew	#0x2300,sr

	rts

/*--- Vector uninstaller ---*/

_SDL_AtariVblUninstall:
	movel	sp@(4),d0
	cmpl	my_vector,d0
	bnes	badvector
	
	movel	#_my_vbl,d0

	/* Stop interrupts */

	movew	#0x2700,sr

	/* Read vbl_queue pointer */
	movel	_vbl_queue.w,a1

	/* Search where we are */
	moveq	#7,d1
bcl2_search_place:
	cmpl	(a1),d0
	bnes	next_place
	clrl	(a1)
	moveq	#0,d1
next_place:
	addql	#4,a1
	dbra	d1,bcl2_search_place

	/* Restart interrupts */
	movew	#0x2300,sr
badvector:
	rts

/*--- Our vbl ---*/

_my_vbl:
	/* Verify if this is not already running */

	tstw	vbl_mutex
	bnes	vbl_end
	notw	vbl_mutex

	moveml	d0-d7/a0-a6,sp@-
	movel	my_vector,a0
	jsr		a0@
	moveml	sp@+,d0-d7/a0-a6

	clrw	vbl_mutex
vbl_end:
	rts

	.data
	.even
	.comm	vbl_mutex,2*1
	.even
	.comm	my_vector,4*1
