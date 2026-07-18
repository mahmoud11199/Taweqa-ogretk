---
name: frontend-design
description: |
  Use when building or reviewing UI components, layouts, or design systems.
  Focus on responsive, accessible, consistent, and visually polished frontend interfaces.
  Applies to any framework (React, Flutter, Vue, etc.) or raw HTML/CSS/JS.
---

# Frontend Design Skill

## Core Principles

### 1. Responsive & Adaptive
- **Mobile-first**: Start from the smallest screen, then scale up with `min-width` breakpoints (sm: 640px, md: 768px, lg: 1024px, xl: 1280px, 2xl: 1536px).
- **Fluid layouts**: Use CSS Grid and Flexbox. Avoid fixed pixel widths for containers — prefer `max-width` + `margin: auto` or `clamp()`.
- **Touch targets**: All interactive elements must be at least 44×44px (WCAG 2.5.8).

### 2. Visual Consistency
- **Design tokens**: Use a centralized system for colors, typography, spacing, shadows, and radii. No hardcoded magic values.
- **Typography**: Establish a clear type scale (e.g., 12/14/16/18/20/24/30/36/48px). Line-height: 1.2 for headings, 1.5–1.6 for body.
- **Spacing**: Stick to a 4px or 8px grid. Use a consistent spacing scale (e.g., 4/8/12/16/24/32/48/64).
- **Color**: Define semantic tokens (`--color-primary`, `--color-surface`, `--color-text`, `--color-error`) rather than raw hex values.

### 3. Accessibility (a11y)
- Every interactive element must be keyboard-focusable (`tabindex` when needed) and have a visible focus ring.
- Images must have meaningful `alt` text (or `alt=""` for decorative).
- Color contrast must meet WCAG AA (4.5:1 for normal text, 3:1 for large text).
- Use semantic HTML elements (`<nav>`, `<main>`, `<button>`, `<label>`, etc.).

### 4. Performance
- Lazy-load below-the-fold images and heavy components.
- Minimize re-renders: extract expensive calculations with `useMemo`/`useCallback` (React), or `shouldRebuild` checks (Flutter).
- Avoid layout thrashing — batch DOM reads/writes.

### 5. Animation & Micro-interactions
- Use subtle transitions (150–300ms, ease-in-out) for hover/focus/active states.
- Prefer CSS `transform` and `opacity` for GPU-accelerated animations.
- Respect `prefers-reduced-motion` by disabling or simplifying animations.

## Framework-Specific Guidelines

### React / Next.js
- Use Tailwind CSS or CSS Modules for scoped styling. Avoid inline styles for layout.
- Follow the component pattern: `ComponentName.tsx` + `ComponentName.module.css` (or Tailwind utility classes).
- Co-locate tests, stories, and types next to the component.

### Flutter
- Use `ThemeData` with `ThemeExtension` for custom tokens. Avoid passing raw `Color`/`TextStyle` through widget props.
- Leverage `LayoutBuilder`, `MediaQuery`, and `Flexible` / `Expanded` for responsive layouts.
- Prefer `const` constructors everywhere to reduce rebuilds.

### Vue
- Use scoped styles (`<style scoped>`) or CSS modules. Avoid global CSS pollution.
- Leverage `<Suspense>` for async components and `v-memo` for heavy lists.

## When to Apply
- Creating a new screen, page, or component from scratch.
- Reviewing a PR that touches UI styles or layout.
- Debugging layout shifts, overflow, or visual inconsistency.
- Setting up a new project — establish design tokens first.
