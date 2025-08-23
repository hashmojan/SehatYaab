import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../colors/app_colors.dart';

class RoundButton extends StatelessWidget {
  RoundButton({
    super.key,
    this.textColor = AppColors.white,
    this.buttonColor = Colors.black12,
    this.loading = false,
    this.width = double.infinity,
    this.height = 50,
    required this.onPress,
    required this.title,
    this.borderRadius = 15,
    this.elevation = 4,
    this.icon,
  });

  final String title;
  final bool loading;
  final double width, height;
  final Color textColor, buttonColor;
  final VoidCallback onPress;
  final double borderRadius;
  final double elevation;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onPress,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              colors: [AppColors.secondaryColor,AppColors.primaryColor, ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: loading
              ? Center(
            child: CircularProgressIndicator(
              color: AppColors.white,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 24,
                  color: textColor,
                ),
              if (icon != null) const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}