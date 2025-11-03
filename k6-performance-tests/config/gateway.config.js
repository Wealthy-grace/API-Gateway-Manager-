// config/gateway.config.js - Configuration for K6 performance tests

export const config = {
    gatewayUrl: __ENV.GATEWAY_URL || 'http://localhost:9500',

    keycloak: {
        url: __ENV.KEYCLOAK_URL || 'http://localhost:8080',
        realm: 'friendly-housing',
        clientId: 'booking-service',
        clientSecret: '39JGwi1wzcPzEXotI2z6igOIl4xGWSAm',
    },

    testUsers: {
        student: {
            username: 'jennifer275',
            password: 'MeiChen@Edu4!',
            email: 'Jenny_275@gmail.com'
        },
        property_manager: {
            username: 'Stefan',
            password: 'Stefan@227',
            email: 'Jessica@friendly_house25.com'
        },
        admin: {
            username: 'Jessica-Admin',
            password: 'Admin@225',
            email: 'Jessica@friendly_house25.com'
        },
    },

    endpoints: {
        auth: '/api/auth',
        users: '/api/internal',
        properties: '/api/v1/properties',
        appointments: '/api/v1/appointments',
        bookings: '/api/bookings',
        notifications: '/api/notifications'

    },

    thresholds: {
        http_req_duration: ['p(95)<500', 'p(99)<1000'],
        http_req_failed: ['rate<0.01'],
        http_reqs: ['rate>5'],
    },

    // ✅ NEW: Quick Test - 30 seconds (FASTEST)
    quickTest: {
        vus: 10,
        duration: '30s',
    },

    // ✅ NEW: Fast Load Test - 2 minutes (FAST)
    fastLoadTest: {
        stages: [
            { duration: '30s', target: 20 },   // Quick ramp to 20
            { duration: '1m', target: 20 },    // Hold at 20
            { duration: '30s', target: 0 },    // Quick ramp down
        ],
    },

    // ✅ EXISTING: Smoke Test - 1 minute (QUICK CHECK)
    smokeTest: {
        vus: 5,
        duration: '1m'
    },

    // ✅ EXISTING: Load Test - 16 minutes (FULL TEST)
    loadTest: {
        stages: [
            { duration: '2m', target: 20 },
            { duration: '5m', target: 20 },
            { duration: '2m', target: 50 },
            { duration: '5m', target: 50 },
            { duration: '2m', target: 0 },
        ],
    },

    // ✅ EXISTING: Stress Test - 10 minutes
    stressTest: {
        stages: [
            { duration: '2m', target: 50 },
            { duration: '3m', target: 100 },
            { duration: '2m', target: 150 },
            { duration: '3m', target: 0 },
        ],
    },

    // ✅ EXISTING: Spike Test - 2 minutes
    spikeTest: {
        stages: [
            { duration: '30s', target: 100 },
            { duration: '1m', target: 300 },
            { duration: '30s', target: 0 },
        ],
    },

    // ✅ NEW: Soak Test - 30 minutes (STABILITY TEST)
    soakTest: {
        stages: [
            { duration: '2m', target: 20 },     // Ramp up
            { duration: '25m', target: 20 },    // Stay at load
            { duration: '3m', target: 0 },      // Ramp down
        ],
    },
};

export default config;