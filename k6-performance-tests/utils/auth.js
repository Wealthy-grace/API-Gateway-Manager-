// utils/auth.js

import http from 'k6/http';
import { check } from 'k6';
import { config } from '../config/gateway.config.js';

/**
 * Login and get JWT token
 */
export function login(username, password) {
    const url = `${config.gatewayUrl}${config.endpoints.auth}/login`;

    const payload = JSON.stringify({
        username: username,
        password: password,
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
        },
        tags: { endpoint: 'auth' },
    };

    const response = http.post(url, payload, params);

    const success = check(response, {
        'login successful': (r) => r.status === 200,
        'token received': (r) => {
            try {
                const body = JSON.parse(r.body);
                return body.token !== undefined;
            } catch {
                return false;
            }
        },
    });

    if (success && response.status === 200) {
        const body = JSON.parse(response.body);
        return body.token;
    }

    console.error(`Login failed for ${username}:`, response.status, response.body);
    return null;
}

/**
 * Get authorization headers with JWT token
 */
export function getAuthHeaders(token) {
    return {
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
    };
}

/**
 * Setup authentication for a specific user type
 */
export function setupUser(userType = 'student') {
    const user = config.testUsers[userType];
    const token = login(user.username, user.password);

    if (!token) {
        throw new Error(`Failed to authenticate as ${userType}`);
    }

    return {
        token: token,
        headers: getAuthHeaders(token),
        user: user,
    };
}