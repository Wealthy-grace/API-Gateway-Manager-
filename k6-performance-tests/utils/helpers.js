// utils/helpers.js
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom Metrics
export const errorRate = new Rate('custom_error_rate');
export const successRate = new Rate('custom_success_rate');
export const responseTime = new Trend('custom_response_time');
export const requestCount = new Counter('custom_request_count');

/**
 * Make HTTP request with error handling and metrics
 */
export function makeRequest(httpFunc, url, payload, params, checkName) {
    const startTime = Date.now();
    const response = httpFunc(url, payload, params);
    const duration = Date.now() - startTime;

    // Record metrics
    responseTime.add(duration);
    requestCount.add(1);

    const success = response.status >= 200 && response.status < 300;
    errorRate.add(!success);
    successRate.add(success);

    // Perform checks
    const checkResult = check(response, {
        [`${checkName}: status 2xx`]: (r) => r.status >= 200 && r.status < 300,
        [`${checkName}: response time < 2s`]: (r) => r.timings.duration < 2000,
    });

    if (!checkResult) {
        console.error(` ${checkName} failed:`, response.status);
    }

    return response;
}

/**
 * Random sleep to simulate user think time
 */
export function thinkTime(min = 1, max = 3) {
    sleep(Math.random() * (max - min) + min);
}