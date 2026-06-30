---
name: spring-boot-testing
description: "Apply this skill whenever writing or reviewing unit and slice tests for Java 17 / Spring Boot 3.x microservices that proxy a legacy Core monolith. Triggers: testing a service, controller, mapper, or Core HTTP call; mentions of JUnit 5, Mockito, MockRestServiceServer, @WebMvcTest, @MockBean, or AssertJ; deciding what is and isn't worth testing. Enforces: mock RestTemplate and assert behaviour; validate input rejection at the controller slice; assert Core URL/method/body with MockRestServiceServer and always verify(); test error paths (Core 4xx/5xx); use AssertJ; one behaviour per test; descriptive shouldXxx names; no H2/real Oracle, no Thread.sleep, no unexplained @Disabled."
---

# TESTING.md — Unit Testing Guide


## Stack

- **JUnit 5** (`@ExtendWith(MockitoExtension.class)`)
- **Mockito** for mocking
- **MockRestServiceServer** for asserting RestTemplate calls to Core
- **`@WebMvcTest`** for controller slice tests
- **No H2, no real Oracle** in unit or integration tests

## What to Test

### Service layer — mock RestTemplate, assert behaviour

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private OrderService orderService;

    @Test
    void shouldReturnMappedOrderWhenCoreResponds() {
        CoreOrderDto coreDto = new CoreOrderDto("ORD-1", "PENDING");
        when(restTemplate.getForObject(anyString(), eq(CoreOrderDto.class)))
            .thenReturn(coreDto);

        OrderResponse result = orderService.findById("ORD-1");

        assertThat(result.id()).isEqualTo("ORD-1");
        assertThat(result.status()).isEqualTo(Status.PENDING);
    }
}
```

### Controller — validate input rejection before the service is reached

```java
@WebMvcTest(OrderController.class)
class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private OrderService orderService;

    @Test
    void shouldReturn400WhenIdIsBlank() throws Exception {
        mockMvc.perform(get("/orders/ "))
            .andExpect(status().isBadRequest());
    }
}
```

### Core HTTP calls — assert correct URL, method, and body

```java
@SpringBootTest
class OrderServiceIntegrationTest {

    @Autowired RestTemplate restTemplate;
    @Autowired OrderService orderService;

    private MockRestServiceServer mockServer;

    @BeforeEach
    void setUp() {
        mockServer = MockRestServiceServer.createServer(restTemplate);
    }

    @Test
    void shouldCallCoreWithCorrectUrl() {
        mockServer.expect(requestTo("http://core/api/orders/ORD-1"))
            .andExpect(method(HttpMethod.GET))
            .andRespond(withSuccess("""
                {"id":"ORD-1","status":"PENDING"}
                """, MediaType.APPLICATION_JSON));

        orderService.findById("ORD-1");

        mockServer.verify(); // fails if unexpected calls were made
    }
}
```

### Error paths — Core 4xx/5xx handling

```java
@Test
void shouldThrowNotFoundWhenCore404() {
    when(restTemplate.getForObject(anyString(), eq(CoreOrderDto.class)))
        .thenThrow(new HttpClientErrorException(HttpStatus.NOT_FOUND));

    assertThatThrownBy(() -> orderService.findById("ORD-X"))
        .isInstanceOf(OrderNotFoundException.class);
}
```

### Pure mapping logic — no Spring context needed

```java
class OrderMapperTest {
    private final OrderMapper mapper = new OrderMapper();

    @Test
    void shouldMapPendingStatus() {
        assertThat(mapper.map("PENDING")).isEqualTo(Status.PENDING);
    }

    @Test
    void shouldThrowForUnknownStatus() {
        assertThatThrownBy(() -> mapper.map("UNKNOWN"))
            .isInstanceOf(IllegalArgumentException.class);
    }
}
```

## What NOT to Test

- That Spring wires beans correctly
- That `RestTemplate` makes HTTP calls (it's a library)
- Lombok-generated getters, setters, builders
- Configuration loading
- Batch jobs (they live in Core)

## Rules

- Use **AssertJ** (`assertThat(...)`) — better failure messages than JUnit assertions
- One behaviour per test — if you have 3 unrelated `verify()` calls, split the test
- Method names: `shouldReturn404WhenOrderNotFoundInCore`, not `testFindById`
- Always call `mockServer.verify()` after MockRestServiceServer tests
- No `@Disabled` without a comment and a ticket reference
- No `Thread.sleep()` — it signals a design problem
