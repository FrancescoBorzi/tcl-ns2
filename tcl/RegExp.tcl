# Insert a Regular Expression, for example: (^[a-z]{2,4})([0-9]{2}$)
# and check if a string matches with it

puts "RegExp: "
gets stdin regexpr

while {1} {
    puts "\nInsert a string: "
    gets stdin str

    if {[regexp $regexpr $str]} {
        puts "It matches!"
    } else {
        puts "It doesn't match!"
    }
}
