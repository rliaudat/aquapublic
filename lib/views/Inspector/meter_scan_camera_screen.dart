import 'dart:io';
import 'dart:async';
import 'package:agua_med/Components/bottomSheets/show_reading_bottom_sheet.dart';
import 'package:agua_med/models/house.dart';
import 'package:agua_med/providers/meter_camera_provider.dart';
import 'package:agua_med/theme.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
// ignore: depend_on_referenced_packages
import 'package:image/image.dart' as img;
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../Components/Reuseable.dart';
import '../../loading.dart';

class MeterScanCameraScreen extends StatefulWidget {
  final House data;
  final bool isOCREnabled;
  const MeterScanCameraScreen(
      {super.key, required this.data, required this.isOCREnabled});

  @override
  State<MeterScanCameraScreen> createState() => _MeterScanCameraScreenState();
}

class _MeterScanCameraScreenState extends State<MeterScanCameraScreen>
    with WidgetsBindingObserver {
  late List<CameraDescription> cameras = [];
  late CameraController cameraController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<MeterCameraProvider>().reset();
    init();
  }

  Future<void> init() async {
    // print("init");
    if (await Permission.camera.isDenied) await Permission.camera.request();
    cameras = await availableCameras();
    // print("availableCameras${cameras.length}");
    if (cameras.isNotEmpty) {
      // print("cameras.isNotEmpty");
      cameraController = CameraController(
        kIsWeb ? cameras.last : cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await cameraController.initialize();
      if (!kIsWeb) await cameraController.setZoomLevel(1.8);
      context.read<MeterCameraProvider>().setIsCameraControllerInit(true);
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  String extractNumbers(String input) =>
      RegExp(r'\d+').allMatches(input).map((m) => m.group(0)!).join();

  bool isValidNumber(String text) {
    final numberRegex = RegExp(r'^-?\d+(\.\d+)?$');
    return numberRegex.hasMatch(text);
  }

  Future<void> extractTextFromImage(XFile imageFile) async {
    try {
      final inputImage = kIsWeb
          ? InputImage.fromFilePath(imageFile.path)
          : InputImage.fromFilePath(imageFile.path);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      if (isValidNumber(recognizedText.text)) {
        context
            .read<MeterCameraProvider>()
            .setReading(extractNumbers(recognizedText.text));
        await textRecognizer.close();
      } else {
        showToast(context, msg: 'Reading can only be numbers!');
      }
    } catch (e) {
      showToast(context, msg: 'Unable to extract reading from the image!');
    }
  }

  Future<void> cropImage(XFile imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) throw Exception("Unable to decode image");

    const rectWidth = 250;
    const rectHeight = 90;
    final centerX = image.width ~/ 2;
    final centerY = image.height ~/ 2;
    final left = (centerX - rectWidth ~/ 2).clamp(0, image.width);
    final top = (centerY - rectHeight ~/ 2).clamp(0, image.height);
    final width = rectWidth.clamp(0, image.width - left);
    final height = rectHeight.clamp(0, image.height - top);

    final croppedImage = img.copyCrop(image,
        x: left - 40, y: top, width: width + 80, height: height + 30);

    // ignore: unused_local_variable
    final Uint8List croppedImageBytes =
        Uint8List.fromList(img.encodeJpg(croppedImage));

    if (widget.isOCREnabled) {
      await extractTextFromImage(imageFile);
    }

    showReadingBottomSheet(context, imageFile.path);
  }

  Future<void> takePicture() async {
    if (!cameraController.value.isInitialized) return;
    var image = await cameraController.takePicture();

    if (kIsWeb) {
      context
          .read<MeterCameraProvider>()
          .setWebImageBytes(await image.readAsBytes());
    }
    context.read<MeterCameraProvider>().setOriginalImage(image);
  }

  Future<String> uploadImageToFirebaseStorage(XFile file) async {
    try {
      String fileName = 'Meter/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask;
      if (kIsWeb) {
        final Uint8List imageData = await file.readAsBytes();
        uploadTask = ref.putData(imageData);
      } else {
        uploadTask = ref.putFile(File(file.path));
      }

      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }

  void showReadingBottomSheet(BuildContext context, String? imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShowReadingBottomSheet(
          data: widget.data,
          imagePath: imagePath,
          newReading: context.read<MeterCameraProvider>().reading,
          oldReadings: widget.data.lastReading == null
              ? 0.00
              : widget.data.lastReading!['reading'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const targetHeight = 90.0;
    const targetWidth = 250.0;

    return Consumer<MeterCameraProvider>(builder: (context, provider, child) {
      return PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            context.read<MeterCameraProvider>().reset();
          }
        },
        child: Scaffold(
          appBar: CustomAppBar(title: 'MeterScanCameraScreen.ocrCamera'.tr()),
          backgroundColor: blackColor,
          body: provider.isCameraControllerInit
              ? Stack(
                  children: [
                    if (provider.originalImage != null)
                      Center(
                        child: kIsWeb
                            ? Image.memory(provider
                                .webImageBytes!) // Use Image.memory for web
                            : Image.file(
                                File(provider.originalImage!.path),
                              ), // Use Image.file for mobile
                      ),
                    if (provider.originalImage == null)
                      Center(child: CameraPreview(cameraController)),
                    ClipPath(
                      clipper: CustomOverlayClipper(
                        screenWidth: width(context),
                        screenHeight: height(context),
                        rectWidth: targetWidth,
                        rectHeight: targetHeight,
                        appBarHeight: kToolbarHeight,
                      ),
                      // ignore: deprecated_member_use
                      child: Container(color: Colors.black.withOpacity(0.2)),
                    ),
                    Center(
                      child: Container(
                        height: targetHeight,
                        width: targetWidth,
                        decoration: BoxDecoration(
                            border: Border.all(color: redColor, width: 2),
                            color: Colors.transparent),
                      ),
                    ),
                    if (provider.originalImage != null)
                      Positioned(
                        bottom: 120,
                        child: SizedBox(
                          height: 50,
                          width: width(context),
                          child: Center(
                            child: Button(
                              width: width(context) * 0.9,
                              text: 'MeterScanCameraScreen.retake'.tr(),
                              onPressed: () async {
                                provider.setIsCameraControllerInit(false);
                                provider.setOriginalImage(null);
                                provider.setWebImageBytes(null);

                                await init();
                              },
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 50,
                      child: SizedBox(
                        height: 50,
                        width: width(context),
                        child: Center(
                          child: Button(
                            width: width(context) * 0.9,
                            text: provider.originalImage == null
                                ? 'MeterScanCameraScreen.capture'.tr()
                                : 'MeterScanCameraScreen.process'.tr(),
                            onPressed: () async {
                              if (provider.originalImage == null) {
                                takePicture();
                              } else {
                                await cropImage(provider.originalImage!);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      );
    });
  }
}

class CustomOverlayClipper extends CustomClipper<Path> {
  final double screenWidth;
  final double screenHeight;
  final double rectWidth;
  final double rectHeight;
  final double appBarHeight;

  CustomOverlayClipper({
    required this.screenWidth,
    required this.screenHeight,
    required this.rectWidth,
    required this.rectHeight,
    required this.appBarHeight,
  });

  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.addRect(Rect.fromLTWH(0, 0, screenWidth, screenHeight));

    final double centerX = screenWidth / 2 - rectWidth / 2;
    final double centerY = (screenHeight - appBarHeight) / 2 - rectHeight / 2;
    path.addRect(Rect.fromLTWH(centerX, centerY, rectWidth, rectHeight));
    path.fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
// import 'dart:io';
// import 'package:agua_med/Components/bottomSheets/show_reading_bottom_sheet.dart';
// import 'package:agua_med/models/house.dart';
// import 'package:agua_med/providers/meter_camera_provider.dart';
// import 'package:agua_med/theme.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:image/image.dart' as img;
// import 'package:easy_localization/easy_localization.dart';
// import 'package:provider/provider.dart';
// import '../../Components/Reuseable.dart';
// import '../../loading.dart';

// class MeterScanCameraScreen extends StatefulWidget {
//   final House data;
//   final bool isOCREnabled;
//   const MeterScanCameraScreen({
//     super.key,
//     required this.data,
//     required this.isOCREnabled,
//   });

//   @override
//   State<MeterScanCameraScreen> createState() => _MeterScanCameraScreenState();
// }

// class _MeterScanCameraScreenState extends State<MeterScanCameraScreen> {
//   final ImagePicker _picker = ImagePicker();
//   XFile? _imageFile;

//   @override
//   void initState() {
//     super.initState();
//     _checkAndRequestPermission();
//   }

//   Future<void> _checkAndRequestPermission() async {
//     var status = await Permission.camera.status;
//     print("Permission status $status");
//     if (status.isDenied) {
//       status = await Permission.camera.request();
//     }
//     if (status.isPermanentlyDenied || status.isRestricted) {
//       _showSettingsDialog();
//     }
//   }

//   void _showSettingsDialog() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Camera Permission Required"),
//         content:
//             const Text("Please enable camera access in settings to proceed."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () {
//               openAppSettings();
//               Navigator.pop(context);
//             },
//             child: const Text("Open Settings"),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _takePicture() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.camera);
//     if (pickedFile != null) {
//       setState(() => _imageFile = pickedFile);
//       context.read<MeterCameraProvider>().setOriginalImage(pickedFile);
//       context
//           .read<MeterCameraProvider>()
//           .setWebImageBytes(await pickedFile.readAsBytes());
//     }
//   }

//   String extractNumbers(String input) =>
//       RegExp(r'\d+').allMatches(input).map((m) => m.group(0)!).join();

//   bool isValidNumber(String text) {
//     final numberRegex = RegExp(r'^-?\d+(\.\d+)?\$');
//     return numberRegex.hasMatch(text);
//   }

//   Future<void> extractTextFromImage(XFile imageFile) async {
//     try {
//       final inputImage = InputImage.fromFilePath(imageFile.path);
//       final textRecognizer =
//           TextRecognizer(script: TextRecognitionScript.latin);
//       RecognizedText recognizedText =
//           await textRecognizer.processImage(inputImage);

//       if (isValidNumber(recognizedText.text)) {
//         context
//             .read<MeterCameraProvider>()
//             .setReading(extractNumbers(recognizedText.text));
//         await textRecognizer.close();
//       } else {
//         showToast(context, msg: 'Reading can only be numbers!');
//       }
//     } catch (_) {
//       showToast(context, msg: 'Unable to extract reading from the image!');
//     }
//   }

//   Future<void> cropImage(XFile imageFile) async {
//     final imageBytes = await imageFile.readAsBytes();
//     final image = img.decodeImage(imageBytes);

//     if (image == null) throw Exception("Unable to decode image");

//     const rectWidth = 250;
//     const rectHeight = 90;
//     final centerX = image.width ~/ 2;
//     final centerY = image.height ~/ 2;
//     final left = (centerX - rectWidth ~/ 2).clamp(0, image.width);
//     final top = (centerY - rectHeight ~/ 2).clamp(0, image.height);
//     final width = rectWidth.clamp(0, image.width - left);
//     final height = rectHeight.clamp(0, image.height - top);

//     final croppedImage = img.copyCrop(image,
//         x: left - 40, y: top, width: width + 80, height: height + 30);

//     if (widget.isOCREnabled) {
//       await extractTextFromImage(imageFile);
//     }

//     showReadingBottomSheet(context, imageFile.path);
//   }

//   Future<String> uploadImageToFirebaseStorage(XFile file) async {
//     try {
//       String fileName = 'Meter/\${DateTime.now().millisecondsSinceEpoch}.jpg';
//       Reference ref = FirebaseStorage.instance.ref().child(fileName);

//       UploadTask uploadTask;
//       if (kIsWeb) {
//         final Uint8List imageData = await file.readAsBytes();
//         uploadTask = ref.putData(imageData);
//       } else {
//         uploadTask = ref.putFile(File(file.path));
//       }

//       await uploadTask;
//       return await ref.getDownloadURL();
//     } catch (e) {
//       throw Exception("Failed to upload image: \$e");
//     }
//   }

//   void showReadingBottomSheet(BuildContext context, String? imagePath) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ShowReadingBottomSheet(
//           data: widget.data,
//           imagePath: imagePath,
//           newReading: context.read<MeterCameraProvider>().reading,
//           oldReadings: widget.data.lastReading == null
//               ? 0.00
//               : widget.data.lastReading!['reading'],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     const targetHeight = 90.0;
//     const targetWidth = 250.0;

//     return Consumer<MeterCameraProvider>(builder: (context, provider, child) {
//       return Scaffold(
//         appBar: CustomAppBar(title: 'MeterScanCameraScreen.ocrCamera'.tr()),
//         backgroundColor: blackColor,
//         body: Stack(
//           children: [
//             if (_imageFile != null)
//               Center(child: Image.file(File(_imageFile!.path))),
//             if (_imageFile == null)
//               Center(child: const Text("No image captured")),
//             ClipPath(
//               clipper: CustomOverlayClipper(
//                 screenWidth: width(context),
//                 screenHeight: height(context),
//                 rectWidth: targetWidth,
//                 rectHeight: targetHeight,
//                 appBarHeight: kToolbarHeight,
//               ),
//               child: Container(color: Colors.black.withOpacity(0.2)),
//             ),
//             Center(
//               child: Container(
//                 height: targetHeight,
//                 width: targetWidth,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: redColor, width: 2),
//                   color: Colors.transparent,
//                 ),
//               ),
//             ),
//             Positioned(
//               bottom: 50,
//               child: SizedBox(
//                 height: 50,
//                 width: width(context),
//                 child: Center(
//                   child: Button(
//                     width: width(context) * 0.9,
//                     text: _imageFile == null
//                         ? 'MeterScanCameraScreen.capture'.tr()
//                         : 'MeterScanCameraScreen.process'.tr(),
//                     onPressed: () async {
//                       if (_imageFile == null) {
//                         await _takePicture();
//                       } else {
//                         await cropImage(_imageFile!);
//                       }
//                     },
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }
// }

// class CustomOverlayClipper extends CustomClipper<Path> {
//   final double screenWidth;
//   final double screenHeight;
//   final double rectWidth;
//   final double rectHeight;
//   final double appBarHeight;

//   CustomOverlayClipper({
//     required this.screenWidth,
//     required this.screenHeight,
//     required this.rectWidth,
//     required this.rectHeight,
//     required this.appBarHeight,
//   });

//   @override
//   Path getClip(Size size) {
//     final Path path = Path();
//     path.addRect(Rect.fromLTWH(0, 0, screenWidth, screenHeight));

//     final double centerX = screenWidth / 2 - rectWidth / 2;
//     final double centerY = (screenHeight - appBarHeight) / 2 - rectHeight / 2;
//     path.addRect(Rect.fromLTWH(centerX, centerY, rectWidth, rectHeight));
//     path.fillType = PathFillType.evenOdd;

//     return path;
//   }

//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) => true;
// }
