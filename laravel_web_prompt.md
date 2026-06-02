# Laravel Web Presence Prompt for RiceWatch

Paste the prompt below into your preferred AI (Claude, ChatGPT, etc.) inside a fresh Laravel project.

---

## PROMPT

You are a senior **Laravel 11 + Vue 3 + Inertia.js + Tailwind CSS** developer. Build the complete web presence for **RiceWatch** — an AI-powered mobile app for Filipino rice farmers. The website must feel trustworthy, approachable, and rooted in the agricultural context of the Philippine farming community.

The frontend is driven entirely by **Vue 3 Single File Components (SFCs)** using `<script setup>` syntax (Composition API). Inertia.js bridges Laravel controllers to Vue pages — no API calls, no JSON endpoints, no page reloads. All interactivity (navigation menu, FAQ accordion, contact form) is handled in Vue.

---

### Tech Stack

| Layer | Technology |
|-------|------------|
| Backend | Laravel 11 (PHP 8.2+) |
| Frontend | Vue 3 (Composition API, `<script setup>`) |
| Bridge | Inertia.js v2 (`inertiajs/inertia-laravel` + `@inertiajs/vue3`) |
| Styling | Tailwind CSS v3 (via `vite` + `tailwindcss`, NOT Play CDN) |
| Build tool | Vite 5 |
| Router | Inertia client-side (no `vue-router` needed) |
| State | `ref`, `reactive`, `computed` — no Pinia/Vuex needed |

---

### Brand Identity

| Token | Value |
|-------|-------|
| App Name | RiceWatch |
| Tagline | *Bantay-Ani sa Inyong mga Kamay* ("Crop guardian in your hands") |
| Primary Green | `#4A8C4E` |
| Primary Light | `#C8E6C9` |
| Background | `#F5F8F4` |
| Text Dark | `#1A2E1C` |
| Text Muted | `#3A5A3D` |
| Accent (dark mode) | `#66BB6A` |
| Error/High Risk | `#B00020` |
| Warning/Moderate | `#F57C00` |
| Success/Low Risk | `#388E3C` |
| Developer | Virgilio Tuga Jr. (virgilio.tuga@gmail.com) |
| Package ID | `com.ricewatch.app` |
| Version | 1.0.1 |

---

### About the App

RiceWatch is an AI-powered Flutter mobile app (Android & iOS) designed for Filipino rice farmers, especially those in Visayan-speaking (Cebuano/Bisaya) regions. It helps farmers:

1. **Scan & Analyze** — Take a photo of a rice leaf and the AI (OpenAI Vision) identifies diseases, assigns a risk level (Low / Moderate / High), and explains findings in Cebuano.
2. **Weather Forecast** — 7-day GPS-based weather forecast and interactive Windy map to plan fieldwork.
3. **AI Farming Assistant** — Chat with an AI that answers only rice-farming questions in Cebuano/Bisaya, with text-to-speech support.
4. **Scan History** — Review all past scans with detailed disease information stored locally on-device.
5. **Dark / Light Mode** — Follows system preference.

Detected diseases: Rice Blast, Brown Spot, Bacterial Leaf Blight, Sheath Blight, Tungro, Leaf Scald, Stem Rot, False Smut, Narrow Brown Leaf Spot, Bakanae, and more.

Data collected: Device GPS (weather only), camera/photos (leaf scanning only). No accounts. No personal data. No developer-controlled servers store user data.

---

### Project Setup Instructions

Generate these setup steps as a comment at the top of the output so the developer can bootstrap quickly:

```bash
# 1. Install Inertia server-side adapter
composer require inertiajs/inertia-laravel

# 2. Publish middleware
php artisan inertia:middleware

# 3. Register HandleInertiaRequests in bootstrap/app.php
#    ->withMiddleware(function (Middleware $middleware) {
#        $middleware->web(append: [HandleInertiaRequests::class]);
#    })

# 4. Install frontend packages
npm install @inertiajs/vue3 vue @vitejs/plugin-vue

# 5. Install Tailwind
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

---

### File Architecture

```
app/Http/Controllers/
└── PageController.php

resources/
├── views/
│   └── app.blade.php                  ← Inertia root (only Blade file needed)
├── js/
│   ├── app.js                         ← Inertia bootstrap
│   ├── Layouts/
│   │   └── AppLayout.vue              ← Shared nav + footer wrapper
│   ├── Components/
│   │   ├── AppNavbar.vue
│   │   ├── AppFooter.vue
│   │   ├── FeatureCard.vue
│   │   ├── HowItWorksStep.vue
│   │   ├── DiseasePill.vue
│   │   ├── FaqAccordion.vue
│   │   └── ContactForm.vue
│   └── Pages/
│       ├── Home.vue
│       ├── Privacy.vue
│       ├── Terms.vue
│       └── Support.vue
└── css/
    └── app.css                        ← Tailwind directives

tailwind.config.js
vite.config.js
routes/web.php
```

---

### Files to Generate

---

#### 1. `vite.config.js`

```js
import { defineConfig } from 'vite'
import laravel from 'laravel-vite-plugin'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [
    laravel({ input: ['resources/css/app.css', 'resources/js/app.js'], refresh: true }),
    vue({ template: { transformAssetUrls: { base: null, includeAbsolute: false } } }),
  ],
})
```

---

#### 2. `tailwind.config.js`

Extend with brand colors:

```js
export default {
  content: ['./resources/**/*.blade.php', './resources/**/*.vue', './resources/**/*.js'],
  theme: {
    extend: {
      colors: {
        primary:        '#4A8C4E',
        'primary-dark': '#2E6B32',
        'primary-light':'#C8E6C9',
        'bg-app':       '#F5F8F4',
        'text-dark':    '#1A2E1C',
        'text-muted':   '#3A5A3D',
        'accent':       '#66BB6A',
        'risk-high':    '#B00020',
        'risk-moderate':'#F57C00',
        'risk-low':     '#388E3C',
        'dark-surface': '#1A2E1C',
      },
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui'],
      },
    },
  },
  plugins: [],
}
```

---

#### 3. `resources/css/app.css`

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  html { scroll-behavior: smooth; }
  body { @apply bg-bg-app text-text-dark font-sans; }
}

@layer components {
  .btn-primary {
    @apply inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-primary text-white font-semibold
           hover:bg-primary-dark transition-all duration-200 shadow-sm hover:shadow-md;
  }
  .btn-outline {
    @apply inline-flex items-center gap-2 px-6 py-3 rounded-xl border-2 border-primary text-primary
           font-semibold hover:bg-primary hover:text-white transition-all duration-200;
  }
  .section-heading {
    @apply text-3xl font-bold text-text-dark text-center mb-4;
  }
  .section-subheading {
    @apply text-text-muted text-center max-w-2xl mx-auto mb-12;
  }
}
```

---

#### 4. `resources/js/app.js`

Bootstrap Inertia with Vue 3:

```js
import { createApp, h } from 'vue'
import { createInertiaApp } from '@inertiajs/vue3'
import { resolvePageComponent } from 'laravel-vite-plugin/inertia-helpers'
import '../css/app.css'

createInertiaApp({
  title: (title) => title ? `${title} — RiceWatch` : 'RiceWatch',
  resolve: (name) => resolvePageComponent(`./Pages/${name}.vue`, import.meta.glob('./Pages/**/*.vue')),
  setup({ el, App, props, plugin }) {
    createApp({ render: () => h(App, props) })
      .use(plugin)
      .mount(el)
  },
})
```

---

#### 5. `resources/views/app.blade.php`

The single Inertia root Blade file:

```html
<!DOCTYPE html>
<html lang="en" class="scroll-smooth">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="AI-powered rice leaf disease detection with 7-day weather and Cebuano farming advice." />
  <meta property="og:title" content="RiceWatch — AI Rice Disease Detection for Filipino Farmers" />
  <meta property="og:description" content="AI-powered rice leaf disease detection with 7-day weather and Cebuano farming advice." />
  <meta property="og:type" content="website" />
  @vite(['resources/css/app.css', 'resources/js/app.js'])
  @inertiaHead
</head>
<body>
  @inertia
</body>
</html>
```

---

#### 6. `routes/web.php`

```php
use App\Http\Controllers\PageController;

Route::get('/',               [PageController::class, 'home'])->name('home');
Route::get('/privacy-policy', [PageController::class, 'privacy'])->name('privacy');
Route::get('/terms',          [PageController::class, 'terms'])->name('terms');
Route::get('/support',        [PageController::class, 'support'])->name('support');
```

---

#### 7. `app/Http/Controllers/PageController.php`

Use `Inertia::render()` — pass the current route name as a shared prop so the nav can highlight the active link:

```php
namespace App\Http\Controllers;
use Inertia\Inertia;

class PageController extends Controller
{
    public function home()    { return Inertia::render('Home'); }
    public function privacy() { return Inertia::render('Privacy'); }
    public function terms()   { return Inertia::render('Terms'); }
    public function support() { return Inertia::render('Support'); }
}
```

Also share the current route name globally via `HandleInertiaRequests::share()`:

```php
// In App\Http\Middleware\HandleInertiaRequests
public function share(Request $request): array
{
    return array_merge(parent::share($request), [
        'currentRoute' => $request->route()?->getName(),
    ]);
}
```

---

#### 8. `resources/js/Layouts/AppLayout.vue`

Wraps every page. Contains `AppNavbar` and `AppFooter`. Accept a `title` prop for the `<Head>` tag:

- Use `<Head :title="title" />` from `@inertiajs/vue3` for per-page `<title>` and meta.
- Use `<slot />` for page content.
- Apply `bg-bg-app min-h-screen flex flex-col` on the wrapper div.

---

#### 9. `resources/js/Components/AppNavbar.vue`

**Props:** none. Read `currentRoute` from Inertia's shared props via `usePage().props.currentRoute`.

Requirements:
- Sticky top (`sticky top-0 z-50`), white background, subtle shadow on scroll (use Vue `ref` + `scroll` event listener to toggle `shadow-md`).
- Logo: `🌾 RiceWatch` in `text-primary font-bold text-xl`.
- Desktop nav links (hidden on mobile): Home, Privacy Policy, Terms, Support — using `<Link>` from `@inertiajs/vue3` with `href` set to the correct route.
- Active link style: `text-primary font-semibold border-b-2 border-primary`. Inactive: `text-text-muted hover:text-primary`.
- Mobile: hamburger button (`☰` / `✕` toggle) — use `ref` boolean `menuOpen`. Clicking toggles a dropdown drawer below the nav with the same links stacked vertically.
- The active route comparison must use `currentRoute` from `usePage()`.

Vue `<script setup>` example structure:
```vue
<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { Link, usePage } from '@inertiajs/vue3'

const menuOpen = ref(false)
const scrolled = ref(false)
const page = usePage()

const navLinks = [
  { label: 'Home',           route: 'home',    href: '/' },
  { label: 'Privacy Policy', route: 'privacy', href: '/privacy-policy' },
  { label: 'Terms',          route: 'terms',   href: '/terms' },
  { label: 'Support',        route: 'support', href: '/support' },
]

const isActive = (routeName) => page.props.currentRoute === routeName

const handleScroll = () => { scrolled.value = window.scrollY > 10 }
onMounted(() => window.addEventListener('scroll', handleScroll))
onUnmounted(() => window.removeEventListener('scroll', handleScroll))
</script>
```

---

#### 10. `resources/js/Components/AppFooter.vue`

- Dark green background `bg-dark-surface`, white text.
- 3-column grid on desktop, stacked on mobile:
  - **Col 1:** `🌾 RiceWatch` logo + tagline *"Bantay-Ani sa Inyong mga Kamay"*
  - **Col 2:** Quick links (Home, Privacy Policy, Terms, Support) using `<Link>`.
  - **Col 3:** Contact — `📧 virgilio.tuga@gmail.com`
- Bottom bar: `© 2025 RiceWatch. Developed by Virgilio Tuga Jr.`

---

#### 11. `resources/js/Components/FeatureCard.vue`

Reusable card. Props: `icon` (string/emoji), `title` (string), `description` (string).

- White background, `rounded-2xl shadow-sm hover:-translate-y-1 hover:shadow-md transition-all duration-200`.
- Icon in a `bg-primary-light rounded-xl p-3` container.
- Title in `text-text-dark font-semibold text-lg`.
- Description in `text-text-muted text-sm`.

---

#### 12. `resources/js/Components/HowItWorksStep.vue`

Props: `step` (number 1-3), `title` (string), `description` (string), `isLast` (boolean, default false).

- Numbered circle: `bg-primary text-white w-12 h-12 rounded-full flex items-center justify-center font-bold text-xl`.
- Horizontal connector line between steps (shown on desktop, hidden on mobile) — use `v-if="!isLast"`.

---

#### 13. `resources/js/Components/DiseasePill.vue`

Props: `name` (string).

- `bg-primary text-white text-sm font-medium px-4 py-1.5 rounded-full`.

---

#### 14. `resources/js/Components/FaqAccordion.vue`

Props: `items` — array of `{ question: string, answer: string }`.

Use Vue reactive state (NOT Alpine.js):

```vue
<script setup>
import { ref } from 'vue'
const props = defineProps({ items: Array })
const openIndex = ref(null)
const toggle = (i) => { openIndex.value = openIndex.value === i ? null : i }
</script>
```

Template: for each item, render a button that toggles the answer. Animate height with `max-h-0 overflow-hidden` → `max-h-96` using Tailwind `transition-all duration-300`. Show `▼` / `▲` chevron.

---

#### 15. `resources/js/Components/ContactForm.vue`

A controlled Vue form component. Use `ref` for each field: `name`, `email`, `subject`, `message`.

`subject` is a `<select>` with options: Bug Report, Feature Request, General Question.

On submit, build a `mailto:` URL and open it:

```vue
<script setup>
import { ref } from 'vue'
const name = ref('')
const email = ref('')
const subject = ref('General Question')
const message = ref('')

const submit = () => {
  const body = encodeURIComponent(`Name: ${name.value}\n\n${message.value}`)
  const sub  = encodeURIComponent(subject.value)
  window.location.href = `mailto:virgilio.tuga@gmail.com?subject=${sub}&body=${body}`
}
</script>
```

Style inputs with `w-full border border-gray-200 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary`.
Submit button uses `.btn-primary` class.

---

#### 16. `resources/js/Pages/Home.vue`

Use `AppLayout` as the layout. Build a single-page marketing site with 6 sections:

```vue
<script setup>
import AppLayout from '@/Layouts/AppLayout.vue'
import FeatureCard from '@/Components/FeatureCard.vue'
import HowItWorksStep from '@/Components/HowItWorksStep.vue'
import DiseasePill from '@/Components/DiseasePill.vue'
import { Link } from '@inertiajs/vue3'

const features = [
  { icon: '🔬', title: 'Scan & Analyze', description: 'Take a photo of your rice leaf and get instant disease detection with risk levels and Cebuano explanations.' },
  { icon: '🌤️', title: '7-Day Weather Forecast', description: 'Location-aware weather with an interactive Windy map so you can plan your field activities.' },
  { icon: '🤖', title: 'AI Farming Assistant', description: 'Ask any rice farming question and get expert advice in Cebuano/Bisaya, with text-to-speech.' },
  { icon: '📋', title: 'Scan History', description: 'Keep a full record of all your past scans with detailed disease information stored on your device.' },
]

const steps = [
  { title: 'Kuhaa og Litrato', description: 'Point your camera at a rice leaf and take a photo.' },
  { title: 'Palihogi ang AI', description: 'RiceWatch analyzes the leaf using OpenAI Vision technology.' },
  { title: 'Makakuha og Resulta', description: 'Get the disease name, risk level, and treatment advice — all in Cebuano.' },
]

const diseases = [
  'Rice Blast', 'Brown Spot', 'Bacterial Leaf Blight', 'Sheath Blight',
  'Tungro', 'Leaf Scald', 'Stem Rot', 'False Smut',
  'Narrow Brown Leaf Spot', 'Bakanae',
]
</script>
```

**Section 1 — Hero**
- `min-h-screen flex items-center justify-center` with `bg-gradient-to-b from-[#E8F5E9] to-bg-app`.
- Center-aligned:
  - Green pill badge: `🌱 Free for Filipino Farmers`
  - H1: `AI-Powered Rice Disease Detection for Filipino Farmers` — `text-5xl font-extrabold text-text-dark`
  - Subtitle: `Bantay ang imong ani gamit ang artificial intelligence. Libre. Offline-ready. Sa Cebuano.` — `text-xl text-text-muted`
  - CTA row: `<a href="#download" class="btn-primary">⬇️ Download on Android</a>` + `<a href="#features" class="btn-outline">Learn More</a>`
  - Badge row (flex gap-3): `🌾 AI-Powered` · `📍 GPS Weather` · `🗣️ Cebuano/Bisaya` — each in `bg-primary-light text-primary text-sm font-medium px-3 py-1 rounded-full`
- Decorative SVG rice stalk watermark, absolute positioned, low opacity (`opacity-5`), right side.

**Section 2 — Features** (`id="features"`)
- Section tag with `py-24 px-4 max-w-6xl mx-auto`.
- `<h2 class="section-heading">Everything a Rice Farmer Needs</h2>`
- Grid: `grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6`
- Render `<FeatureCard v-for="f in features" :key="f.title" v-bind="f" />`

**Section 3 — How It Works** (`id="how-it-works"`)
- `bg-white py-24 px-4`
- `<h2 class="section-heading">Giunsa Kini Paggamit?</h2>`
- Flex row on desktop, column on mobile, with `<HowItWorksStep>` components.
- Use `v-for="(step, i) in steps"`, pass `:step="i+1"`, `:isLast="i === steps.length - 1"`.

**Section 4 — Diseases** (`id="diseases"`)
- `py-20 px-4 max-w-4xl mx-auto text-center`
- `<h2 class="section-heading">Mamatikdan nga mga Sakit sa Palay</h2>`
- Flex wrap gap: `flex flex-wrap justify-center gap-3`
- `<DiseasePill v-for="d in diseases" :key="d" :name="d" />`
- Add a final pill: `+ daghang uban pa` (and more)

**Section 5 — Download** (`id="download"`)
- `bg-dark-surface text-white py-24 px-4 text-center`
- `<h2 class="text-4xl font-extrabold mb-4">I-download Karon — Libre!</h2>`
- Subtitle: `Libre. Walay account. Walay subscription.`
- CTA buttons row (flex gap-4 justify-center flex-wrap):
  - Google Play: `<a href="#" class="btn-primary">▶ Get it on Google Play</a>`
  - App Store: `<a href="#" class="border-2 border-white text-white hover:bg-white hover:text-dark-surface px-6 py-3 rounded-xl font-semibold transition-all">🍎 Available on the App Store</a>`
- Small requirement note: `text-gray-400 text-sm mt-6 Requires Android 6.0+ or iOS 13+`

**Section 6 — Privacy Assurance**
- `bg-[#E8F5E9] py-16 px-4`
- Centered card: `max-w-2xl mx-auto text-center`
- `🔒` large icon, heading `Your Data Stays on Your Device`
- Paragraph about no personal data collection.
- `<Link href="/privacy-policy" class="text-primary underline font-medium">Read our Privacy Policy →</Link>`

---

#### 17. `resources/js/Pages/Privacy.vue`

Use `AppLayout`. Full privacy policy page.

```vue
<script setup>
import AppLayout from '@/Layouts/AppLayout.vue'
import { Link } from '@inertiajs/vue3'
</script>

<template>
  <AppLayout title="Privacy Policy">
    <main class="max-w-3xl mx-auto px-4 py-16">
      <!-- Back breadcrumb -->
      <Link href="/" class="text-primary hover:underline text-sm">← Back to Home</Link>

      <!-- Document content below -->
    </main>
  </AppLayout>
</template>
```

Write the full privacy policy content as structured HTML inside `<main>`. Use:
- `<h1 class="text-4xl font-extrabold text-text-dark mt-6 mb-2">Privacy Policy</h1>`
- `<p class="text-text-muted text-sm mb-10">Effective Date: January 1, 2026 · Last Updated: May 30, 2025</p>`
- `<h2 class="text-2xl font-bold text-text-dark mt-10 mb-3">Section Title</h2>`
- `<p class="text-text-muted leading-relaxed mb-4">...</p>`
- `<ul class="list-disc list-inside text-text-muted space-y-2 mb-4">` for bullet lists.

**Sections to include (complete prose, not placeholders):**

1. Introduction
2. Information We Collect (Location, Photos/Camera, Device Storage, No Account Data)
3. How We Use Information
4. Third-Party Services (OpenAI, Weather/Windy API, no ad/analytics SDKs)
5. Data Retention
6. Children's Privacy (COPPA/GDPR)
7. Data Security
8. Your Rights
9. Changes to This Policy
10. Contact Us — `virgilio.tuga@gmail.com`

---

#### 18. `resources/js/Pages/Terms.vue`

Use `AppLayout`. Same structure as Privacy. Full Terms of Service.

Sections:

1. Acceptance of Terms
2. Description of Service (informational/educational only)
3. **AI Disclaimer** — prominently styled in a yellow warning box (`bg-yellow-50 border-l-4 border-yellow-400 p-4 rounded-r-xl my-6`): "The disease detection and farming advice provided by RiceWatch are generated by AI and are **not a substitute for professional agronomic advice**. Results may be inaccurate. The developer is not liable for crop losses or damages. Consult a licensed agriculturist or the Department of Agriculture (Philippines) for critical decisions."
4. Use of Third-Party APIs
5. User Responsibilities
6. Intellectual Property
7. Availability & Updates
8. Limitation of Liability
9. Governing Law — Republic of the Philippines
10. Contact — `virgilio.tuga@gmail.com`

---

#### 19. `resources/js/Pages/Support.vue`

Use `AppLayout`. Import `FaqAccordion` and `ContactForm`.

```vue
<script setup>
import AppLayout from '@/Layouts/AppLayout.vue'
import FaqAccordion from '@/Components/FaqAccordion.vue'
import ContactForm from '@/Components/ContactForm.vue'

const faqs = [
  {
    question: 'The app says "Image analysis is not available on this device."',
    answer: 'This feature requires an internet connection. Please check your WiFi or mobile data and try again. Web builds also have this limitation.',
  },
  {
    question: 'How do I delete my scan history?',
    answer: 'Go to Settings → Data & Privacy → Clear Scan History and confirm. This permanently removes all local scan data.',
  },
  {
    question: 'The AI responses are in English, not Cebuano.',
    answer: 'Make sure you are using the latest version of the app. The AI assistant is instructed to respond in Cebuano/Bisaya. If the issue persists, clear your chat history and start a new conversation.',
  },
  {
    question: 'Is my data shared with anyone?',
    answer: 'Your scan history and chat messages are stored only on your device. Photos are sent to OpenAI for analysis. Please review our Privacy Policy for full details.',
  },
  {
    question: 'Can I use RiceWatch without an internet connection?',
    answer: 'The Scan & Analyze and AI Assistant features require internet. Weather data is cached but requires periodic connection to refresh. Scan history and past chats are available offline.',
  },
  {
    question: 'Which rice diseases can RiceWatch detect?',
    answer: 'Rice Blast, Brown Spot, Bacterial Leaf Blight, Sheath Blight, Tungro, Leaf Scald, Stem Rot, False Smut, Narrow Brown Leaf Spot, Bakanae, and more.',
  },
]
</script>
```

Layout:
- Hero banner: `bg-gradient-to-b from-[#E8F5E9] to-bg-app py-16 px-4 text-center`
  - H1: "Need Help?" in `text-4xl font-extrabold text-text-dark`
  - Subtitle: "Kumusta! Reach out if you have questions about RiceWatch. We usually respond within 1–2 business days."
- Two-column grid on desktop (`grid lg:grid-cols-2 gap-12`), single column on mobile:
  - **Left:** FAQ section with `<FaqAccordion :items="faqs" />`
  - **Right:**
    - Contact card: `bg-white rounded-2xl shadow-sm p-6`
      - `📧 virgilio.tuga@gmail.com` as a `mailto:` link
      - "For urgent store listing issues, contact via email directly."
    - `<ContactForm />` below the card

---

### Additional Requirements

1. **No Alpine.js, no jQuery.** All interactivity must use Vue 3 reactive primitives (`ref`, `reactive`, `computed`, `watch`, event handlers).

2. **Smooth scrolling** — set in `app.css` via `html { scroll-behavior: smooth; }`.

3. **`<Head>` tags** — Each page must use `<Head title="Page Name" />` from `@inertiajs/vue3` so the browser tab title updates correctly via Inertia.

4. **`<Link>` not `<a>`** — All internal navigation must use `<Link href="...">` from `@inertiajs/vue3` for Inertia's SPA-style navigation (no full page reloads).

5. **Mobile-first** — All layouts must look correct at 375px (iPhone SE). Use `sm:`, `md:`, `lg:` Tailwind breakpoints. Test mental-model: hero stacks vertically, features grid is 1-col, nav collapses to hamburger.

6. **Path aliases** — Configure `@` alias in `vite.config.js` to point to `resources/js/`:
   ```js
   resolve: { alias: { '@': '/resources/js' } }
   ```

7. **Accessibility** — Use semantic HTML5 elements in Vue templates: `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<footer>`. Add `aria-label` on icon-only buttons. Add `aria-expanded` on accordion buttons.

8. **Transitions** — Use Vue's `<Transition>` component for the mobile menu slide-down and for the FAQ answer expand/collapse instead of CSS-only hacks.

---

### File Output Checklist

Generate every file completely — no placeholder comments:

- [ ] `vite.config.js`
- [ ] `tailwind.config.js`
- [ ] `resources/css/app.css`
- [ ] `resources/js/app.js`
- [ ] `resources/views/app.blade.php`
- [ ] `routes/web.php`
- [ ] `app/Http/Controllers/PageController.php`
- [ ] `app/Http/Middleware/HandleInertiaRequests.php` (share `currentRoute`)
- [ ] `resources/js/Layouts/AppLayout.vue`
- [ ] `resources/js/Components/AppNavbar.vue`
- [ ] `resources/js/Components/AppFooter.vue`
- [ ] `resources/js/Components/FeatureCard.vue`
- [ ] `resources/js/Components/HowItWorksStep.vue`
- [ ] `resources/js/Components/DiseasePill.vue`
- [ ] `resources/js/Components/FaqAccordion.vue`
- [ ] `resources/js/Components/ContactForm.vue`
- [ ] `resources/js/Pages/Home.vue`
- [ ] `resources/js/Pages/Privacy.vue`
- [ ] `resources/js/Pages/Terms.vue`
- [ ] `resources/js/Pages/Support.vue`
