# Spotify OAuth redirect (Vercel)

Spotify, girişten sonra tarayıcıyı şu adrese yönlendirir:

`https://SENIN-ALANIN/spotify-callback?code=...&state=...`

Bu sayfa aynı query string ile uygulamayı açar:

`gecebitecek://spotify-callback?code=...&state=...`

## Yayınlama (Vercel)

1. `vercel-spotify-callback/spotify-callback/index.html` içinde `APP_SCHEME` değerini Flutter’da kullanacağın şema ile değiştir.
2. Bu klasörü bir Git deposuna gönder (veya Vercel CLI ile doğrudan yükle).
3. [Vercel](https://vercel.com) → **Add New** → **Project** → repoyu seç.
4. **Root Directory:** Repo kökünü kullan (`.`) — kökteki `vercel.json`, `/spotify-callback` yolunu `vercel-spotify-callback/spotify-callback/index.html` dosyasına yönlendirir.  
   Alternatif: Root Directory’yi `vercel-spotify-callback` yaparsan bu rewrite gerekmez; yine `https://.../spotify-callback` çalışır.
5. **Framework Preset:** Other; **Build Command** boş.
6. Deploy tamamlanınca aldığın URL’yi not et: `https://xxx.vercel.app`
7. Spotify Developer Dashboard → uygulaman → **Redirect URIs** → şunu ekle (kendi domain’in neyse):

   `https://xxx.vercel.app/spotify-callback`

8. PKCE akışında kullandığın `redirect_uri` parametresi ile bu adres **karakter karakter aynı** olmalı.

## Yerel önizleme

```bash
cd vercel-spotify-callback
npx vercel dev
```

Tarayıcıda `http://localhost:3000/spotify-callback?code=demo&state=test` açıp deep link üretimini test edebilirsin (gerçek token alışverişi yine Spotify ile olur).
