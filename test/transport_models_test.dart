import 'dart:convert';

import 'package:hyper_axis/hyper_axis.dart';
import 'package:test/test.dart';

void main() {
  group('HyperAxisInfoQuery.orderStatus', () {
    test('encodes a client order id selector', () {
      final query = HyperAxisInfoQuery.orderStatus(
        user: '0x000000000000000000000000000000000000beef',
        selector: HyperAxisOrderStatusSelector.cloid(
          '0x1234567890abcdef1234567890abcdef',
        ),
      );

      expect(jsonDecode(query.toBridgeJson()), <String, Object?>{
        'type': 'orderStatus',
        'user': '0x000000000000000000000000000000000000beef',
        'selector': <String, Object?>{
          'kind': 'cloid',
          'cloid': '0x1234567890abcdef1234567890abcdef',
        },
      });
    });

    test('keeps a wide order id as a decimal string', () {
      final query = HyperAxisInfoQuery.orderStatus(
        user: '0x000000000000000000000000000000000000beef',
        selector: HyperAxisOrderStatusSelector.oid('18446744073709551615'),
      );

      expect(jsonDecode(query.toBridgeJson()), <String, Object?>{
        'type': 'orderStatus',
        'user': '0x000000000000000000000000000000000000beef',
        'selector': <String, Object?>{
          'kind': 'oid',
          'oid': '18446744073709551615',
        },
      });
    });
  });

  group('HyperAxisSubscription user streams', () {
    const user = '0x000000000000000000000000000000000000beef';

    test('encodes account state, orders, and fills', () {
      final subscriptions = <HyperAxisSubscription>[
        HyperAxisSubscription.clearinghouseState(user: user),
        HyperAxisSubscription.orderUpdates(user: user),
        HyperAxisSubscription.userFills(user: user, aggregateByTime: true),
      ];

      expect(
        subscriptions.map((value) => value.command('subscribe')),
        <Object?>[
          <String, Object?>{
            'method': 'subscribe',
            'subscription': <String, Object?>{
              'type': 'clearinghouseState',
              'user': user,
              'dex': '',
            },
          },
          <String, Object?>{
            'method': 'subscribe',
            'subscription': <String, Object?>{
              'type': 'orderUpdates',
              'user': user,
            },
          },
          <String, Object?>{
            'method': 'subscribe',
            'subscription': <String, Object?>{
              'type': 'userFills',
              'user': user,
              'aggregateByTime': true,
            },
          },
        ],
      );
    });
  });
}
