import http from 'k6/http';
import { config } from '../config/gateway.config.js';
import { setupUser } from '../utils/auth.js';
import { makeRequest, thinkTime, randomData } from '../utils/helpers.js';

export const options = {
    stages: config.loadTest.stages,
    thresholds: config.thresholds,
};

const GATEWAY = config.gatewayUrl;
const ENDPOINT = config.endpoints.appointments;

export function setup() {
    return {
        student: setupUser('student'),
        landlord: setupUser('landlord'),
    };
}

export default function (data) {
    const { student, landlord } = data;

    // Test 1: Student views appointments
    makeRequest(
        http.get,
        `${GATEWAY}${ENDPOINT}`,
        null,
        { ...student.headers, tags: { endpoint: 'appointments' } },
        'Get appointments'
    );

    thinkTime(1, 2);

    // Test 2: Create appointment
    const appointmentData = JSON.stringify({
        propertyId: 1,
        appointmentTitle: 'Property Viewing - K6 Test',
        appointmentDateTime: new Date(Date.now() + 86400000).toISOString(),
        durationMinutes: 60,
        notes: 'Performance test appointment',
    });

    makeRequest(
        http.post,
        `${GATEWAY}${ENDPOINT}`,
        appointmentData,
        { ...student.headers, tags: { endpoint: 'appointments' } },
        'Create appointment'
    );

    thinkTime(2, 3);

    // Test 3: Landlord views their appointments
    makeRequest(
        http.get,
        `${GATEWAY}${ENDPOINT}/provider/1`,
        null,
        { ...landlord.headers, tags: { endpoint: 'appointments' } },
        'Landlord views appointments'
    );
}