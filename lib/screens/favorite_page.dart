import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/globalprovider.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final favs = context.watch<GlobalProvider>().favorites;
    if (favs.isEmpty) {
      return const Center(
        child: Text('Та одоогоор дуртай бараа нэмээгүй байна'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      itemCount: favs.length,
      itemBuilder: (_, i) {
        final item = favs[i];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.image != null && item.image!.isNotEmpty
                  ? Image.network(item.image!, width: 56, height: 56, fit: BoxFit.cover)
                  : const Icon(Icons.favorite, size: 56, color: Colors.pink),
            ),
            title: Text(
              item.title ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => context.read<GlobalProvider>().toggleFavorite(item),
              tooltip: 'Remove from favorites',
            ),
          ),
        );
      },
    );
  }
}
