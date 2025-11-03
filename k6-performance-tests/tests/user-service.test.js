// k6-tests/tests/user-service.test.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { config } from '../utils/config.js';
import { setupAuth } from '../utils/auth.js';
import { makeRequest, generateRandomData } from '../utils/helpers.js';

export const options = {
    stages: config.loadTestStages,
    thresholds: config.thresholds,
};

const BASE_URL = config.baseUrls.user;

export function setup() {
    // Get authentication token
    return setupAuth('admin');
}

export default function (authParams) {
    // Test 1: Get all users
    makeRequest(
        http.get,
        `${BASE_URL}/api/v1/users`,
        null,
        authParams,
        'Get all users'
    );

    sleep(1);

    // Test 2: Get user by ID
    makeRequest(
        http.get,
        `${BASE_URL}/api/v1/users/1`,
        null,
        authParams,
        'Get user by ID'
    );

    sleep(1);

    // Test 3: Search users
    makeRequest(
        http.get,
        `${BASE_URL}/api/v1/users/search?keyword=test`,
        null,
        authParams,
        'Search users'
    );

    sleep(1);

    // Test 4: Create user
    const userData = generateRandomData();
    const createPayload = JSON.stringify({
        username: userData.username,
        email: userData.email,
        firstName: userData.firstName,
        lastName: userData.lastName,
        phone: userData.phone,
        password: 'Password123!',
        role: 'STUDENT'
    });

    makeRequest(
        http.post,
        `${BASE_URL}/api/v1/users`,
        createPayload,
        authParams,
        'Create user'
    );

    sleep(1);
}

export function teardown(data) {
    console.log('User Service Test completed');
}