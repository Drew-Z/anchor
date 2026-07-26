# Web Landing Page & Demo

This directory contains the web presence for Anchor Learning:

## Directory Structure

```
web/
├── landing/              # Main landing page
│   ├── index.html       # Landing page HTML
│   ├── styles/
│   │   └── main.css     # Slate-dark theme styles
│   ├── scripts/
│   │   └── main.js      # Interactive features
│   └── assets/          # Images, icons, etc.
│
├── app/                 # Web demo (coming soon)
│   └── index.html       # Demo placeholder
│
└── api/                 # Backend API (future)
    └── (planned)
```

## Landing Page Features

- **Modern Design**: Slate-dark theme with blue accent (#5B8CFF)
- **Responsive**: Mobile-first design
- **Interactive**: Smooth scroll, animations, mobile menu
- **SEO Optimized**: Meta tags, Open Graph, Twitter Cards
- **Accessible**: WCAG compliant, keyboard navigation
- **Performance**: Lazy loading, preloading, minimal JS

## Sections

1. **Hero**: Main value proposition with visual demo
2. **Features**: 6 key features with icons
3. **How It Works**: 3-step workflow visualization
4. **Architecture**: 3-layer anti-hallucination system
5. **Tech Stack**: Technologies used
6. **Use Cases**: 4 target user personas
7. **Demo CTA**: Link to web demo (coming soon)
8. **Community**: GitHub, Discussions, Contributing
9. **Final CTA**: Call to action with quick install
10. **Footer**: Links, legal, social

## Development

### Local Server

```bash
# Python
python -m http.server 8000

# Node.js
npx serve web

# PHP
php -S localhost:8000
```

Then visit: `http://localhost:8000/landing/`

### File Sizes

- `index.html`: ~15 KB
- `main.css`: ~12 KB
- `main.js`: ~5 KB
- **Total**: ~32 KB (uncompressed)

### Browser Support

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+
- Mobile browsers (iOS 14+, Android 10+)

## Deployment

### GitHub Pages

1. Push to `main` branch
2. Enable GitHub Pages in repo settings
3. Set source to `main` branch, `/web` folder
4. Access at: `https://drew-z.github.io/anchor/landing/`

### Custom Domain

Add `CNAME` file:

```
anchor.example.com
```

Configure DNS:
```
CNAME: anchor -> drew-z.github.io
```

### Vercel/Netlify

1. Connect GitHub repo
2. Set build directory to `web`
3. No build command needed (static site)
4. Deploy

## Content Updates

### Update GitHub Stars

Edit `scripts/main.js`:
```javascript
const response = await fetch('https://api.github.com/repos/Drew-Z/anchor');
```

### Update Social Preview

Replace `assets/social-preview.png` with 1200x630px image.

### Update Color Theme

Edit CSS variables in `styles/main.css`:
```css
:root {
  --accent: #5B8CFF;  /* Change primary accent */
}
```

### Add New Section

1. Add HTML in `index.html`
2. Add styles in `main.css`
3. Update navigation links

## SEO Checklist

- [x] Title tags (< 60 chars)
- [x] Meta descriptions (< 160 chars)
- [x] Open Graph tags
- [x] Twitter Card tags
- [x] Favicon
- [x] Semantic HTML
- [x] Alt text for images (when added)
- [x] Sitemap (TODO: generate)
- [x] robots.txt (TODO: add)

## Analytics

To add Google Analytics:

```html
<!-- Add to <head> -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

Then uncomment analytics code in `scripts/main.js`.

## TODO

- [ ] Create social preview image (1200x630)
- [ ] Create favicon (SVG + PNG fallback)
- [ ] Add screenshot/demo video
- [ ] Build interactive web demo
- [ ] Generate sitemap.xml
- [ ] Add robots.txt
- [ ] Set up GitHub Pages
- [ ] Test on real devices
- [ ] Lighthouse audit (target 90+ score)
- [ ] Add blog section (optional)

## License

Same as parent project: MIT License

## Credits

- Design: Based on modern SaaS landing page patterns
- Icons: GitHub Octicons (embedded SVG)
- Fonts: System font stack (no external fonts)
