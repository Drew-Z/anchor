# Anchor Learning - Web Deployment Guide

This guide covers deploying the Anchor Learning landing page to various hosting platforms.

## Quick Deploy Options

### Option 1: GitHub Pages (Recommended for open source)

**Pros**: Free, automatic SSL, GitHub integration
**Cons**: Public repos only (for free tier)

1. **Enable GitHub Pages**
   ```bash
   # Push your code to GitHub
   git add web/
   git commit -m "Add landing page"
   git push origin main
   ```

2. **Configure in GitHub**
   - Go to repo Settings → Pages
   - Source: Deploy from branch
   - Branch: `main`, Folder: `/web`
   - Save

3. **Access your site**
   - URL: `https://drew-z.github.io/anchor/landing/`
   - Custom domain: Add `CNAME` file in `/web` folder

4. **Custom Domain (optional)**
   ```bash
   echo "anchor.yourdomain.com" > web/CNAME
   ```
   
   Then add DNS record:
   ```
   Type: CNAME
   Name: anchor
   Value: drew-z.github.io
   ```

### Option 2: Vercel (Best for fast deployment)

**Pros**: Automatic deployments, preview URLs, edge network
**Cons**: None for static sites

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Deploy**
   ```bash
   cd web/landing
   vercel
   ```

3. **Configuration** (optional)
   Create `vercel.json` in `/web`:
   ```json
   {
     "version": 2,
     "public": true,
     "cleanUrls": true,
     "trailingSlash": false
   }
   ```

4. **Production deploy**
   ```bash
   vercel --prod
   ```

### Option 3: Netlify

**Pros**: Drag-and-drop deploy, form handling, edge functions
**Cons**: Build minutes limited on free tier

1. **Via Netlify Drop**
   - Visit https://app.netlify.com/drop
   - Drag `web/landing` folder
   - Done!

2. **Via Git**
   - Connect GitHub repo
   - Build settings:
     - Build command: (leave empty)
     - Publish directory: `web/landing`
   - Deploy

3. **Configuration** (optional)
   Create `netlify.toml` in `/web`:
   ```toml
   [build]
     publish = "landing"

   [[redirects]]
     from = "/demo"
     to = "/app/index.html"
     status = 200
   ```

### Option 4: Cloudflare Pages

**Pros**: Free unlimited bandwidth, fast CDN
**Cons**: Slightly more complex setup

1. **Via Dashboard**
   - Connect GitHub repo
   - Framework preset: None
   - Build directory: `web/landing`
   - Deploy

2. **Configuration**
   Create `_headers` in `/web/landing`:
   ```
   /*
     X-Frame-Options: DENY
     X-Content-Type-Options: nosniff
     Referrer-Policy: strict-origin-when-cross-origin
   ```

### Option 5: Self-hosted (VPS/Server)

**Pros**: Full control, no limits
**Cons**: Requires server management

1. **Nginx Configuration**
   ```nginx
   server {
       listen 80;
       server_name anchor.yourdomain.com;

       root /var/www/anchor/web/landing;
       index index.html;

       location / {
           try_files $uri $uri/ =404;
       }

       # Cache static assets
       location ~* \.(css|js|jpg|png|svg|ico)$ {
           expires 1y;
           add_header Cache-Control "public, immutable";
       }

       # Security headers
       add_header X-Frame-Options "DENY" always;
       add_header X-Content-Type-Options "nosniff" always;
   }
   ```

2. **Deploy**
   ```bash
   # Copy files to server
   rsync -avz web/ user@server:/var/www/anchor/web/

   # Restart Nginx
   sudo systemctl restart nginx
   ```

3. **SSL with Let's Encrypt**
   ```bash
   sudo certbot --nginx -d anchor.yourdomain.com
   ```

## Performance Optimization

### 1. Compress Assets

```bash
# Install dependencies
npm install -g html-minifier clean-css-cli uglify-js

# Minify HTML
html-minifier --collapse-whitespace --remove-comments \
  --minify-css --minify-js \
  web/landing/index.html > web/landing/index.min.html

# Minify CSS
cleancss -o web/landing/styles/main.min.css \
  web/landing/styles/main.css

# Minify JS
uglifyjs web/landing/scripts/main.js \
  -o web/landing/scripts/main.min.js -c -m
```

### 2. Enable Compression (Server-side)

**Nginx**:
```nginx
gzip on;
gzip_types text/css application/javascript application/json image/svg+xml;
gzip_min_length 1000;
```

**Apache** (`.htaccess`):
```apache
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/css application/javascript
</IfModule>
```

### 3. Image Optimization

```bash
# Install tools
npm install -g sharp-cli svgo

# Optimize PNG/JPG
sharp -i screenshot.png -o screenshot-optimized.png

# Optimize SVG
svgo web/landing/assets/*.svg
```

### 4. Add Cache Headers

Create `.htaccess` (Apache):
```apache
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType text/css "access plus 1 year"
  ExpiresByType application/javascript "access plus 1 year"
  ExpiresByType image/svg+xml "access plus 1 year"
  ExpiresByType text/html "access plus 1 hour"
</IfModule>
```

## Analytics Setup

### Google Analytics 4

1. Create property at https://analytics.google.com
2. Get Measurement ID (e.g., `G-XXXXXXXXXX`)
3. Add to `web/landing/index.html` before `</head>`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

### Plausible (Privacy-friendly alternative)

```html
<script defer data-domain="anchor.yourdomain.com" 
  src="https://plausible.io/js/script.js"></script>
```

## SEO Enhancement

### 1. Add Sitemap

Create `web/landing/sitemap.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://anchor.yourdomain.com/</loc>
    <lastmod>2024-01-15</lastmod>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://anchor.yourdomain.com/app/</loc>
    <lastmod>2024-01-15</lastmod>
    <priority>0.8</priority>
  </url>
</urlset>
```

### 2. Add robots.txt

Create `web/landing/robots.txt`:
```
User-agent: *
Allow: /
Sitemap: https://anchor.yourdomain.com/sitemap.xml
```

### 3. Submit to Search Engines

- Google: https://search.google.com/search-console
- Bing: https://www.bing.com/webmasters

## Monitoring

### 1. Uptime Monitoring

- **UptimeRobot**: https://uptimerobot.com (free, 50 monitors)
- **Pingdom**: https://www.pingdom.com

### 2. Performance Monitoring

Run Lighthouse audit:
```bash
npm install -g lighthouse
lighthouse https://anchor.yourdomain.com --view
```

Target scores:
- Performance: 90+
- Accessibility: 95+
- Best Practices: 95+
- SEO: 95+

### 3. Error Tracking

Add Sentry (optional):
```html
<script src="https://browser.sentry-cdn.com/7.x.x/bundle.min.js"></script>
<script>
  Sentry.init({ dsn: 'YOUR_DSN' });
</script>
```

## Continuous Deployment

### GitHub Actions

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy Landing Page

on:
  push:
    branches: [main]
    paths:
      - 'web/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./web/landing
```

## Troubleshooting

### Issue: 404 on GitHub Pages

**Solution**: Ensure path is correct
- URL should be: `https://username.github.io/repo-name/landing/`
- Or set `landing/` as root in Pages settings

### Issue: CSS/JS not loading

**Solution**: Check paths are relative
```html
<!-- Wrong -->
<link rel="stylesheet" href="/styles/main.css">

<!-- Correct -->
<link rel="stylesheet" href="styles/main.css">
```

### Issue: Slow loading

**Solution**: 
1. Run Lighthouse audit
2. Optimize images
3. Enable compression
4. Use CDN

## Security Checklist

- [x] HTTPS enabled
- [x] Security headers configured
- [x] No sensitive data in code
- [x] Dependencies up to date
- [x] CORS properly configured
- [x] CSP header (optional)

## Next Steps

1. Deploy to chosen platform
2. Set up custom domain
3. Configure analytics
4. Submit sitemap to search engines
5. Set up monitoring
6. Share on social media!

## Support

For deployment issues:
- Check platform docs
- Open issue: https://github.com/Drew-Z/anchor/issues
- Discussions: https://github.com/Drew-Z/anchor/discussions
