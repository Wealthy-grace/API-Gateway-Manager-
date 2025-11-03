// scenarios/smoke-test.js - SMOKE TEST (Fixed)
import http from 'k6/http';
import { check, sleep } from 'k6';
import { config } from '../config/gateway.config.js';
import { setupUser } from '../utils/auth.js';

export const options = {
    vus: config.smokeTest.vus,
    duration: config.smokeTest.duration,
    thresholds: config.thresholds,
};

const GATEWAY = config.gatewayUrl;

export function setup() {
    return setupUser(config.testUsers.student);
}

export default function (data) {
    const { headers } = data;

    // ✅ Test 1: Can list properties?
    const propertiesCheck = http.get(
        `${GATEWAY}${config.endpoints.properties}`,
        { headers }
    );
    check(propertiesCheck, {
        'can list properties': (r) => r.status === 200
    });
    sleep(0.5);

    // ✅ Test 2: Can get property details?
    const propertyDetail = http.get(
        `${GATEWAY}${config.endpoints.properties}/1`,
        { headers }
    );
    check(propertyDetail, {
        'can get property details': (r) => r.status === 200
    });
    sleep(0.5);

    // ✅ Test 3: Can search properties?
    const searchCheck = http.get(
        `${GATEWAY}${config.endpoints.properties}/search/location/CITY_CENTER`,
        { headers }
    );
    check(searchCheck, {
        'can search properties': (r) => r.status === 200
    });
    sleep(0.5);

    // ✅ Test 4: Can access appointments?
    const appointmentsCheck = http.get(
        `${GATEWAY}${config.endpoints.appointments}/user/1`,
        { headers }
    );
    check(appointmentsCheck, {
        'can access appointments': (r) => r.status === 200
    });
    // ✅ NEW: Test 5: Can access notifications?
    const notificationsCheck = http.get(
        `${GATEWAY}${config.endpoints.notifications}/user/1`,
        { headers }
    );
    check(notificationsCheck, {
        'can access notifications': (r) => r.status === 200
    });

    sleep(0.5);
}