import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:solana/solana.dart';
import 'package:web3_login/services/nft_api.dart';

import '../models/NFT.dart';
import '../services/mint_nft.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _publicKey;
  String? _balance;
  SolanaClient? client;
  final storage = const FlutterSecureStorage();
  bool _mintNftExpanded = false;
  final _cidController = TextEditingController();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  String CID = '';
  String name = '';
  String symbol = '';
  bool _fetchNFT = false;
  bool newFetch = false;

  bool _showNftExpanded = false;
  @override
  void initState() {
    super.initState();
    _readPk();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    const Text('Wallet Address',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                            width: 200,
                            child: Text(_publicKey ?? 'Loading...')),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            if (_publicKey != null) {
                              Clipboard.setData(
                                  ClipboardData(text: _publicKey!));
                            }
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    const Text('Balance',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_balance ?? 'Loading...'),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            _getBalance();
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mint NFT'),
                    IconButton(
                      icon: Icon(_mintNftExpanded
                          ? Icons.expand_less
                          : Icons.expand_more),
                      onPressed: () {
                        setState(() {
                          _cidController.clear();
                          _mintNftExpanded = !_mintNftExpanded;
                          _showNftExpanded = false;
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
            if (_mintNftExpanded)
              Container(
                  height: 200,
                  padding: EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 250,
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                  labelStyle: TextStyle(fontSize: 12),
                                  labelText: 'Name of the NFT'),
                            )),
                        Container(
                            width: 250,
                            child: TextField(
                              controller: _symbolController,
                              decoration: const InputDecoration(
                                  labelStyle: TextStyle(fontSize: 12),
                                  labelText: 'Symbol for the NFT'),
                            )),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                width: 250,
                                child: TextField(
                                  controller: _cidController,
                                  decoration: const InputDecoration(
                                      labelStyle: TextStyle(fontSize: 12),
                                      labelText:
                                          'Enter a valid QuickNode IPFS Json CID'),
                                )),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () {
                                CID = _cidController.text;
                                name = _nameController.text;
                                symbol = _symbolController.text;
                                setState(() {
                                  _fetchNFT = true;
                                });
                                newFetch = true;
                              },
                            )
                          ],
                        ),
                      ])),
            if (_fetchNFT && _mintNftExpanded)
              FutureBuilder<String>(
                  future: _createNFT(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    return Text(snapshot.data!);
                  }),
            Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Show Wallet NFTs'),
                    IconButton(
                      icon: Icon(_showNftExpanded
                          ? Icons.expand_less
                          : Icons.expand_more),
                      onPressed: () {
                        setState(() {
                          _showNftExpanded = !_showNftExpanded;
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
            if (_showNftExpanded)
              SingleChildScrollView(
                  child: Container(
                      height: _showNftExpanded ? 200 : 0,
                      child: FutureBuilder<List<NFT>>(
                          future: fetchNfts(_publicKey!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            } else {
                              final nfts = snapshot.data;
                              return ListView.builder(
                                  itemCount: (nfts?.length ?? 0) + 1,
                                  itemBuilder: (context, index) {
                                    if (nfts == null) {
                                      return IconButton(
                                        icon: Icon(Icons.refresh),
                                        onPressed: () {
                                          fetchNfts(_publicKey!);
                                        },
                                      );
                                    }
                                    if (index < nfts.length) {
                                      final nft = nfts[index];
                                      return ListTile(
                                        onTap: () {},
                                        title: Text(nft.name ?? ""),
                                        subtitle: Text(nft.description ?? ""),
                                        leading: Image.network(nft.imageUrl ??
                                            "https://placehold.co/600x400/png"),
                                      );
                                    } else {
                                      return IconButton(
                                        icon: Icon(Icons.refresh),
                                        onPressed: () {
                                          setState(() {
                                            fetchNfts(_publicKey!);
                                          });
                                        },
                                      );
                                    }
                                  });
                            }
                          }))),
            Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Log out'),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () {
                        GoRouter.of(context).go("/");
                      },
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _createNFT() async {
    if (newFetch) {
      newFetch = false;
      return await createNft(client!, CID, name, symbol);
    }
    return "";
  }

  void _readPk() async {
    final mnemonic = await storage.read(key: 'mnemonic');
    if (mnemonic != null) {
      final keypair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
      setState(() {
        _publicKey = keypair.address;
      });
      _initializeClient();
    }
  }

  void _initializeClient() async {
    await dotenv.load(fileName: ".env");

    client = SolanaClient(
      rpcUrl: Uri.parse(dotenv.env['QUICKNODE_RPC_URL'].toString()),
      websocketUrl: Uri.parse(dotenv.env['QUICKNODE_RPC_WSS'].toString()),
    );
    _getBalance();
  }

  void _getBalance() async {
    setState(() {
      _balance = null;
    });
    final getBalance = await client?.rpcClient
        .getBalance(_publicKey!, commitment: Commitment.confirmed);
    final balance = (getBalance!.value) / lamportsPerSol;
    setState(() {
      _balance = balance.toString();
    });
  }
}
