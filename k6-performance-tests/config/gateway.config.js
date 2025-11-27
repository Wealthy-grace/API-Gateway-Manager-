// config/gateway.config.js - Configuration for K6 performance tests

export const config = {
    gatewayUrl: __ENV.GATEWAY_URL || 'http://localhost:9500',

    keycloak: {
        url: __ENV.KEYCLOAK_URL || 'http://localhost:8080',
        realm: __ENV.KEYCLOAK_REALM || 'friendly-housing',
        clientId: __ENV.KEYCLOAK_CLIENT_ID || 'user-service',
        // Set to empty string '' for PUBLIC clients
        // Set to actual secret for CONFIDENTIAL clients
        clientSecret: __ENV.KEYCLOAK_CLIENT_SECRET || '', // Try empty first for public client

        // Alternative: If you know it's confidential, uncomment this:
        // clientSecret: __ENV.KEYCLOAK_CLIENT_SECRET || 'w17mfIu8cNiHihx8hYZEHLkEkjEA1BIf',
    },

    testUsers: {
        student: {
            username: __ENV.TEST_USER_STUDENT || 'jennifer275',
            password: __ENV.TEST_PASS_STUDENT || 'MeiChen@Edu4!',
            email: 'Jenny_275@gmail.com',
            role: 'student'
        },
        property_manager: {
            username: __ENV.TEST_USER_PM || 'Stefan',
            password: __ENV.TEST_PASS_PM || 'Stefan@227',
            email: 'Jessica@friendly_house25.com',
            role: 'property_manager'
        },
        admin: {
            username: __ENV.TEST_USER_ADMIN || 'Jessica-Admin',
            password: __ENV.TEST_PASS_ADMIN || 'Admin@225',
            email: 'Jessica@friendly_house25.com',
            role: 'admin'
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

    quickTest: {
        vus: 10,
        duration: '30s',
        gracefulStop: '30s',
    },

    fastLoadTest: {
        stages: [
            { duration: '30s', target: 20 },
            { duration: '1m', target: 20 },
            { duration: '30s', target: 0 },
        ],
        gracefulStop: '10s',
    },

    smokeTest: {
        vus: 5,
        duration: '1m',
        gracefulStop: '10s',
    },

    loadTest: {
        stages: [
            { duration: '2m', target: 20 },
            { duration: '5m', target: 20 },
            { duration: '2m', target: 50 },
            { duration: '5m', target: 50 },
            { duration: '2m', target: 0 },
        ],
        gracefulStop: '30s',
    },

    stressTest: {
        stages: [
            { duration: '2m', target: 50 },
            { duration: '3m', target: 100 },
            { duration: '2m', target: 150 },
            { duration: '3m', target: 0 },
        ],
        gracefulStop: '30s',
    },

    spikeTest: {
        stages: [
            { duration: '30s', target: 100 },
            { duration: '1m', target: 300 },
            { duration: '30s', target: 0 },
        ],
        gracefulStop: '30s',
    },

    soakTest: {
        stages: [
            { duration: '2m', target: 20 },
            { duration: '25m', target: 20 },
            { duration: '3m', target: 0 },
        ],
        gracefulStop: '30s',
    },
};

export default config;