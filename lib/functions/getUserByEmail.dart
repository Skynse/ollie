import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';

import 'package:ollie/repositories/appwrite/appwrite_config.dart';

Future<bool> checkUserByEmail(String email) async {
  Functions functions = Functions(AppwriteConfig.client);
  try {
    final response = await functions.createExecution(
      functionId: '68f65dce000d5613cd05',
      body: jsonEncode({'email': email}),
      method: ExecutionMethod.gET,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.responseStatusCode == 200) {
      final responseBody = jsonDecode(response.responseBody);
      // The server function you provided returns a JSON map: {'exists': true/false}
      return responseBody['exists'] as bool? ?? false;
    } else {
      print(
        'Error executing function [${response.status}]: ${response.responseBody}',
      );
      return false;
    }
  } on AppwriteException catch (e) {
    // The 'function_not_found' error you received will be caught here.
    // Please double-check the function ID in your Appwrite project console.
    print('Error checking user by email: $e');
    return false;
  }
}
