---
name: react-best-practices
description: |
  Use when writing, reviewing, or refactoring React and Next.js code.
  Covers components, hooks, state management, performance, and project structure.
  Do NOT use for non-React JavaScript/TypeScript projects.
---

# React Best Practices

## Project Structure

- **Feature-based folders**: Group by domain/feature (`features/auth/`, `features/dashboard/`, `shared/ui/`) — NOT by file type (`components/`, `containers/`, `hooks/`).
- **Co-location**: Keep component logic, styles, tests, and types in the same folder as the component.
- **Barrel exports**: Use `index.ts` files to re-export public API surfaces; avoid deep relative imports.

## Components

### Functional Components Only
- Always use function components + hooks. No class components.
- Default to `const ComponentName: React.FC<Props> = ({ ... }) => { ... }`.

### Props
- Define explicit `interface Props` (or `type Props`) per component.
- Destructure props in the function signature.
- Avoid spreading props (`<Component {...props} />`) unless building a generic wrapper.
- Use `React.PropsWithChildren` for components that render `children`.

### Composition
- Prefer composition over inheritance or complex conditionals.
- Use `children` prop or render props for flexible layouts.
- Extract reusable sub-components: keep each component focused on one job.

### Conditional Rendering
- Use early returns for guard clauses: `if (!data) return <Loader />;`
- Use ternary for simple inline conditions: `{isLoading ? <Spinner /> : <Content />}`
- Avoid `&&` for non-boolean values (risk of rendering `0` or empty string).

## Hooks

### Rules of Hooks
- Only call hooks at the top level of a function component or custom hook.
- Only call hooks from React function components or custom hooks.
- Prefix custom hooks with `use` (e.g., `useAuth`, `useDebounce`).

### useState
- Keep state minimal: derive values when possible (e.g., `const isComplete = items.every(...)` instead of a separate `isComplete` state).
- Use functional updates when new state depends on previous: `setCount(prev => prev + 1)`.

### useEffect
- Always specify dependencies explicitly. The linter's dependency array is authoritative.
- Use cleanup functions to cancel subscriptions, timers, or fetch requests.
- **DO NOT use `useEffect` for data fetching** — use a data-fetching library (React Query, SWR, RTK Query) instead.
- Separate concerns: one `useEffect` per logical side-effect.

### useMemo & useCallback
- Use `useMemo` for expensive computations (e.g., sorting/filtering large arrays).
- Use `useCallback` when passing stable callbacks to memoized children.
- Don't wrap everything — the overhead of memoization can exceed the benefit for cheap operations.

### Custom Hooks
- Extract reusable logic into custom hooks (e.g., `useLocalStorage`, `useMediaQuery`, `useIntersectionObserver`).
- Return an object (not an array) from custom hooks for named access.

## State Management

### Local State First
- Start with `useState` / `useReducer` at the component level.
- Lift state up only when truly shared between sibling components.

### Global State
- Use React Context sparingly — it triggers re-renders on all consumers when any value changes.
- For frequent updates or complex state, use Zustand, Jotai, or Redux Toolkit.
- Structure stores by domain slice, not by UI section.

### Server State
- Use TanStack React Query (or SWR) for server data: caching, refetching, optimistic updates, and pagination.
- Keep server state separate from UI state. Do not duplicate server data in a global store.

## Performance

- **React.lazy + Suspense**: Code-split at route level or for heavy components below the fold.
- **React.memo**: Wrap pure presentational components that receive the same props frequently.
- **Virtualization**: Use `react-window` or `@tanstack/react-virtual` for lists with 100+ items.
- **Key prop**: Use stable, unique keys (`item.id`). Never use array index as key for dynamic lists.
- **Bundle analysis**: Periodically run `next/bundle-analyzer` or `vite-plugin-inspect` to find large dependencies.

## Next.js Specific

- **Pages Router vs App Router**: Prefer App Router (`app/`) for new projects.
- **Server Components by default**: Only add `'use client'` when you need interactivity, hooks, or browser APIs.
- **Data fetching**: Use `fetch` with `next: { revalidate }` for ISR, or `generateStaticParams` for SSG. No `getServerSideProps`/`getStaticProps` in App Router.
- **Layouts**: Use `layout.tsx` for persistent UI (headers, sidebars). Nest layouts for multi-level shells.
- **Image optimization**: Use `next/image` for automatic optimization, lazy loading, and responsive srcsets.

## Testing

- **Unit**: Vitest (or Jest) + Testing Library. Test behavior, not implementation.
- **Integration**: Use `@testing-library/react` with `userEvent` (not `fireEvent`).
- **E2E**: Playwright or Cypress for critical user flows.
- **Coverage**: Focus on user-visible behavior (renders, interactions, API calls) — not internal utilities.
