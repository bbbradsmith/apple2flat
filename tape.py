#!/usr/bin/env python3

# Transforms a list of files into a WAV file for tape input.
# Also includes a decoding utility for extracting data from tape audio.

import sys
import wave
import struct

CPU_SPEED = 1020484 # Apple II average CPU speed (accounting for 1/64 cycle delay)

SAMPLERATE = 44100 # default encoding samplerate
SILENCE = 2 # seconds of silence between packets
HEADTIME = 10 # seconds of header tone

DECODE_THRESHOLD = 0.2 # bit flip threshold relative to waveform peak
DECODE_CHECKSUM = False # append checksum byte to output

def decode_tape(filein):
    # read WAVE
    w = wave.open(filein,"rb")
    assert w.getnchannels() == 1, "Mono only."
    assert w.getsampwidth() <= 2, "8-bit or 16-bit only."
    assert w.getcomptype() == 'NONE', "Uncompressed only."
    wrate = w.getframerate()
    wb = w.readframes(w.getnframes())
    ws = []
    if w.getsampwidth() == 1: # 8-bit unsigned
        ws = [(x-128) for x in wb]
    else: # 16-bit signed, little endian
        ws = [x[0] for x in struct.iter_unpack("<h",wb)]
    w.close()
    # NOTE: we could use a highpass filter here to improve the signal?
    # set threshold
    peak = max(max(ws), -min(ws))
    t = int(DECODE_THRESHOLD * peak)
    print("%s: %d samples, %d Hz, %d peak, %d threshold" % (filein,len(ws),wrate,peak,t))
    # convert to stream of time between flips
    bs = []
    signal = True
    count = 0
    for sample in ws:
        if (signal == True) and sample < -t:
            signal = False
            bs.append(count)
            count = 0
        elif (signal == False) and sample > t:
            signal = True
            bs.append(count)
            count = 0
        count += 1
    # set timings
    SH = int(650 * wrate / CPU_SPEED) # samples per header flip
    S0 = int(250 * wrate / CPU_SPEED) # samples per 0 bit flip
    S1 = int(500 * wrate / CPU_SPEED) # samples per 1 bit flip
    S1H = (SH + S0) / 2 # average of 1/H
    S01 = (S0 + S1) / 2 # average of 0/1
    SHX = SH + (SH - S1H) # high tolerance for header
    HEADLOCK = 5 # this many samples in a row will be considered the header
    # decode packets
    packets = 0
    p = 0
    headcount = 0
    while p < len(bs):
        # find start of header tone (a few flips of the right length)
        while p < len(bs):            
            if bs[p] < S1H or bs[p] > SHX:
                headcount = 0
                p += 1
                continue
            headcount += 1
            p += 1
            if headcount < HEADLOCK:
                continue
            break
        # proceed to end of header tone
        while p < len(bs) and bs[p] > S1:
            p += 1
        # skip 2 sync bits
        p += 2
        # decode bytes
        bd = bytearray()
        bits = 0
        b = 0
        while (p+1) < len(bs):
            if bs[p] > SHX: # a long gap marks the end of the signal
                break
            fp = (bs[p+0] + bs[p+1]) // 2 # average of 2 half-waves
            b <<= 1
            if fp > S01:
                b |= 1
            bits += 1
            if bits >= 8:
                bd.append(b)
                b = 0
                bits = 0
            p += 2
        # check XOR-sum
        check = "none"
        if len(bd) > 0:
            check = "fail"
            esum = 0xFF
            for b in bd:
                esum ^= b
            if esum == 0:
                check = "pass"
            check = "%02X %s" % (bd[len(bd)-1], check)
            if not DECODE_CHECKSUM:
                bd = bd[0:len(bd)-1]
        # output file
        fileout = filein + (".%02X.bin" % packets)
        print("%02X: %s, %d bytes, check: %s" % (packets,fileout,len(bd),check))
        open(fileout,"wb").write(bd)
        packets += 1
    print("%d packets decoded." % packets)

def encode_tape(fileout,filesin,wrate=SAMPLERATE):
    # set volumes
    VS = 128
    V1 = VS + 64
    V0 = VS - 64
    # set timings
    SH = int(650 * wrate / CPU_SPEED) # samples per header flip
    SS = int(200 * wrate / CPU_SPEED) # samples per first half of sync
    S0 = int(250 * wrate / CPU_SPEED) # samples per 0 bit flip
    S1 = int(500 * wrate / CPU_SPEED) # samples per 1 bit flip
    HW = int((wrate * HEADTIME) / SH) # header half-wave count
    # byte array
    bd = bytearray()
    def add(s,c):
        for i in range(c):
            bd.append(s)
    def addbyte(s):
        for i in range(8):
            if (s & 0x80):
                add(V1,S1)
                add(V0,S1)
            else:
                add(V1,S0)
                add(V0,S0)
            s = (s << 1) & 0xFF
    add(VS,int(wrate*SILENCE))
    for filein in filesin:
        # header
        for i in range(HW//2):
            add(V1,SH)
            add(V0,SH)
        # sync
        add(V1,SS)
        add(V0,S0)
        # data
        fd = open(filein,"rb").read()
        esum = 0xFF
        for b in fd:
            esum ^= b
            addbyte(b)
        addbyte(esum)
        add(V1,int(wrate*SILENCE)) # final flip to terminate the last bit
    # NOTE: would a lowpass filter be appropriate?
    # output
    print("%s: %d samples, %d Hz" % (fileout, len(bd), wrate))
    w = wave.open(fileout,"wb")
    w.setnchannels(1)
    w.setsampwidth(1)
    w.setframerate(wrate)
    w.setnframes(len(bd))
    w.writeframes(bd)
    w.close()
    print("%d packets encoded." % (len(filesin)))

if __name__ == "__main__" and 'idlelib' not in sys.modules:
    encode_tape(sys.argv[1],sys.argv[2:])
