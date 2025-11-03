// scenarios/quick-test.js - Ultra-fast 30 second validation
import http from 'k6/http';
import { check } from 'k6';
import { config } from '../config/gateway.config.js';
import { setupUser } from '../utils/auth.js';

export const options = {
    ...config.quickTest,
    thresholds: {
        http_req_duration: ['p(95)<500'],
        http_req_failed: ['rate<0.05'],
    },
};

const GATEWAY = config.gatewayUrl;

export function setup() {
    return setupUser(config.testUsers.student);
}

export default function (data) {
    const { headers } = data;

    // Test 1: Search properties
    http.get(`${GATEWAY}${config.endpoints.properties}/search/location/CITY_CENTER`, { headers });

    // Test 2: Get property details
    http.get(`${GATEWAY}${config.endpoints.properties}/1`, { headers });

    // Test 3: Get appointments
    http.get(`${GATEWAY}${config.endpoints.appointments}/user/1`, { headers });
}