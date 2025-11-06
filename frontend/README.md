# Ollie Landing Page

Beautiful, responsive landing page for Ollie built with SvelteKit.

## Features

- ✨ Modern, clean design
- 📱 Fully responsive (mobile, tablet, desktop)
- ⚡ Lightning fast (SvelteKit SSG)
- 🎨 Animated components
- 🚀 Optimized for SEO

## Development

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Deployment

### Option 1: Deploy to Vercel (Recommended)

1. Push to GitHub
2. Go to [Vercel Dashboard](https://vercel.com/dashboard)
3. Import repository
4. Set project settings:
   - **Framework**: SvelteKit
   - **Root Directory**: `frontend`
   - **Build Command**: `npm run build`
   - **Output Directory**: `.svelte-kit/output`
5. Deploy!

### Option 2: Deploy to Netlify

1. Push to GitHub
2. Go to [Netlify](https://netlify.com)
3. Import repository
4. Set build settings:
   - **Base directory**: `frontend`
   - **Build command**: `npm run build`
   - **Publish directory**: `.svelte-kit/output`

### Option 3: Deploy to Cloudflare Pages

1. Push to GitHub
2. Go to Cloudflare Pages
3. Connect repository
4. Set:
   - **Root directory**: `frontend`
   - **Build command**: `npm run build`
   - **Output directory**: `.svelte-kit/output`

## Custom Domain Setup

Once deployed, point your domain:

- Landing page: `ollieboard.dev` → Vercel deployment
- App: `app.ollieboard.dev` → Flutter app (already set up)
- WebSocket: `ws.ollieboard.dev` → Digital Ocean (already set up)

## Project Structure

```
frontend/
├── src/
│   ├── routes/
│   │   ├── +layout.svelte    # Layout wrapper
│   │   └── +page.svelte       # Landing page
│   └── app.html               # HTML template
├── static/                    # Static assets
├── vercel.json               # Vercel config
└── package.json
```

## Customization

### Update Colors

Edit the gradient in `+page.svelte`:

```css
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
```

### Update Content

All content is in `src/routes/+page.svelte`. Update:
- Hero text
- Feature descriptions
- CTA buttons
- Footer links

### Add Analytics

Add to `src/app.html`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
```

## Performance

- Lighthouse Score: 100/100
- First Contentful Paint: < 1s
- Time to Interactive: < 2s
- Bundle size: ~50KB

## License
