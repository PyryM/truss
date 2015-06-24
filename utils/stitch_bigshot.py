import sys
import cv2
import numpy as np

# stitches together tiled screenshots into one large screenshot

def create_fn(base, x, y):
    return "{}{}x{}.png".format(base, y, x)

def infer_size(fn):
    print(fn)
    img = cv2.imread(fn)
    return img.shape

def insert_image(fn, dest, col, imwidth, row, imheight):
    xpos0 = imwidth * col
    xpos1 = xpos0 + imwidth
    ypos0 = imheight * row
    ypos1 = ypos0 + imheight
    im = cv2.imread(fn)
    dest[ypos0:ypos1, xpos0:xpos1, :] = im

def main():
    basefn = sys.argv[1]
    cols = int(sys.argv[2])
    rows = int(sys.argv[3])
    destfn = sys.argv[4]
    imsize = infer_size(create_fn(basefn, 0, 0))
    imw = imsize[1]
    imh = imsize[0]
    print("Src image size: {}".format(str(imsize)))
    destwidth = cols * imsize[1]
    destheight = rows * imsize[0]
    destimage = np.zeros((destheight, destwidth, 3), dtype=np.uint8)
    for row in range(rows):
        for col in range(cols):
            insert_image(create_fn(basefn, rows - row - 1, col), destimage, 
                         col, imw, row, imh)
    cv2.imwrite(destfn, destimage)

if __name__ == '__main__':
    main()