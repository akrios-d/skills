---
name: socket-pattern
description: "Apply this skill whenever designing or implementing screens using the Socket Pattern — a Full-Stack Hexagonal architecture where every boundary is defined by an explicit interface contract. Triggers: creating a new screen, page, component, or feature; mentions of ViewModel, ModelView, ViewController, IView, IController, IModel, socket pattern, contracted MVVM, hexagonal, ports and adapters, plug and play architecture. Enforces: define IModel + IView + IController interfaces first, ModelView implements IModel+IView, ViewController implements IView+IController, IView is the shared port between them, no logic in templates."
---

# Socket Pattern — Full-Stack Hexagonal UI Architecture

A UI architecture where every boundary between layers is defined by an explicit interface contract before any implementation is written. The interface is the **socket** — it defines the shape. The implementation is the **plug** — it must conform to the shape.

Coined as "Socket Pattern" for its USB analogy: any plug that fits the socket works, regardless of what's inside.

---

## Core Concept

Every screen has **three interface contracts** and **two implementation classes**:

```
IModel  ──┐
           ├──► ModelView    (service/class — owns data fetching + reactive state)
IView   ──┤
           │
IView   ──┤
           ├──► ViewController  (component — owns template binding + user actions)
IController ──┘
```

`IView` is the **shared port** — the contract between data and UI. The ViewController never knows how data is fetched. The ModelView never knows how it's displayed.

---

## Layer Map

| Layer | Role | File |
|---|---|---|
| **IModel** | Data operations contract | `*.contracts.ts` |
| **IView** | Reactive state contract (the shared port) | `*.contracts.ts` |
| **IController** | User action contract | `*.contracts.ts` |
| **ModelView** | Implements IModel + IView. Fetches data, produces reactive state | `*.viewmodel.ts` |
| **ViewController** | Implements IView + IController. Binds template, handles actions | `*.page.ts` / component |
| **View** | Pure template/markup — zero logic | `*.html` / JSX / template |

---

## Step-by-Step: Creating a Screen

### 1. Define the three contracts first

Before writing any implementation, define what each layer exposes:

```ts
// orders.contracts.ts

export interface IOrderModel {
  fetchOrders(userId: string): Promise<Order[]>;
  saveOrder(data: CreateOrder): Promise<Order>;
  deleteOrder(id: string): Promise<void>;
}

export interface IOrderView {
  readonly orders: Signal<Order[]>;
  readonly loading: Signal<boolean>;
  readonly saving: Signal<boolean>;
  readonly isEmpty: Signal<boolean>;    // derived state — still Signal<boolean>
  readonly canCreate: Signal<boolean>;  // derived from role/auth
}

export interface IOrderController {
  load(): void;
  create(data: CreateOrder): void;
  remove(id: string): void;
}
```

### 2. Implement the ModelView

Knows data. Produces reactive state. Pure class — no UI concerns:

```ts
// orders.viewmodel.ts
@Injectable()
export class OrderViewModel implements IOrderView {
  private readonly model = inject(OrderService); // IOrderModel

  // ── IOrderView ───────────────────────────────────────────
  readonly orders  = signal<Order[]>([]);
  readonly loading = signal(false);
  readonly saving  = signal(false);
  readonly isEmpty  = computed(() => this.orders().length === 0 && !this.loading());
  readonly canCreate = computed(() => this.auth.role() === 'admin');

  load(): void {
    this.loading.set(true);
    this.model.fetchOrders(this.userId).then(data => {
      this.orders.set(data);
      this.loading.set(false);
    });
  }
}
```

### 3. Implement the ViewController

Knows UI. Injects the ModelView via IView. Handles user actions:

```ts
// orders.page.ts
@Component({
  selector: 'app-orders',
  standalone: true,
  providers: [OrderViewModel],   // scoped to this component — not singleton
  templateUrl: './orders.html',
})
export class OrdersPage implements IOrderController {
  private readonly vm = inject(OrderViewModel); // IOrderView

  // Delegate all view state to the ViewModel
  readonly orders    = this.vm.orders;
  readonly loading   = this.vm.loading;
  readonly isEmpty   = this.vm.isEmpty;
  readonly canCreate = this.vm.canCreate;

  ngOnInit() { this.vm.load(); }

  // ── IOrderController ─────────────────────────────────────
  create(data: CreateOrder): void { ... }
  remove(id: string): void { ... }
}
```

### 4. Write the template against IView + IController only

The template only uses names that exist in the two interfaces. Nothing else:

```html
<!-- orders.html -->
@if (loading()) {
  <app-spinner />
} @else if (isEmpty()) {
  <p>{{ i18n.t('orders.empty') }}</p>
} @else {
  @for (order of orders(); track order.id) {
    <app-order-card [order]="order" (remove)="remove(order.id)" />
  }
}
@if (canCreate()) {
  <button (click)="create(form.value)">{{ i18n.t('orders.create') }}</button>
}
```

---

## Rules

### Contracts always first
Write `*.contracts.ts` before any implementation. The interface is the design decision. Implementation is mechanical.

### IView is the only bridge
The ViewController must NOT inject the ModelView directly by class if you want full substitutability. Inject by class for pragmatism, but only call what IView declares.

### No logic in templates
Every conditional, filter, or derived value is a `computed()` in the ModelView, declared in IView. The template only reads signals and calls controller methods.

```ts
// ✗ Wrong — logic in template
@if (orders().length > 0 && !loading() && user().role === 'admin')

// ✓ Correct — logic in ModelView, exposed via IOrderView
readonly showList = computed(
  () => this.orders().length > 0 && !this.loading() && this.isAdmin()
);
```

### ModelView is always scoped to the component
Use `providers: [XxxViewModel]` on the `@Component` decorator, not `providedIn: 'root'`. This ties the ViewModel's lifecycle to the component — no stale state across navigations.

### Model is always injected into the ModelView
The ModelView never instantiates services. It injects them. The ViewController never touches the Model.

---

## Framework Implementations

### React (hooks) — most natural fit

Hooks are scoped to the component instance automatically — no singleton concern:

```ts
// useOrderViewModel.ts — ModelView as a hook
function useOrderViewModel(): IOrderView & Pick<IOrderController, 'load'> {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(false);
  const isEmpty = orders.length === 0 && !loading;
  const canCreate = useAuth().role === 'admin';

  const load = useCallback(async () => {
    setLoading(true);
    setOrders(await orderService.fetchOrders());
    setLoading(false);
  }, []);

  return { orders, loading, isEmpty, canCreate, load };
}

// OrdersPage.tsx — ViewController as a component
function OrdersPage() {
  const vm = useOrderViewModel();             // IOrderView
  const { create, remove } = useOrderController(vm); // IOrderController

  useEffect(() => { vm.load(); }, []);

  return <OrdersView {...vm} onCreate={create} onRemove={remove} />;
}
```

### SwiftUI — native fit

```swift
// OrderViewModel.swift — ModelView
@MainActor
class OrderViewModel: ObservableObject, IOrderView {
  @Published var orders: [Order] = []
  @Published var loading = false
  var isEmpty: Bool { orders.isEmpty && !loading }

  private let model: IOrderModel

  init(model: IOrderModel = OrderService()) { self.model = model }

  func load() async { ... }
}

// OrdersView.swift — ViewController
struct OrdersView: View, IOrderController {
  @StateObject private var vm = OrderViewModel()

  var body: some View {
    Group {
      if vm.loading { ProgressView() }
      else if vm.isEmpty { EmptyStateView(onCreate: create) }
      else { OrderListView(orders: vm.orders, onRemove: remove) }
    }
    .task { await vm.load() }
  }

  func create(_ data: CreateOrder) { ... }
  func remove(_ id: String) { ... }
}
```

### Jetpack Compose — native fit

```kotlin
// OrderViewModel.kt — ModelView
class OrderViewModel(private val model: IOrderModel) : ViewModel(), IOrderView {
  private val _orders = MutableStateFlow<List<Order>>(emptyList())
  override val orders: StateFlow<List<Order>> = _orders.asStateFlow()
  override val loading = MutableStateFlow(false)
  override val isEmpty = combine(orders, loading) { o, l -> o.isEmpty() && !l }
    .stateIn(viewModelScope, SharingStarted.Lazily, true)

  override fun load() { viewModelScope.launch { ... } }
}

// OrdersScreen.kt — ViewController
@Composable
fun OrdersScreen(vm: OrderViewModel = viewModel()) {
  val orders by vm.orders.collectAsState()
  val isEmpty by vm.isEmpty.collectAsState()

  if (isEmpty) EmptyState(onCreate = vm::create)
  else OrderList(orders = orders, onRemove = vm::remove)
}
```

---

## Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Model interface | `IXxxModel` | `IOrderModel` |
| View interface | `IXxxView` | `IOrderView` |
| Controller interface | `IXxxController` | `IOrderController` |
| Contracts file | `xxx.contracts.ts` | `orders.contracts.ts` |
| ModelView | `XxxViewModel` | `OrderViewModel` |
| ViewController | `XxxPage` / `XxxScreen` | `OrdersPage` |
| Computed booleans | Descriptive names | `isEmpty`, `canCreate`, `showList` |

---

## What This Is Not

- **Not MVC** — no separate Controller class; actions live in the ViewController alongside view state.
- **Not classic MVVM** — adds an explicit `IView` port between the two classes, and splits ViewModel into ModelView (data side) and ViewController (UI side).
- **Not over-engineering** — the contracts file is 15–30 lines. The benefit is permanent clarity, testability without a DOM, and substitutable implementations.

---

## Connection to Hexagonal Architecture

This pattern extends **Ports & Adapters (Hexagonal)** to the UI layer:

```
Template / Markup              ← outer shell
    ↕  IXxxView / IXxxController   ← UI port (Socket Pattern)
ModelView + ViewController
    ↕  IXxxModel / IService        ← domain port
Service layer
    ↕  ICollection / IEmailSender  ← infrastructure port (classic hexagonal)
MongoDB / Dynamo / SendGrid    ← adapters
```

Classic hexagonal defines ports only at the infrastructure boundary. The Socket Pattern closes the hexagon symmetrically — ports at every boundary, top to bottom.
