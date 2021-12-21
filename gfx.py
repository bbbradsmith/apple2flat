#!/usr/bin/env python3

# converts PNG images into apple2flat blit data
# requires PIL: https://python-pillow.org/

import sys
import PIL.Image
import PIL.ImageDraw

USAGE = "Usage:\n" + \
    "  gfx palette [out.png] - generate palette reference image\n"

#
# Converting images to indexed palette
#

PALETTE = [
    (  0,  0,  0),
    ( 31, 53,211),
    (  0,118, 12),
    (  7,168,224),
    ( 98, 76,  0),
    (126,126,126),
    ( 67,200,  0),
    ( 93,247,132),
    (147, 11,124),
    (187, 54,255),
    (130,130,130),
    (157,172,255),
    (249, 86, 29),
    (255,129,236),
    (220,205, 22),
    (255,255,255),
    (255,255,  0)] # yellow for transparent

def index_image(filename,palette=PALETTE):
    src = PIL.Image.open(filename).convert("RGB")
    dst = PIL.Image.new("P",src.size,color=0)
    for y in range(src.size[1]):
        for x in range(src.size[0]):
            p = src.getpixel((x,y))
            mag = ((255**2)*3)+1
            mat = 0
            for i in range(len(palette)):
                m = sum([(a-b)**2 for (a,b) in zip(p[0:3],palette[i])])
                if m < mag: # better match
                    mat = i
                    mag = m
                    if m == 0: # perfect match
                        break
            dst.putpixel((x,y),mat)
    dst.putpalette([p for t in palette for p in (t[0:3])])
    return dst

def palette_img(w=16):
    img = PIL.Image.new("P",(w*4,w*4),color=0)
    d = PIL.ImageDraw.Draw(img)
    for i in range(16):
        x = (i%4)*w
        y = (i//4)*w
        d.rectangle(((x,y),(x+w,y+w)),i)
    img.putpalette([p for t in PALETTE for p in t[0:3]])
    return img

#
# Convert image to byte-spanning groups
#

def span_mono(img,x,y): # read monochrome pixels 7x1
    b = 0
    for px in range(7):
        p = img.getpixel((x+(6-px),y)) & 1
        b = (b << 1) | p
    return b

def span_lr(img,x,y): # read low-resolution pixels 1x2
    b = 0
    for px in range(2):
        p = img.getpixel((x,y+px)) & 15
        b = (b >> 4) | (p << 4)
    return b

last_hr_group = 0

def span_hr(img,x,y,last=None):
    global last_hr_group
    group = last if (last != None) else last_hr_group
    # remap palette: black, magenta, green, orange, blue, white
    PALMAP = (0,4,2,4, 3,0,2,2, 1,1,5,4, 3,1,3,5,  0)
    # stored 2-bit pixels, in reverse-bit order
    BITMAP = (0,2,1,2,1,3)
    # generate 14-bit content, and determine shift group
    b = 0
    for px in range(7):
        p = PALMAP[img.getpixel((x+px,y))]
        if (p == 1 or p == 2): group = 0
        if (p == 3 or p == 4): group = 1
        b = (b >> 2) | (BITMAP[p] << 12)
    last_hr_group = group # remember previous group to prevent excess switching
    return bytes([ # split 14-bit row into 2 bytes with shift group high bit
        (b & 0x7F) | (group << 7),
        (b >>   7) | (group << 7)])

def span_dhr(img,x,y):
    b = 0
    for px in range(7):
        p = img.getpixel((x+px,y)) & 15
        # TODO bitreverse or shift P?
        b = (b >> 4) | (p << 24)
    return bytes([
        (b >>  0) & 0x7F,
        (b >>  7) & 0x7F,
        (b >> 14) & 0x7F,
        (b >> 21) & 0x7F])

#
# 7x8 font
#

def block_mono(img,x,y):
    ba = bytearray()
    for py in range(8):
        ba.append(span_mono(img,x,y+py))
    return ba           

def make_font(img,count=256):
    ba = bytearray()
    gw = img.size[0] // 7
    gh = img.size[1] // 8
    for gy in range(gh):
        for gx in range(gw):
            if (count <= 0):
                return ba
            ba += block_mono(img,gx*7,gy*8)
            count -= 1
    return ba

#
# variable width font generation (?x8 mono)
#

def glyph_vwf(img,gx,gy):
    while gx < img.width: # skip to next non-magenta area
        if img.getpixel((gx,gy)) < 2:
            break
        gx += 1
    if gx >= img.width: # nothing found, just return to the start of the next row with an empty array
        return (0,gy+8,bytearray(),[])
    b = bytearray([0]*8)
    w = 0
    for w in range(min(img.width-gx,16)):
        if img.getpixel((gx+w,gy)) >= 2:
            break
        if w < 8:
            for y in range(8):
                b[y] |= (img.getpixel((gx+w,gy+y)) & 1) << w
    assert (w>0), "glyph_vwf should not be able to generate 0-width glyph"
    return (gx+w,gy,b,[w-1])

def make_font_vwf(img,count=256):
    ba = bytearray()
    wa = []
    gx = 0
    gy = 0
    ba = bytearray()
    while (gy+8) <= img.height and count > 0:
        (gx,gy,b,w) = glyph_vwf(img,gx,gy)
        ba += b
        wa += w
        count -= (len(ba)//8)
    # pack pairs of widths into nibbles
    if (len(wa) & 1) == 1:
        wa.append(0)
    wn = bytearray()
    for i in range(0,len(wa),2):
        wn.append(wa[i+0] | (wa[i+1]<<4))
    return (ba,wn)

#
# Graphics
#

def pad_to(img,x,y):
    xpad = 0
    ypad = 0
    if (img.width  % x) != 0: xpad = x - (img.width  % x)
    if (img.height % y) != 0: ypad = y - (img.height % y)
    if (xpad == 0) and (ypad == 0): return img
    imp = PIL.Image("P",(img.width+xpad,img.height+ypad),0)
    imp.putpalette(img.getpalette())
    imp.paste(img)
    return imp

def make_lores(img):
    img = pad_to(img,1,2)
    d = bytearray()
    d.append(img.width)
    d.append(img.height//2)
    for y in range(0,img.height,2):
        for x in range(0,img.width):
            d.append(span_lr(img,x,y))
    return d

#
# Command line
#

def usage():
    print(USAGE)
    sys.exit(1)

def load_img(filename):
    img = index_image(filename)
    # TODO apply global crop option
    return img

if __name__ == "__main__" and 'idlelib' not in sys.modules:
    command = None
    file = [None,None,None]
    for i in range(1,len(sys.argv)):
        a = sys.argv[i]
        if a.startswith("-"):
            # TODO parse options?
            usage()
        elif command == None: command = a.lower()
        elif file[0] == None: file[0] = a
        elif file[1] == None: file[1] = a
        elif file[2] == None: file[2] = a
        else: usage()
    if command == None: usage()
    if file[0] == None: usage() # all commands need at least 1 file
    if command == "palette":
        if file[1] != None: usage()
        print("palette: " + file[0])
        palette_img().save(file[0])
        print("Done.")
        exit(0)
    if file[1] == None: usage() # all other commands need 2 files
    print(file[0] + " test")
    if command == "font_vwf":
        print("font_vwf: %s %s %s" % (file[0],file[1],file[2]))
        (d0,d1) = make_font_vwf(load_img(file[0]))
        open(file[1],"wb").write(d0)
        open(file[2],"wb").write(d0)
        print("Done.")
        exit(0)
    if file[2] != None: usage() # all remaining commands have only in/out files
    print("%s: %s %s" % (command,file[0],file[1]))
    d = None
    if command == "font":   d = make_font(load_img(file[0]))
    if command == "lores":  d = make_lores(load_img(file[0]))
    if command == "hires":  pass 
    if command == "mono":   pass
    if command == "double": pass
    if d == None: usage()
    open(file[1],"wb").write(d)
    print("Done.")
    exit(0)
