# Example 1

set ns [new Simulator]

# nam output file
set fd [open out.nam w]
$ns namtrace-all $fd


# finish procedure
proc finish {} {
	global ns fd
	$ns flush-trace
	close $fd
	exec nam out.nam &
	exit 0
}


# nodes
set n0 [$ns node]

set n1 [$ns node]
set n2 [$ns node]

set n3 [$ns node]
set n4 [$ns node]

set n5 [$ns node]


# links
$ns duplex-link $n1 $n0 5Mb 100ms DropTail
$ns duplex-link $n2 $n0 5Mb 100ms DropTail

$ns duplex-link $n0 $n5 5Mb 100ms DropTail

$ns duplex-link $n5 $n3 5Mb 100ms DropTail
$ns duplex-link $n5 $n4 5Mb 100ms DropTail


# transport agents
set agent1 [new Agent/TCP]
set agent2 [new Agent/TCP]

set agent3 [new Agent/TCPSink]
set agent4 [new Agent/TCPSink]

$ns attach-agent $n1 $agent1
$ns attach-agent $n2 $agent2

$ns attach-agent $n3 $agent3
$ns attach-agent $n4 $agent4

$ns connect $agent1 $agent3
$ns connect $agent2 $agent4


# colors

$ns color 1 red
$ns color 2 green

$agent1 set fid_ 1
$agent2 set fid_ 2


# applications

set ftp1 [new Application/FTP]
set ftp2 [new Application/FTP]

$ftp1 attach-agent $agent1
$ftp2 attach-agent $agent2


# run

$ns at 0.1 "$ftp1 start"
$ns at 0.1 "$ftp2 start"
$ns at 8.0 "finish"

$ns run
