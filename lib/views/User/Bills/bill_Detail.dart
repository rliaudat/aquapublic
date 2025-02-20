import 'package:agua_med/Components/Drawer.dart';
import 'package:agua_med/Components/Reuseable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../../theme.dart';

class BillDetailScreen extends StatefulWidget {
  const BillDetailScreen({super.key});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {

  Future<Uint8List> generateUtilityBillPdf() async {

    final pdf = pw.Document();
    final ByteData bytes = await rootBundle.load('assets/images/icon.png');
    final List<int> imageData = bytes.buffer.asUint8List();
    final Uint8List image8List = Uint8List.fromList(imageData);
    final pw.MemoryImage image = pw.MemoryImage(image8List);


    const headerColor = PdfColor.fromInt(0xff197ba9);
    const bgColor = PdfColor.fromInt(0xffefefef);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
              color: bgColor,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    color: headerColor,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Row(
                            children: [
                              pw.Image(image, width: 50,),
                              pw.Text('AGUAMED', style: const pw.TextStyle(fontSize: 16, color: PdfColors.white)),

                            ]
                        ),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('AguaMed Powers Inc', style: const pw.TextStyle( color: PdfColors.white)),
                              pw.Text('+9218891919', style: const pw.TextStyle( color: PdfColors.white)),
                              pw.Text('info@aguamed.com', style: const pw.TextStyle( color: PdfColors.white)),


                            ]
                        )

                      ],
                    ),
                  ),
                  pw.SizedBox(height: p),

                  pw.Padding(padding:  const pw.EdgeInsets.symmetric(horizontal: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Invoice No.: 199101',),
                        pw.Text('Consumer No.: 12345678910',),
                        pw.Text('Account Name: John Doe',),
                        pw.Text('Address: 4344 Poco Mas Drive, Dallas, FL, 33009',),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: p),
                  pw.Padding(
                      padding:  const pw.EdgeInsets.symmetric(horizontal: 8),
                      child: pw.TableHelper.fromTextArray(
                        headers: ['Date', 'Reading' ,'Consumption', 'Cost (per Unit)', 'Amount (\$)'],
                        data: [
                          ['11/01/2024','0292829','300', '10', '3000'],
                        ],
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        cellPadding: const pw.EdgeInsets.all(5),
                      )
                  ),

                  pw.SizedBox(height: p),
                  pw.Padding(
                    padding:  const pw.EdgeInsets.symmetric(horizontal: 8),
                    child:  pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      color: PdfColors.blue200,
                      child: pw.Text('Bill History', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ),
                  ),

                  pw.SizedBox(height: p),
                  pw.Padding(  padding:  const pw.EdgeInsets.symmetric(horizontal: 8),
                      child: pw.TableHelper.fromTextArray(
                        headers: ['Month', 'Reading' ,'Consumption', 'Cost (per Unit)', 'Amount (\$)'],
                        data: [
                          ['January','0292829','300', '10', '3000'],
                          ['February','0292900','200', '10', '3000'],
                          ['March','0292829','300', '10', '3000'],
                          ['April','0292829','300', '10', '3000'],
                          ['May','0292829','300', '10', '3000'],
                          ['June','0292829','300', '10', '3000'],
                          ['July','0292829','300', '10', '3000'],
                          ['August','0292829','300', '10', '3000'],
                          ['September','0292829','300', '10', '3000'],
                          ['October','0292829','300', '10', '3000'],
                          ['November','0292829','300', '10', '3000'],
                          ['December','0292829','300', '10', '3000'],
                        ],
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        cellPadding: const pw.EdgeInsets.all(5),
                      )
                  ),
                  pw.SizedBox(height: 20),
                  pw.Padding(
                    padding:  const pw.EdgeInsets.symmetric(horizontal: 8),
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      color: PdfColors.blue200,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Bill Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Previous Charges (\$):', style: const pw.TextStyle(fontSize: 12)),
                              pw.Text('1.00', style: const pw.TextStyle(fontSize: 12)),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Current Charges (\$):', style: const pw.TextStyle(fontSize: 12)),
                              pw.Text('3000.00', style: const pw.TextStyle(fontSize: 12)),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Total Amount (\$):', style: const pw.TextStyle(fontSize: 12)),
                              pw.Text('3001.00', style: const pw.TextStyle(fontSize: 12)),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Due Date:', style: const pw.TextStyle(fontSize: 12)),
                              pw.Text('November 19, 2021', style: const pw.TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),


                ],
              )
          );
        },
      ),
    );


    return pdf.save();
  }
  @override
  Widget build(BuildContext context) {
    bool isTablet =  ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return Scaffold(
      appBar:  isTablet ? null : const CustomAppBar(title: 'Bill Details'),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isTablet ? const CustomDrawer() : Container(),
          Expanded(
            child: Padding(
              padding:  EdgeInsets.symmetric(horizontal: p),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isTablet ? const  CustomAppBar(
                    title: 'Bill Details',
                    showAction: false,
                    showButton: false,
                  ): Container(),
                  const SizedBox(height: 60,),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 350,
                        width: width(context),
                        decoration: BoxDecoration(
                            color: greyColor,
                            borderRadius: BorderRadius.circular(radius),
                            boxShadow: [
                              BoxShadow(
                                  color: borderColor,
                                  blurRadius: 2,
                                  spreadRadius: 0.1
                              )
                            ]
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 40,),
                              Text('AguaMed',
                              style: TextStyle(
                                color: darkGreyColor,
                                fontWeight: FontWeight.bold,
                              ),
                              ),
                              Text('info@aguamed.com',
                                style: TextStyle(
                                  color: darkGreyColor,
                                ),
                              ),
                              const SizedBox(height: 5,),
                              Text('\$ 256.2',
                                style: TextStyle(
                                  color: darkGreyColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 5,),
                              GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      child: SizedBox(
                                        height: 500,
                                        width: 400,
                                        child: PdfPreview(
                                          build: (format) async {
                                            return  generateUtilityBillPdf();
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset('assets/images/waterBill.png', width: 15, color: secondaryColor),
                                      const SizedBox(width: 5),
                                      Text(
                                        'VIEW BILL',
                                        style: TextStyle(
                                          color: secondaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Invoice No',
                                    style: TextStyle(
                                        color: darkGreyColor,
                                        fontSize: 14
                                    ),),
                                  Text('19726',
                                    style: TextStyle(
                                        color: darkGreyColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14

                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 5,),
                              Divider(
                                color: borderColor,
                              ),
                              const SizedBox(height: 5,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Consumer Name',
                                  style: TextStyle(
                                    color: darkGreyColor,
                                    fontSize: 14
                                  ),),
                                  Text('John Doe',
                                    style: TextStyle(
                                      color: darkGreyColor,
                                      fontWeight: FontWeight.bold,
                                        fontSize: 14

                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 5,),
                              Divider(
                                color: borderColor,
                              ),
                              const SizedBox(height: 5,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Consumer Number',
                                    style: TextStyle(
                                        color: darkGreyColor,
                                        fontSize: 14
                                    ),),
                                  Text('+927191991',
                                    style: TextStyle(
                                        color: darkGreyColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14

                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 5,),
                              Divider(
                                color: borderColor,
                              ),
                              const SizedBox(height: 5,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Due date',
                                    style: TextStyle(
                                        color: darkGreyColor,
                                        fontSize: 14
                                    ),),
                                  Text('10 Nov',
                                    style: TextStyle(
                                        color: darkGreyColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14

                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 5,),



                            ],
                          ),
                        ),
                      ),
                      Positioned(
                          right: 0,
                          left: 0,
                          top: -30,
                          child: Center(
                            child: Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: whiteColor,
                                  border: Border.all(
                                      color: borderColor
                                  )
                              ),
                              child: Center(child: Image.asset('assets/images/icon.png', width: 38,)),
                            ),
                          )),
                    ],
                  )


                ],
              )
            ),
          ),
        ],
      ),
    );
  }
}
