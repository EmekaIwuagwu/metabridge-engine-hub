# Authentication System Tests

This directory contains comprehensive tests for the Metabridge authentication system.

## Test Files

### `jwt_test.go`
Tests for JWT token generation, validation, and refresh functionality.

**Coverage:**
- Token generation with user roles and permissions
- Token validation and signature verification
- Token expiration handling
- Token refresh flow
- Role-based permission assignment
- Malformed token handling
- Invalid signature detection

**Run:**
```bash
go test -v -run TestJWT
```

### `middleware_test.go`
Tests for authentication middleware and rate limiting.

**Coverage:**
- Rate limiter token bucket algorithm
- Rate limit reset behavior
- Multiple identifier isolation
- Permission checking (HasPermission, IsAdmin)
- Public endpoint detection
- Identifier extraction from requests
- Auth context retrieval
- Role permission definitions

**Run:**
```bash
go test -v -run TestMiddleware
go test -v -run TestRateLimiter
go test -v -run TestAuthContext
```

### `integration_test.go`
End-to-end integration tests and examples.

**Coverage:**
- Complete authentication flow (login → token → validation → permissions)
- Authenticated API requests with JWT
- Unauthorized request handling
- Rate limiting behavior
- Token refresh flow
- Role permission matrix across all roles
- Performance benchmarks

**Run:**
```bash
go test -v -run TestAuthentication
go test -v -run TestAPIRequest
go test -v -run TestRolePermission
```

## Running All Tests

Run all authentication tests:
```bash
cd internal/auth
go test -v
```

Run with coverage:
```bash
go test -v -cover
go test -coverprofile=coverage.out
go tool cover -html=coverage.out
```

Run specific test:
```bash
go test -v -run TestJWTService_GenerateToken
```

## Benchmarks

Run performance benchmarks:
```bash
go test -bench=. -benchmem
```

Expected results:
- JWT Generation: ~50-100 µs per operation
- JWT Validation: ~30-60 µs per operation
- Rate Limiter: ~1-5 µs per operation

## Test Examples

### Basic JWT Usage

```go
func TestBasicJWT(t *testing.T) {
    // Create JWT service
    jwtService := auth.NewJWTService("your-secret-key", 24)

    // Create user
    user := &auth.User{
        ID:    "user-123",
        Email: "user@example.com",
        Role:  string(auth.RoleDeveloper),
    }

    // Generate token
    token, expiresAt, err := jwtService.GenerateToken(user)
    if err != nil {
        t.Fatal(err)
    }

    // Validate token
    claims, err := jwtService.ValidateToken(token)
    if err != nil {
        t.Fatal(err)
    }

    // Use claims...
}
```

### Testing Authenticated Endpoints

```go
func TestAuthenticatedEndpoint(t *testing.T) {
    // Create request
    req := httptest.NewRequest("GET", "/api/v1/messages", nil)

    // Add JWT token
    req.Header.Set("Authorization", "Bearer "+token)

    // Process through middleware...
    // Check that auth context is set...
}
```

### Testing Rate Limiting

```go
func TestRateLimit(t *testing.T) {
    limiter := auth.NewRateLimiter(5)

    // Make 5 successful requests
    for i := 0; i < 5; i++ {
        if !limiter.Allow("user-id") {
            t.Error("Should allow request", i)
        }
    }

    // 6th request should fail
    if limiter.Allow("user-id") {
        t.Error("Should be rate limited")
    }
}
```

## Testing with Database

For tests that require database access, you'll need to:

1. Set up a test database:
```bash
createdb metabridge_test
psql -d metabridge_test -f internal/database/schema.sql
psql -d metabridge_test -f internal/database/auth.sql
```

2. Set test environment variables:
```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=test_user
export DB_PASSWORD=test_password
export DB_NAME=metabridge_test
export JWT_SECRET=test-secret-key
```

3. Run integration tests:
```bash
go test -v -tags=integration
```

## Test Data

### Sample Users

**Admin User:**
- Email: admin@metabridge.local
- Role: admin
- Permissions: All (admin permission grants everything)

**Developer User:**
- Email: developer@metabridge.local
- Role: developer
- Permissions: All read/write except admin

**Regular User:**
- Email: user@metabridge.local
- Role: user
- Permissions: Read/write messages, batches, webhooks, routes, stats

**Readonly User:**
- Email: readonly@metabridge.local
- Role: readonly
- Permissions: Read-only access to all resources

### Sample API Keys

Generate test API keys:
```go
apiKey := auth.GenerateAPIKey()
// Returns: "mbh_..." format key
```

## Continuous Integration

Add to your CI pipeline:

```yaml
# .github/workflows/test.yml
- name: Run Authentication Tests
  run: |
    go test -v -race -coverprofile=coverage.txt ./internal/auth/
    go tool cover -func=coverage.txt
```

## Common Test Scenarios

### 1. Test Invalid JWT Signature
```go
service1 := auth.NewJWTService("secret1", 24)
service2 := auth.NewJWTService("secret2", 24)

token, _ := service1.GenerateToken(user)
_, err := service2.ValidateToken(token)
// Should fail with "invalid signature"
```

### 2. Test Expired Token
```go
service := auth.NewJWTService("secret", 0) // 0 hours
token, _ := service.GenerateToken(user)
time.Sleep(100 * time.Millisecond)
_, err := service.ValidateToken(token)
// Should fail with "token expired"
```

### 3. Test Permission Checking
```go
authCtx := &auth.AuthContext{
    Role: string(auth.RoleDeveloper),
    Permissions: []auth.Permission{
        auth.PermissionReadMessages,
        auth.PermissionWriteMessages,
    },
}

if !authCtx.HasPermission(auth.PermissionWriteMessages) {
    t.Error("Should have write permission")
}

if authCtx.HasPermission(auth.PermissionAdmin) {
    t.Error("Should not have admin permission")
}
```

### 4. Test Rate Limiting per User
```go
limiter := auth.NewRateLimiter(3)

// User 1 uses all tokens
limiter.Allow("user1")
limiter.Allow("user1")
limiter.Allow("user1")

// User 2 should still have tokens
if !limiter.Allow("user2") {
    t.Error("User 2 should have independent rate limit")
}
```

## Troubleshooting

### Tests Fail with "database not ready"
- Ensure PostgreSQL is running
- Check database credentials in environment variables
- Run database migrations

### Tests Fail with "invalid signature"
- Ensure consistent JWT_SECRET across tests
- Check that secret is not empty

### Rate Limit Tests Flaky
- Rate limiter uses time-based buckets
- Ensure tests don't run across minute boundaries
- Consider using fixed time in tests

## Additional Resources

- [Go Testing Documentation](https://golang.org/pkg/testing/)
- [Table-Driven Tests](https://github.com/golang/go/wiki/TableDrivenTests)
- [JWT RFC 7519](https://tools.ietf.org/html/rfc7519)
- [OWASP Authentication Guide](https://owasp.org/www-project-authentication-cheat-sheet/)
