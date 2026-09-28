import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Cloudinary Image Service
/// - Gallery se image khud user pick karega (image_picker)
/// - Real Cloudinary unsigned upload (koi simulation nahi)
/// - Upload hone ke baad URL Firestore document me save hota hai (optional helper,
///   is app me DataService.addProduct/updateProduct khud imageUrl Firestore me likhta hai)
class CloudinaryService {
  static const String cloudName = 'dmlxze89y';
  static const String uploadPreset = 'FireGuard';

  /// Step 1: Gallery se image pick karo
  /// Return: File? (agar user ne cancel kiya to null aayega)
  static Future<File?> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // thora compress taake upload fast ho
    );

    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  /// Step 2: Cloudinary par real upload karo (unsigned preset use ho raha hai)
  /// Return: Cloudinary se aaya hua secure_url (hosted image URL)
  static Future<String> uploadImage(
    File file, {
    String folder = 'products',
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final String secureUrl = data['secure_url'] as String;
      return secureUrl;
    } else {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Optional helper: agar kabhi standalone (product model se bahar) URL
  /// Firestore me save karna ho to ye use kar sakte ho.
  /// [collection] -> jaisay 'products'
  /// [docId] -> product ka document id
  /// [imageUrl] -> Cloudinary se mila url
  static Future<void> saveImageUrlToFirestore({
    required String collection,
    required String docId,
    required String imageUrl,
  }) async {
    await FirebaseFirestore.instance.collection(collection).doc(docId).set(
      {'imageUrl': imageUrl, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true), // taake baaki fields delete na hon
    );
  }

  /// Audio file Cloudinary par upload karo (/raw/upload endpoint use hota hai)
  /// AAC, MP3, M4A sab formats support karta hai
  /// Return: Cloudinary se aaya hua secure_url
  static Future<String> uploadAudio(
    File file, {
    String folder = 'voice_messages',
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final String secureUrl = data['secure_url'] as String;
      return secureUrl;
    } else {
      throw Exception(
        'Cloudinary audio upload failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// All-in-one helper: pick -> upload (Firestore save yahan nahi kiya gaya
  /// kyunki is app me poora product object DataService.addProduct/updateProduct
  /// ke zariye ek sath Firestore me save hota hai)
  /// Return: uploaded imageUrl (ya null agar user ne image select nahi ki)
  static Future<String?> pickAndUpload({String folder = 'products'}) async {
    final file = await pickImageFromGallery();
    if (file == null) return null; // user ne cancel kar diya

    final imageUrl = await uploadImage(file, folder: folder);
    return imageUrl;
  }

  /// Category ke hisaab se local placeholder (jab tak real image na ho)
  static String getCategoryPlaceholder(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('veg')) {
      return 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=800&q=80';
    } else if (cat.contains('fruit')) {
      return 'https://images.unsplash.com/photo-1560493676-04071c5f467b?w=800&q=80';
    } else if (cat.contains('dairy')) {
      return 'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=800&q=80';
    } else if (cat.contains('honey') || cat.contains('organ')) {
      return 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=800&q=80';
    }
    return 'https://images.unsplash.com/photo-1557844352-761f2565b576?w=800&q=80';
  }
}
