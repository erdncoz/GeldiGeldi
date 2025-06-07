
"""
    YAPAY ZEKA 
Yapay zekanın amacı normal olarak insan zeaksını gerektiren görevleri yapabilecek makineler yapmaktır. yayap zeka Bilgisyarları akıllı yapama bilimidir.Hem pc leri daha fayadalı hale gtilmeke isteyenler hemde
zekanın doğasını anakamak isteyenler tarafından uygulanamatadır.Zekanın doğası ile ilgili olaaların amacı zekayı taklit etme değil proglamı zeki hale getilmektir.Tüm bu tanımları farklığından hareketle yapay zekanın
iki temel yapıyla ilgili olduğu söylenebilir.Bunlarandan birincisi zekanın ne olduğu anlaşılabilmesi insan düşünce sürecinin anlaışılması,ikğncisi ise bu süerecin pcler ,robotlar ve bunun gibi aracılığla somutlaştırılmasıdır
  
YAPAY ZEKANIN AMAÇLARI 
Genel Olarak yapay zekanın amaçlarını 3 ana baslık altında toplayabiliriz.
1-)Zekanın ne olduğubu analamak
2_)Makineleri daha akıllı hale getilmek
3-)Makinelerşi daha faydalı hale getilmek
Bu noktada makinleer için akıllı davarnısın tanımı ortaya koymak gelekmektedir bir çok davaranıs türü zekanın işaretleri olarak kabul ediloebilir.
ör.
1.Tecrübelerden öğrenme ve anlama
2.Karışık mesajlaradan anlam çıkarma
3.Yeni bir duruma başarılı ve çabuk bir şekilde crvap verme
4.Problemelrin çözümümde muakkeme yeteneğini kullanma
5.Bişgiyi anlama ve kullanama
6.Alışık olunmayan şaşırtıcı durumların üstesinden gelebilme
7.Düşünme ve muakkeme yeteneği

YAPAY ZEKA VE İNSAN ZEKASININ KARŞILIŞTIRILMASI
Yapay zeka daha fazla kalıcıdır.
2.Yapay zeka kolaylıkla koplalanabilir
3.Yapay zeka doğal zekadan daha ucuza elde edilebilir
4.Yapay zeka bir pc teknolojisi olarak bütünüyle tutarlıdır.
5.Yapay zeka dökümante edilebilir
6.Doğal zeka yaratıcı ve doğulgandır
7.Doğal zeka insanlara duyuları yolu ile öğrendiği 
8.Doğal zeka avantajşarının en önemlsi insan muakeme gücününün problemelriçözmek için geniş tecrğbelere,karşılaşılan konuya göre hemen kullanma yeteneğidir.

DERİN ÖĞRENME 
Öğlenme nesilden nesile yazılan ve bilgiler vasıtasıyla gerçekleşen bri kavramdır.
Makine öğlenimi veriden öğreline modellerin tasalanması analiz edilmesi ve tahmin için ekili algoritmaların geliştirmesiyele ilgilenilmektedir makine öğlenimi algoritmalara bağlı istatislik,örüntü tanıma,sinyal ve dil işleme,bilgiysayar dili,
veri madenciliği,endüstürü,sağlık gibi pek çok alanda kullanılmaktadır
          """


"""import turtle
import time

# Ekranı oluştur
pencere = turtle.Screen()
pencere.bgcolor("white")
time.sleep(1)
# Kalp çizimi için kalem
kalem = turtle.Turtle()
kalem.hideturtle()
kalem.speed(3)
kalem.color("red", "red")

# Kalp çizimi
kalem.penup()
kalem.goto(0, -100)
kalem.pendown()
kalem.begin_fill()
kalem.left(140)
kalem.forward(180)
kalem.circle(-90, 200)
kalem.left(120)
kalem.circle(-90, 200)
kalem.forward(180)
kalem.end_fill()

# "Ş" harfini tam ortaya yerleştir
yazi = turtle.Turtle()
yazi.hideturtle()
yazi.penup()
yazi.color("black")
yazi.goto(0, -20)  # merkeze yerleştir
yazi.write("Ş", align="center", font=("Arial", 40, "bold"))

# Pencereyi açık tut
pencere.mainloop()
"""
from PIL import Image, ImageDraw, ImageFont
import math

# Görsel boyutu
width, height = 800, 600
image = Image.new("RGB", (width, height), "white")
draw = ImageDraw.Draw(image)

# Kalbin merkezi
center_x = width // 2
center_y = height // 2 + 50  # biraz aşağı kaydırdık

# Kalp çizimi (matematiksel formülle)
scale = 20
for t in range(0, 360):
    t_rad = math.radians(t)
    x = scale * 16 * math.sin(t_rad) ** 3
    y = -scale * (13 * math.cos(t_rad) - 5 * math.cos(2*t_rad) -
                  2 * math.cos(3*t_rad) - math.cos(4*t_rad))

    draw.ellipse(
        (center_x + x - 3, center_y + y - 3,
         center_x + x + 3, center_y + y + 3),
        fill="red"
    )

# Font ayarları
try:
    font = ImageFont.truetype("arial.ttf", 150)
except:
    font = ImageFont.load_default()

# "Ş" harfini ortala
text = "Ş"
text_width, text_height = draw.textsize(text, font=font)
text_x = center_x - text_width // 2
text_y = center_y - text_height // 2

draw.text((text_x, text_y), text, font=font, fill="black")

# Görseli kaydet ve göster
image.show()
image.save("yaratıcı_kalp.png")
