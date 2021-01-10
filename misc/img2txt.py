
from PIL import Image
import ansi
import sys

def nextFrame(imgOrig, frame, newWidth, newHeight):
    imgOrig.seek(frame)
    img = imgOrig
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    # antialias = Image.ANTIALIAS
    antialias = Image.NEAREST
    img = img.resize((newWidth, newHeight), antialias)
    pixel = img.load()
    width, height = img.size

    # output frame
    fill_string = "\x1b[49m"
    fill_string += "\x1b[K"
    sys.stdout.write(fill_string)
    sys.stdout.write(ansi.generate_ANSI_from_pixels(pixel, width, height, None)[0])
    sys.stdout.write("\x1b[0m\n")

    # frame separator
    sys.stdout.write('ZF_img2txt_ZF\n')


# ============================================================
# main
imageFile = sys.argv[1]
maxWidth = int(sys.argv[2])
maxHeight = int(sys.argv[3])
heightScale = float(sys.argv[4])


imgOrig = Image.open(imageFile)

imgWidth, imgHeight = imgOrig.size
newWidth = maxWidth
newHeight = maxHeight / heightScale
if imgWidth / imgHeight >= newWidth / newHeight:
    newHeight = newWidth * imgHeight / imgWidth
else:
    newWidth = imgWidth * newHeight / imgHeight

try:
    frame = 0
    while 1:
        nextFrame(imgOrig, frame, int(newWidth), int(newHeight * heightScale))
        frame += 1;
except EOFError:
    pass

