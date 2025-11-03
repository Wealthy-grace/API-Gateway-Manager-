// tests/04-booking-service.test.js
import http from 'k6/http';
import { config } from '../config/gateway.config.js';
import { setupUser } from '../utils/auth.js';
import { makeRequest, thinkTime } from '../utils/helpers.js';

export const options = {
    stages: config.loadTest.stages,
    thresholds: config.thresholds,
};

const GATEWAY = config.gatewayUrl;
const ENDPOINT = config.endpoints.bookings;

export function setup() {
    return {
        student: setupUser('student'),
        landlord: setupUser('landlord'),
    };
}

export default function (data) {
    const { student, landlord } = data;

    // Test 1: Get bookings for student
    makeRequest(
        http.get,
        `${GATEWAY}${ENDPOINT}/requester/1`,
        null,
        { ...student.headers, tags: { endpoint: 'bookings' } },
        'Get student bookings'
    );

    thinkTime(1, 2);

    // Test 2: Get bookings for property
    makeRequest(
        http.get,
        `${GATEWAY}${ENDPOINT}/property/1`,
        null,
        { ...student.headers, tags: { endpoint: 'bookings' } },
        'Get property bookings'
    );

    thinkTime(1, 2);

    // Test 3: Landlord views their bookings
    makeRequest(
        http.get,
        `${GATEWAY}${ENDPOINT}/provider/1`,
        null,
        { ...landlord.headers, tags: { endpoint: 'bookings' } },
        'Landlord views bookings'
    );

    thinkTime(1, 2);

    // Test 4: Create booking (if appointment exists)
    const bookingData = JSON.stringify({
        appointmentId: 'test-appointment-id',
        moveInDate: new Date(Date.now() + 30 * 86400000).toISOString(),
        moveOutDate: new Date(Date.now() + 395 * 86400000).toISOString(),
        bookingDurationMonths: 12,
        notes: 'K6 performance test booking',
    });

    makeRequest(
        http.post,
        `${GATEWAY}${ENDPOINT}`,
        bookingData,
        { ...student.headers, tags: { endpoint: 'bookings' } },
        'Create booking'
    );

    thinkTime(2, 3);
}