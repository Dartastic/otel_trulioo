// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_trulioo/otel_trulioo.dart';

/// Traces Trulioo calls with OpenTelemetry.
///
/// `otel_trulioo` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Trulioo call in
/// [tracedTrulioo]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'trulioo-example');

  // Wraps a Trulioo API call in a CLIENT span.
  final truliooId = await tracedTrulioo<String>(
    operation: 'embedid.create_session',
    product: 'example',
    invoke: () async {
      // Make the Trulioo call here, then report what it returned.
      const id = 'trulioo_8f3a2c';
      return const TruliooCallResult(
          value: id,
          result: TruliooResult(
              transactionId: 'transaction_8f3a2c',
              recordStatus: 'match',
              country: 'example',
              product: 'identity_verification',
              datasourceCount: 3,
              datasourcesMatched: 1,
              consent: 'ConsentForDataSources',
              watchlistHits: 1,
              kybMatchScore: 1,
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedTrulioo embedid.create_session returned $truliooId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutTruliooInstrumentationAsync.
  await runWithoutTruliooInstrumentationAsync(
    () => tracedTrulioo<String>(
      operation: 'embedid.create_session',
      product: 'example',
      invoke: () async {
        const id = 'trulioo_8f3a2c';
        return const TruliooCallResult(
            value: id,
            result: TruliooResult(
                transactionId: 'transaction_8f3a2c',
                recordStatus: 'match',
                country: 'example',
                product: 'identity_verification',
                datasourceCount: 3,
                datasourcesMatched: 1,
                consent: 'ConsentForDataSources',
                watchlistHits: 1,
                kybMatchScore: 1,
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
