# generate tuning tables for music routines

import math

# Average rate of CPU cycle (14,318,180 Hz divided by 14 on 64/65 cycles, and 16 on the 65th)
# Reference: Understanding the Apple II, Jim Sather 1983. Section 3-3.
CPU_RATE = 1020484

period0 = [] # cycle period in octave 0
timing8 = [] # frequency in octave 8

for i in range(0,12):
    freq = 440 * pow(2,(i-57)/12)
    p0 = math.floor((CPU_RATE / freq) + 0.5)
    t8 = math.floor((freq * pow(2,8)) + 0.5)
    print("%2d: %10.3f Hz, %5d cy, %5d times" % (i,freq,p0,t8))
    period0.append(p0)
    timing8.append(t8)

def lotable(a):
    s = "".join([("$%02X,"%(x&0xFF)) for x in a])
    return s.rstrip(",")

def hitable(a):
    s = "".join([("$%02X,"%(x>>8)) for x in a])
    return s.rstrip(",")

print ("music_period0lo: .byte " + lotable(period0))
print ("music_period0hi: .byte " + hitable(period0))
print ("music_timing8lo: .byte " + lotable(timing8))
print ("music_timing8hi: .byte " + hitable(timing8))

# 9 octaves to represent:
# C0    ~16Hz / ~62409 cycles (lowest usable in 16-bit)
# C5   ~262Hz /  ~3901 cycles
# F8 ~11175Hz /    ~86 cycles (highest usable above cycle delay limit)
# C9 ~16744Hz /    ~61 cycles

# 90 cycle wavelength is lower limit 2 x (vdelay 29 + sound_pulse 16)

# print some test period values for finding representable range
def test_tuning():
    for i in range(-10,10): # investigate octaves
        cbase = 440 * pow(2,(3/12))
        f = cbase * pow(2,i)
        p = CPU_RATE / f
        print("%3d: %10.3f Hz period = %10.3f" % (i,f,p))
    for i in range(-80,80): # investigate pitches
        f = 440 * pow(2,i/12)
        ic = (i + 96 - 3) % 12 # pitch class (C=0)
        p = CPU_RATE / f
        print("%3d (%2d): %10.3f Hz period = %10.3f" % (i,ic,f,p))

#test_tuning()
