# Kurulum rehberi (yalnızca bakımcı için)

Bu dosyayı repoda tutabilir ya da silebilirsin. Sıra önemli: **önce 0-2, sonra 3**.

## 0. Checksum'ları doldur (yerel, 1 dk)

`PKGBUILD` içindeki üç checksum bilerek sıfırlarla geliyor. Doldurmadan build hata verir.

```bash
cd vr-cyberdeck-bin
./scripts/update-pkgbuild.sh        # gerekli: curl, python3
git diff PKGBUILD
```

Kontrol: ilk sha256 (AppImage), eski PKGBUILD'daki değerle aynı olmalı:
`f09917e38c5aacb80a7986069c799b652696cc85055637f1ed55c7bf895c015c`.
Farklıysa durma ve nedenini araştır.

Script "upstream LICENSE is not GPL-3.0" derse upstream'in `LICENSE` dosyasını aç ve
`PKGBUILD` içindeki `license=` alanını (ve `prepare()` içindeki kontrolü) ona göre düzelt.

İsteğe bağlı yerel deneme: `makepkg -f && namcap *.pkg.tar.zst`

## 1. İmza anahtarı oluştur (yerel)

Bu anahtar yalnızca bu repo içindir. CI kullanacağı için **parolasız** olmalı.

```bash
gpg --batch --passphrase '' --quick-generate-key \
  "vr-cyberdeck-bin repo <maxwell523452@users.noreply.github.com>" ed25519 sign never

FPR="$(gpg --list-secret-keys --with-colons | awk -F: '/^fpr:/{print $10; exit}')"
echo "$FPR"

# README'deki yer tutucuyu doldur
sed -i "s/YOUR_FINGERPRINT_HERE/$FPR/g" README.md

# GitHub secret'a yapıştıracağın özel anahtar (BEGIN...END satırları dahil)
gpg --armor --export-secret-keys "$FPR"
```

Özel anahtarın bir yedeğini güvenli bir yerde (şifreli disk, parola yöneticisi) sakla.
Repoya asla commit etme (`.gitignore` `*.asc` ve `*.gpg` dosyalarını zaten dışlıyor).

## 2. GitHub ayarları

Repo sayfasında **Settings**:

1. **Actions → General → Workflow permissions**
   - "Read repository contents permissions" seçili kalsın.
   - **"Allow GitHub Actions to create and approve pull requests"** kutusunu işaretle
     (günlük güncelleme botunun PR açabilmesi için).
2. **Environments → New environment → `release`**
   - *Environment secrets* → `GPG_PRIVATE_KEY` = 1. adımdaki özel anahtar.
   - *Environment variables* → `GPG_FINGERPRINT` = 1. adımdaki `$FPR`.
   - *Deployment branches and tags* → "Selected branches" → `main`.
   - İstersen *Required reviewers* olarak kendini ekle (her yayında onay ister).
3. **Rules (veya Branches) → main için kural**: force-push'u engelle, PR zorunlu olsun.
   "Required status checks" **ekleme**: bot'un açtığı PR'larda `ci` otomatik çalışmaz
   (GITHUB_TOKEN kısıtı), merge'i kilitler. Bot PR'ı zaten açmadan önce test-build yapıyor.
4. Hesabında 2FA açık olsun.

## 3. Yükleme (mevcut repoya)

```bash
git clone https://github.com/maxwell523452/vr-cyberdeck-bin.git old
unzip vr-cyberdeck-bin-hardened.zip          # vr-cyberdeck-bin/ klasörünü oluşturur
cp -a old/.git vr-cyberdeck-bin/.git         # eski geçmişi yeni dosyalara taşır
cd vr-cyberdeck-bin
git switch -c hardening

git add PKGBUILD 51-vr-cyberdeck-quest.rules
git commit -m "fix: ship quest udev rule and pin all package sources by sha256"

git add scripts .github
git commit -m "security: sign pacman repo and publish updates through reviewed prs"

# (.deb build is part of the scripts/.github commit above)

git add -A
git commit -m "chore: revise readme"

git push -u origin hardening
```

GitHub'da PR aç. `ci` iş akışı (lint + test build) yeşil olunca **merge et**.
Merge, `release` iş akışını tetikler:

- Actions sekmesinde `release` çalışmalı (varsa onay ver).
- Bitince **Releases** altında `v2.0.0-1` ve `pacman-repo` görünmeli.
- `pacman-repo` içinde `.db`, `.db.sig`, `.files`, `vr-cyberdeck.gpg` ve paket + `.sig` olmalı.

Eski, imzasız `pacman-repo` varlıkları ilk yayında otomatik silinir.

## 4. Kendi makinende dene (CachyOS)

README'deki "Install" adımlarını uygula. Eskiden `SigLevel = Optional` ile eklenmiş
`[vr-cyberdeck]` bloğu varsa `SigLevel = Required DatabaseRequired` olarak değiştir.

## 5. Günlük işleyiş

- Upstream yeni sürüm çıkarırsa bot `update/upstream-X.Y.Z` PR'ı açar.
  PR'da diff'i incele, AppImage'ın sha256'sını kendin indirip karşılaştırabilirsin,
  sonra merge et. Yayın otomatik olur.
- Sadece paketleme düzeltmesi (PKGBUILD, udev kuralı): dosyayı düzenle, `pkgrel`'i 1 artır,
  kaynak değiştiyse `./scripts/update-pkgbuild.sh` çalıştır, PR aç, merge et.
- Aynı sürümü yeniden yayınlamak: Actions → release → Run workflow → `force`.
- Eski bir sürüme dönmek: Releases'ten ilgili `.pkg.tar.zst` + `.sig` indir, `sudo pacman -U`.

## 6. Anahtar sızarsa

Yeni anahtar üret, `GPG_PRIVATE_KEY` ve `GPG_FINGERPRINT` değerlerini güncelle, README'deki
parmak izini değiştir, `release` iş akışını `force` ile çalıştır ve kullanıcılara yeni anahtarı
güvenmelerini söyle.

## .deb çıktısı

Her release artık Arch paketinin yanında `.deb` de üretir (`scripts/build-deb.sh`).
`.deb`, Arch paketinin içinden çıkarılır, yani iki formatta da birebir aynı dosyalar vardır.
`.deb` ve `.sig` dosyaları `vX.Y.Z-N` release'ine yüklenir. `pacman-repo` release'ine girmez.
APT reposu yok, Debian/Ubuntu kullanıcıları güncellemeyi elle indirir.

## Bilinen sınırlar

- `.deb` içindeki `Depends` paket adları Debian/Ubuntu'da denenmedi (t64 yeniden adlandırmaları için
  `a | b` alternatifleri koydum). İlk `.deb`'i bir Ubuntu/Debian makinede `sudo apt install ./...deb`
  ile dene ve eksik bağımlılık çıkarsa bana yaz.

- Upstream'in kendisi ele geçirilirse checksum bunu yakalamaz, çünkü checksum'lar indirilen
  dosyadan hesaplanır. Bu yüzden güncellemeler PR ile gelir ve elle onay ister.
- İş akışlarını GitHub'da çalıştıramadım. Scriptlerin mantığını yerelde (sahte `curl`,
  `gh`, `repo-add` ile) test ettim, ama gerçek `makepkg`/`repo-add`/Docker adımları ilk
  çalıştırmada görülecek.
- Action SHA'ları eski dosyalarından aynen alındı, doğrulayamadım. Dependabot haftalık günceller.
- `archlinux:base-devel` imajı digest ile sabitlenmedi.
- `depends` içindeki Electron kütüphaneleri güvenli bir üst küme. Gereksizleri sonra çıkarabilirsin.
- AppImage `/opt` altında root'a ait, uygulamanın kendi kendini güncellemesi çalışmaz
  (güncelleme pacman ile gelir).
