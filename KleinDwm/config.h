/* See LICENSE file for copyright and license details. */

#include "colors/space.h"
#include "keys.h"

#define ICONSIZE 20   /* icon size */
#define ICONSPACING 5 /* space between icon and title */
static const unsigned int borderpx  = 2;        /* border pixel of windows */
static const unsigned int gappx     = 5;       /* gaps between windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const unsigned int systraypinning = 0;   /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor X */
static const unsigned int systrayonleft = 0;   	/* 0: systray in the right corner, >0: systray on left of status text */
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int systraypinningfailfirst = 1;   /* 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor*/
static const int showsystray        = 1;     /* 0 means no systray */
static const int showbar            = 1;     /* 0 means no bar */
static const int topbar             = 1;     /* 0 means bottom bar */
static const char *fonts[]          = { "monospace:size=11", "DroidSansMono Nerd Font:size=11", "Noto Color Emoji:size=11", "Cairo:size=12" };
static const int user_bh            = 8;        /* 2 is the default spacing around the bar's font */

/* tagging */
//static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };
//static const char *tags[] = { " \u2680 ", " \u2681 ", " \u2682 ", " \u2683 ", " \u2684 ", " \u2685 ", " \u2661 ", " \u2665 ", "\u266c" };  	// Dice Faces
//                               tag1        tag2        tag3        tag4        tag5        tag6        tag7        tag8        tag9 
//static const char *tags[] = { " \uf17c ", " \uf1d8 ", " \uf0ac ", " \uf109 ", " \uf09b ", " \uf02d ", " \uf044 ", " \uf1bc ", " \uf120 " };

static const char *tags[] = { "\uf17c", "\uf1d8", "\uf0ac", "\uf109", "\uf09b", "\uf02d", "\uf044", "\uf1bc", "\uf120" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class        instance    title       tags mask     isfloating  CenterThisWindow?  monitor */
	{ "Gimp",       NULL,       NULL,       0,            1,          0,                 -1 },
	{ "Tk",         NULL,       NULL,       0,            1,          0,                 -1 },
    { NULL,         NULL, "lumos", 0,        1,          0,                 -1 },
    { NULL,         NULL, "Screenshot Tool", 0,           1,          0,                 -1 },
	{ "Conky",	    NULL,		NULL,		0,		  1,		  0,                 -1 },
	{ NULL,		    NULL, "Task Tray",      0,	      1,	      0,                 -1 },
	{ NULL,         NULL,       "YAD",      0,            1,          0,                 -1 },
    { "Ssh_popup",  NULL,       NULL,       0,            1,          0,                 -1 },
    { "Conky-Sysinfo", NULL,    "Conky",    0,            1,          1,                 -1 },
    { "BrightnessControl", NULL, NULL,      0,            1,          1                  -1 },
    { "Arduino",    NULL,       NULL,       0,            1,          1,                 -1 },
};

static const char *ipcsockpath = "/tmp/dwm.sock";
static IPCCommand ipccommands[] = {
  IPCCOMMAND(  view,                1,      {ARG_TYPE_UINT}   ),
  IPCCOMMAND(  toggleview,          1,      {ARG_TYPE_UINT}   ),
  IPCCOMMAND(  tag,                 1,      {ARG_TYPE_UINT}   ),
  IPCCOMMAND(  toggletag,           1,      {ARG_TYPE_UINT}   ),
  IPCCOMMAND(  tagmon,              1,      {ARG_TYPE_UINT}   ),
  IPCCOMMAND(  focusmon,            1,      {ARG_TYPE_SINT}   ),
  IPCCOMMAND(  focusstack,          1,      {ARG_TYPE_SINT}   ),
  IPCCOMMAND(  zoom,                1,      {ARG_TYPE_NONE}   ),
  IPCCOMMAND(  incnmaster,          1,      {ARG_TYPE_SINT}   ),
  IPCCOMMAND(  killclient,          1,      {ARG_TYPE_SINT}   ),
  IPCCOMMAND(  togglefloating,      1,      {ARG_TYPE_NONE}   ),
  IPCCOMMAND(  setmfact,            1,      {ARG_TYPE_FLOAT}  ),
  IPCCOMMAND(  setlayoutsafe,       1,      {ARG_TYPE_PTR}    ),
  IPCCOMMAND(  quit,                1,      {ARG_TYPE_NONE}   )
};

