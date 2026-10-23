import 'package:flutter/material.dart';

/// Ошибка + кнопка «Повторить»
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Пустое состояние
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Плашка «показаны сохранённые данные»
class CachedBanner extends StatelessWidget {
  const CachedBanner({super.key, this.savedAt, this.error});

  final DateTime? savedAt;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final time = savedAt == null
        ? ''
        : ' от ${savedAt!.hour.toString().padLeft(2, '0')}:'
            '${savedAt!.minute.toString().padLeft(2, '0')}';
    final text = error == null
        ? 'Показаны сохранённые данные$time. Обновляем…'
        : 'Показаны сохранённые данные$time. $error';

    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            error == null ? Icons.sync : Icons.wifi_off,
            size: 18,
            color: Colors.brown,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
