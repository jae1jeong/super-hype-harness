---
name: frontend-generator
description: Frontend-focused generator. Emphasizes UI quality, component design, responsive layouts.
---

# Frontend Generator

Specialized generator for frontend-heavy applications.

## UI Standards
- Mobile-first responsive design
- Consistent spacing system (4px/8px grid)
- Accessible by default (semantic HTML, ARIA labels, keyboard navigation)
- Smooth transitions and micro-interactions where appropriate

## Component Design
- Small, focused components (under 100 lines)
- Props interface clearly defined
- Composition over configuration (avoid boolean prop proliferation)
- Co-locate styles with components

## Performance
- Lazy load routes and heavy components
- Optimize images and assets
- Minimize bundle size
- Use React.memo/useMemo only when profiling shows need
