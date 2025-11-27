// scenarios/load-test.js
import http from 'k6/http';
import { sleep, check } from 'k6';
import { setupUser } from '../utils/auth.js';
import { config } from '../config/gateway.config';
// ✅ FAST VERSION - 2 minutes total
export const options = {
    stages: [
        { duration: '30s', target: 20 },   // Quick ramp to 20
        { duration: '1m', target: 20 },    // Hold at 20
        { duration: '30s', target: 0 },    // Quick ramp down
    ],
    thresholds: config.thresholds,
};

const GATEWAY = config.gatewayUrl;

export function setup() {
    return setupUser(config.testUsers.student);
}

export default function (data) {
    const { headers } = data;

    //  Search by location
    let res = http.get(
        `${GATEWAY}${config.endpoints.properties}/search/location/CITY_CENTER`,
        { headers }
    );
    check(res, { 'searched properties': r => r.status === 200 });
    sleep(0.5);  //  Reduced from 2s to 0.5s

    //  Get property details
    res = http.get(`${GATEWAY}${config.endpoints.properties}/1`, { headers });
    check(res, { 'fetched property details': r => r.status === 200 });
    sleep(0.5);  //  Reduced from 3s to 0.5s

    //  Get appointments
    res = http.get(`${GATEWAY}${config.endpoints.appointments}/user/1`, { headers });
    check(res, { 'fetched appointments': r => r.status === 200 });
    sleep(0.5);  //  Reduced from 1s to 0.5s
}