import 'package:http/http.dart' as http;

import 'odoo_http_client_stub.dart'
    if (dart.library.html) 'odoo_http_client_web.dart';

http.Client createOdooHttpClient() => createPlatformHttpClient();
