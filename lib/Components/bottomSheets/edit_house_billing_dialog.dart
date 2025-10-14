import 'package:agua_med/Components/Reuseable.dart';
import 'package:agua_med/providers/billing_calculate_provider.dart';
import 'package:agua_med/theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditHouseBillingDialog extends StatefulWidget {
  final Map<String, dynamic> invoice;
  const EditHouseBillingDialog({super.key, required this.invoice});

  @override
  State<EditHouseBillingDialog> createState() => _EditHouseBillingDialogState();
}

class _EditHouseBillingDialogState extends State<EditHouseBillingDialog> {
  late TextEditingController consumtionBasedAmountController;
  late TextEditingController houseBasedAmountController;
  late TextEditingController fixedAmountController;
  late TextEditingController unitPriceController;
  bool _byHouseUnits = false;
  bool _byConsumptionAverage = false;

  @override
  void initState() {
    super.initState();
    consumtionBasedAmountController = TextEditingController(
      text: widget.invoice['consumtionBasedAmount'].toString(),
    );
    houseBasedAmountController = TextEditingController(
      text: widget.invoice['houseBasedAmount'].toString(),
    );
    fixedAmountController = TextEditingController(
      text: widget.invoice['fixedAmount'].toString(),
    );
    unitPriceController = TextEditingController(
      text: widget.invoice['unitPrice'].toString(),
    );

    // Set initial mode based on invoice
    _byHouseUnits = widget.invoice['basedOn'] == 'Units';
    _byConsumptionAverage = widget.invoice['basedOn'] == 'Consumptions';
  }

  @override
  Widget build(BuildContext context) {
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
          child: Consumer<BillingCalculateProvider>(
              builder: (context, provider, child) {
            return provider.isLoading
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
                          const Text(
                            'Edit Bill Calculation',
                            style: TextStyle(
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
                      TextField(
                        controller: TextEditingController(
                            text:
                                widget.invoice['houseName'] ?? 'Unknown House'),
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'House Name',
                          prefixIcon: Icon(Icons.home, color: borderColor),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: unitPriceController,
                              readOnly: _byConsumptionAverage,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  setState(() {
                                    _byHouseUnits = true;
                                    _byConsumptionAverage = false;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'CalculateBill.unitPriceM3'.tr(),
                                prefixIcon: Icon(Icons.electric_meter,
                                    color: borderColor),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: consumtionBasedAmountController,
                              readOnly: _byHouseUnits,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  setState(() {
                                    _byConsumptionAverage = true;
                                    _byHouseUnits = false;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                hintText:
                                    'CalculateBill.totalAmountToDivideByConsumptions'
                                        .tr(),
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
                                hintText:
                                    'CalculateBill.totalAmountToDivideByHouse'
                                        .tr(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: fixedAmountController,
                              decoration: InputDecoration(
                                hintText:
                                    'CalculateBill.fixedAmountToBeCharged'.tr(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Button(
                          color: secondaryColor,
                          height: 45,
                          width: width(context),
                          text: 'Save Changes',
                          fontSize: 14,
                          onPressed: () async {
                            await provider.updateHouseBilling(
                                context: context,
                                invoiceId: widget.invoice['id'],
                                consumtionBasedAmount: double.parse(
                                    consumtionBasedAmountController.text),
                                houseBasedAmount: double.parse(
                                    houseBasedAmountController.text),
                                fixedAmount:
                                    double.parse(fixedAmountController.text),
                                unitPrice:
                                    double.parse(unitPriceController.text),
                                basedOn:
                                    _byHouseUnits ? 'Units' : 'Consumptions',
                                consumptions: widget.invoice['reading']
                                    ['units']);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
          }),
        ),
      ),
    );
  }

  @override
  void dispose() {
    consumtionBasedAmountController.dispose();
    houseBasedAmountController.dispose();
    fixedAmountController.dispose();
    unitPriceController.dispose();
    super.dispose();
  }
}
