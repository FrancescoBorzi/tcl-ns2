# Calculate the average, reading from file numbers.txt

set f [open "numbers.txt" "r"]

set sum 0
set i 0

set x [gets $f]

while {$x != ""} {
    incr sum $x
    incr i
    set x [gets $f]
}

puts [expr $sum/$i]

close $f
