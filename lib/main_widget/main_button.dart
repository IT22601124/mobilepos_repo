import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class MainButton extends StatefulWidget {
  String text;
  Color? backgroundColor;
  Color? textColor;
  VoidCallback? onPressed;
  bool? isLoading ;

   MainButton({super.key, required this.text, this.backgroundColor, this.textColor, this.onPressed, this.isLoading = false});

  @override
  State<MainButton> createState() => _MainButtonState();
}

class _MainButtonState extends State<MainButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),child: Center(
        child: widget.isLoading == true ?  SizedBox(
          height: 20,
          width: 20,
          child: LoadingAnimationWidget.hexagonDots(
              color: widget.textColor ?? Colors.white, size: 30),
        ) : Text(
          widget.text,
          style: TextStyle(
            color: widget.textColor ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
