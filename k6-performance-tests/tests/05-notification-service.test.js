// tests/05-notification-service.test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { config } from '../config/gateway.config.js';
import { setupUser } from '../utils/auth.js';

export const options = {
    vus: 5,
    duration: '1m',
    thresholds: {
        http_req_duration: ['p(95)<500'],
        http_req_failed: ['rate<0.01'],
    },
};

const GATEWAY = config.gatewayUrl;

export function setup() {
    // Use admin user for notification tests (has permissions)
    return setupUser(config.testUsers.admin);
}

export default function (data) {
    const { headers } = data;

    // Test 1: Send a notification
    const sendNotificationPayload = {
        userId: 1,
        userEmail: 'Jenny_275@gmail.com',
        userName: 'Jennifer Chen',
        type: 'NEW_PROPERTY',
        subject: 'Test Notification',
        message: 'This is a test notification from K6',
        propertyId: 1,
        propertyTitle: 'Test Property',
        propertyAddress: 'Test Address',
        propertyPrice: 1000.0
    };

    let res = http.post(
        `${GATEWAY}${config.endpoints.notifications}/send`,
        JSON.stringify(sendNotificationPayload),
        { headers: { ...headers, 'Content-Type': 'application/json' } }
    );
    check(res, {
        'notification sent': (r) => r.status === 201 || r.status === 200
    });
    sleep(1);

    // Test 2: Get user notifications
    res = http.get(
        `${GATEWAY}${config.endpoints.notifications}/user/1`,
        { headers }
    );
    check(res, {
        'fetched user notifications': (r) => r.status === 200
    });
    sleep(1);

    // Test 3: Get notification statistics
    res = http.get(
        `${GATEWAY}${config.endpoints.notifications}/stats`,
        { headers }
    );
    check(res, {
        'fetched notification stats': (r) => r.status === 200
    });
    sleep(1);

    // Test 4: Notify about new property
    const notifyPropertyPayload = {
        propertyId: 1,
        userIds: [1]
    };

    res = http.post(
        `${GATEWAY}${config.endpoints.notifications}/new-property`,
        JSON.stringify(notifyPropertyPayload),
        { headers: { ...headers, 'Content-Type': 'application/json' } }
    );
    check(res, {
        'notified about new property': (r) => r.status === 200 || r.status === 201
    });
    sleep(1);
}