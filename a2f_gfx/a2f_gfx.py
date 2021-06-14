#!/usr/bin/env python3

import PIL.Image

#
# palettes
#

PAL_MONO = [
    (  0,  0,  0),
    (255,255,255),
    (255,  0,255), ] # magenta for transparency
PAL_LORES = [
    (  0,  0,  0),
    (147, 11, 24),
    ( 31, 53,211),
    (187, 54,255),
    (  0,118, 12),
    (126,126,126),
    (  7,168,224),
    (157,172,255),
    ( 98, 76,  0),
    (249, 86, 29),
    (190,190,190), # fake "light grey", same as colour 5 but reversed
    (255,129,236),
    ( 67,200,  0),
    (220,205, 22),
    ( 93,247,132),
    (255,255,255),
    (255,  0,255), ] # magenta for transparecny
PAL_HIRES = [
    PAL_LORES[ 0],
    PAL_LORES[15],
    PAL_LORES[ 3],
    PAL_LORES[12],
    PAL_LORES[ 9],
    PAL_LORES[ 6],
    (255,  0,255), ]
NIBROL = ((((x>>1)&0x7)|((x<<3)&0x8)) for x in range(16)) # nibble left-rotate
NIBROR = ((((x<<1)&0xE)|((x>>3)&0x1)) for x in range(16)) # nibble right-rotate

#
# image reading
#

def palette_image(img,palette):
    img.putpalette([x for rgb in palette for x in rgb]) # unpack palette into linear array

# load and convert image to indexed palette
def index_image(filename, palette):
    src = PIL.Image.open(filename)
    dst = PIL.Image.new("P",src.size,color=0)
    for y in range(src.size[1]):
        for x in range(src.size[0]):
            p = src.getpixel((x,y))
            mag = ((255**2)*3)+1
            mat = 0
            for i in range(len(palette)):
                m = sum([(a-b)**2 for (a,b) in zip(p,palette[i])])
                if m < mag: # better match
                    mat = i
                    mag = m
                    if m == 0: # perfect match
                        break
            dst.putpixel((x,y),mat)
    return dst

#
# monochrone 7-pixel groups
#

def span_high_mono(img,x,y):
    b = 0
    for px in range(7):
        p = img.getpixel((x+(6-px),y)) & 1
        b = (b << 1) | p
    return b

def block_high_mono(img,x,y):
    ba = bytearray()
    for py in range(8):
        ba.append(span_high_mono(img,x,y+py))
    return ba           

def paste_span_high_mono(img,x,y,b):
    for px in range(7):
        img.putpixel((x+px,y),b&1)
        b >>= 1

def paste_block_high_mono(img,x,y,ba):
    for py in range(len(ba)):
        paste_span_high_mono(img,x,y+py,ba[py])

#
# font generation (7x8 mono)
#

def preview_font(ba,offset=0x20):
    COLUMNS = 32
    img = PIL.Image.new("P",(7*COLUMNS,8*(256//COLUMNS)),color=2)
    palette_image(img,PAL_MONO)
    count = max(offset+(len(ba)//8),256)
    for i in range(count):
        a = i + offset
        paste_block_high_mono(img,7*(a%COLUMNS),8*(a//COLUMNS),ba[i*8:i*8+8])
    return img

def make_font(filename,count=256):
    img = index_image(filename,PAL_MONO)
    ba = bytearray()
    gw = img.size[0] // 7
    gh = img.size[1] // 7
    for gy in range(gh):
        for gx in range(gw):
            if (count <= 0):
                return ba
            ba += block_high_mono(img,gx*7,gy*8)
            count -= 1
    return ba

# TODO monochrome masked (1 byte AND, 1 byte OR) span
# TODO hires (2 bytes) span
# TODO hires masked (2 + 2) span
# TODO dhires (4) span
# TODO dhires masked (4 + 4) span
# TODO lores (1 byte, vertical 2px) span
# TODO dlores (2 bytes, 2x2 px) span

# test of font generation
f = make_font("../font.png")
open("../font.bin","wb").write(f)
preview_font(f).save("../test.png")
