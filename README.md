# gece-bitecek

## Spotify OAuth redirect (Vercel)

Spotify, girişten sonra tarayıcıyı şu adrese yönlendirir:

`https://SENIN-ALANIN/spotify-callback?code=...&state=...`

Bu sayfa aynı query string ile uygulamayı açar:

`gecebitecek://spotify-callback?code=...&state=...`

### Yayınlama (Vercel)

1. `spotify-callback/index.html` içinde `APP_SCHEME` değerini Flutter ile aynı yap.
2. Repo kökü **Vercel Project Root** olsun (`.`) — HTML dosyası `spotify-callback/index.html` yolunda durur; **rewrite gerekmez**.
3. Deploy sonrası Spotify Dashboard → **Redirect URIs**:

   `https://xxx.vercel.app/spotify-callback`

4. PKCE’deki `redirect_uri` ile bu adres **bire bir** aynı olmalı.

### Test

`https://xxx.vercel.app/spotify-callback?code=demo&state=test`

### Not: Kök adres 404

`/spotify-callback` çalışıyorsa kurulum doğrudur. Ana domain **kökü** (`/`) bazen boş kalabilir; Spotify için önemli olan yol **`/spotify-callback`**. Production URL’yi Vercel → **Deployments** → **Production** üzerindeki “Visit” ile doğrula (preview URL’leri farklı olabilir).
