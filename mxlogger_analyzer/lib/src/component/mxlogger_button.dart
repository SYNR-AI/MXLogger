import 'package:flutter/material.dart';
import 'package:mxlogger_analyzer/src/theme/mx_theme.dart';
class MXLoggerButton extends StatelessWidget {
  const MXLoggerButton({Key? key,this.size, required this.text,required this.onPressed}) : super(key: key);
  final Size? size;
  final String text;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size?.width,
      height: size?.height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateColor.resolveWith((states) => MXTheme.buttonColor)
        ),
        child: Text(text,style: TextStyle(fontSize: 16),),
      ),
    );
  }
}
