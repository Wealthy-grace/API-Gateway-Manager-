// scenarios/stress-test.js - STRESS TEST
import http from 'k6/http';
import { sleep, check } from 'k6';
import { config } from '../config/gateway.config.js';
import { setupUser } from '../utils/auth.js';

export const options = {
    stages: config.stressTest.stages,
    thresholds: {
        http_req_duration: ['p(95)<3000'],  // More lenient for stress
        http_req_failed: ['rate<0.05'],     // Allow 5% failure under stress
    },
};

const GATEWAY = config.gatewayUrl;

export function setup() {
    return setupUser(config.testUsers.student);
}

export default function (data) {
    const { headers } = data;

    // Hit multiple endpoints simultaneously with batch
    const responses = http.batch([
        ['GET', `${GATEWAY}${config.endpoints.properties}/search/location/CITY_CENTER`, null, { headers }],
        ['GET', `${GATEWAY}${config.endpoints.properties}/1`, null, { headers }],
        ['GET', `${GATEWAY}${config.endpoints.appointments}/user/1`, null, { headers }],
    ]);

    // Check responses
    check(responses[0], { 'searched properties': r => r.status === 200 });
    check(responses[1], { 'fetched property details': r => r.status === 200 });
    check(responses[2], { 'fetched appointments': r => r.status === 200 });

    sleep(0.3);  // Short sleep for maximum stress
}