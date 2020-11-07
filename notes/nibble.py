# Generate denibblize / nibblize tables

denib = [-1] * 256
renib = [-1] * 64
RWST16_FILL = False

# Based on Disk II controller BOOT0 loader (C600) table generator:
y = 0
x = 3
while (x < 128):
    bits = x
    # reject any with 2 adjacent 1s
    if 0 == (x & (x << 1)):
        x += 1
        continue
    # reject any with 2 adjacent 0s
    a = ((x | (x << 1)) ^ 0xFF) & 0x7E # 1s represent adjacent 0s not at start/end
    c = x & 0x80
    valid = False
    while (c == 0):
        c = a & 1
        a = a >> 1
        if a == 0:
            valid = True
            break
    if not valid:
        x += 1
        continue
    # usable value
    denib[x|0x80] = y
    y += 1
    x += 1

# Reverse table for writing:
renib = [denib.index(x) for x in range(64)]

# RWST16 fills denibblize table with their position instead?
for x in range(256):
    if denib[x] < 0:
        if RWST16_FILL:
            denib[x] = x
        elif x >= 0x96:
            denib[x] = 0

def hexout(l,columns=16):
    s = ""
    for i in range(len(l)):
        if (i % columns) == 0:
            s += "\n.byte $%02X" % l[i]
        else:
            s += ",$%02X" % l[i]
    return s

print("denib" + hexout(denib))
print("renib" + hexout(renib))
