import http from 'k6/http';
import { sleep } from 'k6';
import { config } from '../config/gateway.config.js';
import { setupUser } from '../utils/auth.js';
import { makeRequest, thinkTime } from '../utils/helpers.js';

export const options = {
    stages: config.loadTest.stages,
    thresholds: config.thresholds,
};

const GATEWAY = config.gatewayUrl;
const ENDPOINT = config.endpoints.properties;

export function setup() {
    // Setup authentication
    const studentAuth = setupUser('student');
    const landlordAuth = setupUser('landlord');

    return {
        student: studentAuth,
        landlord: landlordAuth,
    };
}

export default function (data) {
    const { student, landlord } = data;

    // Test 1: Browse properties (public - no auth needed)
    makeRequest(
        http.get,
        `${GATEWAY}${ENDPOINT}/search?city=Amsterdam`,
        null,
        { tags: { endpoint: 'properties' } },
        'Browse properties'
    );

    thinkTime(1, 2);

    // Test 2: View specific property
    makeRequest(
        http.get,
        `${GATEWAY}${ENDPOINT}/1`,
        null,
        { ...student.headers, tags: { endpoint: 'properties' } },
        'View property details'
    );

    thinkTime(2, 3);

    // Test 3: Get available properties
    makeRequest(
        http.get,
        `${GATEWAY}${ENDPOINT}/available`,
        null,
        { ...student.headers, tags: { endpoint: 'properties' } },
        'Get available properties'
    );

    thinkTime(1, 2);

    // Test 4: Landlord views their properties
    makeRequest(
        http.get,
        `${GATEWAY}${ENDPOINT}/landlord/1`,
        null,
        { ...landlord.headers, tags: { endpoint: 'properties' } },
        'Landlord views properties'
    );

    sleep(1);
}