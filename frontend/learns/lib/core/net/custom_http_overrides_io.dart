import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context)
      ..connectionTimeout = const Duration(seconds: 60);
    return client;
  }

  @override
  Future<List<InternetAddress>> lookup(String host,
      {InternetAddressType type = InternetAddressType.any}) async {
    try {
      return await InternetAddress.lookup(host, type: type);
    } on SocketException {
      final fallback = await _lookupWithGoogleDns(host);
      if (fallback.isNotEmpty) return fallback;
      if (host == 'learnsynth-api.fly.dev') {
        return [InternetAddress('66.241.125.136')];
      }
      rethrow;
    }
  }

  Future<List<InternetAddress>> _lookupWithGoogleDns(String host) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final id = Random().nextInt(0xFFFF);
    final packet = _buildQueryPacket(host, id);
    final completer = Completer<List<InternetAddress>>();
    socket.send(packet, InternetAddress('8.8.8.8'), 53);
    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = socket.receive();
        if (dg == null) return;
        final res = _parseResponse(dg.data, id);
        completer.complete(res);
        socket.close();
      }
    });
    return completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      socket.close();
      return [];
    });
  }

  List<int> _buildQueryPacket(String host, int id) {
    final parts = host.split('.');
    final b = BytesBuilder();
    b.add([id >> 8, id & 0xFF]); // ID
    b.add([0x01, 0x00]); // flags: recursion desired
    b.add([0x00, 0x01]); // QDCOUNT
    b.add([0x00, 0x00]); // ANCOUNT
    b.add([0x00, 0x00]); // NSCOUNT
    b.add([0x00, 0x00]); // ARCOUNT
    for (final p in parts) {
      final bytes = utf8.encode(p);
      b.add([bytes.length]);
      b.add(bytes);
    }
    b.add([0]);
    b.add([0x00, 0x01]); // QTYPE A
    b.add([0x00, 0x01]); // QCLASS IN
    return b.toBytes();
  }

  List<InternetAddress> _parseResponse(Uint8List data, int id) {
    if (data.length < 12) return [];
    final recvId = (data[0] << 8) | data[1];
    if (recvId != id) return [];
    final qdCount = (data[4] << 8) | data[5];
    final anCount = (data[6] << 8) | data[7];
    int idx = 12;
    for (int i = 0; i < qdCount; i++) {
      while (data[idx] != 0) {
        idx += data[idx] + 1;
      }
      idx += 5; // null + type + class
    }
    final res = <InternetAddress>[];
    for (int i = 0; i < anCount; i++) {
      if (data[idx] & 0xC0 == 0xC0) {
        idx += 2;
      } else {
        while (data[idx] != 0) {
          idx += data[idx] + 1;
        }
        idx++;
      }
      final type = (data[idx] << 8) | data[idx + 1];
      idx += 8; // type+class+ttl
      final rdLength = (data[idx] << 8) | data[idx + 1];
      idx += 2;
      if (type == 1 && rdLength == 4) {
        res.add(InternetAddress(
            '${data[idx]}.${data[idx + 1]}.${data[idx + 2]}.${data[idx + 3]}'));
      }
      idx += rdLength;
    }
    return res;
  }
}

void initCustomHttpOverrides() {
  HttpOverrides.global = CustomHttpOverrides();
}
