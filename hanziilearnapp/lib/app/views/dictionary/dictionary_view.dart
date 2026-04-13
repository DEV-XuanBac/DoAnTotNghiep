import 'package:flutter/material.dart';
import 'package:hanziilearnapp/app/providers/dictionary_provider.dart';
import 'package:provider/provider.dart';

class DictionaryView extends StatelessWidget {
  const DictionaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DictionaryProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Dictionary")),
      body: Column(
        children: [
          TextField(
            onChanged: (value) {
              provider.searchWord(value);
            },
          ),

          Expanded(
            child: ListView.builder(
              itemCount: provider.words.length,
              itemBuilder: (_, i) {
                final word = provider.words[i];
                return ListTile(
                  title: Text(word.hanzi),
                  subtitle: Text("${word.pinyin} - ${word.meaning}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
