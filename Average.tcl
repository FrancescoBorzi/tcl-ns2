# Calculate the average

puts "Insert the amount of numbers:"
gets stdin n

set sum 0

for {set i 1} {$i <= $n} {incr i} {
    puts "Insert number $i:"
    gets stdin tmp
    incr sum $tmp
}

puts "The average is [expr $sum/$n]"
