set ns [new Simulator]


# files

#set fd [open out.nam w]
#$ns namtrace-all $fd

#set tracefile [open tracefile.txt w]


# finish procedure

proc finish {} {
	#global ns fd tracefile
	#$ns flush-trace
	#close $fd
	#close $tracefile
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

# debug
# set dataAD [expr 100]
# set dataDA [expr 20]

# packet amount

set expectedPacketsAD [expr $dataAD / $packetSize]
set expectedPacketsDA [expr $dataDA / $packetSize]


# simulation & check procedures

set n 0
set simulations 10 ;# numero di simulazioni
set times(0) 0

# queue limits

set queueLimit(0) 2
set queueLimit(1) 4 
set queueLimit(2) 8
set queueLimit(3) 16
set queueLimit(4) 32
set queueLimit(5) 64
set queueLimit(6) 128
set queueLimit(7) 256
set queueLimit(8) 512
set queueLimit(9) 1024


proc simulation {} {
	global ns ftpAD ftpDA n dataAD dataDA agent_A_sender agent_D_sender simulations times B C queueLimit
	
	if {$n == $simulations} {
		set deltaTimes(0) $times(0)

		for { set i 1 } { $i < $simulations } { incr i } {
			set deltaTimes($i) [expr "$times($i) - $times([expr "$i - 1"])"]
		}

		$ns at [$ns now] "finish"

	} else {
		$ns queue-limit $B $C queueLimit($n)
		$ns queue-limit $C $B queueLimit($n)

		$ns at [expr [$ns now] + 0.1] "$ftpAD send $dataAD"
		$ns at [expr [$ns now] + 0.1] "$ftpDA send $dataDA"
		$ns at [expr [$ns now] + 0.2] "check"
		$ns run
	}
}

proc check {} {
	global ns agent_A_sender agent_D_sender times expectedPacketsAD expectedPacketsDA n

	set receivedPacketsAD [$agent_A_sender set ack_]
	set receivedPacketsDA [$agent_D_sender set ack_]
	
	#puts "#$n) A received acks: $receivedPacketsAD ([$ns now])"
	#puts "#$n) D received acks: $receivedPacketsDA ([$ns now])"
	
	if { $expectedPacketsAD >= $receivedPacketsAD || $expectedPacketsDA >= $receivedPacketsDA } {
		$ns at [expr [$ns now] + 0.1] "check"
	} else {
		set times($n) [$ns now]
		puts "#$n completata"
		set n [expr $n + 1]
		$ns at [expr [$ns now] + 0.1] "simulation"
	}
}

# run

simulation
