package com.example.restservice;

import io.micrometer.core.aop.TimedAspect;
import io.micrometer.core.instrument.Meter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.config.MeterFilter;
import io.micrometer.core.instrument.distribution.DistributionStatisticConfig;
import io.micrometer.registry.otlp.OtlpMeterRegistry;
import org.springframework.boot.actuate.autoconfigure.metrics.MeterRegistryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

@Configuration
public class MetricsConfig {

    @Bean
    public MeterRegistryCustomizer<MeterRegistry> metricsCommonTags() {
        return registry -> registry.config().commonTags("application", "rest-service");
    }

    @Bean
    public MeterRegistryCustomizer<OtlpMeterRegistry> otlpMetricNaming() {
        return registry -> registry.config()
            .meterFilter(new MeterFilter() {
                @Override
                public Meter.Id map(Meter.Id id) {
                    // Add _otlp suffix to all metric names sent via OTLP
                    return id.withName(id.getName() + "_otlp");
                }
            });
    }

    @Bean
    public MeterRegistryCustomizer<MeterRegistry> configureHistogramBuckets() {
        return registry -> registry.config()
            .meterFilter(new MeterFilter() {
                @Override
                public DistributionStatisticConfig configure(io.micrometer.core.instrument.Meter.Id id, DistributionStatisticConfig config) {
                    if (id.getName().startsWith("http.server.requests")) {
                        return DistributionStatisticConfig.builder()
                            .percentiles(0.5, 0.75, 0.95, 0.99)
                            .percentilesHistogram(true)
                            .serviceLevelObjectives(
                                Duration.ofMillis(50).toNanos(),
                                Duration.ofMillis(100).toNanos(),
                                Duration.ofMillis(200).toNanos(),
                                Duration.ofMillis(300).toNanos(),
                                Duration.ofMillis(500).toNanos(),
                                Duration.ofSeconds(1).toNanos(),
                                Duration.ofSeconds(2).toNanos(),
                                Duration.ofSeconds(5).toNanos()
                            )
                            .build()
                            .merge(config);
                    }
                    return config;
                }
            });
    }

    @Bean
    public TimedAspect timedAspect(MeterRegistry registry) {
        return new TimedAspect(registry);
    }
}
