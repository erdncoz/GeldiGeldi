# GeldiGeldi
# 🚍 GeldiGeldi - Otobüs Takip Uygulaması / Bus Tracking App

![Flutter](https://img.shields.io/badge/Flutter-3.13-blue?logo=flutter)
![Python](https://img.shields.io/badge/Python-3.10%2B-yellow?logo=python)
![Playwright](https://img.shields.io/badge/Playwright-1.35-green?logo=playwright)

## 📌 GeldiGeldi, gerçek zamanlı otobüs konumu sunan ve 5 büyük şehirde (Ankara, Konya, İzmir, Bursa, Antalya) çalışan mobil bir uygulamadır. / GeldiGeldi is a real-time bus tracking app that works in 5 major cities (Ankara, Konya, Izmir, Bursa, Antalya).

## ✨ Özellikler / Features
- 🏙️ 5 Şehir Desteği / 5 City Support  
- ⭐ Favori Duraklar: Sık kullandığınız durakları kaydedin / Favorite Stops: Save frequently used stops  
- 📊 En Çok Aranan Duraklar: İstatistiksel analiz / Most Searched Stops: Analytics of popular stops  
- 📍 Yakındaki Duraklar: Konum bazlı durak gösterimi / Nearby Stops: Show stops based on your location  
- 📱 iOS ve Android Desteği / iOS and Android Support  

## 🛠 Kurulum / Setup

### 🔧 Gereksinimler / Requirements  
- Flutter SDK 3.13+  
- Python 3.10+  
- pip  
- Playwright → `pip install playwright && playwright install`  

### 🖥️ Backend Başlatma / Starting Backend

```bash
cd backend
pip install -r requirements.txt
playwright install
python app.py


Backend http://localhost:5000 adresinde çalışır / runs at http://localhost:5000

Flutter Uygulaması Başlatma / Starting Flutter App
cd flutter_app
flutter pub get
flutter run

POST /bus_info → Durak numarasına göre otobüs bilgisini getirir / Returns bus info by stop ID

{
  "sehir": "Ankara",
  "durak_id": "1234"
}

