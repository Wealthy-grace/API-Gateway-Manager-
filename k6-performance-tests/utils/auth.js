// utils/auth.js - Authentication utilities for K6 tests
import http from 'k6/http';
import { check } from 'k6';
import { config } from '../config/gateway.config.js';

/**
 * Login to Keycloak and return access token
 */
export function login(username, password) {
    const keycloakUrl = config.keycloak.url;
    const realm = config.keycloak.realm;
    const url = `${keycloakUrl}/realms/${realm}/protocol/openid-connect/token`;

    console.log(`🔐 Attempting login for user: ${username}`);
    console.log(`🌐 Keycloak URL: ${url}`);

    // Try direct credentials grant (password grant type)
    const payload = {
        grant_type: 'password',
        client_id: config.keycloak.clientId,
        username,
        password,
        scope: 'openid profile email'
    };

    // Only add client_secret if the client is confidential
    // For public clients, remove client_secret
    if (config.keycloak.clientSecret && config.keycloak.clientSecret !== '') {
        payload.client_secret = config.keycloak.clientSecret;
    }

    const headers = { 'Content-Type': 'application/x-www-form-urlencoded' };

    // Convert payload to URL-encoded string
    const body = Object.entries(payload)
        .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
        .join('&');

    console.log(`📤 Request payload (without sensitive data): grant_type=${payload.grant_type}, client_id=${payload.client_id}, username=${username}`);

    const res = http.post(url, body, { headers, timeout: '30s' });

    console.log(`📊 Login response status: ${res.status}`);

    if (res.status !== 200) {
        console.error(`❌ Login failed for ${username}: Status ${res.status}`);
        console.error(`Response: ${res.body}`);

        // Provide helpful debugging information
        if (res.status === 401) {
            console.error(`
🔍 Troubleshooting 401 Error:
1. Verify Keycloak is running at: ${keycloakUrl}
2. Check realm name is correct: ${realm}
3. Verify client_id exists: ${config.keycloak.clientId}
4. Check if client is set to 'public' or 'confidential' in Keycloak
5. If confidential, verify client_secret is correct
6. Ensure 'Direct Access Grants' is enabled for the client
7. Verify user credentials: ${username}
            `);
        }
        return null;
    }

    let tokenData;
    try {
        tokenData = JSON.parse(res.body);
    } catch (e) {
        console.error(`❌ Failed to parse token response: ${e.message}`);
        console.error(`Response body: ${res.body}`);
        return null;
    }

    const token = tokenData.access_token;

    if (!token) {
        console.error(`❌ No access_token in response`);
        console.error(`Response keys: ${Object.keys(tokenData).join(', ')}`);
        return null;
    }

    const tokenCheck = check(token, {
        'login successful': () => res.status === 200,
        'has access token': t => t !== undefined && t.length > 0
    });

    if (!tokenCheck) {
        console.error(`❌ Token validation failed for ${username}`);
        return null;
    }

    console.log(`✅ Login successful for user: ${username}`);
    console.log(`🔑 Token length: ${token.length} characters`);

    return token;
}

/**
 * Setup a test user and return headers for requests
 */
export function setupUser(user) {
    console.log(`🔧 Setting up user: ${user.username}`);

    const token = login(user.username, user.password);

    if (!token) {
        console.error(`❌ setupUser failed for user: ${user.username}`);
        throw new Error(`Failed to authenticate user: ${user.username}`);
    }

    console.log(`✅ User setup complete: ${user.username}`);

    return {
        headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        token: token,
        user: user,
    };
}

/**
 * Test Keycloak connectivity
 */
export function testKeycloakConnection() {
    const keycloakUrl = config.keycloak.url;
    const realm = config.keycloak.realm;
    const wellKnownUrl = `${keycloakUrl}/realms/${realm}/.well-known/openid-configuration`;

    console.log(`🔍 Testing Keycloak connectivity: ${wellKnownUrl}`);

    const res = http.get(wellKnownUrl, { timeout: '10s' });

    if (res.status === 200) {
        console.log(`✅ Keycloak is reachable at ${keycloakUrl}`);
        console.log(`✅ Realm '${realm}' exists`);
        return true;
    } else {
        console.error(`❌ Cannot reach Keycloak: ${res.status}`);
        console.error(`Response: ${res.body}`);
        return false;
    }
}

export default {
    login,
    setupUser,
    testKeycloakConnection,
};