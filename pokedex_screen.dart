import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pokedex/cloud_storage.dart';
import 'package:pokedex/main.dart';
import 'package:pokedex/pokemon_list_display.dart';

// Primary Display
class PokedexScreen extends StatefulWidget {
  PokedexScreen({super.key});

  final pokemonRef =
      FirebaseFirestore.instance.collection('pokemon').orderBy("number");

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  bool displayFavorite = false;
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: AppBar(
        leading: null,
        title: SizedBox(
            height: 40,
            child: TextField(
              textAlignVertical: TextAlignVertical.center,
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                hintText: 'Search Pokémon',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            )),
        backgroundColor: const Color.fromARGB(255, 243, 18, 2),
        actions: [
          IconButton(
              onPressed: () async {
                try {
                  displayFavorite = !displayFavorite;
                  setState(() {});
                } catch (e) {
                  if (kDebugMode) {
                    print('Error $e');
                  }
                }
              },
              icon: Icon(
                displayFavorite ? Icons.star : Icons.star_border,
                color: displayFavorite ? Colors.yellow : null,
              )),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 243, 18, 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          FloatingActionButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AboutScreen()));
              },
              child: const Text("About")),
          FloatingActionButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()));
              },
              child: const Text("Profile")),
          FloatingActionButton(
              onPressed: () {
                tryLogout();
              },
              child: const Text("Logout")),
        ]),
      ),
      body: displayFavorite
          ? FavoritePokemonList(searchText: searchText)
          : PokemonList(searchText: searchText),
    );
  }

  void tryLogout() async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("You have logged out")));

      Navigator.pop(context);
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    }
  }
}

// Primary Display Helper
class PokemonList extends StatelessWidget {
  final String searchText;

  PokemonList({required this.searchText, super.key});

  final pokemonRef =
      FirebaseFirestore.instance.collection('pokemon').orderBy("number");

  final imageRef = FirebaseFirestore.instance.collection('images');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: pokemonRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const CircularProgressIndicator();
          }

          var pokemonDocs = snapshot.data!.docs;

          // Filter Pokemon based on search text
          var filteredPokemon = searchText.isNotEmpty
              ? pokemonDocs.where((pokemon) {
                  final name = pokemon.get('name').toLowerCase();
                  return name.contains(searchText);
                }).toList()
              : pokemonDocs;

          return ListView.builder(
              itemCount: filteredPokemon.length,
              itemBuilder: (context, index) => Card(
                  child: ListTile(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PokemonInfoScreen(
                                  filteredPokemon[index].get('name')))),
                      leading: AspectRatio(
                          aspectRatio: 1,
                          child: Image.asset(
                            filteredPokemon[index].get('image'),
                            fit: BoxFit.cover,
                          )),
                      title: Text(
                        filteredPokemon[index].get('name'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing:
                          Text('# ${filteredPokemon[index].get('number')}'),
                      leadingAndTrailingTextStyle: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w500),
                      subtitle: Text(
                          "${filteredPokemon[index].get('type1')} ${filteredPokemon[index].get('type2')}"))));
        });
  }
}

class FavoritePokemonList extends StatelessWidget {
  final String searchText;

  FavoritePokemonList({required this.searchText, super.key});

  final pokemonRef =
      FirebaseFirestore.instance.collection('pokemon').orderBy("number");

  final userRef = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: userRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return const CircularProgressIndicator();
          }

          var userFavorites = snapshot.data!.data()!['favorites'] ?? [];

          return StreamBuilder(
              stream: pokemonRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const CircularProgressIndicator();
                }

                var pokemonDocs = snapshot.data!.docs;

                List<DocumentSnapshot> favoritePokemon =
                    pokemonDocs.where((pokemon) {
                  return userFavorites.contains(pokemon.get('name'));
                }).toList();

                // Filter favorite Pokémon based on search text
                var filteredFavorites = searchText.isNotEmpty
                    ? favoritePokemon.where((pokemon) {
                        final name = pokemon.get('name').toLowerCase();
                        return name.contains(searchText);
                      }).toList()
                    : favoritePokemon;

                if (filteredFavorites.isEmpty) {
                  return const Center(
                      child: Text(
                    "No favorites yet :(",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ));
                } else {
                  return ListView.builder(
                    itemCount: filteredFavorites.length,
                    itemBuilder: (context, index) => Card(
                      child: ListTile(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PokemonInfoScreen(
                                filteredFavorites[index].get('name')),
                          ),
                        ),
                        leading: AspectRatio(
                          aspectRatio: 1,
                          child: Image.asset(
                            filteredFavorites[index].get('image'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          filteredFavorites[index].get('name'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing:
                            Text('# ${filteredFavorites[index].get('number')}'),
                        leadingAndTrailingTextStyle:
                            const TextStyle(color: Colors.black),
                        subtitle: Text(
                          "${filteredFavorites[index].get('type1')} ${filteredFavorites[index].get('type2')}",
                        ),
                      ),
                    ),
                  );
                }
              });
        });
  }
}
