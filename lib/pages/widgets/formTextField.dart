import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/providers/login_page_provider.dart';

class FormTextField extends StatefulWidget {
  final TextEditingController textEditingController;
  final String labelText;
  final FormFieldValidator<String>? validator;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool? enabled;
  final TextInputType? keyboardType;
  final bool autofocus;
  final bool obscureText;

  const FormTextField({
    super.key,
    required this.textEditingController,
    required this.labelText,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.keyboardType,
    this.autofocus = false,
    this.obscureText = false,
  });

  @override
  State<FormTextField> createState() => _FormTextFieldState();
}

class _FormTextFieldState extends State<FormTextField> {
  bool _obscureText = true;
  static const _borderRadius = BorderRadius.all(Radius.circular(10.0));
  static const _contentPadding = EdgeInsets.only(top: 20, left: 15, right: 15);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPassword = widget.labelText == LoginPageProvider.password;

    return Padding(
      padding: _contentPadding,
      child: TextFormField(
        controller: widget.textEditingController,
        validator: widget.validator,
        obscureText: isPassword ? _obscureText : widget.obscureText,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        autofocus: widget.autofocus,
        enableInteractiveSelection: true,
        cursorColor: isDark ? AppColors.darkWhiteText : AppColors.brandPrimary,
        contextMenuBuilder: (context, editableTextState) {
          return AdaptiveTextSelectionToolbar.editableText(
            editableTextState: editableTextState,
          );
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: _borderRadius,
            borderSide: BorderSide(
              color: isDark ? AppColors.darkWhiteText : AppColors.brandPrimary,
              width: 2.0,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: _borderRadius,
            borderSide: BorderSide(
              color: isDark ? AppColors.darkWhiteText : AppColors.lightDarkText,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: _borderRadius,
            borderSide: BorderSide(
              color: isDark ? AppColors.greyColor.withOpacity(0.5) : AppColors.greyColor.withOpacity(0.3),
            ),
          ),
          labelText: widget.labelText,
          labelStyle: TextStyle(
            color: isDark ? AppColors.darkWhiteText.withOpacity(0.7) : AppColors.lightDarkText.withOpacity(0.7),
          ),
          prefixIcon:
              widget.prefixIcon != null ? Icon(widget.prefixIcon, size: 22) : null,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : (widget.suffixIcon != null
                  ? Icon(widget.suffixIcon, size: 22)
                  : null),
        ),
      ),
    );
  }
}
