import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Secondary Display
class PokemonInfoScreen extends StatefulWidget {
  const PokemonInfoScreen(this.pokemon, {super.key});

  final String pokemon;

  @override
  State<PokemonInfoScreen> createState() => _PokemonInfoScreenState();
}

class _PokemonInfoScreenState extends State<PokemonInfoScreen> {
  Map<String, dynamic>? pokemonData;
  late List<dynamic> evolutionData = [];

  final userRef = FirebaseFirestore.instance.collection('users');
  bool favorite = false;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    await fetchPokemonData();
    await isFavorite(userRef, pokemonData!['name']);
    setState(() {
      evolutionData = pokemonData!['evolution'];
    });
  }

  Future<void> fetchPokemonData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('pokemon')
          .where('name', isEqualTo: widget.pokemon)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.first;
        } else {
          throw Exception('no doc found');
        }
      });

      if (snapshot.exists) {
        setState(() {
          pokemonData = snapshot.data() as Map<String, dynamic>?;
        });
      } else {
        //print('Pokemon not found');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  Future<void> isFavorite(CollectionReference userRef, String pokemon) async {
    try {
      DocumentSnapshot userSnapshot =
          await userRef.doc(FirebaseAuth.instance.currentUser!.uid).get();

      List<dynamic> favorites = userSnapshot.get('favorites');

      setState(() {
        favorite = favorites.contains(pokemonData!['name']);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pokemonData == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(actions: [
          IconButton(
              onPressed: () async {
                DocumentSnapshot userSnapshot = await userRef
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .get();

                List<dynamic> favorites = userSnapshot.get('favorites');

                if (!favorites.remove(pokemonData!['name'])) {
                  favorites.add(pokemonData!['name']);
                }

                favorite = favorites.contains(pokemonData!['name']);

                setState(() {});

                await userRef
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .update({'favorites': favorites});
              },
              icon: Icon(
                favorite ? Icons.star : Icons.star_border,
                color: favorite ? Colors.yellow : null,
              ))
        ]),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          pokemonData!['image'],
                          fit: BoxFit.cover,
                          height: 350,
                          width: 350,
                        ),
                      ],
                    ),
                    Text(
                      '${pokemonData!['name']} the ${pokemonData!['species']}',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('  # ${pokemonData!['number']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500)),
                          const Text('Type: ',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Image.asset(
                              'assets/images/${pokemonData!['type1']}.png'
                                  .toLowerCase()),
                          if (pokemonData!['type2'] != '')
                            Image.asset(
                                'assets/images/${pokemonData!['type2']}.png'
                                    .toLowerCase()),
                        ]),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Description:',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(
                      '${pokemonData!['description']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Evolutions',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (evolutionData.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (int i = 0; i < evolutionData.length - 1; i++)
                              Row(
                                children: [
                                  Image.asset(
                                    '${evolutionData[i]}',
                                    height: 100,
                                    width: 100,
                                  ),
                                  evolutionData.length == 2
                                      ? const SizedBox(width: 1)
                                      : const SizedBox(width: 20),
                                  const Icon(Icons.arrow_forward),
                                ],
                              ),
                            Image.asset(
                              '${evolutionData.last}',
                              height: 100,
                              width: 100,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
