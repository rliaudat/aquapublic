import 'dart:io';
import 'package:agua_med/Components/bottomSheets/show_reading_bottom_sheet.dart';
import 'package:agua_med/theme.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:easy_localization/easy_localization.dart';
import '../../Components/Reuseable.dart';
import '../../loading.dart';
// import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
// import 'dart:html' as html;

class MeterScanCameraScreen extends StatefulWidget {
  final dynamic data;
  final bool isOCREnabled;
  const MeterScanCameraScreen({super.key, required this.data, required this.isOCREnabled});

  @override
  State<MeterScanCameraScreen> createState() => _MeterScanCameraScreenState();
}

class _MeterScanCameraScreenState extends State<MeterScanCameraScreen> {
  late List<CameraDescription> cameras = [];
  late CameraController cameraController;
  String reading = '';
  bool isCameraControllerInit = false;
  String? capturedImagePath;
  XFile? originalImage;

  @override
  void initState() {
    init();
    super.initState();
  }

  init() async {
    if (await Permission.camera.isDenied) await Permission.camera.request();
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      cameraController = CameraController(
        kIsWeb ? cameras.last : cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await cameraController.initialize();
      if (kIsWeb == false) await cameraController.setZoomLevel(1.8);
      isCameraControllerInit = true;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    isCameraControllerInit = false;
    super.dispose();
  }

  String extractNumbers(String input) => RegExp(r'\d+').allMatches(input).map((m) => m.group(0)!).join();

  Future<void> extractTextFromImage(String imagePath) async {
    try {
      final InputImage inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      if (recognizedText.text.isEmpty) {
        // Retry with adjustments for a better image
        recognizedText = await retryWithEnhancedImage(inputImage);
      }

      reading = extractNumbers(recognizedText.text);
      if (mounted) setState(() {});
      await textRecognizer.close();
    } catch (e) {
      showToast(context, msg: 'MeterScanCameraScreen.failedToExtractText'.tr() + '$e');
    }
  }

  Future<RecognizedText> retryWithEnhancedImage(InputImage inputImage) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    return await textRecognizer.processImage(inputImage);
  }

  Future<File> preprocessImage(File image) async {
    final img.Image original = img.decodeImage(await image.readAsBytes())!;
    // some image preprocessing to make water meter reading text more readable

    // Save the preprocessed image to a new file
    final File processedImage = File('${image.path}_processed.jpg')..writeAsBytesSync(img.encodeJpg(original));
    return processedImage;
  }

  Future<String> uploadImageToFirebaseStorage(File file) async {
    try {
      String fileName = 'Meter/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask = ref.putFile(file);
      await uploadTask;

      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception("MeterScanCameraScreen.failedToUploadImage".tr() + '$e');
    }
  }

  showReadingBottomSheet(BuildContext context, String? imagePath) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ShowReadingBottomSheet(data: widget.data, imagePath: imagePath, newReading: reading)));
  }

  cropImageToCenter(File imageFile, BuildContext context) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception("MeterScanCameraScreen.unableToDecodeImage".tr());
    }
    const rectWidth = 250;
    const rectHeight = 90;
    // Calculate the center cropping rectangle
    final centerX = image.width ~/ 2;
    final centerY = (image.height ~/ 2);
    final left = (centerX - rectWidth ~/ 2).clamp(0, image.width);
    final top = (centerY - rectHeight ~/ 2).clamp(0, image.height);
    final width = rectWidth.clamp(0, image.width - left);
    final height = rectHeight.clamp(0, image.height - top);
    // Crop the image
    final croppedImage = img.copyCrop(
      image,
      x: left - 40,
      y: top,
      width: width + 80,
      height: height + 30,
    );

    // Save the cropped image to a new file
    final croppedFilePath = '${imageFile.parent.path}/cropped_${imageFile.uri.pathSegments.last}';
    File croppedFile = File(croppedFilePath);
    await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));
    if (widget.isOCREnabled) {
      croppedFile = await preprocessImage(croppedFile);
      await extractTextFromImage(croppedFile.path);
    }
    showReadingBottomSheet(context, originalImage!.path);
  }

  Future<void> takePicture(BuildContext context) async {
    if (cameraController.value.isInitialized) {
      originalImage = await cameraController.takePicture();

      await cropImageToCenter(File(originalImage!.path), context); // comment this line if you are using web
      // await cropImageToCenterWeb(originalImage!, context); // comment this line if you are using android or ios
    }
  }

  // comment cropImageToCenterWeb function if you are using android or ios

  // Future<void> cropImageToCenterWeb(XFile imageFile, BuildContext context) async {
  //   final imageBytes = await imageFile.readAsBytes();
  //   final image = img.decodeImage(imageBytes);
  //   if (image == null) {
  //     throw Exception("Unable to decode image");
  //   }
  //   const rectWidth = 250;
  //   const rectHeight = 90;
  //   // Calculate the center cropping rectangle
  //   final centerX = image.width ~/ 2;
  //   final centerY = (image.height ~/ 2);
  //   final left = (centerX - rectWidth ~/ 2).clamp(0, image.width);
  //   final top = (centerY - rectHeight ~/ 2).clamp(0, image.height);
  //   final width = rectWidth.clamp(0, image.width - left);
  //   final height = rectHeight.clamp(0, image.height - top);
  //   // Crop the image
  //   final croppedImage = img.copyCrop(
  //     image,
  //     x: left - 40,
  //     y: top,
  //     width: width + 80,
  //     height: height + 30,
  //   );
  //   // Convert the cropped image to a byte array
  //   final croppedImageBytes = Uint8List.fromList(img.encodeJpg(croppedImage));
  //   // Create a blob from the byte array
  //   final blob = html.Blob([croppedImageBytes]);
  //   // Create a URL for the blob
  //   final url = html.Url.createObjectUrlFromBlob(blob);
  //   if (widget.isOCREnabled) {
  //     String ocrText = await FlutterTesseractOcr.extractText(
  //       url,
  //       language: "eng",
  //       args: {
  //         "psm": "4",
  //         "preserve_interword_spaces": "1",
  //       },
  //     );
  //     reading = extractNumbers(ocrText);
  //     if (mounted) setState(() {});
  //   }

  //   showReadingBottomSheet(context, url);
  // }

  @override
  Widget build(BuildContext context) {
    // Dimensions of the target rectangle
    const targetHeight = 90.0;
    const targetWidth = 250.0;
    return Scaffold(
      appBar: CustomAppBar(title: 'MeterScanCameraScreen.ocrCamera'.tr()),
      backgroundColor: blackColor,
      body: isCameraControllerInit
          ? Stack(
              children: [
                // Camera Preview
                Center(child: CameraPreview(cameraController)),
                // Clipped overlay
                ClipPath(
                  clipper: CustomOverlayClipper(
                    screenWidth: width(context),
                    screenHeight: height(context),
                    rectWidth: targetWidth,
                    rectHeight: targetHeight,
                    appBarHeight: kToolbarHeight,
                  ),
                  child: Container(color: Colors.black.withOpacity(0.2)),
                ),
                // Red border for target area
                Center(
                  child: Container(
                    height: targetHeight,
                    width: targetWidth,
                    decoration: BoxDecoration(border: Border.all(color: redColor, width: 2), color: Colors.transparent),
                  ),
                ),
                // Capture button
                Positioned(
                  bottom: 50,
                  child: SizedBox(
                    height: 50,
                    width: width(context),
                    child: Center(
                      child: Button(
                        width: width(context) * 0.9,
                        text: 'MeterScanCameraScreen.captureAndProcess'.tr(),
                        onPressed: () async {
                          if (isCameraControllerInit) {
                            takePicture(context);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class CustomOverlayClipper extends CustomClipper<Path> {
  final double screenWidth;
  final double screenHeight;
  final double rectWidth;
  final double rectHeight;
  final double appBarHeight;

  CustomOverlayClipper({required this.screenWidth, required this.screenHeight, required this.rectWidth, required this.rectHeight, required this.appBarHeight});

  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.addRect(Rect.fromLTWH(0, 0, screenWidth, screenHeight));
    var sub = kIsWeb ? 10 : 40;
    final double adjustedHeight = screenHeight - appBarHeight - sub;
    final double centerX = screenWidth / 2 - rectWidth / 2;
    final double centerY = (adjustedHeight / 2 - rectHeight / 2);
    path.addRect(Rect.fromLTWH(centerX, centerY, rectWidth, rectHeight));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
