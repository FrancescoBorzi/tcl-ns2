# SIMULATORE
set ns [new Simulator]

# COLORI
$ns color 0 red
$ns color 1 blue

# PER GRAFICI E ANIMAZIONE
set namf [open queue.nam w]
set nsf [open queue.ns w]
$ns namtrace-all $namf
$ns trace-all $nsf

set qsize [open queuesize.tr w]
set qbw [open queuebw.tr w]
set qlost [open queuelost.tr w]

# CREIAMO 4 NODI
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

# LABEL
$n1 label "Switch (25)"

# PROCEDURA DI FINISH
proc finish {} {
 global ns namf qsize qbw qlost 
 $ns flush-trace
 close $qsize
 close $qbw
 close $qlost
 exec nam queue.nam &

 exec xgraph queuesize.tr -t "Queuesize" &
 exec xgraph queuebw.tr -t "Throughput" &
 exec xgraph queuelost.tr -t "Lost" &
 exit 0
}


# PROCEDURA PER I GRAFICI E MONITORAGGIO
set old_departure 0

proc record {} {
global ns qmon_size qmon_bw qmon_lost qsize qbw qlost old_departure
set ns [Simulator instance]
set time 0.05; # OGNI QUANTO MONITORARE
set now [$ns now]; #TEMPO ATTUALE

$qmon_size instvar size_ pkts_ barrivals_ bdepartures_ parrivals_ pdepartures_ bdrops_ pdrops_ ; #VARIABILI DELLA CLASSE MONITOR
puts $qsize "$now [$qmon_size set size_]"; #INSERISCO NEL FILE , IL TEMPO ATTUALE E LA DIMENSIONE DELLA CODA IN BYTE

puts $qbw "$now [expr ($bdepartures_ - $old_departure)*8/$time]"; #INSERISCO NEL FILE IL NUMERO DI PACCHETTI TRASMESSI IN TEMPO ATTUALE
set old_departure $bdepartures_

#if { $now !=0 } { puts $qbw "$now [expr $bdepartures_*8/$now]" } 
#puts $qbw "$now [expr $bdepartures_*8/$time] $bdepartures_"
#set bdepartures_ 0

puts $qlost "$now $pdrops_ $bdrops_"; #INSERISCO NEL FILE IL TEMPO ATTUALE, NUMERO DEI PACCHETTI SCARTATI, NUMERO DEI PACCHETTI SCARTATI IN BYTE
$ns at [expr $now+$time] "record"
}


# CREIAMO I LINK
$ns duplex-link $n1 $n3 1.5Mb 10ms DropTail
$ns duplex-link $n0 $n1 5Mb 10ms DropTail
$ns duplex-link $n2 $n1 5Mb 10ms DropTail

# NEI LINK METTIAMO ALCUNE CONDIZIONI, ES LIMITIAMO LA CODA
$ns duplex-link-op $n1 $n3 orient right
$ns duplex-link-op $n0 $n1 orient right-down
$ns duplex-link-op $n2 $n1 orient right-up
$ns duplex-link-op $n1 $n3 queuePos 0.5
$ns queue-limit $n1 $n3 25

# CONNESSIONE tcp ...n0 manda , n3 riceve , impostiamo alcuni parametri
set tick 0.5
set tcp0 [$ns create-connection TCP $n0 TCPSink $n3 0]
$tcp0 set packetSize_ 1460
$tcp0 set tcpTick_ $tick
$tcp0 set fid_ 0

# CREIAMO TRAFFICO ESTERNO E LO ATTACCHIAMO ALLA NOSTRA CONNESSIONE tcp0
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 1460
$cbr0 set rate_ 1200k
$cbr0 attach-agent $tcp0

# UN'ALTRA CONNESSIONE tcp TRA n2 ED n3
set tcp1 [$ns create-connection TCP $n2 TCPSink $n3 1]
$tcp1 set packetSize_ 1460; #dimensione in byte del pacchetto trasmesso
$tcp1 set tcpTick_ $tick; #granularità temporale nella stima del RTT
$tcp1 set fid_ 1; #flow id

# CREIAMO TRAFFICO ESTERNO E LO ATTACCHIAMO ALLA NOSTRA CONNESSIONE tcp1
set cbr1 [new Application/Traffic/CBR]
$cbr1 set packetSize_ 1460
$cbr1 set rate_ 1200k; #
$cbr1 attach-agent $tcp1



####################
# QUEUE MONITOR #
####################

set qf_size [open queue.size w]
set qmon_size [$ns monitor-queue $n1 $n3 $qf_size 0.05]; # nodi da monitorare trace e intervallo--> oggetto monitor da chiamare nella procedura record

# CHIAMIAMO LE PROCEDURE
$ns at 0.0 "record"
$ns at 0.1 "$cbr0 start"
$ns at 0.5 "$cbr1 start"
$ns at 5.1 "$cbr0 stop"
$ns at 5.5 "$cbr1 stop"


$ns at 5.5 "finish"

$ns run