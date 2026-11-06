// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_trulioo/otel_trulioo.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_trulioo-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('verify records country + datasource counts', () async {
    await tracedTrulioo<String>(
      operation: 'verify',
      product: 'identity_verification',
      invoke: () async => const TruliooCallResult(
        value: 'ok',
        result: TruliooResult(
          transactionId: 't-1',
          recordStatus: 'match',
          country: 'CA',
          product: 'identity_verification',
          datasourceCount: 3,
          datasourcesMatched: 3,
          consent: 'Equifax,Acuant',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('trulioo verify')!);
    expect(a['trulioo.country'], 'CA');
    expect(a['trulioo.datasource_count'], 3);
    expect(a['trulioo.datasources_matched'], 3);
    expect(a['trulioo.product'], 'identity_verification');
  });

  test('nomatch sets span error', () async {
    await tracedTrulioo<String>(
      operation: 'verify',
      invoke: () async => const TruliooCallResult(
        value: 'ok',
        result: TruliooResult(recordStatus: 'nomatch'),
      ),
    );
    expect(
      spans.findSpanByName('trulioo verify')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutTruliooInstrumentationAsync(() async {
      await tracedTrulioo<String>(
        operation: 'configuration.consents',
        invoke: () async => const TruliooCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('trulioo '), isEmpty);
  });
}
