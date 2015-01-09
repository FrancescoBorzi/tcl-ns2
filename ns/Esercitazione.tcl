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

$ns simplex-link $B $C 7Mb 	 200ms DropTail
$ns simplex-link $C $B 480Kb 200ms DropTail


# loss

set lossrate 0.005
loss $lossrate $B $C
loss $lossrate $C $B


# transport agents

set agent_A_sender [new Agent/TCP]
set agent_D_sender [new Agent/TCP]

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


# run

$ns at 0.1 "$ftpAD send 100MB"
$ns at 0.1 "$ftpDA send 20MB"
$ns at 8.0 "finish"

$ns run