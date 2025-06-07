from flask import Flask, request, jsonify
from playwright.sync_api import sync_playwright
import time
from flask_cors import CORS
import random
import math

app = Flask(__name__)
CORS(app)

class Sistem_Analizi:
    def __init__(self):
        self.playwright = sync_playwright().start()
        self.browser = self.playwright.chromium.launch(headless=True)
        self.page = self.browser.new_page()
    
    def get_bus_info(self, sehir, durak_id):
        try:
            if sehir == "Ankara":
                return self.Ankara(durak_id)
            elif sehir == "Konya":
                return self.Konya(durak_id)
            elif sehir == "İzmir":
                return self.İzmir(durak_id)
            elif sehir == "Antalya":
                return self.Antalya(durak_id)
            elif sehir == "Bursa":
                return self.Bursa(durak_id)
            else:
                return "Geçersiz şehir"
        except Exception as e:
            return f"Hata oluştu: {str(e)}"
        finally:
            self.browser.close()
            self.playwright.stop()
    
    def Ankara(self, durak_id):
        self.page.goto("https://www.ego.gov.tr/otobusnerede")
        self.page.locator("xpath=//*[@id='durak_no']").fill(str(durak_id))
        self.page.locator("xpath=//*[@id='icsayfa-orta']/div[6]/div[1]/form/div[3]/input").click()
        self.page.wait_for_selector("xpath=//*[@id='icsayfa-orta']/div[6]/div[2]/table/tbody[2]")
        otobüsler = self.page.locator("xpath=//*[@id='icsayfa-orta']/div[6]/div[2]/table/tbody[2]").all()
        result = ""
        for i in otobüsler:
            result += i.text_content() + "\n"
        return result if result else "Sonuç bulunamadı"
        
    def Konya(self, durak_id):
        self.page.goto("https://atus.konya.bel.tr/atus/otobusum-nerede?")
        self.page.locator("xpath=//*[@id='select2-liste-container']").click()
        self.page.locator("xpath=/html/body/span/span/span[1]/input").fill(str(durak_id))
        self.page.locator("xpath=/html/body/span/span/span[1]/input").press("Enter")
        self.page.locator("xpath=/html/body/div[3]/div/div/div[2]/div[2]/div[3]/div/div[1]/div/button[2]").click()
        self.page.wait_for_selector("xpath=/html/body/div[3]/div/div/div[2]/div[2]/div[4]/table")
        otobüsler = self.page.locator("xpath=/html/body/div[3]/div/div/div[2]/div[2]/div[4]/table").all() 
        result = ""
        for i in otobüsler:
            result += i.text_content() + "\n"
        return result if result else "Sonuç bulunamadı"
    
    def İzmir(self, durak_id):
        self.page.goto("https://www.eshot.gov.tr/tr/OtobusumNerede/290")
        self.page.locator(f"xpath=//*[@id='{durak_id}']").click()
        self.page.wait_for_selector("xpath=//*[@id='mobile-jump']/div[2]/div[1]")
        otobüsler = self.page.locator("xpath=//*[@id='mobile-jump']/div[2]/div[1]").all()
        result = ""
        for i in otobüsler:
            result += i.text_content() + "\n"
        return result if result else "Sonuç bulunamadı"
 
    def Antalya(self, durak_id):
        self.page.goto("https://online.antalyakart.com.tr/#/home")
        element = self.page.wait_for_selector("xpath=/html/body/app-root/app-layout/div/div/mat-sidenav-container/mat-sidenav-content/main/div[1]/app-home/section/auto-complete/div")
        element.click()
        element = self.page.locator("xpath=/html/body/app-root/app-layout/div/div/mat-sidenav-container/mat-sidenav-content/main/div[1]/app-home/section/auto-complete/div/input").fill(str(durak_id))
        self.page.locator("xpath=/html/body/app-root/app-layout/div/div/mat-sidenav-container/mat-sidenav-content/main/div[1]/app-home/section/auto-complete/div/input").press("Enter")
        element = self.page.wait_for_selector("xpath=/html/body/app-root/app-layout/div/div/mat-sidenav-container/mat-sidenav-content/main/div[1]/app-search/div[2]/div/div/ul[2]/li")
        element.click()
        self.page.wait_for_selector("xpath=/html/body/app-root/app-layout/div/div/mat-sidenav-container/mat-sidenav-content/main/div[1]/app-bus-stop-detail/body/div/div/div[2]/div[4]/div/ul")
        otobüsler = self.page.locator("xpath=/html/body/app-root/app-layout/div/div/mat-sidenav-container/mat-sidenav-content/main/div[1]/app-bus-stop-detail/body/div/div/div[2]/div[4]/div/ul").all()
        result = ""
        for i in otobüsler:
            result += i.text_content() + "\n"
        return result if result else "Sonuç bulunamadı"
        
    def Bursa(self, durak_id):
        self.page.goto("https://www.bursakart.com.tr/wheremybus")
        element = self.page.wait_for_selector("xpath=/html/body/app-root/app-wheremybus/div[1]/section/div/div/div/div[1]/div")
        element.click()
        self.page.locator("xpath=//*[@id='mat-input-0']").fill(str(durak_id))
        self.page.wait_for_selector("xpath=//*[@id='mat-option-6553']/div").click()
        self.page.wait_for_selector("xpath=/html/body/app-root/app-wheremybus/div[1]/section/div/div/div/div[1]/div/div[3]/div/div[2]/div[1]")
        otobüsler = self.page.locator("xpath=/html/body/app-root/app-wheremybus/div[1]/section/div/div/div/div[1]/div/div[3]/div").all()
        result = ""
        for i in otobüsler:
            result += i.text_content() + "\n"
        return result if result else "Sonuç bulunamadı"

@app.route('/bus_info', methods=['POST'])
def bus_info():
    data = request.json
    sehir = data.get('sehir')
    durak_id = data.get('durak_id')
    
    if not sehir or not durak_id:
        return jsonify({"error": "Şehir ve durak ID'si gereklidir"}), 400
    
    sistem = Sistem_Analizi()
    result = sistem.get_bus_info(sehir, durak_id)
    
    return jsonify({"result": result})


DURAKLAR = {
    "Ankara": [
        {"adi": "Kızılay", "lat": 39.9208, "lng": 32.8541},
        {"adi": "Ulus", "lat": 39.9417, "lng": 32.8560},
        {"adi": "Sıhhiye", "lat": 39.9337, "lng": 32.8597},
    ],
    "Konya": [
        {"adi": "Zafer", "lat": 37.8719, "lng": 32.4846},
        {"adi": "Otogar", "lat": 37.9406, "lng": 32.5322},
        {"adi": "Alaaddin", "lat": 37.8715, "lng": 32.4845},
    ],
    "İzmir": [
        {"adi": "Konak", "lat": 38.4192, "lng": 27.1287},
        {"adi": "Alsancak", "lat": 38.4322, "lng": 27.1384},
        {"adi": "Bornova", "lat": 38.4592, "lng": 27.2222},
    ],
    "Antalya": [
        {"adi": "Meydan", "lat": 36.8969, "lng": 30.6954},
        {"adi": "Otogar", "lat": 36.9081, "lng": 30.6848},
        {"adi": "MarkAntalya", "lat": 36.8902, "lng": 30.7026},
    ],
    "Bursa": [
        {"adi": "Heykel", "lat": 40.1840, "lng": 29.0624},
        {"adi": "Kent Meydanı", "lat": 40.2100, "lng": 29.0600},
        {"adi": "Terminal", "lat": 40.2552, "lng": 29.0094},
    ],
}

def haversine(lat1, lng1, lat2, lng2):
    R = 6371.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi/2)*2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)*2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    return R * c

@app.route('/nearby_stops', methods=['POST'])
def nearby_stops():
    data = request.json
    sehir = data.get('sehir')
    lat = data.get('latitude')
    lng = data.get('longitude')

    if not sehir or lat is None or lng is None:
        return jsonify({"error": "Şehir ve konum gereklidir"}), 400

    duraklar = DURAKLAR.get(sehir)
    if not duraklar:
        return jsonify({"error": "Şehir için durak verisi yok"}), 404

    min_dist = float('inf')
    en_yakin = None
    for durak in duraklar:
        dist = haversine(lat, lng, durak["lat"], durak["lng"])
        if dist < min_dist:
            min_dist = dist
            en_yakin = durak

    if en_yakin:
        return jsonify({
            "durak_adi": en_yakin["adi"],
            "latitude": en_yakin["lat"],
            "longitude": en_yakin["lng"]
        })
    else:
        return jsonify({"error": "Durak bulunamadı"}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)