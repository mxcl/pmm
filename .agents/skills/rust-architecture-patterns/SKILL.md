---
name: rust-architecture-patterns
description: Software architecture and system design patterns for Rust applications. Use when designing module boundaries, planning application layers, implementing dependency injection, structuring domain logic, or organizing error handling across architectural boundaries.
---

# Rust Architecture Patterns

A comprehensive guide to software architecture and system design patterns for Rust applications.

## Table of Contents

1. [Architecture Philosophy](#1-architecture-philosophy)
2. [Architecture Pattern Comparison](#2-architecture-pattern-comparison)
3. [Hexagonal Architecture (Ports & Adapters)](#3-hexagonal-architecture-ports--adapters)
4. [Domain-Driven Design in Rust](#4-domain-driven-design-in-rust)
5. [Module Organization](#5-module-organization)
6. [Visibility Architecture](#6-visibility-architecture)
7. [Prelude Pattern](#7-prelude-pattern)
8. [Dependency Injection](#8-dependency-injection)
9. [Layered Error Handling](#9-layered-error-handling)
10. [Configuration Architecture](#10-configuration-architecture)
11. [Documentation Architecture](#11-documentation-architecture)
12. [Long-Term Maintainability](#12-long-term-maintainability)

---

## 1. Architecture Philosophy

### Core Principle: Managing Coupling to Volatile Code

The goal of software architecture is not perfection, but **managing coupling to volatile code**—keeping core domain logic isolated from implementation details that change at different rates. Rust's type system is your most powerful tool for this; use it to encode invariants at compile-time rather than enforcing them at runtime.

### Key Principles

| Principle | Description |
|-----------|-------------|
| **Dependencies flow inward** | Core domain has no external dependencies; outer layers depend on inner layers |
| **Start concrete, abstract when patterns emerge** | Don't prematurely generalize; wait for 3+ similar cases before abstracting |
| **Compile-time verification over runtime checks** | Leverage the type system to catch errors before production |
| **Default to private** | Explicitly choose what to expose; minimize public API surface |
| **Make illegal states unrepresentable** | Use types to enforce invariants at compile-time |

### Decision Framework

When designing a new Rust system, ask yourself:

1. What changes frequently? (Keep isolated in outer layers)
2. What is stable business logic? (Keep in the core domain)
3. What invariants must always hold? (Encode in the type system)
4. What can be verified at compile-time vs runtime? (Prefer compile-time)

---

## 2. Architecture Pattern Comparison

All three major architectural patterns—**Hexagonal (Ports & Adapters)**, **Onion**, and **Clean Architecture**—solve the same underlying problem: managing coupling to code that changes at different rates than your core business logic.

| Pattern | Core Concept | Best For | Rust Fit |
|---------|--------------|----------|----------|
| **Hexagonal** | Ports (interfaces) at boundaries, adapters (implementations) as pluggable modules | Maximum flexibility to swap infrastructure | Excellent—traits as ports |
| **Onion** | Concentric layers with dependencies pointing inward | Clear visual hierarchy, independent layer testing | Good—module hierarchy |
| **Clean** | Formal rules about layer responsibilities and communication | Very large teams needing strict guidelines | Heavier ceremony |

### Recommendation

For Rust projects, **hexagonal architecture pairs best with domain-driven design** because:

- Rust traits naturally express ports (interfaces)
- Adapters are easily swappable through trait implementations
- The dependency rule is enforceable through module visibility
- Testing is simplified with mock trait implementations

---

## 3. Hexagonal Architecture (Ports & Adapters)

Hexagonal architecture provides exceptional separation of concerns by isolating your business logic (the "domain") from external dependencies (infrastructure).

### Layer Diagram

```
                    ┌─────────────────────────────────────┐
                    │           Presentation              │
                    │    (HTTP handlers, CLI, GraphQL)    │
                    └─────────────────┬───────────────────┘
                                      │
                    ┌─────────────────▼───────────────────┐
                    │           Application               │
                    │   (Use cases, orchestration)        │
                    └─────────────────┬───────────────────┘
                                      │
        ┌─────────────────────────────▼─────────────────────────────┐
        │                        Domain                              │
        │  (Entities, Value Objects, Domain Services, Ports/Traits)  │
        └─────────────────────────────┬─────────────────────────────┘
                                      │
                    ┌─────────────────▼───────────────────┐
                    │          Infrastructure             │
                    │  (Database, HTTP clients, Email)    │
                    └─────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility | Dependencies |
|-------|----------------|--------------|
| **Domain** | Pure business logic, entities, domain services. Define ports (traits) here. | None (no external dependencies) |
| **Application** | Use cases and orchestration. Coordinates domain logic to fulfill application requirements. | Domain layer only |
| **Infrastructure** | Concrete implementations of abstractions from domain/application (databases, HTTP clients, external APIs). Adapters live here. | Domain, Application layers |
| **Presentation** | HTTP handlers, request/response mapping, CLI interface. | Application layer |

### The Dependency Rule

**Critical**: Outer layers depend on inner layers, never the reverse. This ensures your business logic remains testable and portable.

```
Presentation → Application → Domain ← Infrastructure
                              ↑
                      (implements ports)
```

The domain layer defines traits (ports) that describe what it needs. Infrastructure implements those traits (adapters). The domain never imports infrastructure code.

### Ports: Trait Definitions

Ports define interfaces that the domain needs. They live in the domain layer and have no external dependencies.

```rust
// crates/core/src/ports.rs - Define interfaces as traits

use crate::domain::{User, UserId, Email};
use crate::error::Result;
use async_trait::async_trait;
use chrono::{DateTime, Utc};

/// Repository port - how the domain accesses persistence
#[async_trait]
pub trait UserRepository: Send + Sync {
    async fn find_by_id(&self, id: UserId) -> Result<Option<User>>;
    async fn save(&self, user: &User) -> Result<()>;
    async fn delete(&self, id: UserId) -> Result<()>;
}

/// External service port - how the domain sends notifications
#[async_trait]
pub trait EmailService: Send + Sync {
    async fn send(&self, email: Email) -> Result<()>;
}

/// Clock port - for testable time
/// This allows injecting fake time in tests
pub trait Clock: Send + Sync {
    fn now(&self) -> DateTime<Utc>;
}

// Production implementation
pub struct SystemClock;

impl Clock for SystemClock {
    fn now(&self) -> DateTime<Utc> {
        Utc::now()
    }
}

// Test implementation
#[cfg(test)]
pub struct FakeClock {
    pub time: DateTime<Utc>,
}

#[cfg(test)]
impl Clock for FakeClock {
    fn now(&self) -> DateTime<Utc> {
        self.time
    }
}
```

### Adapters: Implementations

Adapters implement ports using concrete technologies. They live in the infrastructure layer.

```rust
// crates/infra/src/db/postgres_user_repo.rs - Adapter implementation

use async_trait::async_trait;
use sqlx::PgPool;
use my_core::ports::UserRepository;
use my_core::domain::{User, UserId};
use my_core::error::Result;

pub struct PostgresUserRepository {
    pool: PgPool,
}

impl PostgresUserRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl UserRepository for PostgresUserRepository {
    async fn find_by_id(&self, id: UserId) -> Result<Option<User>> {
        sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id.0)
            .fetch_optional(&self.pool)
            .await
            .map_err(Into::into)
    }
    
    async fn save(&self, user: &User) -> Result<()> {
        sqlx::query!(
            "INSERT INTO users (id, email, name) VALUES ($1, $2, $3)
             ON CONFLICT (id) DO UPDATE SET email = $2, name = $3",
            user.id.0, user.email.as_str(), user.name
        )
        .execute(&self.pool)
        .await?;
        Ok(())
    }
    
    async fn delete(&self, id: UserId) -> Result<()> {
        sqlx::query!("DELETE FROM users WHERE id = $1", id.0)
            .execute(&self.pool)
            .await?;
        Ok(())
    }
}
```

**HTTP Client Adapter Example:**

```rust
// crates/infra/src/http/stripe_gateway.rs

use async_trait::async_trait;
use reqwest::Client;
use my_core::ports::PaymentGateway;
use my_core::domain::{Payment, PaymentResult};
use my_core::error::Result;

pub struct StripePaymentGateway {
    client: Client,
    api_key: String,
}

impl StripePaymentGateway {
    pub fn new(api_key: impl Into<String>, client: Client) -> Self {
        Self {
            client,
            api_key: api_key.into(),
        }
    }
}

#[async_trait]
impl PaymentGateway for StripePaymentGateway {
    async fn process(&self, payment: Payment) -> Result<PaymentResult> {
        let response = self.client
            .post("https://api.stripe.com/v1/charges")
            .bearer_auth(&self.api_key)
            .json(&payment)
            .send()
            .await?;
        
        let result = response.json().await?;
        Ok(result)
    }
}
```

### Swappability Benefits

With adapters implementing ports, you can:

- Swap PostgreSQL for SQLite without changing domain code
- Replace Stripe with a different payment processor
- Use in-memory implementations for testing
- Add caching layers as decorators around adapters

---

## 4. Domain-Driven Design in Rust

DDD emphasizes modeling your software around the business domain using explicit types and relationships.

### Core Concepts

| Concept | Definition | Rust Implementation |
|---------|------------|---------------------|
| **Bounded Context** | Explicit boundary where a unified domain model applies | Workspace crate or module |
| **Entity** | Object with identity that persists over time | Struct with ID field |
| **Value Object** | Immutable object defined by its attributes | Newtype or tuple struct |
| **Aggregate** | Cluster of entities treated as a unit | Struct containing related entities |
| **Domain Service** | Business logic that doesn't fit in a single entity | Function or service struct |

### Bounded Contexts as Workspace Crates

Different bounded contexts may model the same concept differently. Each context gets its own crate:

```
workspace/
├── Cargo.toml
├── crates/
│   ├── ordering/              # Order bounded context
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── domain/
│   │       │   ├── mod.rs
│   │       │   ├── order.rs
│   │       │   └── customer.rs  # Customer as seen by ordering
│   │       ├── application/
│   │       └── infrastructure/
│   │
│   ├── inventory/             # Inventory bounded context
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── domain/
│   │       │   ├── mod.rs
│   │       │   ├── product.rs
│   │       │   └── warehouse.rs
│   │       ├── application/
│   │       └── infrastructure/
│   │
│   ├── shipping/              # Shipping bounded context
│   │   └── src/
│   │       ├── domain/
│   │       │   ├── shipment.rs
│   │       │   └── address.rs   # Address as seen by shipping
│   │       └── ...
│   │
│   └── shared/                # Shared kernel (if needed)
│       └── src/
│           ├── lib.rs
│           └── types.rs       # Truly shared types only
```

### Inter-Context Communication

Bounded contexts communicate through:

- **Events**: Publish domain events that other contexts subscribe to
- **Shared types**: Minimal shared kernel for truly common concepts
- **Translation layers**: Anti-corruption layers that translate between contexts

```rust
// crates/ordering/src/events.rs
pub enum OrderEvent {
    OrderPlaced { order_id: OrderId, customer_id: CustomerId },
    OrderShipped { order_id: OrderId, tracking_number: String },
}

// crates/shipping/src/handlers.rs
impl ShippingService {
    pub async fn handle_order_placed(&self, event: OrderEvent) -> Result<()> {
        if let OrderEvent::OrderPlaced { order_id, customer_id } = event {
            // Create shipment in shipping context
            let shipment = self.create_shipment(order_id, customer_id).await?;
            // ...
        }
        Ok(())
    }
}
```

### Domain vs Persistence Models

**Critical insight**: Don't treat domain models and persistence models as the same.

```rust
// Domain model - rich with behavior and validation
pub struct User {
    id: UserId,
    email: Email,           // Validated email type
    status: UserStatus,     // Rich enum with data
    created_at: DateTime<Utc>,
}

impl User {
    pub fn can_login(&self) -> bool {
        matches!(self.status, UserStatus::Active { .. })
    }
    
    pub fn suspend(&mut self, reason: String, by: UserId) {
        self.status = UserStatus::Suspended {
            reason,
            suspended_at: Utc::now(),
            suspended_by: by,
        };
    }
}

// Persistence model - flat structure for database
pub struct UserRow {
    pub id: i64,
    pub email: String,
    pub status: String,
    pub status_reason: Option<String>,
    pub status_changed_at: Option<DateTime<Utc>>,
    pub status_changed_by: Option<i64>,
    pub created_at: DateTime<Utc>,
}

// Conversion between models
impl TryFrom<UserRow> for User {
    type Error = DomainError;
    
    fn try_from(row: UserRow) -> Result<Self, Self::Error> {
        Ok(User {
            id: UserId(row.id as u64),
            email: Email::new(&row.email)?,
            status: UserStatus::from_row(&row)?,
            created_at: row.created_at,
        })
    }
}
```

---

## 5. Module Organization

### File-Based vs mod.rs Style

**Recommendation**: Use file-based modules (Rust 2018+ style):

```
src/
├── lib.rs
├── domain.rs           # NOT domain/mod.rs
├── domain/
│   ├── user.rs
│   └── order.rs
├── services.rs
└── services/
    ├── auth.rs
    └── payment.rs
```

In `lib.rs`:

```rust
mod domain;
mod services;

pub use domain::{User, Order};
pub use services::{AuthService, PaymentService};
```

In `domain.rs`:

```rust
mod user;
mod order;

pub use user::User;
pub use order::Order;
```

### Organizing by Responsibility

Organize modules by what they do, not by technical classification:

```
src/
├── lib.rs               # Public API re-exports
├── models/              # Domain entities, value objects
│   ├── mod.rs
│   ├── user.rs
│   └── order.rs
├── services/            # Business logic (use cases)
│   ├── mod.rs
│   ├── user_service.rs
│   └── order_service.rs
├── ports/               # Traits for dependencies
│   ├── mod.rs
│   ├── repository.rs
│   └── notification.rs
├── adapters/            # Implementations of ports
│   ├── mod.rs
│   ├── sqlite_repository.rs
│   └── email_notification.rs
└── error.rs             # Error types for this crate
```

### Module Naming Conventions

| Module Type | Naming | Example |
|-------------|--------|---------|
| Domain entity | Singular noun | `user.rs`, `order.rs` |
| Service | Noun + `_service` | `user_service.rs`, `auth_service.rs` |
| Repository port | Noun + `_repository` | `user_repository.rs` |
| Adapter | Technology + entity | `postgres_user_repo.rs`, `smtp_email.rs` |
| Error | `error.rs` at crate root | `error.rs` |

---

## 6. Visibility Architecture

### Visibility Hierarchy

| Visibility | Use Case | When to Use |
|------------|----------|-------------|
| `pub` | Stable public API | Carefully—think twice before using |
| `pub(crate)` | Internal to crate but shared across modules | Extensively—excellent intermediate boundary |
| `pub(super)` | Visible to parent module only | Helper functions used by siblings |
| `pub(in path)` | Visible to specific ancestor module | Rarely—when you need precise control |
| (private) | Default—implementation details | Always start here |

**Key principle**: Default to private, explicitly choose what to expose.

### Strategic Use of pub(crate)

`pub(crate)` exposes items within your crate but not to external consumers. Use it liberally:

```rust
// lib.rs - The public API facade
pub mod prelude;              // Convenient re-exports
pub mod domain;               // Public domain types
pub mod error;                // Public error types

mod internal;                 // Private implementation
pub(crate) mod utils;         // Crate-internal utilities

// Selective re-exports form your API
pub use domain::{User, Order};
pub use error::{Error, Result};
```

```rust
// internal/helpers.rs
pub(crate) fn validate_checksum(data: &[u8]) -> bool {
    // This function is available to all modules in the crate
    // but not exposed in the public API
    // ...
}
```

### The Facade Pattern with Re-exports

Hide complex internal structure behind a clean API:

```rust
// src/lib.rs
mod parser;
mod lexer;
mod ast;
mod codegen;

// Only expose what users need
pub use parser::parse;
pub use ast::Ast;
pub use codegen::generate;

// Internal types stay hidden
// Users don't see lexer::Token, parser::State, etc.
```

When modules grow complex, use `pub use` to create a facade that masks internal module structure:

```rust
// src/repositories/mod.rs - private internal structure
mod user;
mod product;
mod helpers;

// Expose through a clean public interface
pub use user::UserRepository;
pub use product::ProductRepository;
// helpers stays private
```

This pattern decouples the internal module hierarchy from the public API, allowing refactoring without breaking external code.

**Example: Selective Re-exports in lib.rs**

```rust
// src/lib.rs

// Private modules - internal structure
mod domain;
mod services;
mod infrastructure;
mod error;

// Public API - what external code sees
pub use domain::{
    User,
    UserId,
    Email,
    Order,
    OrderId,
};

pub use services::{
    UserService,
    OrderService,
};

pub use error::{Error, Result};

// Prelude for convenience
pub mod prelude {
    pub use crate::{User, UserId, Email, Order, OrderId};
    pub use crate::{UserService, OrderService};
    pub use crate::{Error, Result};
}
```

---

## 7. Prelude Pattern

### When to Create a Prelude

Create a prelude module when your library has many commonly-used types that users typically import together.

**Create a prelude when:**
- Users typically need 5+ types from your crate
- Types form a coherent set (error types, core traits, fundamental types)
- Your crate is used extensively in a codebase

**Don't create a prelude when:**
- Your crate has few public types
- Types are used independently
- Import clarity is more important than convenience

### What to Include

Include in your prelude:
- Core traits that users implement or call
- Common error types and Result alias
- Fundamental types used throughout
- Extension traits

Do NOT include:
- Rarely-used types
- Implementation details
- Everything (that's what `use crate::*` is for)

### Example Implementation

```rust
// src/prelude.rs

//! Convenience re-exports for common use.
//!
//! # Usage
//!
//! ```rust
//! use my_crate::prelude::*;
//! ```

// Core types
pub use crate::domain::{User, UserId, Email};
pub use crate::domain::{Order, OrderId, OrderItem};

// Error handling
pub use crate::error::{Error, Result};

// Traits users implement
pub use crate::ports::{Repository, Service};

// Traits users call methods on
pub use crate::traits::{Validate, Cacheable};

// Extension traits
pub use crate::extensions::ResultExt;
```

Users can then:

```rust
use my_crate::prelude::*;

fn process_user(user: User) -> Result<()> {
    user.validate()?;
    // ...
    Ok(())
}
```

---

## 8. Dependency Injection

### Generics vs Trait Objects Decision

| Aspect | Generics | Trait Objects (`dyn Trait`) |
|--------|----------|----------------------------|
| **Dispatch** | Static (monomorphization) | Dynamic (vtable) |
| **Performance** | Zero-cost, inlining possible | Small overhead (~2 pointer indirections) |
| **Binary size** | Larger (code duplicated per type) | Smaller (single code path) |
| **Flexibility** | Compile-time type resolution | Runtime type resolution |
| **Error messages** | Can be complex with many bounds | Simpler |
| **Use when** | Performance critical, types known at compile time | Runtime polymorphism, reducing generics bloat |

### Decision Guide Flowchart

```
Do you need runtime polymorphism (types determined at runtime)?
├── Yes → Use trait objects (dyn Trait)
└── No
    ├── Is this a hot path where performance matters?
    │   ├── Yes → Use generics
    │   └── No → Either works, prefer generics
    └── Are you experiencing compile time / binary size issues from generics?
        ├── Yes → Consider trait objects
        └── No → Use generics
```

### Constructor Injection (Recommended)

The most common and recommended pattern. Dependencies are injected through the constructor:

```rust
pub struct UserService<R, E, C> {
    repo: R,
    email: E,
    clock: C,
}

impl<R, E, C> UserService<R, E, C>
where
    R: UserRepository,
    E: EmailService,
    C: Clock,
{
    pub fn new(repo: R, email: E, clock: C) -> Self {
        Self { repo, email, clock }
    }
    
    pub async fn register(&self, input: RegisterInput) -> Result<User> {
        // Validate
        let email = Email::new(&input.email)?;
        
        // Create user with current time from injected clock
        let user = User {
            id: UserId::new(),
            email,
            created_at: self.clock.now(),
        };
        
        // Persist
        self.repo.save(&user).await?;
        
        // Send welcome email
        self.email.send(WelcomeEmail::for_user(&user)).await?;
        
        Ok(user)
    }
    
    pub async fn find(&self, id: UserId) -> Result<Option<User>> {
        self.repo.find_by_id(id).await
    }
}
```

**Testing with mocks:**

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    struct MockUserRepo {
        users: std::sync::Mutex<HashMap<UserId, User>>,
    }
    
    #[async_trait]
    impl UserRepository for MockUserRepo {
        async fn find_by_id(&self, id: UserId) -> Result<Option<User>> {
            Ok(self.users.lock().unwrap().get(&id).cloned())
        }
        
        async fn save(&self, user: &User) -> Result<()> {
            self.users.lock().unwrap().insert(user.id, user.clone());
            Ok(())
        }
        
        async fn delete(&self, id: UserId) -> Result<()> {
            self.users.lock().unwrap().remove(&id);
            Ok(())
        }
    }
    
    #[tokio::test]
    async fn test_register_user() {
        let repo = MockUserRepo::default();
        let email = MockEmailService::default();
        let clock = FakeClock { time: Utc::now() };
        
        let service = UserService::new(repo, email, clock);
        
        let user = service.register(RegisterInput {
            email: "test@example.com".to_string(),
        }).await.unwrap();
        
        assert_eq!(user.email.as_str(), "test@example.com");
    }
}
```

### Trait Object Based DI

When you need runtime flexibility or want to reduce generic complexity:

```rust
pub struct AppState {
    pub user_repo: Arc<dyn UserRepository>,
    pub email_service: Arc<dyn EmailService>,
    pub clock: Arc<dyn Clock>,
}

impl AppState {
    pub fn new(
        user_repo: impl UserRepository + 'static,
        email_service: impl EmailService + 'static,
        clock: impl Clock + 'static,
    ) -> Self {
        Self {
            user_repo: Arc::new(user_repo),
            email_service: Arc::new(email_service),
            clock: Arc::new(clock),
        }
    }
}

// Services use trait objects
pub struct UserService {
    state: Arc<AppState>,
}

impl UserService {
    pub fn new(state: Arc<AppState>) -> Self {
        Self { state }
    }
    
    pub async fn register(&self, input: RegisterInput) -> Result<User> {
        let user = User::new(input, self.state.clock.now())?;
        self.state.user_repo.save(&user).await?;
        self.state.email_service.send(WelcomeEmail::for_user(&user)).await?;
        Ok(user)
    }
}
```

**When to use trait objects:**
- Many dependencies make generic signatures unwieldy
- Dependencies are determined at runtime (e.g., based on configuration)
- You want to reduce compile times and binary size
- Web frameworks that work better with concrete types (Axum state)

### Composition Root Pattern

Wire up all dependencies in one place, typically in `main.rs` or a dedicated module:

```rust
// crates/cli/src/main.rs or crates/app/src/composition.rs

use my_core::ports::*;
use my_infra::*;
use my_app::services::*;
use std::sync::Arc;
use std::time::Duration;

pub struct App {
    pub user_service: UserService<PostgresUserRepository, SmtpEmailService, SystemClock>,
    pub order_service: OrderService<PostgresOrderRepository, StripePaymentGateway, SmtpEmailService>,
    pub config: Config,
}

async fn build_app(config: Config) -> Result<App> {
    // ═══════════════════════════════════════════════════════════
    // Infrastructure layer - concrete implementations
    // ═══════════════════════════════════════════════════════════
    let pool = PgPool::connect(&config.database_url).await?;
    let http_client = reqwest::Client::builder()
        .timeout(Duration::from_secs(30))
        .build()?;
    
    // ═══════════════════════════════════════════════════════════
    // Adapters - implement ports from domain
    // ═══════════════════════════════════════════════════════════
    let user_repo = PostgresUserRepository::new(pool.clone());
    let order_repo = PostgresOrderRepository::new(pool.clone());
    let email_service = SmtpEmailService::new(&config.smtp);
    let payment_gateway = StripePaymentGateway::new(&config.stripe, http_client);
    let clock = SystemClock;
    
    // ═══════════════════════════════════════════════════════════
    // Application services - business logic orchestration
    // ═══════════════════════════════════════════════════════════
    let user_service = UserService::new(user_repo, email_service.clone(), clock);
    let order_service = OrderService::new(order_repo, payment_gateway, email_service);
    
    Ok(App {
        user_service,
        order_service,
        config,
    })
}

#[tokio::main]
async fn main() -> Result<()> {
    // Load configuration
    let config = Config::load()?;
    
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(&config.logging.level)
        .init();
    
    // Build application with all dependencies wired up
    let app = build_app(config).await?;
    
    // Start server
    app.run().await
}
```

### Avoid Heavy DI Frameworks

Rust's type system provides compile-time DI. Frameworks like `shaku` or `inject` add complexity rarely needed. Prefer:

- Constructor injection with generics (most cases)
- Trait objects where runtime flexibility is needed
- Simple factory functions for complex construction

---

## 9. Layered Error Handling

### Error Types per Layer

Each architectural layer defines its own errors and maps lower-layer errors at boundaries.

```rust
// ═══════════════════════════════════════════════════════════════
// crates/core/src/error.rs - Domain errors (no external deps)
// ═══════════════════════════════════════════════════════════════

use thiserror::Error;

#[derive(Debug, Error)]
pub enum DomainError {
    #[error("invalid email format: {0}")]
    InvalidEmail(String),
    
    #[error("user not found: {0}")]
    UserNotFound(UserId),
    
    #[error("business rule violation: {0}")]
    BusinessRule(String),
    
    #[error("insufficient permissions for {action}")]
    Unauthorized { action: &'static str },
}

pub type DomainResult<T> = std::result::Result<T, DomainError>;
```

```rust
// ═══════════════════════════════════════════════════════════════
// crates/infra/src/error.rs - Infrastructure errors
// ═══════════════════════════════════════════════════════════════

use thiserror::Error;

#[derive(Debug, Error)]
pub enum InfraError {
    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),
    
    #[error("network error: {0}")]
    Network(#[from] reqwest::Error),
    
    #[error("serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
    
    #[error("resource not found")]
    NotFound,
}
```

```rust
// ═══════════════════════════════════════════════════════════════
// crates/app/src/error.rs - Application errors (combines both)
// ═══════════════════════════════════════════════════════════════

use thiserror::Error;
use my_core::error::DomainError;
use my_infra::error::InfraError;

#[derive(Debug, Error)]
pub enum AppError {
    #[error(transparent)]
    Domain(#[from] DomainError),
    
    #[error(transparent)]
    Infra(#[from] InfraError),
    
    #[error("configuration error: {0}")]
    Config(String),
    
    #[error("internal error")]
    Internal(#[source] anyhow::Error),
}

pub type AppResult<T> = std::result::Result<T, AppError>;

// Convert infrastructure "not found" to domain "user not found"
impl AppError {
    pub fn user_not_found(id: UserId, source: InfraError) -> Self {
        match source {
            InfraError::NotFound => AppError::Domain(DomainError::UserNotFound(id)),
            other => AppError::Infra(other),
        }
    }
}
```

### Error Conversion at Boundaries

Use `From` implementations for automatic conversion with `?`:

```rust
// In application layer service
impl UserService {
    pub async fn get_user(&self, id: UserId) -> AppResult<User> {
        // InfraError automatically converts to AppError via From
        let user = self.repo.find_by_id(id).await?
            .ok_or_else(|| AppError::Domain(DomainError::UserNotFound(id)))?;
        
        Ok(user)
    }
}
```

For more complex mappings:

```rust
impl UserService {
    pub async fn get_user(&self, id: UserId) -> AppResult<User> {
        self.repo.find_by_id(id)
            .await
            .map_err(|e| AppError::user_not_found(id, e))?
            .ok_or_else(|| AppError::Domain(DomainError::UserNotFound(id)))
    }
}
```

### HTTP Error Conversion

Convert application errors to HTTP responses at the presentation layer:

```rust
// crates/api/src/error.rs

use axum::{
    response::{IntoResponse, Response},
    http::StatusCode,
    Json,
};
use serde_json::json;
use my_app::error::{AppError, DomainError};

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match &self {
            // Domain errors map to client errors
            AppError::Domain(DomainError::UserNotFound(_)) => {
                (StatusCode::NOT_FOUND, self.to_string())
            }
            AppError::Domain(DomainError::InvalidEmail(_)) |
            AppError::Domain(DomainError::BusinessRule(_)) => {
                (StatusCode::BAD_REQUEST, self.to_string())
            }
            AppError::Domain(DomainError::Unauthorized { .. }) => {
                (StatusCode::FORBIDDEN, self.to_string())
            }
            
            // Config errors are server errors
            AppError::Config(_) => {
                (StatusCode::INTERNAL_SERVER_ERROR, "configuration error".into())
            }
            
            // Infrastructure and internal errors: log but don't expose details
            AppError::Infra(_) | AppError::Internal(_) => {
                tracing::error!(error = ?self, "internal error");
                (StatusCode::INTERNAL_SERVER_ERROR, "internal error".into())
            }
        };
        
        (status, Json(json!({ "error": message }))).into_response()
    }
}
```

### Error Decision Tree

```
Is this a library or application?
├── Library → Use thiserror, define specific error enums
└── Application
    ├── Do you need to match on errors programmatically?
    │   ├── Yes → Use thiserror with domain-specific enums
    │   └── No → Use anyhow for convenience
    └── Hybrid: thiserror at boundaries, anyhow internally
```

---

## 10. Configuration Architecture

### Layered Configuration Pattern

Configuration should layer from most general to most specific:

```
Default → Environment-specific → Local overrides → Environment variables
```

Each layer overrides the previous, allowing:
- Sensible defaults in code/files
- Environment-specific settings (dev, staging, prod)
- Local developer overrides (gitignored)
- Environment variables for secrets and deployment config

### Config Struct Design

```rust
use serde::Deserialize;
use std::time::Duration;

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]  // Catch typos in config files
pub struct Config {
    #[serde(default)]
    pub server: ServerConfig,
    
    pub database: DatabaseConfig,  // Required - no default
    
    #[serde(default)]
    pub logging: LoggingConfig,
    
    #[serde(default)]
    pub features: FeatureFlags,
}

#[derive(Debug, Deserialize)]
pub struct ServerConfig {
    #[serde(default = "default_host")]
    pub host: String,
    
    #[serde(default = "default_port")]
    pub port: u16,
    
    #[serde(default = "default_timeout", with = "humantime_serde")]
    pub request_timeout: Duration,
    
    #[serde(default = "default_max_connections")]
    pub max_connections: usize,
}

impl Default for ServerConfig {
    fn default() -> Self {
        Self {
            host: default_host(),
            port: default_port(),
            request_timeout: default_timeout(),
            max_connections: default_max_connections(),
        }
    }
}

fn default_host() -> String { "127.0.0.1".into() }
fn default_port() -> u16 { 8080 }
fn default_timeout() -> Duration { Duration::from_secs(30) }
fn default_max_connections() -> usize { 100 }

#[derive(Debug, Deserialize)]
pub struct DatabaseConfig {
    pub url: String,
    
    #[serde(default = "default_pool_size")]
    pub pool_size: u32,
    
    #[serde(default)]
    pub ssl_mode: SslMode,
}

fn default_pool_size() -> u32 { 10 }

#[derive(Debug, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum SslMode {
    #[default]
    Prefer,
    Require,
    Disable,
}

#[derive(Debug, Default, Deserialize)]
pub struct LoggingConfig {
    #[serde(default = "default_log_level")]
    pub level: String,
    
    #[serde(default)]
    pub format: LogFormat,
}

fn default_log_level() -> String { "info".into() }

#[derive(Debug, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum LogFormat {
    #[default]
    Json,
    Pretty,
}

#[derive(Debug, Default, Deserialize)]
pub struct FeatureFlags {
    #[serde(default)]
    pub new_checkout: bool,
    
    #[serde(default)]
    pub beta_features: bool,
}
```

### Config Loading Implementation

Using the `config` crate for layered configuration:

```rust
use config::{Config as ConfigBuilder, Environment, File, ConfigError};

impl Config {
    pub fn load() -> Result<Self, ConfigError> {
        let env = std::env::var("APP_ENV").unwrap_or_else(|_| "development".into());
        
        ConfigBuilder::builder()
            // Layer 1: Start with defaults
            .add_source(File::with_name("config/default"))
            // Layer 2: Environment-specific config
            .add_source(File::with_name(&format!("config/{}", env)).required(false))
            // Layer 3: Local overrides (gitignored)
            .add_source(File::with_name("config/local").required(false))
            // Layer 4: Environment variables (APP_SERVER__PORT -> server.port)
            .add_source(
                Environment::with_prefix("APP")
                    .separator("__")
                    .try_parsing(true)
            )
            .build()?
            .try_deserialize()
    }
    
    pub fn validate(&self) -> Result<(), ConfigError> {
        if self.database.pool_size == 0 {
            return Err(ConfigError::Message("pool_size must be > 0".into()));
        }
        
        if self.server.port == 0 {
            return Err(ConfigError::Message("port must be > 0".into()));
        }
        
        Ok(())
    }
}
```

**Example config files:**

```toml
# config/default.toml
[server]
host = "127.0.0.1"
port = 8080
request_timeout = "30s"

[logging]
level = "info"
format = "json"

[features]
new_checkout = false
```

```toml
# config/production.toml
[server]
host = "0.0.0.0"
max_connections = 1000

[logging]
level = "warn"
```

```toml
# config/local.toml (gitignored)
[database]
url = "postgres://localhost/myapp_dev"

[logging]
level = "debug"
format = "pretty"
```

### Builder Pattern for Configuration

For complex configuration with validation, use a builder. The `bon` crate is the modern choice:

```rust
use bon::Builder;

#[derive(Builder, Debug)]
pub struct AppConfig {
    #[builder(into)]
    pub database_url: String,
    
    #[builder(default = 8080)]
    pub port: u16,
    
    #[builder(default = 10)]
    pub max_connections: u32,
    
    #[builder(default)]
    pub enable_metrics: bool,
}

// Usage
let config = AppConfig::builder()
    .database_url("postgres://localhost/myapp")
    .port(3000)
    .build();
```

**Builder Crate Comparison:**

| Crate | Type Safety | Features | Use Case |
|-------|-------------|----------|----------|
| `bon` | Compile-time | Functions + structs, Into | Modern default |
| `typed-builder` | Compile-time | Typestate pattern | Established choice |
| `derive_builder` | Runtime | Validation, flexible | Legacy, runtime checks |

---

## 11. Documentation Architecture

### Module-Level Documentation

Every crate and significant module should have documentation explaining its purpose:

```rust
//! # My Crate
//!
//! `my_crate` provides utilities for building scalable web services
//! with a focus on type safety and testability.
//!
//! ## Quick Start
//!
//! ```rust
//! use my_crate::prelude::*;
//!
//! #[tokio::main]
//! async fn main() -> Result<()> {
//!     let config = Config::load()?;
//!     let app = App::new(config).await?;
//!     app.run().await
//! }
//! ```
//!
//! ## Architecture
//!
//! This crate follows hexagonal architecture:
//!
//! - **Domain**: Core business logic in [`domain`] module
//! - **Ports**: Trait definitions in [`ports`] module  
//! - **Adapters**: Infrastructure implementations in [`adapters`] module
//!
//! ## Feature Flags
//!
//! - `postgres`: Enables PostgreSQL support (default)
//! - `sqlite`: Enables SQLite support
//! - `metrics`: Enables Prometheus metrics endpoint
```

### Type Documentation Template

```rust
/// A validated email address.
///
/// Email addresses are validated according to a simplified RFC 5322 pattern.
/// Use [`Email::new`] to create instances—direct construction is not possible.
///
/// # Examples
///
/// ```
/// use my_crate::Email;
///
/// // Valid email
/// let email = Email::new("user@example.com")?;
/// assert_eq!(email.domain(), "example.com");
///
/// // Invalid email returns error
/// assert!(Email::new("invalid").is_err());
/// # Ok::<(), my_crate::ValidationError>(())
/// ```
///
/// # Validation Rules
///
/// - Must contain exactly one `@` symbol
/// - Local part (before `@`) must be non-empty
/// - Domain part (after `@`) must be non-empty and contain at least one `.`
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Email(String);
```

### Function Documentation Template

```rust
/// Processes a batch of items concurrently with bounded parallelism.
///
/// This function spawns up to `max_concurrent` tasks at a time, collecting
/// results as they complete. Failed items are collected separately and
/// returned alongside successful results.
///
/// # Arguments
///
/// * `items` - The items to process
/// * `max_concurrent` - Maximum number of concurrent tasks (clamped to 1..=100)
/// * `processor` - Async function to apply to each item
///
/// # Returns
///
/// A tuple of (successful_results, failed_items_with_errors).
///
/// # Examples
///
/// ```
/// use my_crate::process_batch;
///
/// async fn fetch_url(url: String) -> Result<String, Error> {
///     // ...
/// }
///
/// let urls = vec!["https://a.com".into(), "https://b.com".into()];
/// let (successes, failures) = process_batch(urls, 10, fetch_url).await;
/// ```
///
/// # Errors
///
/// Individual item errors are collected in the failures vector.
/// The function itself only errors if the runtime is unavailable.
///
/// # Panics
///
/// Panics if the tokio runtime is not available.
pub async fn process_batch<T, R, E, F, Fut>(
    items: Vec<T>,
    max_concurrent: usize,
    processor: F,
) -> (Vec<R>, Vec<(T, E)>)
where
    T: Send + 'static,
    R: Send + 'static,
    E: Send + 'static,
    F: Fn(T) -> Fut + Send + Sync + 'static,
    Fut: Future<Output = Result<R, E>> + Send,
{
    // implementation
}
```

### Documentation Sections

| Section | Required | Purpose |
|---------|----------|---------|
| Summary | Yes | One-line description |
| Extended description | If complex | Detailed explanation |
| `# Examples` | For public items | Show typical usage |
| `# Arguments` | For functions with params | Describe each parameter |
| `# Returns` | For non-obvious returns | Describe return value |
| `# Errors` | If returns Result | Document error conditions |
| `# Panics` | If can panic | Document panic conditions |
| `# Safety` | For unsafe fn | Document safety requirements |

---

## 12. Long-Term Maintainability

### Stick to Stable Rust

Avoid nightly Rust features in production code. The stability guarantee means code written on stable today will compile in five years without modification. Nightly features may disappear or change.

```toml
# rust-toolchain.toml
[toolchain]
channel = "1.75"  # Pin to specific stable version
components = ["rustfmt", "clippy"]
```

### Conservative Feature Usage

Rust has powerful features that can make code hard to understand. Use them purposefully:

| Feature | Use When | Avoid When |
|---------|----------|------------|
| **Macros** | True code generation, DSLs | Simple abstractions (use functions/traits) |
| **Heavy Generics** | Actual type flexibility needed | Single concrete use case |
| **Complex Lifetimes** | Genuinely sharing references | Could restructure with ownership |
| **Unsafe** | FFI, performance-critical verified code | Convenience or "just to make it compile" |

### Feature Flags: Additive Only

Features should be **additive only**—they add capabilities, never remove them:

```toml
[features]
default = []

# Good: Adding capabilities
postgres = ["sqlx/postgres"]
sqlite = ["sqlx/sqlite"]
metrics = ["prometheus"]
full = ["postgres", "sqlite", "metrics"]

# Bad: Features that remove functionality
# no_logging = []  # Don't do this
```

Feature-gated implementations:

```rust
#[cfg(feature = "serde")]
impl serde::Serialize for MyType {
    // ...
}

#[cfg_attr(feature = "serde", derive(Serialize, Deserialize))]
pub struct Config {
    // ...
}
```

### Non-Exhaustive Enums

Mark public enums that may gain variants to allow future evolution:

```rust
#[non_exhaustive]
pub enum ApiError {
    NotFound,
    Unauthorized,
    RateLimited,
    // Future variants can be added without breaking downstream
}

// Library users must have a wildcard pattern
match error {
    ApiError::NotFound => { /* ... */ }
    ApiError::Unauthorized => { /* ... */ }
    ApiError::RateLimited => { /* ... */ }
    _ => { /* Handle unknown variants */ }  // Required
}
```

### SOLID Principles in Rust

| Principle | Rust Implementation |
|-----------|---------------------|
| **Single Responsibility** | Each module/struct has one reason to change |
| **Open/Closed** | Use traits and generics for extensibility without modification |
| **Liskov Substitution** | Trait implementations should be truly substitutable |
| **Interface Segregation** | Define focused, minimal traits |
| **Dependency Inversion** | Depend on traits, not concrete types |

### Architecture Decision Checklist

When designing a new Rust system:

1. **Choose architectural pattern**
   - [ ] Hexagonal + DDD for domain-heavy systems
   - [ ] Simpler layering for CRUD applications
   - [ ] Document the choice and rationale

2. **Plan crate/module layout**
   - [ ] Flat workspace if multiple crates needed
   - [ ] One crate per bounded context or major functional area
   - [ ] Clear dependency direction (inward)

3. **Design error handling**
   - [ ] Custom error types per layer
   - [ ] Clear conversion at boundaries
   - [ ] No `unwrap()` in library code

4. **Set up dependency governance**
   - [ ] Workspace dependencies centralized
   - [ ] `cargo-deny` in CI
   - [ ] Regular audit schedule

5. **Design for testability**
   - [ ] Traits for external dependencies
   - [ ] Mock implementations ready
   - [ ] Integration test structure

6. **Define visibility boundaries**
   - [ ] Minimize public API surface
   - [ ] Use `pub(crate)` liberally
   - [ ] Document public API thoroughly

7. **Encode invariants in types**
   - [ ] Newtype for IDs and validated values
   - [ ] Enums for states
   - [ ] Typestate for workflows (where valuable)

---

## Cross-References

- For workspace and Cargo.toml setup, see `rust-project-setup.md`
- For type system patterns (newtypes, typestate, enums), see `rust-implementation-patterns.md`
- For testing strategies and test architecture, see `rust-testing-quality.md`

---

*This guide synthesizes architectural best practices from rust-analyzer, production Rust systems, and the broader Rust community.*
