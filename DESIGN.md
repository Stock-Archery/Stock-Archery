---
name: Aureum Elite
colors:
  surface: '#16130b'
  surface-dim: '#16130b'
  surface-bright: '#3d392f'
  surface-container-lowest: '#110e07'
  surface-container-low: '#1f1b13'
  surface-container: '#231f17'
  surface-container-high: '#2d2a21'
  surface-container-highest: '#38342b'
  on-surface: '#eae1d4'
  on-surface-variant: '#d0c5af'
  inverse-surface: '#eae1d4'
  inverse-on-surface: '#343027'
  outline: '#99907c'
  outline-variant: '#4d4635'
  surface-tint: '#e9c349'
  primary: '#f2ca50'
  on-primary: '#3c2f00'
  primary-container: '#d4af37'
  on-primary-container: '#554300'
  inverse-primary: '#735c00'
  secondary: '#bdc7d6'
  on-secondary: '#27313d'
  secondary-container: '#404a56'
  on-secondary-container: '#afb9c8'
  tertiary: '#cacfd7'
  on-tertiary: '#2c3137'
  tertiary-container: '#afb3bb'
  on-tertiary-container: '#40454c'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffe088'
  primary-fixed-dim: '#e9c349'
  on-primary-fixed: '#241a00'
  on-primary-fixed-variant: '#574500'
  secondary-fixed: '#d9e3f3'
  secondary-fixed-dim: '#bdc7d6'
  on-secondary-fixed: '#131c27'
  on-secondary-fixed-variant: '#3e4854'
  tertiary-fixed: '#dee3eb'
  tertiary-fixed-dim: '#c2c7cf'
  on-tertiary-fixed: '#171c22'
  on-tertiary-fixed-variant: '#42474e'
  background: '#16130b'
  on-background: '#eae1d4'
  surface-variant: '#38342b'
typography:
  display-lg:
    fontFamily: Montserrat
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Montserrat
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-md:
    fontFamily: Montserrat
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-margin-desktop: 48px
  container-margin-mobile: 20px
  gutter: 24px
  card-padding: 24px
---

## Brand & Style

This design system targets high-net-worth aspiring traders and professionals who value precision, exclusivity, and technological superiority. The brand personality is authoritative yet modern, bridging the gap between traditional luxury (Gold) and cutting-edge fintech (Obsidian/Glassmorphism). 

The visual style is **Premium SaaS Minimalism**. It utilizes a "Dark First" philosophy where depth is created through material properties—glass, subtle glows, and metallic accents—rather than heavy drop shadows. The emotional response should be one of "controlled power" and "clarity amidst market noise."

**Core Principles:**
- **Exclusivity:** Heavy use of pure black to create a void that makes gold elements feel rare and valuable.
- **Precision:** Mathematical spacing and razor-sharp typography reflect the nature of trading.
- **Tactile Digitalism:** Using frosted glass (background blur) to simulate high-end hardware interfaces.

## Colors

The palette is strictly high-contrast to ensure maximum legibility for financial data. 

- **Deep Obsidian (#0B0E11):** The primary canvas. It is slightly warmer than pure black to prevent eye strain during long educational sessions.
- **Pure Black (#000000):** Reserved for elevated cards and containers to create a "hole in the screen" effect that recedes behind the content.
- **Metallic Gold (#D4AF37):** Used sparingly for primary actions, progress indicators, and premium statuses. It should never be used for large background areas.
- **Subtle Grey (#848E9C):** The workhorse for metadata, captions, and inactive states. 
- **Functional Accents:** Standard green and red are tuned for high-vibrancy against the dark background to signal market movement without clashing with the gold.

## Typography

The typography system uses a dual-font approach. **Montserrat** provides a geometric, bold architectural feel for headings, while **Inter** ensures maximum readability for complex trading data and educational body text.

- **Headlines:** Set in Montserrat with tighter letter-spacing to emphasize the premium "editorial" feel.
- **Numerical Data:** For tickers and prices, Inter's tabular lining features should be enabled to ensure columns of numbers align perfectly.
- **Hierarchy:** Use gold for primary titles and Subtle Grey for secondary descriptions to create immediate visual order.

## Layout & Spacing

The system follows a **Fixed-Fluid Hybrid** grid. On desktop, content is capped at a 1440px width with 12 columns to maintain focus. On mobile, a single-column layout with generous 20px margins is used to ensure video thumbnails have maximum impact.

**Spacing Philosophy:**
- **The 8px Rule:** All dimensions, padding, and margins must be multiples of 8.
- **Breathing Room:** Educational content requires high white-space (or "black-space") to prevent cognitive overload.
- **Vertical Rhythm:** Video thumbnails are separated by a consistent 32px gap to distinguish between different lessons or modules.

## Elevation & Depth

Hierarchy is defined through **Material Layering** rather than traditional shadows.

1.  **Level 0 (Background):** Deep Obsidian (#0B0E11).
2.  **Level 1 (Cards/Surface):** Pure Black (#000000) with a 1px Subtle Grey (#848E9C) border at 10% opacity. 
3.  **Level 2 (Overlays/Modals):** Glassmorphism. A semi-transparent surface (Black at 60%) with a 20px backdrop blur. This is used for navigation bars and floating video controls.
4.  **Level 3 (Interaction):** Gold-tinted outer glow (8px blur, 20% opacity) for active buttons or selected video cards.

Avoid large-scale shadows. Use subtle internal glows or thin borders to define edges.

## Shapes

The design system uses a **Refined Rounded** language (Level 2). This softens the harshness of the high-contrast black/gold palette, making the platform feel approachable as an "educational" tool rather than just a cold "trading" terminal.

- **Standard Elements:** Buttons and input fields use 8px (0.5rem) corner radii.
- **Containers:** Video thumbnails and lesson cards use 16px (1rem) radii to create a friendly, modern container feel.
- **Iconography:** Icons should be medium-stroke (2px) with slightly rounded terminals to match the font geometry.

## Components

### Buttons
- **Primary:** Solid Gold (#D4AF37) with Black text. No shadow, but a subtle "metallic" linear gradient (top to bottom) is permitted.
- **Secondary:** Ghost style. Transparent background, 1px Gold border, Gold text.
- **Tertiary:** Subtle Grey text with no border.

### Cards (Lessons/Videos)
- **Structure:** Pure black background. Top section features the video thumbnail with a play-button overlay (Glassmorphism). Bottom section contains lesson metadata.
- **Hover State:** The 1px border increases in opacity from 10% to 40% Gold.

### Input Fields
- Background: Deep Obsidian.
- Border: 1px Subtle Grey (20% opacity).
- Active State: Border becomes Gold with a 2px inner-glow.

### Video Thumbnails
- High-quality, high-contrast imagery only. 
- A 10% black gradient overlay at the bottom of the image helps labels (like "Featured Video") pop.

### Navigation Bar
- Position: Fixed top.
- Style: Frosted glass (70% Obsidian, 20px blur).
- Bottom Border: 1px Subtle Grey (10% opacity).