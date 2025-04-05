import 'package:flutter/material.dart';

class UpgradePromptDialog extends StatelessWidget {
  final String feature;

  const UpgradePromptDialog({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('$feature Özelliği Premium\'da!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Bu özellikten tam olarak yararlanmak için Premium\'a geçin.'),
          const SizedBox(height: 16),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Aylık Sadece ',
                  style: TextStyle(color: Colors.black),
                ),
                TextSpan(
                  text: '9.99 TL',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Premium Sürüm Avantajları:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text('Sınırsız kategori oluşturma'),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text('Detaylı yıllık raporlar'),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text('Gelişmiş grafik analizleri'),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text('Bulut yedekleme'),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Daha Sonra'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Abonelik sayfasına yönlendirme
            // Navigator.push(context, MaterialPageRoute(builder: (context) => SubscriptionPage()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Premium\'a Geç'),
        ),
      ],
    );
  }
}
