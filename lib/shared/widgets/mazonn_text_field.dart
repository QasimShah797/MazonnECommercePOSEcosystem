import 'package:flutter/material.dart';

import '../../core/theme/mazonn_colors.dart';

class MazonnTextField extends StatelessWidget {
  const MazonnTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.onToggleObscure,
    this.maxLines = 1,
    this.textInputAction,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final VoidCallback? onToggleObscure;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: MazonnColors.stone),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          textInputAction: textInputAction,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: MazonnColors.stone,
                    ),
                  )
                : suffix,
          ),
        ),
      ],
    );
  }
}
