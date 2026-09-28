// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void main() async {
  const senderEmail = 'appfireguard@gmail.com';
  const appPassword = 'frrqepobltkyfcmf';
  const port = 8089;

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('HarvestHub Mail Relay listening on http://127.0.0.1:$port');

  await for (HttpRequest request in server) {
    // Add CORS headers for Flutter Web (Chrome)
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Origin, Accept');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    if (request.method == 'GET') {
      request.response.statusCode = HttpStatus.ok;
      request.response.write('HarvestHub Mail Relay is running');
      await request.response.close();
      continue;
    }

    if (request.method == 'POST') {
      try {
        final body = await utf8.decoder.bind(request).join();
        final data = jsonDecode(body);
        final recipient = data['recipient'] as String;
        final otp = data['otp'] as String;
        final purpose = data['purpose'] as String? ?? 'Verification';

        print('Sending real OTP $otp to $recipient...');
        final smtpServer = gmail(senderEmail, appPassword);
        final message = Message()
          ..from = const Address(senderEmail, 'HarvestHub')
          ..recipients.add(recipient)
          ..subject = 'HarvestHub - Your OTP Code is $otp'
          ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 550px; margin: 0 auto; padding: 25px; border: 1px solid #e0e0e0; border-radius: 12px; background-color: #ffffff;">
            <div style="text-align: center; margin-bottom: 20px;">
              <h1 style="color: #2E7D32; margin: 0; font-size: 28px;">🌾 HarvestHub</h1>
              <p style="color: #666; margin: 5px 0 0 0; font-size: 14px;">Farm-to-Table Marketplace</p>
            </div>
            <hr style="border: none; border-top: 1px solid #eeeeee; margin: 20px 0;" />
            <h3 style="color: #222222; margin-top: 0;">$purpose</h3>
            <p style="color: #555555; font-size: 15px; line-height: 1.5;">Hello,</p>
            <p style="color: #555555; font-size: 15px; line-height: 1.5;">Your 6-digit verification code is:</p>
            <div style="background-color: #F1F8E9; border: 2px dashed #4CAF50; border-radius: 10px; padding: 18px; text-align: center; margin: 25px 0;">
              <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #2E7D32;">$otp</span>
            </div>
            <p style="color: #777777; font-size: 13px;">⏱️ This code is valid for <strong>10 minutes</strong>.</p>
            <hr style="border: none; border-top: 1px solid #eeeeee; margin: 20px 0;" />
            <p style="color: #999999; font-size: 12px; text-align: center; margin-bottom: 0;">© 2026 HarvestHub. All rights reserved.</p>
          </div>
          ''';

        await send(message, smtpServer);
        print('Email successfully delivered to $recipient');

        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'success': true}));
        await request.response.close();
      } catch (e) {
        print('Error sending email in relay: $e');
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'success': false, 'error': e.toString()}));
        await request.response.close();
      }
    }
  }
}
