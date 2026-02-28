import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
class AppSnackBar{
  static showSnackBar(BuildContext context, String title, String message, dynamic contentType){
    final snackBar = SnackBar(
                  elevation: 0,
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: title,
                    message: message,
                    contentType: contentType,
                    messageTextStyle: message.length > 60 
                        ? const TextStyle(fontSize: 12, color: Colors.white)
                        : const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
  }
}