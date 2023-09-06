import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3_login/models/NFT.dart';

Future<List<NFT>> fetchNfts(String address) async {
  final url = dotenv.env['QUICKNODE_RPC_URL'] ?? '';

  final headers = {
    'Content-Type': 'application/json',
    'x-qn-api-version': '1',
  };

  final body = json.encode({
    "id": 67,
    "jsonrpc": "2.0",
    "method": "qn_fetchNFTs",
    "params": {
      "wallet": address,
      "omitFields": [
        "provenance",
        "traits",
        "collectionName",
        "tokenAddress",
        "collectionAddress",
        "chain",
        "network",
        "creators"
      ],
      "page": 1,
      "perPage": 10
    }
  });

  final response =
      await http.post(Uri.parse(url), headers: headers, body: body);

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    final assetsData = jsonData?['result']?['assets'] as List<dynamic>? ?? [];
    final nfts = assetsData.map((data) => NFT.fromJson(data)).toList();

    return nfts;
  } else {
    throw Exception("Couldn't load NFTs");
  }
}
