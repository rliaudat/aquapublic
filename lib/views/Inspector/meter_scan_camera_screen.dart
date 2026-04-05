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

// class MeterScanCameraScreen extends StatefulWidget {
//   final House data;
//   final bool isOCREnabled;
//   const MeterScanCameraScreen(
//       {super.key, required this.data, required this.isOCREnabled});

//   @override
//   State<MeterScanCameraScreen> createState() => _MeterScanCameraScreenState();
// }

// class _MeterScanCameraScreenState extends State<MeterScanCameraScreen>
//     with WidgetsBindingObserver {
//   late List<CameraDescription> cameras = [];
//   CameraController?
//       cameraController; // Make nullable to prevent LateInitializationError
//   bool _isInitializing =
//       false; // Add flag to prevent multiple simultaneous init attempts

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     // Reset provider state when starting a new session
//     context.read<MeterCameraProvider>().reset();

//     init();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) async {
//     super.didChangeAppLifecycleState(state);

//     // Handle app lifecycle changes
//     if (state == AppLifecycleState.paused ||
//         state == AppLifecycleState.inactive) {
//       // App going to background, dispose camera
//       await _disposeCameraController();
//     } else if (state == AppLifecycleState.resumed) {
//       // App coming back to foreground, reinitialize camera if needed
//       if (!_isInitializing &&
//           !context.read<MeterCameraProvider>().isCameraControllerInit) {
//         init();
//       }
//     }
//   }

//   // Helper method to check if camera controller is ready
//   bool get isCameraReady =>
//       cameraController != null && cameraController!.value.isInitialized;

//   // Helper method to safely dispose and reset camera controller
//   Future<void> _disposeCameraController() async {
//     try {
//       if (isCameraReady) {
//         await cameraController!.dispose();
//       }
//       cameraController = null;
//     } catch (e) {
//       print("Error disposing camera controller: $e");
//       cameraController = null;
//     }
//   }

//   Future<void> init() async {
//     if (_isInitializing) {
//       print("Init called while already initializing, ignoring request");
//       return; // Prevent multiple simultaneous init attempts
//     }

//     _isInitializing = true;
//     print("Starting camera initialization...");

//     try {
//       // Add timeout to prevent stuck initialization
//       final initFuture = _performCameraInit();
//       await initFuture.timeout(
//         const Duration(seconds: 15),
//         onTimeout: () {
//           print("Camera initialization timed out");
//           throw TimeoutException(
//               'Camera initialization timed out', const Duration(seconds: 15));
//         },
//       );
//     } catch (e) {
//       print("Error in init method: $e");
//       showToast(context, msg: 'Camera setup failed: $e');
//       context.read<MeterCameraProvider>().setIsCameraControllerInit(false);
//     } finally {
//       _isInitializing = false;
//       print(
//           "Camera initialization operation finished, _isInitializing set to false");
//     }
//   }

//   Future<void> _performCameraInit() async {
//     final status = await Permission.camera.request();
//     print('Camera permission status: $status');

//     if (status.isGranted) {
//       cameras = await availableCameras();
//       print("Found ${cameras.length} cameras");

//       if (cameras.isEmpty) {
//         showToast(context, msg: 'No cameras found');
//         return;
//       }

//       // Dispose existing controller if it exists and is initialized
//       await _disposeCameraController();

//       cameraController = CameraController(
//         kIsWeb ? cameras.last : cameras.first,
//         ResolutionPreset.medium,
//         enableAudio: false,
//       );

//       try {
//         print("Initializing camera controller...");
//         await cameraController!.initialize();
//         if (!kIsWeb) {
//           print("Setting zoom level...");
//           await cameraController!.setZoomLevel(1.8);
//         }
//         context.read<MeterCameraProvider>().setIsCameraControllerInit(true);
//         print("Camera initialization completed successfully");
//       } catch (e) {
//         print("EXA Camera controller initialization failed: $e");
//         showToast(context, msg: 'Camera initialization failed: $e');
//         context.read<MeterCameraProvider>().setIsCameraControllerInit(false);
//       }
//     } else if (status.isPermanentlyDenied) {
//       showToast(context,
//           msg:
//               'Camera permission permanently denied. Please enable it from settings.');
//       openAppSettings();
//     } else {
//       showToast(context, msg: 'Camera permission denied');
//     }
//   }

//   // Force reset camera state (for emergency use)
//   void _forceResetCameraState() {
//     _isInitializing = false;
//     context.read<MeterCameraProvider>().setIsCameraControllerInit(false);
//     context.read<MeterCameraProvider>().setOriginalImage(null);
//     context.read<MeterCameraProvider>().setWebImageBytes(null);
//     print("Camera state force reset");
//   }

//   // Debug method to show current camera state
//   void _logCameraState(String operation) {
//     print("=== Camera State Log ===");
//     print("Operation: $operation");
//     print("_isInitializing: $_isInitializing");
//     print("isCameraReady: $isCameraReady");
//     print(
//         "provider.isCameraControllerInit: ${context.read<MeterCameraProvider>().isCameraControllerInit}");
//     print(
//         "provider.originalImage: ${context.read<MeterCameraProvider>().originalImage}");
//     print("cameraController: ${cameraController != null ? 'exists' : 'null'}");
//     if (cameraController != null) {
//       print(
//           "cameraController.isInitialized: ${cameraController!.value.isInitialized}");
//     }
//     print("========================");
//   }

//   // Handle the case when user wants to start fresh
//   void _handleStartFresh() {
//     print("Starting fresh - taking new picture");
//     if (isCameraReady) {
//       takePicture();
//     } else {
//       showToast(context,
//           msg: 'Camera not ready. Please wait for initialization.');
//     }
//   }

//   // Check if we should show the retake button
//   bool get shouldShowRetakeButton =>
//       context.read<MeterCameraProvider>().originalImage != null &&
//       context.read<MeterCameraProvider>().isCameraControllerInit;

//   // Debug method to show provider state
//   void _logProviderState(String operation) {
//     final provider = context.read<MeterCameraProvider>();
//     print("=== Provider State Log ===");
//     print("Operation: $operation");
//     print(
//         "provider.isCameraControllerInit: ${provider.isCameraControllerInit}");
//     print("provider.originalImage: ${provider.originalImage}");
//     print("provider.webImageBytes: ${provider.webImageBytes}");
//     print("provider.reading: ${provider.reading}");
//     print("========================");
//   }

//   // Check if camera reset was successful
//   bool get isCameraResetSuccessful =>
//       context.read<MeterCameraProvider>().isCameraControllerInit &&
//       isCameraReady &&
//       context.read<MeterCameraProvider>().originalImage == null;

//   // Check if camera is currently resetting
//   bool get isCameraResetting => _isInitializing;

//   // Add a method to properly reset the camera
//   Future<void> resetCamera() async {
//     if (_isInitializing) {
//       print("Camera is already initializing, ignoring retake request");
//       return; // Prevent multiple simultaneous reset attempts
//     }

//     _isInitializing = true;
//     _logCameraState("resetCamera - start");

//     try {
//       print("Starting camera reset...");

//       // Set loading state but don't clear image yet
//       context.read<MeterCameraProvider>().setIsCameraControllerInit(false);

//       // Safely dispose existing camera controller
//       await _disposeCameraController();

//       // Wait a bit to ensure UI updates
//       await Future.delayed(const Duration(milliseconds: 100));

//       // Reinitialize camera directly with timeout
//       print("Reinitializing camera directly...");
//       await _performCameraInit().timeout(
//         const Duration(seconds: 10),
//         onTimeout: () {
//           print("Camera reinitialization timed out");
//           throw TimeoutException(
//               'Camera reinitialization timed out', const Duration(seconds: 10));
//         },
//       );

//       // Check if camera was successfully reinitialized
//       if (context.read<MeterCameraProvider>().isCameraControllerInit &&
//           isCameraReady) {
//         print("Camera successfully reinitialized, clearing images...");
//         context.read<MeterCameraProvider>().setOriginalImage(null);
//         context.read<MeterCameraProvider>().setWebImageBytes(null);
//         print("Images cleared after successful camera reinitialization");
//       } else {
//         print("Camera reinitialization failed or incomplete, keeping images");
//         print(
//             "isCameraControllerInit: ${context.read<MeterCameraProvider>().isCameraControllerInit}");
//         print("isCameraReady: $isCameraReady");
//       }

//       _logCameraState("resetCamera - success");
//       print("Camera reset completed successfully");
//     } catch (e) {
//       print("Error resetting camera: $e");
//       showToast(context, msg: 'Failed to reset camera: $e');

//       // Ensure camera state is reset on error
//       context.read<MeterCameraProvider>().setIsCameraControllerInit(false);
//       _logCameraState("resetCamera - error");
//     } finally {
//       _isInitializing = false;
//       print("Camera reset operation finished, _isInitializing set to false");
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _disposeCameraController();
//     super.dispose();
//   }

//   String extractNumbers(String input) =>
//       RegExp(r'\d+').allMatches(input).map((m) => m.group(0)!).join();

//   bool isValidNumber(String text) {
//     final numberRegex = RegExp(r'^-?\d+(\.\d+)?$');
//     return numberRegex.hasMatch(text);
//   }

//   Future<void> extractTextFromImage(XFile imageFile) async {
//     try {
//       final inputImage = kIsWeb
//           ? InputImage.fromFilePath(imageFile.path)
//           : InputImage.fromFilePath(imageFile.path);
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
//     } catch (e) {
//       // showToast(context, msg: 'Unable to extract reading from the image!');
//     }
//   }

//   // Check if image can be processed
//   bool get canProcessImage =>
//       context.read<MeterCameraProvider>().originalImage != null &&
//       context.read<MeterCameraProvider>().isCameraControllerInit;

//   Future<void> cropImage(XFile imageFile) async {
//     try {
//       if (imageFile == null) {
//         throw Exception("No image file provided");
//       }

//       final imageBytes = await imageFile.readAsBytes();
//       final image = img.decodeImage(imageBytes);

//       if (image == null) throw Exception("Unable to decode image");

//       const rectWidth = 250;
//       const rectHeight = 90;
//       final centerX = image.width ~/ 2;
//       final centerY = image.height ~/ 2;
//       final left = (centerX - rectWidth ~/ 2).clamp(0, image.width);
//       final top = (centerY - rectHeight ~/ 2).clamp(0, image.height);
//       final width = rectWidth.clamp(0, image.width - left);
//       final height = rectHeight.clamp(0, image.height - top);

//       final croppedImage = img.copyCrop(image,
//           x: left - 40, y: top, width: width + 80, height: height + 30);

//       // ignore: unused_local_variable
//       final Uint8List croppedImageBytes =
//           Uint8List.fromList(img.encodeJpg(croppedImage));

//       if (widget.isOCREnabled) {
//         await extractTextFromImage(imageFile);
//       }

//       showReadingBottomSheet(context, imageFile.path);
//     } catch (e) {
//       print("Error in cropImage: $e");
//       showToast(context, msg: 'Failed to process image: $e');
//       rethrow;
//     }
//   }

//   Future<void> takePicture() async {
//     try {
//       // Check if camera controller is ready
//       if (!isCameraReady) {
//         print("Camera controller not ready");
//         return;
//       }

//       var image = await cameraController!.takePicture();

//       if (kIsWeb) {
//         context
//             .read<MeterCameraProvider>()
//             .setWebImageBytes(await image.readAsBytes());
//       }
//       context.read<MeterCameraProvider>().setOriginalImage(image);
//     } catch (e) {
//       print("Error taking picture: $e");
//       showToast(context, msg: 'Failed to take picture: $e');
//     }
//   }

//   Future<String> uploadImageToFirebaseStorage(XFile file) async {
//     try {
//       String fileName = 'Meter/${DateTime.now().millisecondsSinceEpoch}.jpg';
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
//       throw Exception("Failed to upload image: $e");
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
//       return PopScope(
//         onPopInvokedWithResult: (didPop, result) {
//           if (didPop) {
//             // Don't reset the provider state when navigating away
//             // This preserves the image and camera state
//             print("Navigating away, preserving camera state");
//             // Only dispose the camera controller, don't reset provider
//             _disposeCameraController();
//           }
//         },
//         child: Scaffold(
//           appBar: CustomAppBar(title: 'MeterScanCameraScreen.ocrCamera'.tr()),
//           backgroundColor: blackColor,
//           body: provider.isCameraControllerInit
//               ? Stack(
//                   children: [
//                     if (provider.originalImage != null)
//                       Center(
//                         child: kIsWeb
//                             ? Image.memory(provider
//                                 .webImageBytes!) // Use Image.memory for web
//                             : Image.file(
//                                 File(provider.originalImage!.path),
//                               ), // Use Image.file for mobile
//                       ),
//                     if (provider.originalImage == null)
//                       Center(
//                         child: isCameraReady
//                             ? CameraPreview(cameraController!)
//                             : const CircularProgressIndicator(),
//                       ),
//                     ClipPath(
//                       clipper: CustomOverlayClipper(
//                         screenWidth: width(context),
//                         screenHeight: height(context),
//                         rectWidth: targetWidth,
//                         rectHeight: targetHeight,
//                         appBarHeight: kToolbarHeight,
//                       ),
//                       // ignore: deprecated_member_use
//                       child: Container(color: Colors.black.withOpacity(0.2)),
//                     ),
//                     Center(
//                       child: Container(
//                         height: targetHeight,
//                         width: targetWidth,
//                         decoration: BoxDecoration(
//                             border: Border.all(color: redColor, width: 2),
//                             color: Colors.transparent),
//                       ),
//                     ),
//                     if (provider.originalImage != null)
//                       Positioned(
//                         bottom: 120,
//                         child: SizedBox(
//                           height: 50,
//                           width: width(context),
//                           child: Center(
//                             child: Builder(
//                               builder: (context) {
//                                 // Debug: Log the current state
//                                 print("=== UI State Check ===");
//                                 print(
//                                     "provider.originalImage: ${provider.originalImage}");
//                                 print(
//                                     "provider.isCameraControllerInit: ${provider.isCameraControllerInit}");
//                                 print(
//                                     "shouldShowRetakeButton: $shouldShowRetakeButton");
//                                 print("_isInitializing: $_isInitializing");
//                                 print("=====================");

//                                 if (_isInitializing) {
//                                   return Container(
//                                     width: width(context) * 0.9,
//                                     height: 50,
//                                     decoration: BoxDecoration(
//                                       color: Colors
//                                           .orange, // Changed to orange to show reset in progress
//                                       borderRadius: BorderRadius.circular(100),
//                                     ),
//                                     child: Center(
//                                       child: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           SizedBox(
//                                             width: 20,
//                                             height: 20,
//                                             child: CircularProgressIndicator(
//                                               strokeWidth: 2,
//                                               valueColor:
//                                                   AlwaysStoppedAnimation<Color>(
//                                                       Colors.white),
//                                             ),
//                                           ),
//                                           SizedBox(width: 10),
//                                           Text(
//                                             'MeterScanCameraScreen.resetting'
//                                                 .tr(),
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 } else if (shouldShowRetakeButton) {
//                                   return Button(
//                                     width: width(context) * 0.9,
//                                     text: 'MeterScanCameraScreen.retake'.tr(),
//                                     onPressed: () {
//                                       // Debug: Check current state when button is pressed
//                                       print("=== Retake Button Pressed ===");
//                                       print(
//                                           "provider.originalImage: ${provider.originalImage}");
//                                       print(
//                                           "provider.isCameraControllerInit: ${provider.isCameraControllerInit}");
//                                       print(
//                                           "_isInitializing: $_isInitializing");

//                                       // Safety check: Don't allow retake if there's no image
//                                       if (provider.originalImage == null) {
//                                         print(
//                                             "ERROR: Retake button pressed but no image exists!");
//                                         showToast(context,
//                                             msg:
//                                                 'No image to retake. Starting fresh...');
//                                         // Start fresh by taking a new picture
//                                         _handleStartFresh();
//                                         return;
//                                       }

//                                       // Add timeout protection for stuck camera states
//                                       if (_isInitializing) {
//                                         print(
//                                             "Camera is stuck initializing, force reset");
//                                         _logCameraState(
//                                             "Retake button - stuck state");
//                                         _forceResetCameraState();
//                                         // Try to reset after a short delay
//                                         Future.delayed(
//                                             const Duration(milliseconds: 500),
//                                             () {
//                                           if (!_isInitializing) {
//                                             _logCameraState(
//                                                 "Retake button - delayed reset");
//                                             resetCamera().then((_) {
//                                               // Check if reset was successful
//                                               if (isCameraResetSuccessful) {
//                                                 print(
//                                                     "Camera reset successful - image cleared and camera ready");
//                                               } else {
//                                                 print(
//                                                     "Camera reset incomplete - check logs for details");
//                                               }
//                                             });
//                                           }
//                                         });
//                                       } else {
//                                         _logCameraState(
//                                             "Retake button - normal reset");
//                                         resetCamera().then((_) {
//                                           // Check if reset was successful
//                                           if (isCameraResetSuccessful) {
//                                             print(
//                                                 "Camera reset successful - image cleared and camera ready");
//                                           } else {
//                                             print(
//                                                 "Camera reset incomplete - check logs for details");
//                                           }
//                                         });
//                                       }
//                                     },
//                                   );
//                                 } else {
//                                   return Container(
//                                     width: width(context) * 0.9,
//                                     height: 50,
//                                     decoration: BoxDecoration(
//                                       color: Colors.grey,
//                                       borderRadius: BorderRadius.circular(100),
//                                     ),
//                                     child: Center(
//                                       child: Text(
//                                         'MeterScanCameraScreen.waiting'.tr(),
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   );
//                                 }
//                               },
//                             ),
//                           ),
//                         ),
//                       ),
//                     Positioned(
//                       bottom: 50,
//                       child: SizedBox(
//                         height: 50,
//                         width: width(context),
//                         child: Center(
//                           child: Button(
//                             width: width(context) * 0.9,
//                             text: provider.originalImage == null
//                                 ? 'MeterScanCameraScreen.capture'.tr()
//                                 : 'MeterScanCameraScreen.process'.tr(),
//                             onPressed: () async {
//                               if (provider.originalImage == null) {
//                                 // Take a new picture
//                                 if (isCameraReady) {
//                                   print("Taking new picture...");
//                                   takePicture();
//                                 } else {
//                                   print("Camera not ready for taking picture");
//                                   showToast(context,
//                                       msg:
//                                           'Camera not ready. Please wait for initialization.');
//                                 }
//                               } else {
//                                 // Process existing image
//                                 if (provider.isCameraControllerInit) {
//                                   print("Processing existing image...");
//                                   try {
//                                     await cropImage(provider.originalImage!);
//                                   } catch (e) {
//                                     print("Error processing image: $e");
//                                     showToast(context,
//                                         msg: 'Failed to process image: $e');
//                                   }
//                                 } else {
//                                   print(
//                                       "Camera not ready for processing image");
//                                   showToast(context,
//                                       msg:
//                                           'Camera not ready. Please wait for initialization.');
//                                 }
//                               }
//                             },
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 )
//               : const Center(child: CircularProgressIndicator()),
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
  CameraController? cameraController;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<MeterCameraProvider>().reset();
    init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      await _disposeCameraController();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isInitializing &&
          !context.read<MeterCameraProvider>().isCameraControllerInit) {
        init();
      }
    }
  }

  bool get isCameraReady =>
      cameraController != null && cameraController!.value.isInitialized;

  Future<void> _disposeCameraController() async {
    try {
      if (cameraController != null && cameraController!.value.isInitialized) {
        await cameraController!.dispose();
      }
      cameraController = null;
    } catch (e) {
      print("Error disposing camera controller: $e");
      cameraController = null;
    }
  }

  Future<void> init() async {
    if (_isInitializing) {
      print("Init called while already initializing, ignoring request");
      return;
    }

    setState(() {
      _isInitializing = true;
    });
    print("Starting camera initialization...");

    try {
      final initFuture = _performCameraInit();
      await initFuture.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print("Camera initialization timed out");
          throw TimeoutException(
              'Camera initialization timed out', const Duration(seconds: 15));
        },
      );
    } catch (e) {
      print("Error in init method: $e");
      showToast(context, msg: 'Camera setup failed: $e');
      context.read<MeterCameraProvider>().setIsCameraControllerInit(false);
    } finally {
      setState(() {
        _isInitializing = false;
      });
      print("Camera initialization operation finished, _isInitializing set to false");
    }
  }

  Future<void> _performCameraInit() async {
    final status = await Permission.camera.request();
    print('Camera permission status: $status');

    if (status.isGranted) {
      cameras = await availableCameras();
      print("Found ${cameras.length} cameras");

      if (cameras.isEmpty) {
        showToast(context, msg: 'No cameras found');
        return;
      }

      await _disposeCameraController();

      cameraController = CameraController(
        kIsWeb ? cameras.last : cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      try {
        print("Initializing camera controller...");
        await cameraController!.initialize();
        if (!kIsWeb) {
          print("Setting zoom level...");
          await cameraController!.setZoomLevel(1.8);
        }
        context.read<MeterCameraProvider>().setIsCameraControllerInit(true);
        print("Camera initialization completed successfully");
      } catch (e) {
        print("EXA Camera controller initialization failed: $e");
        showToast(context, msg: 'Camera initialization failed: $e');
        context.read<MeterCameraProvider>().setIsCameraControllerInit(false);
      }
    } else if (status.isPermanentlyDenied) {
      showToast(context,
          msg:
              'Camera permission permanently denied. Please enable it from settings.');
      openAppSettings();
    } else {
      showToast(context, msg: 'Camera permission denied');
    }
  }

  void _forceResetCameraState() {
    setState(() {
      _isInitializing = false;
    });
    context.read<MeterCameraProvider>().setIsCameraControllerInit(false);
    context.read<MeterCameraProvider>().setOriginalImage(null);
    context.read<MeterCameraProvider>().setWebImageBytes(null);
    print("Camera state force reset");
  }

  void _logCameraState(String operation) {
    print("=== Camera State Log ===");
    print("Operation: $operation");
    print("_isInitializing: $_isInitializing");
    print("isCameraReady: $isCameraReady");
    print(
        "provider.isCameraControllerInit: ${context.read<MeterCameraProvider>().isCameraControllerInit}");
    print(
        "provider.originalImage: ${context.read<MeterCameraProvider>().originalImage}");
    print("cameraController: ${cameraController != null ? 'exists' : 'null'}");
    if (cameraController != null) {
      print(
          "cameraController.isInitialized: ${cameraController!.value.isInitialized}");
    }
    print("========================");
  }

  void _handleStartFresh() {
    print("Starting fresh - taking new picture");
    if (isCameraReady) {
      takePicture();
    } else {
      showToast(context,
          msg: 'Camera not ready. Please wait for initialization.');
    }
  }

  bool get shouldShowRetakeButton =>
      context.read<MeterCameraProvider>().originalImage != null &&
      context.read<MeterCameraProvider>().isCameraControllerInit;

  void _logProviderState(String operation) {
    final provider = context.read<MeterCameraProvider>();
    print("=== Provider State Log ===");
    print("Operation: $operation");
    print(
        "provider.isCameraControllerInit: ${provider.isCameraControllerInit}");
    print("provider.originalImage: ${provider.originalImage}");
    print("provider.webImageBytes: ${provider.webImageBytes}");
    print("provider.reading: ${provider.reading}");
    print("========================");
  }

  bool get isCameraResetSuccessful =>
      context.read<MeterCameraProvider>().isCameraControllerInit &&
      isCameraReady &&
      context.read<MeterCameraProvider>().originalImage == null;

  bool get isCameraResetting => _isInitializing;

  Future<void> resetCamera() async {
    if (_isInitializing) {
      print("Camera is already initializing, ignoring retake request");
      return;
    }

    setState(() {
      _isInitializing = true;
    });
    _logCameraState("resetCamera - start");

    try {
      print("Starting camera reset...");

      // Clear the image immediately for better UX
      context.read<MeterCameraProvider>().setOriginalImage(null);
      context.read<MeterCameraProvider>().setWebImageBytes(null);

      // Set loading state
      context.read<MeterCameraProvider>().setIsCameraControllerInit(false);

      // Safely dispose existing camera controller
      await _disposeCameraController();

      // Wait a bit to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));

      // Reinitialize camera directly with timeout
      print("Reinitializing camera directly...");
      await _performCameraInit().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print("Camera reinitialization timed out");
          throw TimeoutException(
              'Camera reinitialization timed out', const Duration(seconds: 10));
        },
      );

      // Check if camera was successfully reinitialized
      if (context.read<MeterCameraProvider>().isCameraControllerInit &&
          isCameraReady) {
        print("Camera successfully reinitialized");
      } else {
        print("Camera reinitialization failed or incomplete");
        print(
            "isCameraControllerInit: ${context.read<MeterCameraProvider>().isCameraControllerInit}");
        print("isCameraReady: $isCameraReady");
      }

      _logCameraState("resetCamera - success");
      print("Camera reset completed successfully");
    } catch (e) {
      print("Error resetting camera: $e");
      showToast(context, msg: 'Failed to reset camera: $e');

      // Ensure camera state is reset on error
      context.read<MeterCameraProvider>().setIsCameraControllerInit(false);
      _logCameraState("resetCamera - error");
    } finally {
      setState(() {
        _isInitializing = false;
      });
      print("Camera reset operation finished, _isInitializing set to false");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCameraController();
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
      // showToast(context, msg: 'Unable to extract reading from the image!');
    }
  }

  bool get canProcessImage =>
      context.read<MeterCameraProvider>().originalImage != null &&
      context.read<MeterCameraProvider>().isCameraControllerInit;

  Future<void> cropImage(XFile imageFile) async {
    try {
      if (imageFile == null) {
        throw Exception("No image file provided");
      }

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
    } catch (e) {
      print("Error in cropImage: $e");
      showToast(context, msg: 'Failed to process image: $e');
      rethrow;
    }
  }

  Future<void> takePicture() async {
    try {
      if (!isCameraReady) {
        print("Camera controller not ready");
        return;
      }

      var image = await cameraController!.takePicture();

      if (kIsWeb) {
        context
            .read<MeterCameraProvider>()
            .setWebImageBytes(await image.readAsBytes());
      }
      
      // Use setState to trigger UI rebuild
      setState(() {
        context.read<MeterCameraProvider>().setOriginalImage(image);
      });
    } catch (e) {
      print("Error taking picture: $e");
      showToast(context, msg: 'Failed to take picture: $e');
    }
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
            print("Navigating away, preserving camera state");
            _disposeCameraController();
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
                            ? Image.memory(provider.webImageBytes!)
                            : Image.file(File(provider.originalImage!.path)),
                      ),
                    if (provider.originalImage == null)
                      Center(
                        child: isCameraReady
                            ? CameraPreview(cameraController!)
                            : const CircularProgressIndicator(),
                      ),
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
                            child: Builder(
                              builder: (context) {
                                print("=== UI State Check ===");
                                print(
                                    "provider.originalImage: ${provider.originalImage}");
                                print(
                                    "provider.isCameraControllerInit: ${provider.isCameraControllerInit}");
                                print(
                                    "shouldShowRetakeButton: $shouldShowRetakeButton");
                                print("_isInitializing: $_isInitializing");
                                print("=====================");

                                if (_isInitializing) {
                                  return Container(
                                    width: width(context) * 0.9,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'MeterScanCameraScreen.resetting'
                                                .tr(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else if (shouldShowRetakeButton) {
                                  return Button(
                                    width: width(context) * 0.9,
                                    text: 'MeterScanCameraScreen.retake'.tr(),
                                    onPressed: () {
                                      print("=== Retake Button Pressed ===");
                                      print(
                                          "provider.originalImage: ${provider.originalImage}");
                                      print(
                                          "provider.isCameraControllerInit: ${provider.isCameraControllerInit}");
                                      print(
                                          "_isInitializing: $_isInitializing");

                                      if (provider.originalImage == null) {
                                        print(
                                            "ERROR: Retake button pressed but no image exists!");
                                        showToast(context,
                                            msg:
                                                'No image to retake. Starting fresh...');
                                        _handleStartFresh();
                                        return;
                                      }

                                      if (_isInitializing) {
                                        print(
                                            "Camera is stuck initializing, force reset");
                                        _logCameraState(
                                            "Retake button - stuck state");
                                        _forceResetCameraState();
                                        Future.delayed(
                                            const Duration(milliseconds: 500),
                                            () {
                                          if (!_isInitializing) {
                                            _logCameraState(
                                                "Retake button - delayed reset");
                                            resetCamera().then((_) {
                                              if (isCameraResetSuccessful) {
                                                print(
                                                    "Camera reset successful - image cleared and camera ready");
                                              } else {
                                                print(
                                                    "Camera reset incomplete - check logs for details");
                                              }
                                            });
                                          }
                                        });
                                      } else {
                                        _logCameraState(
                                            "Retake button - normal reset");
                                        resetCamera().then((_) {
                                          if (isCameraResetSuccessful) {
                                            print(
                                                "Camera reset successful - image cleared and camera ready");
                                          } else {
                                            print(
                                                "Camera reset incomplete - check logs for details");
                                          }
                                        });
                                      }
                                    },
                                  );
                                } else {
                                  return Container(
                                    width: width(context) * 0.9,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'MeterScanCameraScreen.waiting'.tr(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }
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
                                if (isCameraReady) {
                                  print("Taking new picture...");
                                  takePicture();
                                } else {
                                  print("Camera not ready for taking picture");
                                  showToast(context,
                                      msg:
                                          'Camera not ready. Please wait for initialization.');
                                }
                              } else {
                                if (provider.isCameraControllerInit) {
                                  print("Processing existing image...");
                                  try {
                                    await cropImage(provider.originalImage!);
                                  } catch (e) {
                                    print("Error processing image: $e");
                                    showToast(context,
                                        msg: 'Failed to process image: $e');
                                  }
                                } else {
                                  print(
                                      "Camera not ready for processing image");
                                  showToast(context,
                                      msg:
                                          'Camera not ready. Please wait for initialization.');
                                }
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
