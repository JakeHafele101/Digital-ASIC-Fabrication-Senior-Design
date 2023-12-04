ANIMATION_DELAY=0

class Cell:
    def __init__(self, name, width, height):
        self.name = name
        self.bbox = (width, height)
        self.items = []

    def append(self, *items):
        self.items.extend(items)

    def save(self):
        with open(self.name + ".tcl", "w") as file:
            file.write(str(self))

    def __str__(self):
        return f"""
select
erase

property FIXED_BBOX {{0 0 {self.bbox[0]*2} {self.bbox[1]*2}}}

{''.join((str(item) for item in self.items))}

property LEFsite unithd
property LEForigin "0 0"
property LEFclass BLOCK
property LEFsource USER

ext2spice lvs
ext2spice -d

save {self.name}
lef write ../lef/{self.name}.lef
gds write ../gds/{self.name}.gds
extract
ext2spice

select

box values 0 0 {self.bbox[0]*2} {self.bbox[1]*2}
drc why
"""


class Rect:
    def __init__(self, layers, x=None, y=None, x2=None, y2=None, cx=None, cy=None, w=None, h=None):
        if x == None:
            x = cx - (w/2)
        if y == None:
            y = cy - (h/2)
        if x2 == None:
            x2 = x + w
        if y2 == None:
            y2 = y + h

        self.box = (x, y, x2, y2)
        self.layers = (layers,) if isinstance(layers, str) else layers

    def clone(self):
        return Rect(self.layer, *self.box)

    def shift(self, dx, dy):
        self.box = (
            self.box[0] + dx,
            self.box[1] + dy,
            self.box[2] + dx,
            self.box[3] + dy)
        return self

    def __str__(self):
        layers = '\n'.join(f'paint {layer}' for layer in self.layers)
        return f"""
box values {self.box[0]} {self.box[1]} {self.box[2]} {self.box[3]}
{layers}
after {ANIMATION_DELAY}
"""



SIGNAL = "signal"
POWER = "power"
GROUND = "ground"

INPUT = "input"
OUTPUT = "output"
BIDIR = "bidirectional"


STROKE=3200
WIDTH=STROKE * 23
HEIGHT=STROKE * 14

class Path:
    def __init__(self, layer, *points):
        self.rects = []

        points = [((point[0]+1)*STROKE,(point[1]+1)*STROKE) for point in points]

        last = points[0]

        if len(points) == 1:
            self.rects.append(Rect(layer, cx=last[0], cy=last[1], w=STROKE, h=STROKE))

        for point in points[1:]:
            # Horizontal
            if point[1] == last[1]:
                self.rects.append(Rect(layer, cx=(point[0]+last[0])/2, cy=point[1], w=abs(point[0] - last[0]) + STROKE, h=STROKE))
            # Vertical
            else:
                self.rects.append(Rect(layer, cx=point[0], cy=(point[1]+last[1])/2, w=STROKE, h=abs(point[1] - last[1]) + STROKE))
            last = point

    def __str__(self):
        return ''.join(str(r) for r in self.rects)

class Port:
    def __init__(self, label, type, dir, layer, x=None, y=None, x2=None, y2=None, cx=None, cy=None, w=None, h=None):
        if x == None:
            x = cx - (w/2)
        if y == None:
            y = cy - (h/2)
        if x2 == None:
            x2 = x + w
        if y2 == None:
            y2 = y + h

        self.box = (x, y, x2, y2)
        self.layer = layer
        self.label = label
        self.type = type
        self.dir = dir

    def shift(self, dx, dy):
        self.box = (
            self.box[0] + dx,
            self.box[1] + dy,
            self.box[2] + dx,
            self.box[3] + dy)
        return self

    def clone(self):
        return Port(self.label, self.type, self.dir, self.layer, *self.box)

    def __str__(self):
        return f"""
box values {self.box[0]} {self.box[1]} {self.box[2]} {self.box[3]}
after {ANIMATION_DELAY}
label {self.label} FreeSans 15 0 0 0 center {self.layer}
port make n e s w
port use {self.type}
port class {self.dir}
port shape abutment
"""


LAYERS = ('metal1', 'metal2', 'metal3', 'metal4')
cell = Cell("SIGN", WIDTH, HEIGHT)
cell.append(

    # GL
    Path(LAYERS, (4, 5), (1, 5), (1, 1), (4, 1), (4, 3), (3, 3)),
    Path(LAYERS, (6, 5), (6, 1), (9,1)),

    # JH
    Path(LAYERS, (1, 11), (4, 11), (3, 11), (3, 7), (1, 7), (1, 8)),
    Path(LAYERS, (6, 11), (6, 7)),
    Path(LAYERS, (9, 11), (9, 7)),
    Path(LAYERS, (6, 9), (9, 9)),

    # WG
    Path(LAYERS, (12, 11), (12, 7.5)),
    Path(LAYERS, (15, 11), (15, 7.5)),
    Path(LAYERS, (13.5, 9), (13.5, 7.5)),
    Path(LAYERS, (12.5, 7), (14.5, 7)),
    Path(LAYERS, (20, 11), (17, 11), (17, 7), (20, 7), (20, 9), (19, 9)),

    # CB
    Path(LAYERS, (15, 5), (12, 5), (12, 1), (15, 1)),
    Path(LAYERS, (19, 5), (17, 5), (17, 1), (19, 1)),
    Path(LAYERS, (17, 3), (19, 3)),
    Path(LAYERS, (20, 4.5), (20, 1.5)),

    Rect('metal4', cx=400, y=400, w=310, y2=HEIGHT-400),
    Rect('metal4', cx=WIDTH-400, y=400, w=310, y2=HEIGHT-400),
    Port('vssd1', GROUND, BIDIR, 'metal4', cx=400, y=400, w=310, y2=HEIGHT-400),
    Port('vccd1', POWER, BIDIR, 'metal4', cx=WIDTH-400, y=400, w=310, y2=HEIGHT-400)
)


cell.save()
