import 'dart:io';

import 'package:dio/dio.dart';

import '../error/failure.dart';

/// Translates [DioException] into the [Failure] the UI understands.
///
/// Each branch maps to a DIFFERENT user message: the brief requires
/// offline, timeout, and server errors to be distinguishable.
Failure mapDioExceptionToFailure(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const Failure(
        type: FailureType.timeout,
        message: 'Koneksi terlalu lambat. Coba lagi.',
      );
    case DioExceptionType.connectionError:
      return const Failure(
        type: FailureType.offline,
        message: 'Tidak ada internet. Periksa jaringan Anda lalu coba lagi.',
      );
    case DioExceptionType.badResponse:
      final statusCode = exception.response?.statusCode ?? 0;
      if (statusCode == 404) {
        return const Failure(
          type: FailureType.notFound,
          message: 'Kelas tidak ditemukan.',
          retryable: false,
        );
      }
      if (statusCode >= 500) {
        return const Failure(
          type: FailureType.server,
          message: 'Server sedang bermasalah. Coba lagi nanti.',
        );
      }
      return const Failure(
        type: FailureType.unknown,
        message: 'Terjadi kesalahan. Coba lagi.',
      );
    case DioExceptionType.unknown:
      // Some devices report "no internet" as an unknown type wrapping
      // a SocketException instead of connectionError.
      if (exception.error is SocketException) {
        return const Failure(
          type: FailureType.offline,
          message: 'Tidak ada internet. Periksa jaringan Anda lalu coba lagi.',
        );
      }
      return const Failure(
        type: FailureType.unknown,
        message: 'Terjadi kesalahan. Coba lagi.',
      );
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
      return const Failure(
        type: FailureType.unknown,
        message: 'Terjadi kesalahan. Coba lagi.',
      );
  }
}
