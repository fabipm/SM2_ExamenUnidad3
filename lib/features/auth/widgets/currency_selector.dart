import 'package:flutter/material.dart';
import '../constants/auth_constants.dart';

class CurrencySelector extends StatelessWidget {
  const CurrencySelector({
    super.key,
    required this.selectedCurrency,
    required this.onChanged,
    this.label = 'Moneda preferida',
    this.hintText = 'Selecciona una moneda',
    this.validator,
    this.showFullName = true,
  });

  final String selectedCurrency;
  final ValueChanged<String?> onChanged;
  final String label;
  final String hintText;
  final String? Function(String?)? validator;
  final bool showFullName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedCurrency.isNotEmpty ? selectedCurrency : null,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          items: AuthConstants.currencies.map((currency) {
            return DropdownMenuItem<String>(
              value: currency['code'],
              child: showFullName
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currency['code']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            currency['name']!,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      currency['name']!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor selecciona una moneda';
                }
                return null;
              },
          dropdownColor: Theme.of(context).colorScheme.surface,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
          icon: const Icon(Icons.arrow_drop_down),
        ),
      ],
    );
  }
}
