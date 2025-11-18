import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/exceptions/error_handler.dart';
import '../constants/auth_constants.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    // Usar ErrorHandler para obtener la fortaleza y requisitos
    final strength = ErrorHandler.evaluatePasswordStrength(password);
    final requirements = ErrorHandler.getPasswordRequirements(password);

    final (strengthColor, strengthText) = _getStrengthDisplay(
      context,
      strength,
    );

    return AnimatedContainer(
      duration: AuthConstants.strengthIndicatorDuration,
      padding: EdgeInsets.all(AppSizes.spaceS),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStrengthHeader(context, strengthText, strengthColor, strength),
          SizedBox(height: AppSizes.spaceXS),
          _buildProgressBar(context, strength, strengthColor),
          SizedBox(height: AppSizes.spaceS),
          _buildRequirementsList(context, requirements),
        ],
      ),
    );
  }

  Widget _buildStrengthHeader(
    BuildContext context,
    String strengthText,
    Color strengthColor,
    int strength,
  ) {
    return Row(
      children: [
        Text(
          'Fortaleza: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        Text(
          strengthText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: strengthColor,
          ),
        ),
        const Spacer(),
        Icon(
          strength >= 4 ? Icons.check_circle : Icons.info_outline,
          size: 16,
          color: strengthColor,
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    int strength,
    Color strengthColor,
  ) {
    return AnimatedContainer(
      duration: AuthConstants.strengthIndicatorDuration,
      child: LinearProgressIndicator(
        value: strength / 5,
        backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
      ),
    );
  }

  Widget _buildRequirementsList(
    BuildContext context,
    List<dynamic> requirements,
  ) {
    return Column(
      children: requirements.map((requirement) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                requirement.isMet
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 14,
                color: requirement.isMet
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.outline,
              ),
              SizedBox(width: AppSizes.spaceXS),
              Text(
                requirement.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: requirement.isMet
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.outline,
                  fontSize: AuthConstants.strengthIndicatorFontSize,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  (Color, String) _getStrengthDisplay(BuildContext context, int strength) {
    Color strengthColor;
    String strengthText;

    if (strength < 2) {
      strengthColor = Theme.of(context).colorScheme.error;
      strengthText = AuthConstants.strengthLabels[1]; // 'Débil'
    } else if (strength < 4) {
      strengthColor = Colors.orange;
      strengthText = AuthConstants.strengthLabels[2]; // 'Regular'
    } else if (strength < 5) {
      strengthColor = Colors.amber;
      strengthText = AuthConstants.strengthLabels[3]; // 'Buena'
    } else {
      strengthColor = Theme.of(context).colorScheme.secondary;
      strengthText = AuthConstants.strengthLabels[4]; // 'Fuerte'
    }

    return (strengthColor, strengthText);
  }
}
