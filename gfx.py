#!/usr/bin/env python3

# converts PNG images into apple2flat blit data
# requires PIL: https://python-pillow.org/

import sys
import PIL.Image
import PIL.ImageDraw

USAGE = "Usage:\n" + \
    "  gfx palette out.png - palette reference image\n" + \
    "  gfx font in.png out.bin - 7x8 font set\n" + \
    "  gfx font_vwf in.png out.bin out.wid - variable-width font\n" + \
    "  gfx lores in.png out.bin [-sc] - low or double-low resolution (blit data)\n" + \
    "  gfx hires in.png out.bin [-sc] - 4x2-color high resolution\n" + \
    "  gfx double in.png out.bin [-sc] - 16-color double-high-resolution\n" + \
    "  gfx mono in.png out.bin [-sc] - high or double high resolution monochrome\n" + \
    "  -s option: creates a full-screen image for screen_load instead of blit\n" + \
    "  -c=1,2,3,4 option: crops image to top left 1,2 with width 3,4\n" + \
    ""

#
# Converting images to indexed palette
#

PALETTE = [
    (  0,  0,  0),
    (147, 11,124),
    ( 31, 53,211),
    (187, 54,255),
    (  0,118, 12),
    (126,126,126),
    (  7,168,224),
    (157,172,255),
    ( 98, 76,  0),
    (249, 86, 29),
    (130,130,130),
    (255,129,236),
    ( 67,200,  0),
    (220,205, 22),
    ( 93,247,132),
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

def nibble_rotate_left(v):
    return ((v << 1) & 0xEE) | ((v >> 3) & 0x11)

def nibble_rotate_right(v):
    return ((v >> 1) & 0x77) | ((v << 3) & 0x88)

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

global last_hr_group
last_hr_group = 0

def span_hr(img,x,y,last=None):
    group = last if (last != None) else last_hr_group
    # remap palette: black, purple, green, blue, orange, white
    PALMAP = (0,1,3,1, 2,0,3,3, 4,4,5,1, 2,4,2,5, 0)
    # stored 2-bit pixels
    BITMAP = (0,1,2,1,2,3)
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
        p = nibble_rotate_right(p) # double hires uses rotated colours
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
    while gx < img.width: # skip to next non-transparent area
        if img.getpixel((gx,gy)) < 16:
            break
        gx += 1
    if gx >= img.width: # nothing found, just return to the start of the next row with an empty array
        return (0,gy+8,bytearray(),[])
    b = bytearray([0]*8)
    w = 0
    for w in range(min(img.width-gx,16)):
        if img.getpixel((gx+w,gy)) >= 16:
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
        count -= (len(b)//8)
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

def screenify(d,mode=0):
    if mode == 2: # rotate every second byte (double low res) and split into a double
        return screenify(d[1::2]) + screenify(bytearray([nibble_rotate_right(v) for v in d[0::2]]))
    if mode == 1: # split double, every second byte
        return screenify(d[1::2]) + screenify(d[0::2])
    if len(d) > (40*24): # split 8k hires 8-ways
        dm = bytearray()
        for i in range(8):
            dp = bytearray()
            for j in range(i*40,len(d),8*40):
                dp += d[j:j+40]
            dm += screenify(dp)
        return dm
    else: # split 1k lores 3-ways
        dm = bytearray()
        for i in range(8):
            for j in range(i*40,len(d),8*40):
                dm += d[j:j+40]
            dm += bytearray([0]*8) # 8 bytes of padding after every 120
        return dm

def make_lores(img,screen=False):
    if screen and (((img.width != 40) and (img.width != 80)) or (img.height != 48)):
        fail("lores -s requires 40x48 or 80x48 image")
    img = pad_to(img,1,2)
    d = bytearray()
    d.append(img.width)
    d.append(img.height//2)
    for y in range(0,img.height,2):
        for x in range(0,img.width,1):
            d.append(span_lr(img,x,y))
    if screen: return screenify(d[2:],0 if (img.width < 60) else 2)
    return d

def make_mono(img,screen=False):
    if screen and (((img.width != 280) and (img.width != 560)) or (img.height != 192)):
        fail("mono -s requires 280x192 or 560x192 image")
    img = pad_to(img,7,1)
    d = bytearray()
    d.append(img.width//7)
    d.append(img.height)
    for y in range(0,img.height,1):
        for x in range(0,img.width,7):
            d.append(span_mono(img,x,y))
    if screen: return screenify(d[2:],0 if (img.width < 420) else 1)
    return d

def make_hires(img,screen=False):
    if screen and ((img.width != 140) or (img.height != 192)):
        fail("hires -s requires 140x192 image")
    global last_hr_group
    last_hr_group = 0
    img = pad_to(img,7,1)
    d = bytearray()
    d.append(img.width//7)
    d.append(img.height)
    for y in range(0,img.height,1):
        for x in range(0,img.width,7):
            d.extend(span_hr(img,x,y))
    if screen: return screenify(d[2:],0)
    return d

def make_double(img,screen=False):
    if screen and ((img.width != 140) or (img.height != 192)):
        fail("double -s requires 140x192 image")
    img = pad_to(img,7,1)
    d = bytearray()
    d.append(img.width//7)
    d.append(img.height)
    for y in range(0,img.height,1):
        for x in range(0,img.width,7):
            d.extend(span_dhr(img,x,y))
    if screen: return screenify(d[2:],1)
    return d

#
# Command line
#

def fail(message):
    print(message)
    sys.exit(1)

def usage():
    fail(USAGE)

global crop
crop = None

def load_img(filename):
    img = index_image(filename)
    if crop != None:
        img = img.crop((crop[0],crop[1],crop[0]+crop[2],crop[1]+crop[3]))
    return img

if __name__ == "__main__" and 'idlelib' not in sys.modules:
    command = None
    file = [None,None,None]
    screen = False
    for i in range(1,len(sys.argv)):
        a = sys.argv[i]
        if a.startswith("-"):
            op = a.lower()
            if op == "-s": screen = True
            elif op.startswith("-c="):
                p = [int(v) for v in op[3:].split(",")]
                if len(p) < 4: usage()
                crop = c
            else: usage()
        elif command == None: command = a.lower()
        elif file[0] == None: file[0] = a
        elif file[1] == None: file[1] = a
        elif file[2] == None: file[2] = a
        else: usage()
    if command == None: usage()
    if command not in ["palette","font","font_vwf","lores","hires","mono","double"]: usage()
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
        open(file[2],"wb").write(d1)
        print("Done.")
        exit(0)
    if file[2] != None: usage() # all remaining commands have only in/out files
    print("%s: %s %s" % (command,file[0],file[1]))
    d = None
    if command == "font":   d = make_font(  load_img(file[0]))
    if command == "lores":  d = make_lores( load_img(file[0]),screen)
    if command == "hires":  d = make_hires( load_img(file[0]),screen)
    if command == "mono":   d = make_mono(  load_img(file[0]),screen)
    if command == "double": d = make_double(load_img(file[0]),screen)
    if d == None: usage()
    open(file[1],"wb").write(d)
    print("Done. (%d bytes written)" % len(d))
    exit(0)
