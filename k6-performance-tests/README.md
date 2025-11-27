# K6 Performance Tests

## Prerequisites
1. Install K6: `choco install k6`
2. Create test users in Keycloak
3. Start all services

## Quick Start
```bash
# Run smoke test
k6 run scenarios/smoke-test.js
```

## Test Users
Create these in Keycloak (http://localhost:8080/admin):
- perf-test-student (Password: Test@123, Role: STUDENT)
- perf-test-landlord (Password: Test@123, Role: LANDLORD)
```

### Your Complete Structure Should Be:
```
k6-performance-tests/
├── README.md
├── package.json
├── config/
│   └── gateway.config.js
├── utils/
│   ├── auth.js
│   └── helpers.js
├── scenarios/
│   └── smoke-test.js
├── tests/
└── reports/