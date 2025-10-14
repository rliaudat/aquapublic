import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/_helpers/helper.dart';
import 'package:agua_med/loading.dart';
import 'package:agua_med/models/house.dart';
import 'package:agua_med/providers/meter_reading_provider.dart';
import 'package:agua_med/theme.dart';
import 'package:agua_med/views/Inspector/meter_scan_camera_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';

class MeterReadingScreen extends StatefulWidget {
  final House data;
  final bool hasReadings;
  const MeterReadingScreen(
      {super.key, required this.data, required this.hasReadings});

  @override
  State<MeterReadingScreen> createState() => _MeterReadingScreenState();
}

class _MeterReadingScreenState extends State<MeterReadingScreen> {
  late House data;

  @override
  void initState() {
    data = widget.data;
    context.read<MeterReadingProvider>().setHasReading(widget.hasReadings);
    super.initState();
  }

  checkLastReading() async {
    if (data.lastReading != null) {
      Timestamp timestamp = data.lastReading!['date'];
      DateTime lastReading = timestamp.toDate();
      DateTime now = DateTime.now();
      bool isInCurrentMonth =
          lastReading.year == now.year && lastReading.month == now.month;
      if (isInCurrentMonth) {
        showToast(
          context,
          msg:
              "Reading already taken this month. Contact to the Town Manager or Admin",
          duration: 5,
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeterScanCameraScreen(
              data: data,
              isOCREnabled: context.read<MeterReadingProvider>().isOCREnabled,
            ),
          ),
        );
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MeterScanCameraScreen(
            data: data,
            isOCREnabled: context.read<MeterReadingProvider>().isOCREnabled,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<MeterReadingProvider>().reset();
        }
      },
      child: GestureDetector(
        onTap: () => unFocus(context),
        child: Scaffold(
          appBar: isTablet
              ? AppBar(
                  centerTitle: true,
                  // automaticallyImplyLeading: false,
                  title: Text('MeterReadingScreen.meterReading'.tr()),
                  backgroundColor: primaryColor,
                )
              : CustomAppBar(
                  title: 'MeterReadingScreen.meterReading'.tr(),
                  showButton: true),
          body: Consumer<MeterReadingProvider>(
            builder: (context, provider, child) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: p),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'MeterReadingScreen.houseId'
                                          .tr(args: [data.name]),
                                      style: TextStyle(
                                        color: blackColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'MeterReadingScreen.enableAI'.tr(),
                                          style: TextStyle(
                                            color: blackColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Switch(
                                          value: context
                                              .read<MeterReadingProvider>()
                                              .isOCREnabled,
                                          activeColor: primaryColor,
                                          inactiveTrackColor: darkGreyColor,
                                          onChanged: (value) {
                                            context
                                                .read<MeterReadingProvider>()
                                                .setIsOCREnabled(value);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () {
                                    checkLastReading();
                                  },
                                  child: Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      // ignore: deprecated_member_use
                                      color: borderColor.withOpacity(0.4),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Spacer(),
                                        const Spacer(),
                                        Container(
                                          height: 60,
                                          width: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: primaryColor,
                                          ),
                                          child: Icon(
                                            Icons.camera_alt_outlined,
                                            color: whiteColor,
                                            size: 30,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'MeterReadingScreen.takeMeterReading'
                                              .tr(),
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const Spacer(),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Container(
                                  padding: EdgeInsets.all(p),
                                  decoration: BoxDecoration(
                                    color: whiteColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: data.lastReading == null
                                      ? Center(
                                          child: Text(
                                            'MeterReadingScreen.noPreviousReadings'
                                                .tr(),
                                            style: TextStyle(
                                              color: redColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildFieldRow(
                                              icon: Icons.check_circle_outline,
                                              label:
                                                  'MeterReadingScreen.readingStatus'
                                                      .tr(),
                                              value: context
                                                      .read<
                                                          MeterReadingProvider>()
                                                      .hasReadings
                                                  ? 'MeterReadingScreen.completed'
                                                      .tr()
                                                  : 'MeterReadingScreen.pending'
                                                      .tr(),
                                              color: context
                                                      .read<
                                                          MeterReadingProvider>()
                                                      .hasReadings
                                                  ? greenColor
                                                  : redColor,
                                            ),
                                            const SizedBox(height: 12),
                                            _buildFieldRow(
                                              icon: Icons.calendar_today,
                                              label: 'MeterReadingScreen.date'
                                                  .tr(),
                                              value: dateFromTimestamp(
                                                  data.lastReading!['date']),
                                            ),
                                            const SizedBox(height: 12),
                                            _buildFieldRow(
                                              icon: Icons.speed,
                                              label:
                                                  'MeterReadingScreen.reading'
                                                      .tr(),
                                              value: data
                                                  .lastReading!['reading']
                                                  .toString(),
                                            ),
                                            const SizedBox(height: 12),
                                            _buildFieldRow(
                                              icon: Icons.bolt,
                                              label:
                                                  'MeterReadingScreen.calcConsumption'
                                                      .tr(),
                                              value: data.lastReading!['units']
                                                  .toString(),
                                            ),
                                            const SizedBox(height: 12),
                                            _buildFieldRow(
                                              icon: Icons.history_toggle_off,
                                              label:
                                                  'MeterReadingScreen.lastConsumption'
                                                      .tr(),
                                              value: data
                                                  .lastReading!['previousUnits']
                                                  .toString(),
                                            ),
                                            const SizedBox(height: 12),
                                            _buildFieldRow(
                                              icon:
                                                  Icons.calendar_today_outlined,
                                              label:
                                                  'MeterReadingScreen.consumptionDays'
                                                      .tr(),
                                              value: data.lastReading![
                                                      'consumptionDays']
                                                  .toString(),
                                            ),
                                            const SizedBox(height: 8),
                                            const Divider(thickness: 1),
                                            _buildFieldRow(
                                              icon: Icons.attach_money,
                                              label: 'MeterReadingScreen.amount'
                                                  .tr(),
                                              value:
                                                  '\$${data.lastReading!['amount']}',
                                            ),
                                            const Divider(thickness: 1),
                                            const SizedBox(height: 10),
                                            Text(
                                              'MeterReadingScreen.lastConsumptionImage'
                                                  .tr(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            CachedNetworkImage(
                                              imageUrl: data.lastReading![
                                                  'meterImageURL'],
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required String label,
    String? value,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.blue,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value ?? 'N/A',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
