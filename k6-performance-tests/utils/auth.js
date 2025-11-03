// utils/auth.js
import http from 'k6/http';
import { check } from 'k6';
import { config } from '../config/gateway.config.js';

/**
 * Login to Keycloak and return access token
 * @param {string} username
 * @param {string} password
 * @returns {string|null} access token
 */
export function login(username, password) {
    const url = `${config.keycloak.url}/realms/${config.keycloak.realm}/protocol/openid-connect/token`;

    const payload = {
        grant_type: 'password', // Important for password login
        client_id: config.keycloak.clientId,
        client_secret: config.keycloak.clientSecret,
        username,
        password,
    };

    const headers = { 'Content-Type': 'application/x-www-form-urlencoded' };

    // Convert payload to URL-encoded string
    const body = Object.entries(payload)
        .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
        .join('&');

    const res = http.post(url, body, { headers });

    if (res.status !== 200) {
        console.error(`❌ Login failed for ${username}: ${res.status} - ${res.body}`);
        return null;
    }

    const token = JSON.parse(res.body).access_token;
    check(token, { 'has access token': t => t !== undefined });
    return token;
}

/**
 * Setup a test user and return headers for requests
 * @param {object} user - { username, password, email }
 * @returns {object} { headers }
 */
export function setupUser(user) {
    const token = login(user.username, user.password);
    if (!token) {
        throw new Error(`Failed to setup user ${user.username}`);
    }

    // Return headers for authenticated requests
    return {
        headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
    };
}
