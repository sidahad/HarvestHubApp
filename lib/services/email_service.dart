import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // Gmail Address associated with the Google App Password
  static String senderEmail = 'appfireguard@gmail.com'; // User's Gmail
  static const String appPassword = 'frrqepobltkyfcmf'; // Google App Password without spaces

  /// Configure the sender email address
  static void setSenderEmail(String email) {
    senderEmail = email.trim();
  }

  /// Sends a real 6-digit OTP code to the recipient's email address
  static Future<bool> sendOtpEmail({
    required String recipientEmail,
    required String otp,
    required String purposeText,
  }) async {
    // In Web Browser (Chrome), direct raw TCP socket to SMTP port 465 is blocked by browser sandbox.
    // We send via the local relay server on http://127.0.0.1:8089
    if (kIsWeb) {
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8089/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'recipient': recipientEmail.trim(),
            'otp': otp,
            'purpose': purposeText,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          debugPrint('Web Mail Relay: Real OTP successfully sent to $recipientEmail');
          return true;
        } else {
          debugPrint('Web Mail Relay returned status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('Web Mail Relay unreachable: $e');
      }
      return false;
    }

    // In Native environments (Android, Windows Desktop, iOS), raw TCP sockets work directly!
    final smtpServer = gmail(senderEmail, appPassword);

    final message = Message()
      ..from = Address(senderEmail, 'HarvestHub')
      ..recipients.add(recipientEmail.trim())
      ..subject = 'HarvestHub - Your OTP Code is $otp'
      ..html = '''
      <div style="font-family: Arial, sans-serif; max-width: 550px; margin: 0 auto; padding: 25px; border: 1px solid #e0e0e0; border-radius: 12px; background-color: #ffffff;">
        <div style="text-align: center; margin-bottom: 20px;">
          <h1 style="color: #2E7D32; margin: 0; font-size: 28px;">HarvestHub</h1>
          <p style="color: #666; margin: 5px 0 0 0; font-size: 14px;">Farm-to-Table Marketplace</p>
        </div>
        <hr style="border: none; border-top: 1px solid #eeeeee; margin: 20px 0;" />
        <h3 style="color: #222222; margin-top: 0;">$purposeText</h3>
        <p style="color: #555555; font-size: 15px; line-height: 1.5;">Hello,</p>
        <p style="color: #555555; font-size: 15px; line-height: 1.5;">Please use the 6-digit verification code below to verify your account in HarvestHub:</p>
        <div style="background-color: #F1F8E9; border: 2px dashed #4CAF50; border-radius: 10px; padding: 18px; text-align: center; margin: 25px 0;">
          <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #2E7D32;">$otp</span>
        </div>
        <p style="color: #777777; font-size: 13px;">This code is valid for <strong>10 minutes</strong>. Please do not share it with anyone.</p>
        <hr style="border: none; border-top: 1px solid #eeeeee; margin: 20px 0;" />
        <p style="color: #999999; font-size: 12px; text-align: center; margin-bottom: 0;">If you did not request this verification code, please ignore this email.<br/>© 2026 HarvestHub. All rights reserved.</p>
      </div>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('OTP Email successfully sent to $recipientEmail: $sendReport');
      return true;
    } on MailerException catch (e) {
      debugPrint('MailerException sending OTP to $recipientEmail: $e');
      for (var p in e.problems) {
        debugPrint('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      debugPrint('Unexpected error sending email: $e');
      return false;
    }
  }
}
