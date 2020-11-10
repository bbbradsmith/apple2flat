#!/usr/bin/env python3

# Converts a logical/linear sector order BIN to Apple 2 DSK,
# rearranging the sectors into DOS 3.3 physical order.

import sys

SECTOR_SIZE = 256
SECTORS = 16
SECTOR_POSITION = [ 0, 7, 14, 6, 13, 5, 12, 4, 11, 3, 10, 2, 9, 1, 8, 15 ]

def reorder(filein,fileout):
    TRACK_SIZE = SECTOR_SIZE * SECTORS
    print(" In: %s" % filein)
    bi = open(filein,"rb").read()
    assert (len(bi) % TRACK_SIZE) == 0, "File %s not an even number of tracks (%d bytes) in size." % (filein, TRACK_SIZE)
    tracks = len(bi) // TRACK_SIZE
    bo = bytearray([0]*len(bi))
    for t in range(tracks):
        for s in range(SECTORS):
            oi = (t * TRACK_SIZE) + (s * SECTOR_SIZE)
            oo = (t * TRACK_SIZE) + (SECTOR_POSITION[s] * SECTOR_SIZE)
            bo[oo:oo+SECTOR_SIZE] = bi[oi:oi+SECTOR_SIZE]
    print("Out: %s" % fileout)
    open(fileout,"wb").write(bo)
    print("%d tracks reordered." % (tracks))

if __name__ == "__main__" and 'idlelib' not in sys.modules:
    reorder(sys.argv[1],sys.argv[2])
