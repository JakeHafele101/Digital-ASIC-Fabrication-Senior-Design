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
property LEFclass CORE
property LEFsource USER

ext2spice lvs
ext2spice -d

lef write ../lef/{self.name}.lef
gds write ../gds/{self.name}.gds
save DFF
extract
ext2spice

select

box values 0 0 {self.bbox[0]*2} {self.bbox[1]*2}
drc why
"""


class Rect:
    def __init__(self, layer, x=None, y=None, x2=None, y2=None, cx=None, cy=None, w=None, h=None):
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
        return f"""
box values {self.box[0]} {self.box[1]} {self.box[2]} {self.box[3]}
paint {self.layer}
after {ANIMATION_DELAY}
"""


SIGNAL = "signal"
POWER = "power"
GROUND = "ground"

INPUT = "input"
OUTPUT = "output"
BIDIR = "bidirectional"


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
"""


class Group:
    def __init__(self, *items):
        self.items = list(items)

    def append(self, *items):
        self.items.extend(items)

    def shift(self, dx, dy):
        for item in self.items:
            item.shift(dx, dy)
        return self

    def clone(self):
        return Group([item.clone() for item in self.items])

    def __str__(self):
        return ''.join((str(item) for item in self.items))

C = 17
METALW = 20

def Conn(layer, x, y, tall=False):
    cy = C*2 if tall else C
    return Group(
        Rect(layer, cx=x, cy=y, w=C, h=cy),
        Rect('viali', cx=x, cy=y, w=C, h=cy),
    )


HEIGHT = 272 * 2
WIDTH = 138 * 8
MH = HEIGHT/2
MW = WIDTH/2

OVERX = 10
OVERY = 10
NWELLY = HEIGHT - 140
NMR = 27
LIR = NMR - 8
NDIFFR = C/2

PTRANH = 42
NTRANH = 42
PDY = HEIGHT - 38 - (PTRANH/2)
PDY2 = PDY + (PTRANH/2)
PDY3 = PDY - (PTRANH/2)
PPCY = PDY3-49+(C/2)+8

NDY = 38 + (NTRANH/2)
NDY2 = NDY - (NTRANH/2)
NDY3 = NDY + (NTRANH/2)
NPCY = NDY3+49-(C/2)-8

CONW = 1


def pvcc(x):
    return Group(
        Rect('pdiff', cx=x, cy=PDY, w=40, h=PTRANH),
        Rect('locali', cx=x, y=HEIGHT-LIR, w=C, y2=PDY-C),
        Rect('pdc', cx=x, cy=PDY, w=C, h=C),
    )


def plocali(x, y):
    return Group(
        Rect('pdiff', cx=x, cy=PDY, w=40, h=PTRANH),
        Rect('locali', cx=x, cy=PDY, w=C, h=C+16),
        Rect('pdc', cx=x, cy=PDY, w=C, h=C),
        Rect('viali', cx=x, cy=PDY, w=C, h=C),
        Rect('metal1', cx=x, cy=PDY, w=26, h=30),
        Rect('metal1', cx=x, y=y, w=METALW, y2=PDY+C),
    )


def ppoly(x, y):
    return Group(
        Rect('pdiff', cx=x, cy=PDY, w=40, h=PTRANH),
        Rect('poly', cx=x, y=PDY2+13, w=28, y2=PPCY-C/2-8),
        Rect('pc', cx=x, cy=PPCY, w=C, h=C),
        Rect('locali', cx=x, cy=PPCY, w=26, h=C+16),
        Rect('viali', cx=x, cy=PPCY, w=C, h=C),
        Rect('metal1', cx=x, cy=PPCY, w=26, h=30),
        Rect('metal1', cx=x, y=PPCY+C/2+8, w=METALW, y2=y),
    )

def nvss(x):
    return Group(
        Rect('ndiff', cx=x, cy=NDY, w=40, h=NTRANH),
        Rect('locali', cx=x, y=LIR, w=C, y2=NDY+C),
        Rect('ndc', cx=x, cy=NDY, w=C, h=C),
    )

def nlocali(x, y):
    return Group(
        Rect('ndiff', cx=x, cy=NDY, w=40, h=NTRANH),
        Rect('locali', cx=x, cy=NDY, w=C, h=C+16),
        Rect('ndc', cx=x, cy=NDY, w=C, h=C),
        Rect('viali', cx=x, cy=NDY, w=C, h=C),
        Rect('metal1', cx=x, cy=NDY, w=26, h=30),
        Rect('metal1', cx=x, y=y, w=METALW, y2=NDY-C),
    )


def npoly(x, y):
    return Group(
        Rect('ndiff', cx=x, cy=NDY, w=40, h=NTRANH),
        Rect('poly', cx=x, y=NDY2-13, w=28, y2=NPCY+C/2+8),
        Rect('pc', cx=x, cy=NPCY, w=C, h=C),
        Rect('locali', cx=x, cy=NPCY, w=26, h=C+16),
        Rect('viali', cx=x, cy=NPCY, w=C, h=C),
        Rect('metal1', cx=x, cy=NPCY, w=26, h=30),
        Rect('metal1', cx=x, y=NPCY-C/2-8, w=METALW, y2=y),
    )

METAL1, METAL2, METAL3, METAL4, METAL5 = range(5)
METAL = [
    ('metal1', 'via'),
    ('metal2', 'via1'),
    ('metal3', 'via2'),
    ('metal4', 'via3'),
    ('metal5'),
]

def bar(id, x1, x2, y):
    return Rect(METAL[id][0], x=x1-METALW/2, cy=y, x2=x2+METALW/2, h=METALW)

def via(id, x, y):
    if id < 1: return
    return Group(
        Rect(METAL[id-1][0], cx=x, cy=y, w=26, h=32),
        Rect(METAL[id][0], cx=x, cy=y, w=26, h=32),
        Rect(METAL[id][1], cx=x, cy=y, w=26, h=26)
    )

def bridge(id1, id2, y, xs):
    group = Group(bar(id2, min(xs), max(xs), y))
    for x in xs:
        for i in range(max(id1,1), id2+1):
            group.append(via(i, x, y))
    return group

def spread(dx, dy, *items):
    return Group(*[item.shift(dx*i, dy*i) for i, item in enumerate(items)])

B0 = PPCY
B1 = PPCY - 48
B2 = PPCY - 96
B3 = PPCY - 154
BN0 = NPCY
BN1 = NPCY + 48
BN2 = NPCY + 96

cell = Cell("DFF", WIDTH, HEIGHT)
cell.append(
    Rect('nwell', -OVERX, NWELLY, WIDTH + OVERX, HEIGHT + NMR),

    # VPWR row
    Rect('metal1', -OVERX, HEIGHT - NMR, WIDTH + OVERX, HEIGHT + NMR),
    Rect('locali', -OVERX, HEIGHT - LIR, WIDTH + OVERX, HEIGHT + LIR),
    Rect('nnd', 8, HEIGHT - NDIFFR, WIDTH - 8, HEIGHT + NDIFFR),
    *[Conn('nsc', 29 + ((WIDTH-58)/29)*i, HEIGHT) for i in range(30)],

    Port('VPWR', POWER, BIDIR, 'locali', 8, HEIGHT - NDIFFR, WIDTH - 8, HEIGHT + NDIFFR),

    # VGND row
    Rect('metal1', -OVERX, 0 - NMR, WIDTH + OVERX, 0 + NMR),
    Rect('locali', -OVERX, 0 - LIR, WIDTH + OVERX, 0 + LIR),
    Rect('ppd', 8, 0 - NDIFFR, WIDTH - 8, 0 + NDIFFR),
    *[Conn('psc', 29 + ((WIDTH-58)/29)*i, 0) for i in range(30)],

    Port('VGND', POWER, BIDIR, 'locali', 8, -NDIFFR, WIDTH - 8, NDIFFR),
    Port('CLK', SIGNAL, INPUT, 'metal1', cx=80, cy=B2, w=METALW, h=METALW),
    Port('D', SIGNAL, INPUT, 'metal1', cx=160, cy=BN2, w=METALW, h=METALW),
    Port('Q', SIGNAL, OUTPUT, 'metal1', cx=1320, cy=BN2, w=METALW, h=METALW),
    
    # NMOS
    # plocali(25, NDY),

    plocali(40, NDY),
    ppoly(80, NPCY),
    pvcc(120),
    ppoly(160, NPCY),
    plocali(200, NDY),
    ppoly(240, B0),
    plocali(280, B0),

    pvcc(360),
    ppoly(400, NPCY),
    plocali(440, NDY),

    plocali(520, NDY),
    ppoly(560, B1),
    plocali(600, NDY),
    ppoly(640, NPCY),
    pvcc(680),

    plocali(760, NDY),
    ppoly(800, B1),
    plocali(840, B0),

    pvcc(920),
    ppoly(960, NPCY),
    plocali(1000, NDY),

    plocali(1080, NDY),
    ppoly(1120, B0),
    plocali(1160, NDY),
    ppoly(1200, NPCY),
    pvcc(1240),
    ppoly(1280, B0),
    plocali(1320, NDY),

    
    


    nlocali(40, PDY),
    npoly(80, PPCY),
    nvss(120),
    npoly(160, PPCY),
    nlocali(200, PDY),
    npoly(240, BN1),
    nlocali(280, BN0),

    nvss(360),
    npoly(400, PPCY),
    nlocali(440, PDY),

    nlocali(520, PDY),
    npoly(560, BN0),
    nlocali(600, PDY),
    npoly(640, PPCY),
    nvss(680),

    nlocali(760, PDY),
    npoly(800, BN0),
    nlocali(840, BN0),

    nvss(920),
    npoly(960, PPCY),
    nlocali(1000, PDY),

    nlocali(1080, PDY),
    npoly(1120, BN1),
    nlocali(1160, PDY),
    npoly(1200, PPCY),
    nvss(1240),
    npoly(1280, BN0),
    nlocali(1320, PDY),

    bar(METAL1, 280, 400, BN0),
    bar(METAL1, 640, 760, BN0),
    bar(METAL1, 840, 960, BN0),
    bar(METAL1, 1200, 1280, BN0),
    bridge(METAL1, METAL2, BN0, [80, 560, 800]),
    bridge(METAL1, METAL2, BN1, [40, 240, 1120]),

    bar(METAL1, 280, 400, B0),
    bar(METAL1, 640, 760, B0),
    bar(METAL1, 840, 960, B0),
    bar(METAL1, 1200, 1280, B0),
    bridge(METAL1, METAL2, B0, [80, 240, 1120]),
    bridge(METAL1, METAL2, B1, [40, 560, 800]),
    bridge(METAL1, METAL2, B2, [400, 520]),
    bridge(METAL1, METAL2, B3, [440, 640, 760]),
    bridge(METAL1, METAL2, B2, [960, 1080]),
    bridge(METAL1, METAL2, B3, [1000, 1200]),

)


cell.save()
