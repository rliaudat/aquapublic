import 'package:agua_med/providers/billing_calculate_provider.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../Reuseable.dart';

class HouseBillingCalculate extends StatefulWidget {
  final String townId;
  final String? townName;
  final String? townUnitPrice;
  const HouseBillingCalculate({
    super.key,
    required this.townId,
    this.townName,
    this.townUnitPrice,
  });

  @override
  State<HouseBillingCalculate> createState() => _HouseBillingCalculateState();
}

class _HouseBillingCalculateState extends State<HouseBillingCalculate> {
  var townController = TextEditingController();
  var townUnitPriceController = TextEditingController();
  var consumtionBasedAmountController = TextEditingController();
  var houseBasedAmountController = TextEditingController();
  var fixedAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    townController = TextEditingController(text: widget.townName ?? '');
    context.read<BillingCalculateProvider>().setByHouseUnits(false);
    context.read<BillingCalculateProvider>().setByConsumptionAverage(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<BillingCalculateProvider>()
          .checkPendingReadings(widget.townId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillingCalculateProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          child: Container(
            padding: MediaQuery.of(context).viewInsets,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(30),
                topLeft: Radius.circular(30),
              ),
              color: greyColor,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: p),
              child: provider.isLoading
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: m * p),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!provider.billingCompleted)
                              Text(
                                'CalculateBill.calculateBills'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Icon(
                                Icons.close_outlined,
                                color: blackColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (provider.billingCompleted)
                          _buildBillingCompletedMessage()
                        else if (provider.pendingHouses.isNotEmpty)
                          _buildPendingHousesTable(provider)
                        else
                          _buildCalculationForm(provider),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalculationForm(BillingCalculateProvider provider) {
    return Column(
      children: [
        TextField(
          controller: townController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'CalculateBill.addTownName'.tr(),
            prefixIcon: Icon(Icons.home_work, color: borderColor),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: townUnitPriceController,
                readOnly: provider.byConsumptionAverage,
                onChanged: (value) {
                  if (value != '') {
                    provider.setByHouseUnits(true);
                  } else {
                    provider.setByHouseUnits(false);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'CalculateBill.unitPriceM3'.tr(),
                  prefixIcon: Icon(Icons.electric_meter, color: borderColor),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: consumtionBasedAmountController,
                readOnly: provider.byHouseUnits,
                onChanged: (value) {
                  if (value != '') {
                    provider.setByConsumptionAverage(true);
                  } else {
                    provider.setByConsumptionAverage(false);
                  }
                },
                decoration: InputDecoration(
                  hintText:
                      'CalculateBill.totalAmountToDivideByConsumptions'.tr(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: houseBasedAmountController,
                decoration: InputDecoration(
                  hintText: 'CalculateBill.totalAmountToDivideByHouse'.tr(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: fixedAmountController,
                decoration: InputDecoration(
                  hintText: 'CalculateBill.fixedAmountToBeCharged'.tr(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => provider.setButtonHover(true),
          onExit: (_) => provider.setButtonHover(false),
          child: Button(
            color: provider.buttonHover ? primaryColor : secondaryColor,
            height: 45,
            width: width(context),
            text: 'CalculateBill.calculate'.tr(),
            fontSize: 14,
            onPressed: () {
              if (townUnitPriceController.text != '' ||
                  consumtionBasedAmountController.text != '') {
                provider.calculateBillingInvoices(
                  context: context,
                  townId: widget.townId,
                  unitPrice: townUnitPriceController.text != ''
                      ? double.parse(townUnitPriceController.text)
                      : 0.0,
                  consumtionBasedAmount:
                      consumtionBasedAmountController.text != ''
                          ? double.parse(consumtionBasedAmountController.text)
                          : 1.0,
                  houseBasedAmount: houseBasedAmountController.text != ''
                      ? double.parse(houseBasedAmountController.text)
                      : 0.0,
                  fixedAmount: fixedAmountController.text != ''
                      ? double.parse(fixedAmountController.text)
                      : 0.0,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingHousesTable(BillingCalculateProvider provider) {
    return Column(
      children: [
        Text(
          '${provider.pendingHouses.length} Reading Pending',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('House Name'.tr())),
                DataColumn(label: Text('Status'.tr())),
              ],
              rows: provider.pendingHouses.map((house) {
                return DataRow(
                  cells: [
                    DataCell(Text(house['name'])),
                    const DataCell(
                      Text(
                        'pending',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBillingCompletedMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Text(
          'Billing Already Completed!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}
