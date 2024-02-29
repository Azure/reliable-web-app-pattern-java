package com.contoso.cams.serviceplan;

import org.apache.commons.lang3.StringUtils;

/*
 This utility class is used to simulate exceptions to test the CircuitBreaker and Retry implmentations
 based on the error rate set in the environment variable CONTOSO_RETRY_DEMO
 */
public class ServicePlanExceptionSimulator {

    private static int requestCount = 0;

    /**
     * Check if exception should be thrown based on error rate
     */
    public static void checkAndthrowExceptionIfEnabled() {
        int errorRate = getErrorRate();

        // if error rate = 0 then return
        if (errorRate == 0) {
            return;
        }
        if (requestCount++ % errorRate == 0) {
            throw new RuntimeException("Simulated exception calling ServicePlanService.getServicePlans()");
        }
    }

    /*
     * Get error rate from environment variable
     * 0 = no error (Default)
     * 1 = fail request every time
     * 2 = fail request every 2nd time
     */
    private static int getErrorRate() {
        int errorRate = 0;
        String retryDemo = System.getenv("CONTOSO_RETRY_DEMO");
        if (!StringUtils.isEmpty(retryDemo)) {
            errorRate = Integer.parseInt(retryDemo);
        }
        return errorRate;
    }

}