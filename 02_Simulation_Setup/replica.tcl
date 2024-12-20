
replicaBarrier

set nr [numReplicas]
if { $num_replicas != $nr } {
    error "restart with wrong number of replicas"
}
set r [myReplica]
set replica_id $r

if {[info exists restart_root]} { #restart
  set restart_root [format $restart_root $replica_id]
  source $restart_root.$replica_id.tcl
} else {
  set i_job 0 
  set i_run 0
  set i_step 0
  if {[info exists first_timestep]} {
    set i_step $first_timestep
  }

  set replica(index) $r
  set replica(loc.a) $r
  set replica(index.a) $r
  set replica(loc.b) $r
  set replica(index.b) $r
  set replica(exchanges_attempted) 0
  set replica(exchanges_accepted) 0

  if { $r % 2 == 0 && $r+1 < $nr } {
    set replica(loc.a) [expr $r+1]
    set replica(index.a) [expr $r+1]
  }
  if { $r % 2 == 1 && $r > 0 } {
    set replica(loc.a) [expr $r-1]
    set replica(index.a) [expr $r-1]
  }

  if { $r % 2 == 1 && $r+1 < $nr } {
    set replica(loc.b) [expr $r+1]
    set replica(index.b) [expr $r+1]
  }
  if { $r % 2 == 0 && $r > 0 } {
    set replica(loc.b) [expr $r-1]
    set replica(index.b) [expr $r-1]
  }

}

set job_output_root "$output_root.job$i_job"
firsttimestep $i_step

proc replica_temp { i } {
  global num_replicas min_temp max_temp
  return [format "%.2f" [expr ($min_temp * \
         exp( log(1.0*$max_temp/$min_temp)*(1.0*$i/($num_replicas-1)) ) )]]
}

set replica(temperature) [replica_temp $replica(index)]
set replica(temperature.a) [replica_temp $replica(index.a)]
set replica(temperature.b) [replica_temp $replica(index.b)]

proc save_callback {labels values} {
  global saved_labels saved_values
  set saved_labels $labels
  set saved_values $values
}
callback save_callback

proc save_array {} {
  global saved_labels saved_values saved_array
  foreach label $saved_labels value $saved_values {
    set saved_array($label) $value
  }
}

set NEWTEMP $replica(temperature)
seed [expr int(0*srand(int(100000*rand()) + 100*$replica_id) + 100000*rand() + 1)]
langevinTemp $NEWTEMP
outputname [format $job_output_root.$replica_id $replica_id]

if {$i_run} { #restart
  bincoordinates $restart_root.$replica_id.coor
  binvelocities $restart_root.$replica_id.vel
  extendedSystem $restart_root.$replica_id.xsc
}

outputEnergies [expr $steps_per_run / 10]
dcdFreq [expr $steps_per_run * $runs_per_frame]

source $namd_config_file

set history_file [open [format "$job_output_root.$replica_id.history" $replica_id] "w"]
fconfigure $history_file -buffering line

while {$i_run < $num_runs} {

  run $steps_per_run
  save_array
  incr i_step $steps_per_run
  set TEMP $saved_array(TEMP)
  set POTENTIAL [expr $saved_array(TOTAL) - $saved_array(KINETIC)]
  puts $history_file "$i_step $replica(index) $NEWTEMP $TEMP $POTENTIAL"

  if { $i_run % 2 == 0 } {
    set swap a; set other b
  } else {
    set swap b; set other a
  }

  set doswap 0
  if { $replica(index) < $replica(index.$swap) } {
    set temp $replica(temperature)
    set temp2 $replica(temperature.$swap)
    set BOLTZMAN 0.001987191
    set dbeta [expr ((1.0/$temp) - (1.0/$temp2)) / $BOLTZMAN]
    set pot $POTENTIAL
    set pot2 [replicaRecv $replica(loc.$swap)]
    set delta [expr $dbeta * ($pot2 - $pot)]
    set doswap [expr $delta < 0. || exp(-1. * $delta) > rand()]
    replicaSend $doswap $replica(loc.$swap)
    if { $doswap } {
      set rid $replica(index)
      set rid2 $replica(index.$swap)
      puts stderr "EXCHANGE_ACCEPT $rid ($temp) $rid2 ($temp2) RUN $i_run"
      incr replica(exchanges_accepted)
    }
    incr replica(exchanges_attempted)
  }
  if { $replica(index) > $replica(index.$swap) } {
    replicaSend $POTENTIAL $replica(loc.$swap)
    set doswap [replicaRecv $replica(loc.$swap)]
  }

  set newloc $r
  if { $doswap } {
    set newloc $replica(loc.$swap)
    set replica(loc.$swap) $r
  }
  set replica(loc.$other) [replicaSendrecv $newloc $replica(loc.$other) $replica(loc.$other)]
  set oldidx $replica(index)
  if { $doswap } {
    set OLDTEMP $replica(temperature)
    array set replica [replicaSendrecv [array get replica] $newloc $newloc]
    set NEWTEMP $replica(temperature)
    rescalevels [expr sqrt(1.0*$NEWTEMP/$OLDTEMP)]
    langevinTemp $NEWTEMP
  }

  # puts stderr "iteration $i_run replica $replica(index) now on rank $r"
  # replicaBarrier

  incr i_run

  if { $i_run % ($runs_per_frame * $frames_per_restart) == 0 ||
        $i_run == $num_runs } {  # restart
    set restart_root "$job_output_root.restart$i_run"
    output [format $restart_root.$replica_id $replica_id]
    set rfile [open [format "$restart_root.$replica_id.tcl" $replica_id] "w"]
    puts $rfile [list array set replica [array get replica]]
    close $rfile
    replicaBarrier
    if { $replica_id == 0 } {
      set rfile [open [format "$restart_root.tcl" 0] "w"]
      puts $rfile [list set i_job [expr $i_job + 1]]
      puts $rfile [list set i_run $i_run]
      puts $rfile [list set i_step $i_step]
      puts $rfile [list set restart_root $restart_root]
      close $rfile
      if [info exists old_restart_root] {
        set oldroot [format $old_restart_root ""]
        file delete $oldroot.tcl
      }
    }
    replicaBarrier
    if [info exists old_restart_root] {
      set oldroot [format $old_restart_root $replica_id]
      file delete $oldroot.$replica_id.tcl
      file delete $oldroot.$replica_id.coor
      file delete $oldroot.$replica_id.vel
      file delete $oldroot.$replica_id.xsc
    }
    set old_restart_root $restart_root
  }
}

set attempts $replica(exchanges_attempted)
if $attempts {
  set i $replica(index)
  if { $replica(index.a) > $i } {
    set swap a
  } else {
    set swap b
  }
  set temp $replica(temperature)
  set temp2 $replica(temperature.$swap)
  set accepts $replica(exchanges_accepted)
  set ratio [expr 1.0*$accepts/$attempts]
  puts stderr "EXCHANGE_RATIO $temp $temp2 $accepts $attempts $ratio"
}

replicaBarrier

