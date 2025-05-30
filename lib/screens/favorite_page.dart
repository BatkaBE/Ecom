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
      itemCount: favs.length,
      itemBuilder: (_, i) {
        final item = favs[i];
        return Card(
          child: ListTile(
            leading: Image.network(item.image!, width: 50, height: 50),
            title: Text(item.title!),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed:
                  () => context.read<GlobalProvider>().toggleFavorite(item),
            ),
          ),
        );
      },
    );
  }
}
