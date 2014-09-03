#!/usr/bin/tclsh
#set filefont_name "lat0-12.psfu"
set filefont_name $argv
set filefont_id [open $filefont_name r]
fconfigure $filefont_id -translation binary
binary scan [read $filefont_id 2] H4 magic

if {$magic ne "3604"} {
  puts [format "ERROR : Only understand PSF1 format file. (Bad magic numbers, read %s, need "3604"" $magic]
  exit 1
}

binary scan [read $filefont_id 2] H2c* mode charsize

puts "Format : PSF1"
puts "Font Width: 8 pix"
puts [format "Font Hight: %s pix" $charsize ]
if {$mode == "01"} {
  puts "Char Count: 512"
}
if {$mode ne "01"} {
  puts "Char Count: 256"
}

set filecoe_name "font.coe"
set filecoe_id [open ../ise/core_gen/$filecoe_name w]
puts $filecoe_id "memory_initialization_radix  = 16;"
puts $filecoe_id "memory_initialization_vector ="

for {set i 0} {$i < [expr 256 / 4]} {incr i} {
  for {set j 0} {$j < $charsize} {incr j} {
    binary scan [read $filefont_id 1] H2 hex0
    binary scan [read $filefont_id 1] H2 hex1
    binary scan [read $filefont_id 1] H2 hex2
    binary scan [read $filefont_id 1] H2 hex3
    puts $filecoe_id "$hex3$hex2$hex1$hex0,"
  }
}

close $filefont_id
close $filecoe_id
