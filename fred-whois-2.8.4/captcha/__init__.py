#!/usr/bin/python
# PersistentFactory is used in whois module in function Whois.getFactory()
from fred_whois.CaptchaWhois.Visual import Text, Backgrounds, Distortions, ImageCaptcha
from fred_whois.CaptchaWhois import Words,  PersistentFactory
import random
import string

def randomKey(size = 10):
    lowercase = list(string.lowercase)
    lowercase.pop(lowercase.index('o'))
    lowercase.pop(lowercase.index('g'))
    lowercase.pop(lowercase.index('l'))
    uppercase = list(string.uppercase)
    uppercase.pop(uppercase.index('O'))
    digits = list(string.digits)
    digits.pop(digits.index('1'))
    digits.pop(digits.index('9'))
    digits.pop(digits.index('0'))
    all = lowercase + digits
    random.seed()
    random.shuffle(all)
    rnd = ""
    for i in range(size):
        rnd = "%s%s" % (rnd, random.choice(all))
    return rnd

def HSBtoRGB(H, S, V):
    'Convert HSB to RGB and returns string #rrggbb.'
    
    H = H % 360
    S = S % 100
    V = V % 100
    
    h = H/60.0
    s = S/100.0
    v = V/100.0
    if s == 0:
        R = G = B = v*255 
    else:
        i = int(h)
        p = v * (1 - s)
        q = v * (1 - s * (h-i))
        t = v * (1 - s * (1-(h-i)))
        if i == 0:
            r,g,b = v,t,p
        elif i == 1:
            r,g,b = q,v,p
        elif i == 2:
            r,g,b = p,v,t
        elif i == 3:
            r,g,b = p,q,v
        elif i == 4:
            r,g,b = t,p,v
        elif i == 5:
            r,g,b = v,p,q
        elif i == 6:
            r,g,b = v,p,q

        R, G, B = r*255, g*255, b*255

    return '#%02x%02x%02x' % (R, G, B)

class NicGimpy(ImageCaptcha):
    """A relatively easy CAPTCHA that's somewhat easy on the eyes
       modified for random strings
    """
    def getLayers(self, size = 10):
        word = randomKey(size = size)
        self.addSolution(word)

        H, S, B = random.randint(0, 360), random.randint(50, 70), random.randint(80, 99)

        back        = HSBtoRGB(H, S, B)
        front       = HSBtoRGB(H+40, S, B) # near color
        border      = HSBtoRGB(H+60, S, B) # near color
        font_front  = HSBtoRGB(H+random.randint(170, 190), S+10, B) # inverted color
        font_border = HSBtoRGB(H, 100, random.randint(0, 99))

        gridSize = random.randint(7,18)
        dotSize = gridSize + 3
        return [
            random.choice([
                [Backgrounds.SolidColor(color=back), Backgrounds.Grid(size=gridSize, foreground=front)],
                [Backgrounds.SolidColor(color=border), Backgrounds.RandomDots(dotSize=dotSize, colors=(front, back))],
            ]),
            Text.TextLayer("  %s  " % word, borderSize=1, textColor=font_front, borderColor=font_border),
            Distortions.SineWarp(),
            ]

