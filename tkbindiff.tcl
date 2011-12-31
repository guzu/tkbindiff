#!/usr/bin/wish -f

proc Display { } {
    global v

    seek $v(f1,fd) $v(offset)
    seek $v(f2,fd) $v(offset)

    $v(f1,txt) config -state normal
    $v(f2,txt) config -state normal
    $v(f1,txt) delete 1.0 end
    $v(f2,txt) delete 1.0 end

    set nbline [expr $v(txt_height) / $v(fontheight)]
    set n1 $v(offset_step)
    set n2 $v(offset_step)

    for { set ln 0 } { $ln < $nbline-1 && $n1 == $v(offset_step) && $n2 == $v(offset_step) } { incr ln } {
	set bin1 [read $v(f1,fd) $v(offset_step)]
	set bin2 [read $v(f2,fd) $v(offset_step)]

	set lenbin1 [string length $bin1]
	if { $lenbin1 > 0 } {
	    $v(f1,txt) insert insert "[format $v(format) [expr $v(offset) + $v(offset_step) * $ln]] : "
	    set n [binary scan $bin1 \
		       [string repeat "H2" 16] \
		       hex1_1  hex1_2  hex1_3  hex1_4 \
		       hex1_5  hex1_6  hex1_7  hex1_8 \
		       hex1_9  hex1_10 hex1_11 hex1_12 \
		       hex1_13 hex1_14 hex1_15 hex1_16 ]
	    binary scan $bin1 \
		[string repeat "a" 16] \
		char1  char2  char3  char4 \
		char5  char6  char7  char8 \
		char9  char10 char11 char12 \
		char13 char14 char15 char16
	    
	    set hexstr ""
	    set charstr ""
	    for { set i 1 } { $i <= $n } { incr i } {
		append hexstr "[set hex1_${i}] "
		if [string is control [set char${i}]] {
		    append charstr "."
		} else {
		    append charstr [set char${i}]
		}
	    }
	    
	    set space [string repeat "   " [expr $v(offset_step) - $n]]
	    
	    $v(f1,txt) insert insert "$hexstr$space |  $charstr\n"
	}

	set lenbin2 [string length $bin2]
	if { $lenbin2 > 0 } {
	    $v(f2,txt) insert insert "[format $v(format) [expr $v(offset) + $v(offset_step) * $ln]] : "
	    set n [binary scan $bin2 \
		       [string repeat "H2" 16] \
		       hex2_1  hex2_2  hex2_3  hex2_4 \
		       hex2_5  hex2_6  hex2_7  hex2_8 \
		       hex2_9  hex2_10 hex2_11 hex2_12 \
		       hex2_13 hex2_14 hex2_15 hex2_16 ]
	    binary scan $bin2 \
		[string repeat "a" 16] \
		char1  char2  char3  char4 \
		char5  char6  char7  char8 \
		char9  char10 char11 char12 \
		char13 char14 char15 char16
	    
	    set hexstr ""
	    set charstr ""
	    for { set i 1 } { $i <= $n } { incr i } {
		append hexstr "[set hex2_${i}] "
		if [string is control [set char${i}]] {
		    append charstr "."
		} else {
		    append charstr [set char${i}]
		}
	    }
	    
	    set space [string repeat "   " [expr $v(offset_step) - $n]]
	    
	    $v(f2,txt) insert insert "$hexstr$space |  $charstr\n"
	}


	set maxlen [expr ( $lenbin1 < $lenbin2 ) ? $lenbin2 : $lenbin1 ]
	set lasti -1
	for { set i 0 } { $i < $maxlen } {incr i} {
	    set x [expr $v(precision) + 3 + 3 * $i]
	    set y [expr $ln + 1]
	    set j [expr $i + 1]
	    
	    if { $i < $lenbin1 } {
		if { $i < $lenbin2 } {
		     if { [set hex1_$j] != [set hex2_$j] } {
			$v(f1,txt) tag add "diff" \
			    ${y}.[expr $x + (($lasti == $i - 1) ? -1 : 0)] \
			    ${y}.[expr $x + (($lasti == $i - 1) ?  3 : 2)]
			$v(f2,txt) tag add "diff" \
			    ${y}.[expr $x + (($lasti == $i - 1) ? -1 : 0)] \
			    ${y}.[expr $x + (($lasti == $i - 1) ?  3 : 2)]
			set lasti $i
		    } else {
			set lasti -1
		    }
		} else {
		    # si le premier fichier est plus grand que le second
		    $v(f1,txt) tag add "diff" \
			${y}.[expr $x + (($lasti == $i - 1) ? -1 : 0)] \
			${y}.[expr $x + (($lasti == $i - 1) ?  3 : 2)]
		    set lasti $i
		}
	    } else {
		# si le second fichier est plus grand que le premier
		if { $i < $lenbin2 } {
		    $v(f2,txt) tag add "diff" \
			${y}.[expr $x + (($lasti == $i - 1) ? -1 : 0)] \
			${y}.[expr $x + (($lasti == $i - 1) ?  3 : 2)]
		    set lasti $i
		}
	    }
	}
    }
    $v(f1,txt) tag config "diff" -background "#aaaaaa"
    $v(f2,txt) tag config "diff" -background "#aaaaaa"

    $v(f1,txt) config -state disabled
    $v(f2,txt) config -state disabled
}

proc ScrollSet { } {
    global v

    set nbline [expr $v(txt_height) / $v(fontheight)]

    #    puts "$height $nbline"

    set tot   [expr $v(maxfilesize) / $v(offset_step) + 1]
    set start [expr double( $v(offset) / $v(offset_step) ) / $tot]
    set end   [expr double( $v(offset) / $v(offset_step) + $nbline ) / $tot]

    # puts "$start $end"
    $v(scrollbar) set $start $end
}

proc ScrollMe { action args } {
    global v

#    puts "ScrollMe : $args"

    switch $action {
	moveto {
	    set s1 [lindex [$v(scrollbar) get] 0]
	    set s2 [lindex [$v(scrollbar) get] 1]
	    set scroll 1

	    set pos [expr ($args < 0.0) ? 0.0 : $args]

#	    if { [info exists v(old_yscroll2)] && $v(old_yscroll2) == 1.0 } {
#		puts "C1 $pos [expr $s1 + (1.0 - $s1) / 2] $s1 $s2"		
#		if { $pos < $v(old_yscroll) && $pos <= [expr $s1 + (1.0 - $s1) / 2] } {
#		    set scroll 1
#		}
#	    } else {
#		puts "C2"		
#		if { ($s1 != 0.0 && $s2 != 1.0) || ( $s1 == 0.0 && $s2 != 1.0 ) || ( $s1 != 0.0 && $s2 == 1.0 ) } {
#		    set scroll 1
#		}
#	    }
	
	    if { $s1 == 0.0 && $s2 == 1.0 } {
		set scroll 0
	    }

	    if $scroll {
		set v(offset) [expr ((int([lindex $pos 0] * $v(maxfilesize)) / $v(offset_step)) * $v(offset_step))]
	    }

#	    set v(old_yscroll)  $pos
#	    set v(old_yscroll1) $s1
#	    set v(old_yscroll2) $s2
	}
	scroll {
	    set n [lindex $args 0]
	    set unit [lindex $args 1]

	    set v(txt_height) [winfo height $v(f1,txt)]
	    set nbline [expr $v(txt_height) / $v(fontheight) - 1]

	    set tot [expr $v(maxfilesize) / $v(offset_step).0 + 1]

	    switch $unit {
		pages {
		    if { $n < 0 } {
			if { $v(offset) > $v(offset_step) * $nbline } {
			    incr v(offset) [expr -1 * $v(offset_step) * $nbline]
			} else {
			    set v(offset) 0
			}
		    } else {
			if { $v(offset) + 2 * $v(offset_step) * $nbline > $v(maxfilesize) } {
			    set v(offset) [expr $v(maxfilesize) - $v(offset_step) * $nbline]
			} else {
			    incr v(offset) [expr $v(offset_step) * $nbline]
			}
		    }
		}
		units {
		    if { $n < 0 } {
			if { [lindex [$v(scrollbar) get] 0] > 0.0 } {
			    incr v(offset) -$v(offset_step)
			}
		    } else {
			if { [lindex [$v(scrollbar) get] 1] < 1.0 } {
			    incr v(offset) $v(offset_step)
			}
		    }
		}
	    }
	}
    }

    Display
    ScrollSet
}

proc ResizeText { id args } {
    global v

    set v(txt_height) [winfo height $v(f1,txt)]
    Display
    ScrollSet
}

proc SetCursor { id x y } {
    global v

    set pos [split [$v($id,txt) index @$x,$y] .]
    set col [lindex $pos 1]

    if { $col > $v(precision) + 2 && $col <= $v(precision) + 2 + 3 * $v(offset_step) } {
	# verifie qu'on ne clique pas sur un espace
	if { ($col - $v(precision)) % 3 < 2 } {
	    set col [ expr $v(precision) + 3 + 3 * (($col - 2 - $v(precision)) / 3) ]

	    $v(f1,txt) config -state normal
	    $v(f2,txt) config -state normal

	    $v(f1,txt) tag delete cursor
	    $v(f2,txt) tag delete cursor
	    $v(f1,txt) tag add cursor [lindex $pos 0].$col [lindex $pos 0].[expr $col + 2]
	    $v(f2,txt) tag add cursor [lindex $pos 0].$col [lindex $pos 0].[expr $col + 2]

	    $v(f1,txt) tag config cursor -background red -foreground white
	    $v(f2,txt) tag config cursor -background red -foreground white

	    $v(f1,txt) config -state disabled
	    $v(f2,txt) config -state disabled
	}
    }
}

if { $argc != 2 } {
    puts stderr " Usage : $argv0 <filename1> <filename2>"
    exit
}

if { ! [file exists [lindex $argv 0]] } {
    puts stderr " File '[lindex $argv 0]' doesn't exists."
    exit
}
if { ! [file exists [lindex $argv 1]] } {
    puts stderr " File '[lindex $argv 1]' doesn't exists."
    exit
}

set v(f1,filename) [lindex $argv 0]
set v(f2,filename) [lindex $argv 1]
set v(f1,filesize) [file size $v(f1,filename)]
set v(f2,filesize) [file size $v(f2,filename)]
set v(maxfilesize) [expr ( $v(f1,filesize) < $v(f2,filesize) ) ? $v(f2,filesize) : $v(f1,filesize) ]
set v(offset) 0
set v(offset_step) 16
set v(f1,fd) [open $v(f1,filename) r]
set v(f2,fd) [open $v(f2,filename) r]

# calcul de la precision du compteur de gauche
set precision1 1
for { set i [expr $v(f1,filesize) / $v(offset_step)] } { $i > 0 } { set i [expr $i / $v(offset_step)] } {
    incr precision1
}
set precision2 1
for { set i [expr $v(f2,filesize) / $v(offset_step)] } { $i > 0 } { set i [expr $i / $v(offset_step)] } {
    incr precision2
}
set v(precision) [expr ( $precision1 < $precision2 ) ? $precision2 : $precision1]
set v(format) "%0$v(precision)x"


wm withdraw .
set w [toplevel .tkhexdiff]
wm protocol $w WM_DELETE_WINDOW "exit"

pack [frame $w.frm] -expand true -fill both
pack [text $w.frm.hex1] -side left -expand true -fill both
pack [text $w.frm.hex2] -side left -expand true -fill both
pack [scrollbar $w.frm.vscroll -orient vertical -command "ScrollMe" -repeatinterval 50] -side left -expand true -fill y 

set v(f1,txt) $w.frm.hex1
set v(f2,txt) $w.frm.hex2
set v(scrollbar) $w.frm.vscroll
set v(fontheight) [font metrics [$w.frm.hex1 cget -font] -linespace ]

update
set v(txt_height) [winfo height $v(f1,txt)]
bind $v(f1,txt) <Configure> "ResizeText f1"
bind $v(f2,txt) <Configure> "ResizeText f2"
bind $v(f1,txt) <1> "SetCursor f1 %x %y"
bind $v(f2,txt) <1> "SetCursor f2 %x %y"

Display
ScrollSet

