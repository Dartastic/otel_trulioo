// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_trulioo_suppression.dart';

const _tracerName = 'dartastic_otel_libs_trulioo';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class TruliooResult {
  const TruliooResult({
    this.transactionId,
    this.recordStatus,
    this.country,
    this.product,
    this.datasourceCount,
    this.datasourcesMatched,
    this.consent,
    this.watchlistHits,
    this.kybMatchScore,
    this.requestId,
    this.statusCode,
  });

  /// `TransactionId` returned by GlobalGateway.
  final String? transactionId;

  /// `match` / `nomatch` / `partial_match` / `data_unavailable`.
  final String? recordStatus;

  /// ISO 3166 — country verified against.
  final String? country;

  /// `identity_verification` / `business_verification` /
  /// `watchlist_screening` / `document_verification` /
  /// `embedid_workflow`.
  final String? product;

  /// Number of datasources Trulioo queried.
  final int? datasourceCount;

  /// Number of datasources that matched.
  final int? datasourcesMatched;

  /// Comma-joined `ConsentForDataSources` values returned (which
  /// consents were captured).
  final String? consent;

  /// Watchlist hit count.
  final int? watchlistHits;

  /// KYB match score (0-100) when product == business_verification.
  final int? kybMatchScore;

  /// `Trulioo-Transaction-Id` or similar.
  final String? requestId;

  final int? statusCode;
}

class TruliooCallResult<T> {
  const TruliooCallResult({required this.value, this.result});
  final T value;
  final TruliooResult? result;
}

/// Wraps a Trulioo API call in a CLIENT span. [operation] is one of
/// `verify`, `verify_business`, `document_verification`, `watchlist`,
/// `kyb.match`, `configuration.country_subdivisions`,
/// `configuration.consents`, `configuration.recommended_fields`,
/// `embedid.create_session`, `embedid.session_status`.
Future<T> tracedTrulioo<T>({
  required String operation,
  required Future<TruliooCallResult<T>> Function() invoke,
  String? product,
}) async {
  if (truliooInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'trulioo',
    'rpc.method': operation,
    'trulioo.operation': operation,
  };
  if (product != null) m['trulioo.product'] = product;

  final span = _tracer().startSpan(
    'trulioo $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.transactionId != null) {
        extras.add(OTel.attributeString(
          'trulioo.transaction.id',
          r.result!.transactionId!,
        ));
      }
      if (r.result!.recordStatus != null) {
        extras.add(OTel.attributeString(
          'trulioo.record.status',
          r.result!.recordStatus!,
        ));
        if (r.result!.recordStatus == 'nomatch') {
          span.setStatus(
            SpanStatusCode.Error,
            'Trulioo record nomatch',
          );
        }
      }
      if (r.result!.country != null) {
        extras.add(OTel.attributeString(
          'trulioo.country',
          r.result!.country!,
        ));
      }
      if (r.result!.product != null) {
        extras.add(OTel.attributeString(
          'trulioo.product',
          r.result!.product!,
        ));
      }
      if (r.result!.datasourceCount != null) {
        extras.add(OTel.attributeInt(
          'trulioo.datasource_count',
          r.result!.datasourceCount!,
        ));
      }
      if (r.result!.datasourcesMatched != null) {
        extras.add(OTel.attributeInt(
          'trulioo.datasources_matched',
          r.result!.datasourcesMatched!,
        ));
      }
      if (r.result!.consent != null) {
        extras.add(OTel.attributeString(
          'trulioo.consent',
          r.result!.consent!,
        ));
      }
      if (r.result!.watchlistHits != null) {
        extras.add(OTel.attributeInt(
          'trulioo.watchlist.hits',
          r.result!.watchlistHits!,
        ));
      }
      if (r.result!.kybMatchScore != null) {
        extras.add(OTel.attributeInt(
          'trulioo.kyb.match_score',
          r.result!.kybMatchScore!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'trulioo.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Trulioo HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
