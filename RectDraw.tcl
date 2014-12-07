# Draw a Rectangle

puts "Insert base value:"
gets stdin base

puts "Insert height value:"
gets stdin height

puts "Rectangle $base x $height:"

for {set h 0} {$h < $height} {incr h} {
    for {set b 0} {$b < $base} {incr b} {
        puts -nonewline "* "
    }
    puts ""
}
