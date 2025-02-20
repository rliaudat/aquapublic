// import 'package:agua_med/Components/Drawer.dart';
// import 'package:agua_med/loading.dart';
// import 'package:agua_med/theme.dart';
// import 'package:agua_med/Components/Reuseable.dart';
// import 'package:flutter/material.dart';
// import 'package:responsive_framework/responsive_framework.dart';

// class NotificationScreen extends StatefulWidget {
//   const NotificationScreen({super.key});

//   @override
//   State<NotificationScreen> createState() => _NotificationScreenState();
// }

// class _NotificationScreenState extends State<NotificationScreen> {
//   @override
//   Widget build(BuildContext context) {
//     bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
//     return GestureDetector(
//       onTap: () => unFocus(context),
//       child: Scaffold(
//         appBar: isTablet ? null :
//         const  CustomAppBar(
//           title: 'Notifications',
//           showAction: false,
//         ),
//         body: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             isTablet ? const CustomDrawer() : Container(),

//             Expanded(
//               child: Padding(
//                 padding:  EdgeInsets.symmetric(horizontal: p),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                      isTablet? const  CustomAppBar(
//                         title: 'Notifications',
//                         showAction: false,
//                        showButton: false,
//                       ):Container(),
//                       const SizedBox(height: 30,),
//                     Wrap(
//                       runSpacing: p,
//                       children: List.generate(4, (index){
//                         return Stack(
//                           children: [
//                             Container(
//                               height: 60,
//                               width: width(context),
//                               decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(radius),
//                                   color: greyColor
//                               ),

//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                                 child: Row(
//                                   children: [
//                                     ClipRRect(
//                                         borderRadius: BorderRadius.circular(100),
//                                         child: Image.asset('assets/images/profile.png', width: 45,)),
//                                     SizedBox(width: width(context) * 0.03,),
//                                     const Column(
//                                       mainAxisAlignment: MainAxisAlignment.center,
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text('John Doe ',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                         Text('Your monthly invoice has been genrated',
//                                           style: TextStyle(
//                                               fontSize: 10
//                                           ),
//                                         ),
//                                       ],
//                                     )
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             Positioned(
//                               right: p,
//                               bottom: 8,
//                               child: Text('Now',
//                                 style: TextStyle(
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.bold,
//                                     color: darkGreyColor
//                                 ),
//                               ),
//                             )
//                           ],
//                         );
//                       }),
//                     )
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

