import 'package:agua_med/theme.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

FToast fToast = FToast();

showToast(BuildContext context, {int duration = 3, String msg = ''}) {
  fToast.init(context);
  fToast.showToast(
    toastDuration: Duration(seconds: duration),
    gravity: ToastGravity.BOTTOM,
    child: Container(
      padding: const EdgeInsets.only(left: 13, top: 20, right: 5, bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              msg,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}

showLoader(BuildContext dialogContext, message) {
  AlertDialog alert = AlertDialog(
    contentPadding: const EdgeInsets.all(15),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)),
    ),
    content: Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(1),
          child: CircularProgressIndicator(
            backgroundColor: blueColor,
            color: primaryColor,
          ),
        ),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(7),
          child: Text(
            message,
            maxLines: 5,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        )),
      ],
    ),
  );
  showDialog(
    barrierDismissible: false,
    useRootNavigator: false,
    context: dialogContext,
    builder: (BuildContext dialogContext) {
      return alert;
    },
  );
}

unFocus(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
}

pop(BuildContext context) {
  Navigator.pop(context);
}