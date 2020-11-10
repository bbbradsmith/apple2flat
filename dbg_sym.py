#!/usr/bin/env python3

# Converts aa cc65 DBG file into AppleWin SYM file.

import sys

def dbg_line(l):
    # breaks a line into a dictionary with property values
    # [0] will be the type name from the start of the line
    l = l.rstrip() # remove newline
    if len(l) < 1:
        return None
    d = {}
    t = l.find("\t") # type name is separated by a tab
    if t >= 0:
        d[0] = l[0:t]
        ps = l[t+1:].split(",")
        for p in ps:
            e = p.find("=")
            assert e >= 0 # property without =?
            k = p[0:e]
            v = p[e+1:]
            if len(v) > 0:
                if v[0] == '"': # strip quotes and use string
                    assert v[len(v)-1] == '"', ("[%s]" % v) # unpaired quote?
                    v = v[1:len(v)-1]
                elif v[0:2] == "0x": # hexadecimal
                    v = int(v[2:],base=16)
                elif '+' in v: # list of integer references
                    v = map(int,v.split('+'))
                elif v.isdigit():
                    v = int(v)
                else:
                    pass # just use the string
            d[k] = v
    else:
        d[0] = l
    return d

def dbg_sym(filein,fileout):
    count = 0
    s = ""
    dbg = []
    print(" In: %s" % filein)
    for l in open(filein,"rt").readlines():
        d = dbg_line(l)
        if d is not None:
            dbg.append(d)
    used_n = set()
    labels = {}
    for d in dbg:
        if d[0] == "sym" and "name" in d and "val" in d:
            n = d["name"]
            if n == n.upper(): # skip uppercase symbols
                continue
            while n in used_n: # append . to duplicate symbol names
                n += "."
            v = d["val"]
            used_n.add(n)
            labels[v] = n
    for k in sorted(labels):
        s += "%04X %s\n" % (k,labels[k])
    print("Out: %s" % fileout)
    open(fileout,"wt").write(s)
    print("%d symbols exported." % (len(labels)))

if __name__ == "__main__" and 'idlelib' not in sys.modules:
    dbg_sym(sys.argv[1],sys.argv[2])
