// scenarios/quick-test.js - Ultra-fast 30 second validation
import http from 'k6/http';
import { check, sleep } from 'k6';
import { config } from '../config/gateway.config.js';
import { setupUser } from '../utils/auth.js';

export const options = {
    ...config.quickTest,
    thresholds: {
        'http_req_duration': ['p(95)<35000'],
        'http_req_duration{endpoint:search}': ['p(95)<35000'],
        'http_req_duration{endpoint:details}': ['p(95)<35000'],
        'http_req_duration{endpoint:appointments}': ['p(95)<35000'],
        'http_req_duration{endpoint:bookings}': ['p(95)<35000'],
        'http_req_failed': ['rate<0.05'],
        'iteration_duration': ['p(95)<35000'],
    },
};

const GATEWAY = config.gatewayUrl;

export function setup() {
    console.log('🔧 Setting up test user...');
    const userData = setupUser(config.testUsers.student);

    if (!userData || !userData.headers) {
        throw new Error(`Failed to authenticate user: ${config.testUsers.student.username}`);
    }

    console.log('✅ Setup complete for user:', config.testUsers.student.username);
    return userData;
}

export default function (data) {
    const { headers } = data;

    // Test 1: Search properties by location
    const searchRes = http.get(
        `${GATEWAY}${config.endpoints.properties}/search/location/CITY_CENTER`,
        {
            headers,
            tags: { endpoint: 'search' }
        }
    );

    check(searchRes, {
        'search properties successful': (r) => r.status === 200,
        'search returns properties': (r) => {
            try {
                const body = JSON.parse(r.body);
                return Array.isArray(body) || (body && body.properties);
            } catch {
                return false;
            }
        }
    });

    sleep(0.5);

    // Test 2: Get property details
    const detailsRes = http.get(
        `${GATEWAY}${config.endpoints.properties}/1`,
        {
            headers,
            tags: { endpoint: 'details' }
        }
    );

    check(detailsRes, {
        'get property details successful': (r) => r.status === 200 || r.status === 404,
        'property has required fields': (r) => {
            if (r.status !== 200) return true; // Skip if property doesn't exist
            try {
                const body = JSON.parse(r.body);
                return body.id || body.propertyId;
            } catch {
                return false;
            }
        }
    });

    sleep(0.5);

    // Test 3: Get user appointments
    const appointmentsRes = http.get(
        `${GATEWAY}${config.endpoints.appointments}/user/1`,
        {
            headers,
            tags: { endpoint: 'appointments' }
        }
    );

    check(appointmentsRes, {
        'get appointments successful': (r) => r.status === 200 || r.status === 404,
        'appointments response valid': (r) => {
            try {
                const body = JSON.parse(r.body);
                return Array.isArray(body) || body.appointments || r.status === 404;
            } catch {
                return r.status === 404;
            }
        }
    });

    sleep(0.5);

    // Test 4: Get bookings (bonus test)
    const bookingsRes = http.get(
        `${GATEWAY}${config.endpoints.bookings}`,
        {
            headers,
            tags: { endpoint: 'bookings' }
        }
    );

    check(bookingsRes, {
        'get bookings successful': (r) => r.status === 200 || r.status === 404,
    });

    sleep(1);
}

export function teardown(data) {
    console.log('🧹 Test completed');
}