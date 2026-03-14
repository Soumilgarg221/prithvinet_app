import 'package:flutter/material.dart';

import 'theme.dart';

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Form Card ─────────────────────────────────────────────────────────────────
class FormCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? headerTrailing;

  const FormCard({
    super.key,
    required this.title,
    required this.children,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, trailing: headerTrailing),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Labeled Dropdown ──────────────────────────────────────────────────────────
class LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool required;
  final String? hint;

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.required = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, required: required),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: Text(hint ?? '-- Select --'),
          decoration: const InputDecoration(),
          validator: required ? (v) => v == null ? 'Required' : null : null,
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

// ── Labeled Text Field ────────────────────────────────────────────────────────
class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final TextInputType keyboardType;
  final String? hint;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final int maxLines;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.hint,
    this.suffix,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, required: required),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
              hint: hint != null ? Text(hint!) : null, suffixIcon: suffix),
          validator: validator ??
              (required
                  ? (v) => (v == null || v.isEmpty) ? 'Required' : null
                  : null),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

// ── Parameter Input with Limit Badge ─────────────────────────────────────────
class ParameterInput extends StatelessWidget {
  final String label;
  final String unit;
  final double limit;
  final TextEditingController controller;
  final VoidCallback? onChanged;

  const ParameterInput({
    super.key,
    required this.label,
    required this.unit,
    required this.limit,
    required this.controller,
    this.onChanged,
  });

  bool get _isViolation {
    final val = double.tryParse(controller.text);
    return val != null && val > limit;
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$label ($unit)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Limit: $limit',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) {
                setState(() {});
                onChanged?.call();
              },
              decoration: InputDecoration(
                hintText: '—',
                fillColor: _isViolation
                    ? AppTheme.errorColor.withOpacity(0.05)
                    : Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _isViolation
                        ? AppTheme.errorColor
                        : AppTheme.borderColor,
                  ),
                ),
                suffixIcon: _isViolation
                    ? const Icon(Icons.warning_rounded,
                        color: AppTheme.errorColor, size: 18)
                    : null,
              ),
            ),
            if (_isViolation)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'Exceeds prescribed limit',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 11,
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

// ── Violation Badge ───────────────────────────────────────────────────────────
class ViolationBadge extends StatelessWidget {
  const ViolationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_rounded, size: 14, color: AppTheme.errorColor),
          SizedBox(width: 5),
          Text(
            'Violation Detected',
            style: TextStyle(
              color: AppTheme.errorColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── GPS Location Picker Button ────────────────────────────────────────────────
class GpsLocationTile extends StatelessWidget {
  final double? lat;
  final double? lng;
  final VoidCallback onTap;
  final bool isLoading;

  const GpsLocationTile({
    super.key,
    this.lat,
    this.lng,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: lat != null
              ? AppTheme.accentColor.withOpacity(0.07)
              : AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: lat != null
                ? AppTheme.accentColor.withOpacity(0.4)
                : AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              lat != null ? Icons.location_on : Icons.location_searching,
              color: lat != null ? AppTheme.accentColor : AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: isLoading
                  ? const Text('Getting GPS location...',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13))
                  : Text(
                      lat != null
                          ? 'GPS: ${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'
                          : 'Tap to capture GPS coordinates',
                      style: TextStyle(
                        color: lat != null
                            ? AppTheme.accentColor
                            : AppTheme.primaryColor,
                        fontSize: 13,
                        fontWeight:
                            lat != null ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
            ),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Pending Sync Banner ───────────────────────────────────────────────────────
class PendingSyncBanner extends StatelessWidget {
  const PendingSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.sync, color: AppTheme.warningColor, size: 18),
          SizedBox(width: 8),
          Text(
            'Offline — data will sync when connected',
            style: TextStyle(
              color: AppTheme.warningColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private label helper ──────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
        children: required
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppTheme.errorColor),
                )
              ]
            : [],
      ),
    );
  }
}
