set ns [new Simulator]


# files

set fd [open out.nam w]
$ns namtrace-all $fd

set tracefile [open tracefile.txt w]


# finish procedure

proc finish {} {
	global ns fd tracefile
	$ns flush-trace
	close $fd
	close $tracefile
	#exec nam out.nam &
	exit 0
}


# perdite di pacchetti: na, nb identificano il link 
proc loss {rate na nb} {
	set ns [Simulator info instances]
	set em1 [new ErrorModel]
	$em1 unit EU_PKT		;# errori a livello di pacchetto
	$em1 set rate_ $rate
	$em1 ranvar [new RandomVariable/Uniform]
	$em1 drop-target [new Agent/Null]
	$ns lossmodel $em1 $na $nb	;#collega il lossmodel al link assegnato
	
	set em2 [new ErrorModel]
	$em2 unit EU_PKT		;# errori a livello di pacchetto
	$em2 set rate_ $rate
	$em2 ranvar [new RandomVariable/Uniform]
	$em2 drop-target [new Agent/Null]
	$ns lossmodel $em2 $nb $na	;#collega il lossmodel al link assegnato
}


# nodes

set A [$ns node]
set B [$ns node]
set C [$ns node]
set D [$ns node]

$A label "A"
$B label "B"
$C label "C"
$D label "D"

$A shape box
$D shape box

$A color red
$B color blue
$C color purple
$D color green


# links

$ns duplex-link $A $B 100Mb 1ms DropTail
$ns duplex-link $C $D 100Mb 1ms DropTail

$ns simplex-link $B $C 7Mb   200ms DropTail
$ns simplex-link $C $B 480Kb 200ms DropTail

$ns queue-limit $B $C 20
$ns queue-limit $C $B 20


# loss

set lossrate 0.005
loss $lossrate $B $C
loss $lossrate $C $B


# transport agents

set agent_A_sender [new Agent/TCP]
set agent_D_sender [new Agent/TCP]

set packetSize [eval $agent_A_sender set packetSize_]

set agent_A_receiver [new Agent/TCPSink]
set agent_D_receiver [new Agent/TCPSink]

$ns attach-agent $A $agent_A_sender
$ns attach-agent $D $agent_D_sender

$ns attach-agent $A $agent_A_receiver
$ns attach-agent $D $agent_D_receiver

$ns connect $agent_A_sender $agent_D_receiver
$ns connect $agent_D_sender $agent_A_receiver


# colors

$ns color 1 red
$ns color 2 green

$agent_A_sender set fid_ 1
$agent_D_sender set fid_ 2


# applications

set ftpAD [new Application/FTP]
set ftpDA [new Application/FTP]

$ftpAD attach-agent $agent_A_sender
$ftpDA attach-agent $agent_D_sender


# data amount

set dataAD [expr 100 * 1024 * 1024]
set dataDA [expr 20 * 1024 * 1024]

# packet amount

set expectedPacketsAD [expr $dataAD / $packetSize]
set expectedPacketsDA [expr $dataDA / $packetSize]

puts "(AD) Mi aspetto $expectedPacketsAD pacchetti \n"
puts "(DA) Mi aspetto $expectedPacketsDA pacchetti \n"


# check procedure

set time 0

proc check {} {
	global ns agent_A_sender agent_D_sender time expectedPacketsAD expectedPacketsDA
	
	set time [$ns now]
	set time [expr $time + 0.1]

	set receivedPacketsAD [eval $agent_A_sender set ack_]
	set receivedPacketsDA [eval $agent_D_sender set ack_]
	
	puts "A received acks: $receivedPacketsAD"
	puts "D receiveds acks: $receivedPacketsDA"
	
	if { $expectedPacketsAD >= $receivedPacketsAD || $expectedPacketsDA >= $receivedPacketsDA } {
		$ns at $time "check"
	} else {
		$ns at $time "finish"
	}
}

# run

$ns at 0.1 "$ftpAD send $dataAD"
$ns at 0.1 "$ftpDA send $dataDA"
$ns at 0.2 "check"

$ns run
