---
name: angular-vercel
description: "Apply this skill whenever working on an Angular 22 PWA with a Vercel serverless API backend. Triggers: Angular components, signals, standalone, inject(), Vercel API routes, i18n, Zod validation, MongoDB, Auth.js, or any Angular + Vercel TypeScript codebase. Enforces: English-only code, MVVM pattern, Angular standalone components with signals and inject(), Zod validation on API routes, vanilla CSS with CSS variables, and simplicity-first principles."
---

# Angular 22 + Vercel — Coding Guidelines

## Stack

| Layer | Technology |
|---|---|
| Frontend | Angular 22, TypeScript, standalone components |
| State | Angular Signals (`signal`, `computed`, `effect`) |
| Styling | Vanilla CSS, CSS custom properties (`var(--...)`) |
| i18n | Custom `I18nService` — JSON locale files under `/public/i18n/` |
| API routes | Vercel serverless functions (`/api/*.ts`) |
| Server lib | `/server/lib/` — db, auth, session, cors, audit helpers |
| Database | MongoDB (default) or DynamoDB via `DB_PROVIDER` env var |
| Auth | Auth.js (`@auth/core`) — OAuth providers, database sessions |
| Validation | Zod — schemas in `/server/schemas/`, shared types in `core/models/` |
| Testing | Vitest (unit), `ng test` (Angular) |
| Linting | ESLint + angular-eslint, Prettier |
| Deploy | Vercel |

---

## 1. Code Language: English Only

**All code must be written in English.** No exceptions.

- Variable names, function names, class names, interfaces → English
- Comments → English
- File names → English (kebab-case for Angular, camelCase for server)
- User-facing text is **not** code — it goes through i18n (see §7)

```ts
// ✗ Wrong
const fichaAvaliacao = await col.findOne({ userId });
function buscarAlunos() { ... }

// ✓ Correct
const assessmentSheet = await col.findOne({ userId });
function fetchStudents() { ... }
```

---

## 2. Think Before Coding

- State assumptions explicitly before writing code that depends on unclear behaviour.
- If there are multiple valid approaches, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- Flag technical debt without silently fixing unrelated code.

---

## 3. Simplicity First

Minimum code that solves the problem today.

- No features beyond what was asked.
- No abstractions for single-use code.
- No generic wrappers or base classes for logic used in one place.
- No speculative "we might need this later" code.

---

## 4. Surgical Changes

- Touch only what you must.
- Don't refactor code that isn't broken when making a targeted fix.
- Don't improve formatting, naming, or structure of code you weren't asked to change.
- Match existing patterns in the codebase, even if you'd do it differently.

---

## 5. Architecture: Contracted MVVM (Socket Pattern)

The frontend follows **MVVM with explicit interface contracts** — each screen defines a "socket" (interface) the implementation must fit into.

### Layers

| Layer | What it is | Where it lives |
|---|---|---|
| **Model** | Domain types and Zod schemas | `core/models/` |
| **Contracts** | `IXxxView` + `IXxxController` interfaces | `features/**/*.contracts.ts` |
| **ViewModel** | Page component — implements both contracts, injects services | `features/**/*.page.ts` |
| **View** | Declarative template — no logic, only bindings | `features/**/*.html` |

### File structure per feature

```
features/items/
  items.contracts.ts   — IItemsView + IItemsController
  items.page.ts        — ItemsPage implements both
  items.html
  items.css
```

### Contracts first

```ts
// items.contracts.ts
import type { Signal } from '@angular/core';
import type { Item, CreateItem } from '../../core/models';

export interface IItemsView {
  readonly items: Signal<Item[]>;
  readonly loading: Signal<boolean>;
  readonly saving: Signal<boolean>;
  readonly showList: Signal<boolean>; // computed signals also satisfy Signal<T>
}

export interface IItemsController {
  load(): void;
  create(data: CreateItem): void;
  remove(id: string): void;
}
```

### Page implements both contracts

```ts
// items.page.ts
@Component({ selector: 'app-items', standalone: true, ... })
export class ItemsPage implements IItemsView, IItemsController {
  private readonly service = inject(ItemService); // Model injected

  // ── IItemsView ───────────────────────────────────────────
  readonly items   = signal<Item[]>([]);
  readonly loading = signal(false);
  readonly saving  = signal(false);
  readonly showList = computed(() => this.items().length > 0 && !this.loading());

  // ── IItemsController ─────────────────────────────────────
  load(): void { ... }
  create(data: CreateItem): void { ... }
  remove(id: string): void { ... }
}
```

### Rules

- **Contracts before implementation** — write `*.contracts.ts` first.
- **No logic in templates** — computed signals in ViewModel, not inline expressions.
- **No direct service calls from templates** — ViewModel mediates everything.
- **`Signal<T>` in interfaces** — declare as `Signal<T>` (both `signal()` and `computed()` satisfy it).

---

## 6. Angular Patterns

### Components
- Always standalone (`standalone: true`).
- Use `inject()` — never constructor injection.
- State via signals: `signal()`, `computed()`, `effect()`.
- One `.html` + one `.css` per component — no inline templates or styles.

```ts
@Component({
  selector: 'app-example',
  standalone: true,
  imports: [FormsModule, DatePipe],
  templateUrl: './example.html',
  styleUrl: './example.css',
})
export class ExamplePage {
  private readonly service = inject(ExampleService);

  readonly items = signal<Item[]>([]);
  readonly loading = signal(false);
  readonly hasItems = computed(() => this.items().length > 0);
}
```

### Services
- `@Injectable({ providedIn: 'root' })`.
- Inject `HttpClient` via `inject(HttpClient)`.
- Always pass `withCredentials: true` on API calls.
- Return `Observable<T>` — do not subscribe inside services.

```ts
@Injectable({ providedIn: 'root' })
export class ItemService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiUrl}/api/items`;

  list(): Observable<Item[]> {
    return this.http.get<Item[]>(this.base, { withCredentials: true });
  }
}
```

### Routing
- All feature pages lazy-loaded via `loadComponent`.
- Guards as plain functions (`CanActivateFn`) — not class-based.

---

## 7. i18n Rules

**Every user-facing string in templates must go through the i18n service.**

```html
<!-- ✗ Wrong -->
<button title="Delete">Save</button>
<p>No records found</p>

<!-- ✓ Correct -->
<button [title]="i18n.t('common.delete')">{{ i18n.t('common.save') }}</button>
<p>{{ i18n.t('items.empty') }}</p>
```

- Keys are dot-namespaced: `feature.action` or `feature.sub.action`.
- Key names are in English.
- When adding a key, add it to **all** locale files in the same change.

---

## 8. API Routes (Vercel)

Pattern for every `/api/*.ts` handler:

```ts
export default async function handler(req: any, res: any): Promise<void> {
  setCors(res, req);
  if (handleOptions(req, res)) return;

  const userId = await requireSession(req, res); // 401 if unauthenticated
  if (!userId) return;

  const col = await getCollection('items');

  try {
    if (req.method === 'GET') {
      const docs = await col.find({ userId }).toArray();
      res.status(200).json(docs.map(mapDocumentId));
      return;
    }
    if (req.method === 'POST') {
      const body = CreateItemSchema.parse(req.body);
      const result = await col.insertOne({ ...body, userId, createdAt: new Date() });
      res.status(201).json({ id: result.insertedId.toString() });
      return;
    }
    res.status(405).json({ error: 'Method not allowed' });
  } catch (err) {
    if (err instanceof ZodError) {
      res.status(400).json({ error: 'Invalid input', details: err.errors });
      return;
    }
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
}
```

- Always call `requireSession` — no unauthenticated routes except health/auth callbacks.
- Validate every request body with Zod — never trust raw `req.body`.
- Use `mapDocumentId` when returning MongoDB documents.
- Authorization checks (ownership, role) go **inside** the route handler, not the db layer.

---

## 9. Schemas and Models

- Zod schemas in `/server/schemas/` (API validation) and `src/app/core/models/` (shared frontend types).
- Always export both the schema and the inferred type:

```ts
export const CreateItemSchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
});
export type CreateItem = z.infer<typeof CreateItemSchema>;
```

- Don't duplicate shapes — import from `core/models` when the frontend needs the same type.

---

## 10. Styling

- Vanilla CSS — no CSS frameworks or component libraries.
- Use CSS custom properties (`var(--c-primary)`, `var(--c-danger)`, etc.) for colours and spacing.
- One `.css` file per component — scoped to that component.
- No inline styles except for dynamic values (e.g. `[style.color]="item.color"`).
- Dark mode via `[data-theme="dark"]` on `<html>` — always test both themes.

---

## 11. Configuration

- Frontend config: `environment.ts` / `environment.development.ts`.
- Backend config: environment variables — never hardcoded.
- Secrets (DB URIs, OAuth keys) go in `.env.local` locally and Vercel project settings in production.

---

## 12. Testing

- Unit tests: Vitest (`vitest run`) for services, utils, Zod schemas.
- Angular tests: `ng test` for components with complex behaviour.
- Run `lint` and `format:check` before committing.
