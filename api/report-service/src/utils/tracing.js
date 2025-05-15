/**
 * OpenTelemetry 초기화 파일
 * 
 * 이 파일은 애플리케이션의 가장 먼저 불러와져야 합니다.
 */

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');

// 서비스 이름은 환경변수에서 가져오거나 기본값 사용
const serviceName = process.env.SERVICE_NAME || 'report-service';

// OpenTelemetry Collector 엔드포인트 설정
const collectorPort = process.env.OTEL_COLLECTOR_PORT || '4318';
const collectorUrl = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || `http://localhost:${collectorPort}/v1/traces`;

console.log(`[OpenTelemetry] Initializing tracing for service: ${serviceName}`);
console.log(`[OpenTelemetry] Collector endpoint: ${collectorUrl}`);

try {
  // OpenTelemetry SDK 초기화
  const sdk = new NodeSDK({
    serviceName,
    traceExporter: new OTLPTraceExporter({
      url: collectorUrl,
    }),
    instrumentations: [
      getNodeAutoInstrumentations({
        '@opentelemetry/instrumentation-fs': { enabled: false },
        '@opentelemetry/instrumentation-express': { enabled: true },
        '@opentelemetry/instrumentation-http': { enabled: true },
        '@opentelemetry/instrumentation-pg': { enabled: true },
        '@opentelemetry/instrumentation-redis': { enabled: true },
      }),
    ],
  });

  // SDK 시작
  sdk.start();
  console.log(`[OpenTelemetry] Tracing initialized for service: ${serviceName}`);

  // 애플리케이션 종료 시 SDK 종료
  process.on('SIGTERM', () => {
    sdk.shutdown()
      .then(() => console.log('[OpenTelemetry] Tracing terminated'))
      .catch((error) => console.error('[OpenTelemetry] Error terminating tracing', error))
      .finally(() => process.exit(0));
  });
} catch (error) {
  console.error('[OpenTelemetry] Error initializing tracing:', error);
} 