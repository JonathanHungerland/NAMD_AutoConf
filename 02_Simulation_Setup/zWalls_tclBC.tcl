proc calcforces { step unique wallstrength minz maxz } {
    if { $step % 500 == 0 } { cleardrops }
    while {[nextatom]} {
        set rvec [getcoord]
        foreach { x y z } $rvec { break }
        if { $z > $maxz } {
            addforce "0.0 0.0 [expr $wallstrength*($z-$zmax)*($z-$zmax)]"
        } elseif { $z < $minz } {
            addforce "0.0 0.0 [expr $wallstrength*($z-zmin)*($z-$zmin)]"
        } else {
            dropatom
        }
    }
}