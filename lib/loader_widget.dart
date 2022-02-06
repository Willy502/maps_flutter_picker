import 'package:flutter/material.dart';

void showLoader(BuildContext context, {required Color color}) {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Container(
                  height: 100.0,
                  width: 100.0,
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        offset: Offset(0.0, 1.0),
                        blurRadius: 6.0
                      )
                    ]
                  ),
                  child: CircularProgressIndicator(color: color),
                ),
              )
            ],
          ),
        );
      }
    );
    
  }

void hideLoader(BuildContext context) {
  Navigator.of(context).pop();
}
