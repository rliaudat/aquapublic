// import 'package:agua_med/Components/Reuseable.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
//
// import '../../../theme.dart';
//
// class PreviewPdfScreen extends StatefulWidget {
//   const PreviewPdfScreen({super.key});
//
//   @override
//   State<PreviewPdfScreen> createState() => _PreviewPdfScreenState();
// }
//
// class _PreviewPdfScreenState extends State<PreviewPdfScreen> {
//
//   @override
//   void initState() {
//     generateUtilityBillPdf();
//     super.initState();
//   }
//
//   void generateUtilityBillPdf() async {
//     final pdf = pw.Document();
//     final ByteData bytes = await rootBundle.load('assets/images/icon.png');
//     final List<int> imageData = bytes.buffer.asUint8List();
//     final Uint8List image8List = Uint8List.fromList(imageData);
//     final pw.MemoryImage image = pw.MemoryImage(image8List);
//
//     const headerColor = PdfColor.fromInt(0xff197ba9);
//     const bgColor = PdfColor.fromInt(0xffefefef);
//
//     pdf.addPage(
//       pw.Page(
//         build: (pw.Context context) {
//          return pw.Container(
//              color: bgColor,
//              child: pw.Column(
//                crossAxisAlignment: pw.CrossAxisAlignment.start,
//                children: [
//                  pw.Container(
//                    padding: const pw.EdgeInsets.all(8),
//                    color: headerColor,
//                    child: pw.Row(
//                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                      children: [
//                        pw.Row(
//                            children: [
//                              pw.Image(image, width: 50,),
//                              pw.Text('AGUAMED', style: const pw.TextStyle(fontSize: 16, color: PdfColors.white)),
//
//                            ]
//                        ),
//                        pw.Column(
//                            crossAxisAlignment: pw.CrossAxisAlignment.start,
//                            children: [
//                              pw.Text('AguaMed Powers Inc', style: pw.TextStyle( color: PdfColors.white)),
//                              pw.Text('+9218891919', style: pw.TextStyle( color: PdfColors.white)),
//                              pw.Text('info@aguamed.com', style: pw.TextStyle( color: PdfColors.white)),
//
//
//                            ]
//                        )
//
//                      ],
//                    ),
//                  ),
//                  pw.SizedBox(height: p),
//
//                  pw.Padding(padding:  const pw.EdgeInsets.symmetric(horizontal: 8),
//                  child: pw.Column(
//                    crossAxisAlignment: pw.CrossAxisAlignment.start,
//                    children: [
//                      pw.Text('Invoice No.: 199101',),
//                      pw.Text('Consumer No.: 12345678910',),
//                      pw.Text('Account Name: John Doe',),
//                      pw.Text('Address: 4344 Poco Mas Drive, Dallas, FL, 33009',),
//                    ],
//                  ),
//                  ),
//
//                  pw.SizedBox(height: p),
//                  pw.Padding(
//                    padding:  const pw.EdgeInsets.symmetric(horizontal: 8),
//                    child: pw.TableHelper.fromTextArray(
//                      headers: ['Date', 'Reading' ,'Consumption', 'Cost (per Unit)', 'Amount (\$)'],
//                      data: [
//                        ['11/01/2024','0292829','300', '10', '3000'],
//                      ],
//                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                      cellPadding: const pw.EdgeInsets.all(5),
//                    )
//                  ),
//
//                  pw.SizedBox(height: p),
//                  pw.Padding(
//                    padding:  const pw.EdgeInsets.symmetric(horizontal: 8),
//                    child:  pw.Container(
//                      padding: pw.EdgeInsets.all(8),
//                      color: PdfColors.blue200,
//                      child: pw.Text('Bill History', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//                    ),
//                  ),
//
//                  pw.SizedBox(height: p),
//                  pw.Padding(  padding:  const pw.EdgeInsets.symmetric(horizontal: 8),
//                  child: pw.TableHelper.fromTextArray(
//                    headers: ['Month', 'Reading' ,'Consumption', 'Cost (per Unit)', 'Amount (\$)'],
//                    data: [
//                      ['January','0292829','300', '10', '3000'],
//                      ['February','0292900','200', '10', '3000'],
//                      ['March','0292829','300', '10', '3000'],
//                      ['April','0292829','300', '10', '3000'],
//                      ['May','0292829','300', '10', '3000'],
//                      ['June','0292829','300', '10', '3000'],
//                      ['July','0292829','300', '10', '3000'],
//                      ['August','0292829','300', '10', '3000'],
//                      ['September','0292829','300', '10', '3000'],
//                      ['October','0292829','300', '10', '3000'],
//                      ['November','0292829','300', '10', '3000'],
//                      ['December','0292829','300', '10', '3000'],
//                    ],
//                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                    cellPadding: const pw.EdgeInsets.all(5),
//                  )
//                  ),
//                  pw.SizedBox(height: 20),
//                  pw.Padding(
//                    padding:  const pw.EdgeInsets.symmetric(horizontal: 8),
//                    child: pw.Container(
//                      padding: const pw.EdgeInsets.all(8),
//                      color: PdfColors.blue200,
//                      child: pw.Column(
//                        crossAxisAlignment: pw.CrossAxisAlignment.start,
//                        children: [
//                          pw.Text('Bill Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//                          pw.SizedBox(height: 5),
//                          pw.Row(
//                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                            children: [
//                              pw.Text('Previous Charges (\$):', style: pw.TextStyle(fontSize: 12)),
//                              pw.Text('1.00', style: pw.TextStyle(fontSize: 12)),
//                            ],
//                          ),
//                          pw.Row(
//                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                            children: [
//                              pw.Text('Current Charges (\$):', style: pw.TextStyle(fontSize: 12)),
//                              pw.Text('3000.00', style: pw.TextStyle(fontSize: 12)),
//                            ],
//                          ),
//                          pw.Row(
//                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                            children: [
//                              pw.Text('Total Amount (\$):', style: pw.TextStyle(fontSize: 12)),
//                              pw.Text('3001.00', style: pw.TextStyle(fontSize: 12)),
//                            ],
//                          ),
//                          pw.Row(
//                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                            children: [
//                              pw.Text('Due Date:', style: pw.TextStyle(fontSize: 12)),
//                              pw.Text('November 19, 2021', style: pw.TextStyle(fontSize: 12)),
//                            ],
//                          ),
//                        ],
//                      ),
//                    ),
//                  ),
//
//
//                ],
//              )
//          );
//         },
//       ),
//     );
//
//
//     await Printing.layoutPdf(onLayout: (format) async => pdf.save());
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(title: 'PDF'),
//     );
//   }
// }
//
//
//
