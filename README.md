# Walkie Talkie App 📻

Flutter ile geliştirilmiş modern bir walkie talkie uygulaması. Anında sesli iletişim sağlar.

## ✨ Özellikler

- 🎤 **Push-to-Talk (PTT)**: Telsiz tecrübesi için butonuna bas ve konuş
- 🏠 **Oda Sistemi**: Farklı odalar oluştur ve katıl
- 👥 **Çoklu Kullanıcı**: Aynı odada birden fazla kişi
- 🎨 **Modern UI**: Koyu tema ve kullanıcı dostu arayüz
- 📱 **Çoklu Platform**: Android, iOS, Web, Windows, macOS, Linux
- 🔊 **Sesli Mesajlar**: Kaydet, gönder ve dinle
- ⚡ **Gerçek Zamanlı**: Anında iletişim

## 🛠️ Kullanılan Teknolojiler

- **Flutter**: UI framework
- **Provider**: State management
- **flutter_sound**: Ses kaydetme/çalma
- **socket_io_client**: Gerçek zamanlı iletişim (gelecekte)
- **permission_handler**: İzin yönetimi
- **uuid**: Unique ID'ler için

## 🚀 Kurulum

### Gereksinimler
- Flutter 3.24.4 veya üzeri
- Dart 3.5.4 veya üzeri

### Adımlar
1. Repository'yi klonlayın:
```bash
git clone <repository-url>
cd walkie_talkie_app
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. Uygulamayı çalıştırın:
```bash
# Web için
flutter run -d chrome

# Android için
flutter run -d android

# iOS için
flutter run -d ios
```

## 📱 Kullanım

1. **Giriş**: Uygulamayı açın ve adınızı girin
2. **Oda Seçimi**: Mevcut bir odaya katılın veya yeni oda oluşturun
3. **Konuşma**: Sarı butona basılı tutarak konuşun, bırakınca mesaj gönderilir
4. **Dinleme**: Gelen sesli mesajları otomatik olarak duyun

## 🎯 Özellik Detayları

### Push-to-Talk Sistemi
- **Bas ve Konuş**: Sarı butona basılı tutarak konuş
- **Bırak ve Gönder**: Parmağınızı çekince mesaj gönderilir
- **Görsel Geri Bildirim**: Konuşma sırasında animasyonlar
- **Haptic Feedback**: Dokunsal geri bildirim

### Oda Yönetimi
- **Oda Oluşturma**: + butonuna tıklayarak yeni oda açın
- **Katılım**: Mevcut odalara tek tıkla katılın
- **Katılımcı Listesi**: Odadaki kullanıcıları görün
- **Online Durumu**: Kimler aktif görebilin

### Sesli Mesajlar
- **Otomatik Çalma**: Gelen mesajlar otomatik çalar
- **Görsel Dalga**: Ses dalgası animasyonu
- **Zaman Damgası**: Mesaj gönderim zamanı
- **Gönderen Bilgisi**: Kim gönderdi görebilme

## 🎨 UI/UX Özellikleri

- **Koyu Tema**: Modern ve göze rahat tasarım
- **Gradient Arka Planlar**: Güzel görsel efektler
- **Animasyonlar**: Yumuşak geçişler ve etkileşimler
- **Responsive Design**: Tüm ekran boyutlarına uyumlu
- **İkonlar**: Anlaşılır ve modern ikonlar

## 🔧 Geliştirme Notları

### Mimari
```
lib/
├── main.dart              # Uygulama giriş noktası
├── models/               # Veri modelleri
│   ├── room.dart         # Oda modeli
│   ├── user.dart         # Kullanıcı modeli
│   └── audio_message.dart # Ses mesajı modeli
├── providers/            # State management
│   ├── room_provider.dart # Oda yönetimi
│   └── audio_provider.dart # Ses işlemleri
├── screens/              # Ana ekranlar
│   ├── home_screen.dart  # Ana sayfa
│   └── room_screen.dart  # Oda ekranı
├── widgets/              # Yeniden kullanılabilir bileşenler
│   ├── talk_button.dart  # Konuşma butonu
│   └── message_list.dart # Mesaj listesi
└── services/             # Harici servisler (gelecekte)
```

### Gelecek Geliştirmeler
- [ ] Gerçek Socket.IO sunucusu entegrasyonu
- [ ] Kullanıcı profilleri
- [ ] Oda şifreleri
- [ ] Mesaj geçmişi
- [ ] Push bildirimleri
- [ ] Ses kalitesi ayarları
- [ ] Tema seçenekleri

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 📞 İletişim

Sorularınız için issue açabilir veya email gönderebilirsiniz.

---

Made with ❤️ using Flutter
