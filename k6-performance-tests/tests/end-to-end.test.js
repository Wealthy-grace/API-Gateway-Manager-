// k6-tests/tests/end-to-end.test.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { config } from '../utils/config.js';
import { setupAuth } from '../utils/auth.js';

export const options = {
    stages: config.loadTestStages,
    thresholds: config.thresholds,
};

export function setup() {
    return setupAuth('student');
}

export default function (authParams) {
    // Complete user journey: Search → View → Book

    // Step 1: Search for properties
    const searchResponse = http.get(
        `${config.baseUrls.property}/api/v1/properties/search?city=Amsterdam`,
        authParams
    );
    check(searchResponse, {
        'search successful': (r) => r.status === 200,
    });
    sleep(2);

    // Step 2: View property details
    const propertyResponse = http.get(
        `${config.baseUrls.property}/api/v1/properties/1`,
        authParams
    );
    check(propertyResponse, {
        'property details retrieved': (r) => r.status === 200,
    });
    sleep(3);

    // Step 3: Create appointment
    const appointmentData = JSON.stringify({
        propertyId: 1,
        appointmentTitle: 'Viewing',
        appointmentDateTime: new Date(Date.now() + 86400000).toISOString(),
        durationMinutes: 60,
    });

    const appointmentResponse = http.post(
        `${config.baseUrls.appointment}/api/v1/appointments`,
        appointmentData,
        authParams
    );
    check(appointmentResponse, {
        'appointment created': (r) => r.status === 201,
    });

    sleep(2);
}