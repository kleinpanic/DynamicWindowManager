#include "layouts.h"
#include "movestack.c"
#include <X11/XF86keysym.h>

#define TERMINAL	"st"           // default terminal 

/* key definitions */
#define MODKEY Mod4Mask
#define ALTMOD Mod1Mask
#define TAGKEYS(CHAIN,KEY,TAG) \
	{ MODKEY,                       CHAIN,    KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           CHAIN,    KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             CHAIN,    KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, CHAIN,    KEY,      toggletag,      {.ui = 1 << TAG} }, \
    { ALTMOD,                       CHAIN,    KEY,      focusnthmon, {.i = TAG } }, \
    { ALTMOD|ShiftMask,             CHAIN,    KEY,      tagnthmon, {.i = TAG } },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static const char dmenufont[] = "monospace:size=10";
static const char *dmenucmd[] = { "dmenu_run", "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
static const char *termcmd[]  = { TERMINAL, NULL };


/* brightness control */
static const char *inc_light[] = { "brightness", "-a", "up", NULL};
static const char *dec_light[] = { "brightness", "-a", "down", NULL };

/* screenshot command */
static const char *scrotselcmd[] = { "scrot", "-s", "/home/klein/Pictures/screenshots/Screenshot_%Y-%m-%d_%H-%M-%S.png", NULL };

/* volume controls */
// Set up volume controls with amixer, and volumeicon. Without preset keys volumeicon will take over (provided constantly running)
// Do not add keys for XF86XK_AudioRaiseVolume, XF86XKK_AudioLowerVolume, or XF86KX_AudiotMute. 
/* nvim */ 
static const char *nvimcmd[] = { TERMINAL, "-e", "nvim", "vimwiki/index.md", NULL };


static const Key keys[] = {
		/* modifier                     chain key   key        function        argument */
		{ MODKEY,                       -1,         XK_p,      spawn,          {.v = dmenucmd } },
		{ MODKEY|ShiftMask,             -1,         XK_Return, spawn,          {.v = termcmd } }, 
		{ MODKEY|ShiftMask,             -1,         XK_b,      togglebar,      {0} },
		{ MODKEY,                       -1,         XK_j,      focusstack,     {.i = +1 } },
		{ MODKEY,                       -1,         XK_k,      focusstack,     {.i = -1 } },
		{ MODKEY,                       -1,         XK_i,      incnmaster,     {.i = +1 } },
		{ MODKEY,                       -1,         XK_d,      incnmaster,     {.i = -1 } },
	    { MODKEY|ShiftMask,             -1,         XK_x,      movestack,      {.i = +1 } },
	    { MODKEY|ShiftMask,             -1,         XK_z,      movestack,      {.i = -1 } },
		{ MODKEY,                       -1,         XK_h,      setmfact,       {.f = -0.05} },
		{ MODKEY,                       -1,         XK_l,      setmfact,       {.f = +0.05} },
		{ MODKEY,                       -1,         XK_Return, zoom,           {0} },
		{ MODKEY,                       -1,         XK_Tab,    view,           {0} },

        { MODKEY|ShiftMask,             -1,         XK_c,      killclient,     {0} },
		
		{ MODKEY,                       -1,         XK_t,      setlayout,      { .v = &layouts[0] } },
		{ MODKEY,                       -1,         XK_f,      setlayout,      {.v = &layouts[1]} },
		{ MODKEY,                       -1,         XK_m,      setlayout,      {.v = &layouts[2]} },
    	{ MODKEY,                       -1,         XK_r,      setlayout,      {.v = &layouts[3]} },
    	{ MODKEY|ShiftMask,             -1,         XK_r,      setlayout,      {.v = &layouts[4]} },
		{ MODKEY,                       -1,         XK_space,  setlayout,      {0} },
		
		{ MODKEY|ShiftMask,             -1,         XK_space,  togglefloating, {0} },
		{ MODKEY,                       -1,         XK_0,      view,           {.ui = ~0 } },
		{ MODKEY|ShiftMask,             -1,         XK_0,      tag,            {.ui = ~0 } },
		{ MODKEY,                       -1,         XK_comma,  focusmon,       {.i = -1 } },
		{ MODKEY,                       -1,         XK_period, focusmon,       {.i = +1 } },
		{ MODKEY|ShiftMask,             -1,         XK_comma,  tagmon,         {.i = -1 } },
		{ MODKEY|ShiftMask,             -1,         XK_period, tagmon,         {.i = +1 } },
//--//

        { MODKEY,     XK_c,     XK_o,    spawn,     SHCMD("xdotool key Super_L+2 && dissent") }, 
        { MODKEY,     XK_c,     XK_q,    spawn,     SHCMD("xdotool key Super_L+2 && qtox") },
        { MODKEY,     XK_c,     XK_b,    spawn,     SHCMD("xdotool key Super_L+3 && qutebrowser") },
        { MODKEY,     XK_c,     XK_f,    spawn,     SHCMD("xdotool key Super_L+4 && freetube") },
        { MODKEY,     XK_c,     XK_g,    spawn,     SHCMD("xdotool key Super_L+5 && qutebrowser github.com") },
        { MODKEY,     XK_c,     XK_n,    spawn,     SHCMD("xdotool key Super_L+7 && st nvim") },
        { MODKEY,     XK_c,     XK_s,    spawn,     SHCMD("xdotool key Super_L+8 && spotube") }, 
		{ MODKEY,     XK_c,     XK_z,    spawn,     SHCMD("xdotool key Super_L+9 && alacritty") },
		{ MODKEY,     XK_n,     XK_v,    spawn,     {.v = nvimcmd } },

		TAGKEYS(                        -1,         XK_1,                      0)
		TAGKEYS(                        -1,         XK_2,                      1)
		TAGKEYS(                        -1,         XK_3,                      2)
		TAGKEYS(                        -1,         XK_4,                      3)
		TAGKEYS(                        -1,         XK_5,                      4)
		TAGKEYS(                        -1,         XK_6,                      5)
		TAGKEYS(                        -1,         XK_7,                      6)
		TAGKEYS(                        -1,         XK_8,                      7)
		TAGKEYS(                        -1,         XK_9,                      8)
		
		{ MODKEY|ShiftMask,             -1,         XK_q,      quit,           {0} },
	    { MODKEY|ControlMask|ShiftMask, -1,         XK_r,      quit,           {1} },	// restart

		{ 0,						    -1,			XK_F10,	   spawn,		   { .v = scrotselcmd } },
		{ 0,			                -1,       	XF86XK_MonBrightnessUp,	 spawn,	       { .v = inc_light } },
	    { 0,				            -1,         XF86XK_MonBrightnessDown, spawn,	       { .v = dec_light } },
		{ MODKEY|ShiftMask,  -1,  XK_l,  spawn,  SHCMD("slock") }

};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
