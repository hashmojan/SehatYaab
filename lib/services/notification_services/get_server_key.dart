import 'package:googleapis_auth/auth_io.dart';

class GetServerKey {
  Future<String> getServerKeyToken() async {
    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(
          {
            "type": "service_account",
            "project_id": "weather-d82d9",
            "private_key_id": "d3a8db461190066ea0a91458c16a8b21912fa912",
            "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDKP2RqigZU7ORC\noEwdG7Of7U+b+vcMrp5qvCWoYo+9XOvzcQtJV62ATr0TD03/2soHxoRcoFOdELWe\nRCjCtdmtXSL3klrjuoghDD3Vw5Xm6qbhQ/NwOi3ld1aMKMdz1dXzh9T+9h216diW\nFxgXnozkaGs8YvM2mt3Mi2r80cbDr0FHHP8R+SEfegqKwphDKwI/IfdxSjzdwRDB\nkJR2uITto1gV7PQejTGrGDc6icV7yvalBU5XDs/2k2oTAaLIFs9GjQg2vPngZIMV\nq8DcUNZ9LhMmcvgDAYLbTWqrYzDhfw4C110c/on4swO0c2xm7uKrBzzeI7jvKVIy\nRmm11LLbAgMBAAECggEAPuKWHQBctqRP1x2TfQuDfwshUT0n+uQCsupchS5cRkNx\nxCiWm0/tTTNuW9JK7O6BGgjSWCCrzu8GobbMu7oifGK0wCjcJOn3cNsnEOP3JK06\nhVmFBJS6d5pzKTJ2zeAj3cyS4FHzbABRjV2R6qosYcrL6SNVP1nI9FQ3SHQLqwUy\nNFmmMBBDyM+vimZfivDJMfrq30kWB2k1JwL6jm/DGDMK7lnGDnUaG1Ugy8VdQ15A\n1uHEG9ucj4Tb6gAC8XZq1zkKRQ2O98hj+LldUZGXxFvTAFKyxDtt/oLbZCBZOyEA\nlLKTGUznWE6vLgvh9Pdvkb2xzZCn2CJiOVgAXe6PhQKBgQDkw+26rzp4YUxNueBF\nW4WLebdLEvBu+naOS2ejt/M9t04SsXgpjsOzJdhofCYBmm86RXQppfvoWEQ//P4/\n4ub//RRQXG5tZwqmNyWDnKaSTzx7wQJ9ifo6OGisIZN1QmxlCrcd5EJt3cuLS9r8\nAqUaJ595ARbiSeQumsEbsPxETwKBgQDiU0jDVLZusFqFES6Uyw/Jw7NQT8DVsH8S\nZ3weTJuWfz1xpX94isKL0Bbx+kGOVzd9RK5bwNMuO5DoIfYiGKVjXSWCEEqqohm5\n4VP0r7VODFfZQvVCtpv0zHdJAa1YBFOlKQGTxxJ4sNqzSbI/2ccPTyWQgNBksLyz\nooxP7ExptQKBgQCa8vLE7gdmnlC2nN4BXHpZ/HlgSlW8db1zqDNsux3wgYZKNxay\n31ZCs7GfI+gCUf5gs8Z4p0q3F4Iy7UOxNhlM7rihrdnGFHMsHlI0kRhqJW1MTXFI\nYvqwEKElZiCg3frZfaaGgqNUE1TY5upOo+P8kTX9GfXMFEyQHJYMEZbtFQKBgDpD\nJF0cZqZSAct1o98r8xGGrpeDIGoiOGQdfcczA26XrNKfvxPh7LkfRXjfapbg/ujh\nkF0QY4zoSqJnc7xNSe4tYWV9GiuY9TRzvDAmN28zID5OzWJyLe2z4RVLODuLSZkf\n2EcZnTiylmpHE3r6bhMT1eDAOGVjVgCMXMCKXRVtAoGBAJkwove5OlBoWJ4wkkne\nkpXGPdIJb8TDYo16hL3RcHjKT0rCDJMZ1gZyuH16UakDgqD1p62pQhpdewygBKCZ\nxPxskxTFZYE45XnAZ2blRLZjkP6Ucy7dmh5zl6Ubm835p0FkI6swbKoDjKACyEVb\nVupO7glTtV1iQrpoOp+52oPv\n-----END PRIVATE KEY-----\n",
            "client_email": "firebase-adminsdk-fbsvc@weather-d82d9.iam.gserviceaccount.com",
            "client_id": "108602234670850711173",
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
            "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40weather-d82d9.iam.gserviceaccount.com",
            "universe_domain": "googleapis.com"
          }
      ),
      scopes,
    );

    final accessServerKey = client.credentials.accessToken.data;
    return accessServerKey;
  }
}