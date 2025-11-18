import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/constants/app_sizes.dart";
import "../../../core/constants/app_strings.dart";
import "../../../core/exceptions/error_handler.dart";
import "../../../core/exceptions/app_exception.dart";
import "../constants/auth_constants.dart";
import "../widgets/auth_text_field.dart";
import "../widgets/currency_selector.dart";
import "../widgets/password_strength_indicator.dart";
import "../viewmodels/auth_viewmodel.dart";

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  // ValueNotifier para optimizar el performance del indicador de fortaleza
  final _passwordNotifier = ValueNotifier<String>('');

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedCurrency = 'S/';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _passwordNotifier.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authNotifier = ref.read(authViewModelProvider.notifier);

      if (_isLoginMode) {
        await authNotifier.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        _showSuccessSnackBar('Inicio de sesión exitoso');
      } else {
        await authNotifier.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _nameController.text.trim(),
          currency: _selectedCurrency,
        );
        _showSuccessSnackBar('Cuenta creada exitosamente');
      }

      if (mounted) {
        context.go("/home");
      }
    } catch (error) {
      final errorMessage = ErrorHandler.handleError(error, StackTrace.current);
      _showErrorSnackBar(errorMessage.message);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final authNotifier = ref.read(authViewModelProvider.notifier);
      await authNotifier.signInWithGoogle();
      _showSuccessSnackBar('Inicio de sesión exitoso');

      if (mounted) {
        context.go("/home");
      }
    } on AuthException catch (e) {
      // Manejar específicamente las cancelaciones
      if (e.code == 'SIGN_IN_CANCELLED') {
        // No mostrar error para cancelaciones del usuario
        print('Login con Google cancelado por el usuario');
        return;
      }

      // Mostrar otros errores de autenticación
      _showErrorSnackBar(e.message);
    } catch (error) {
      final errorMessage = ErrorHandler.handleError(error, StackTrace.current);

      // Solo mostrar error si no es una cancelación del usuario
      if (!errorMessage.message.contains('cancelado')) {
        _showErrorSnackBar(errorMessage.message);
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu email';
    }
    if (!RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(value)) {
      return 'Por favor ingresa un email válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    try {
      ErrorHandler.validatePassword(value, isRegistration: !_isLoginMode);
      return null;
    } on ValidationException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error de validación';
    }
  }

  String? _validateConfirmPassword(String? value) {
    if (!_isLoginMode) {
      if (value == null || value.isEmpty) {
        return 'Por favor confirma tu contraseña';
      }
      if (value != _passwordController.text) {
        return 'Las contraseñas no coinciden';
      }
    }
    return null;
  }

  String? _validateName(String? value) {
    if (!_isLoginMode && (value == null || value.trim().isEmpty)) {
      return 'Por favor ingresa tu nombre';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con formas geométricas inspirado en la imagen
          _buildGeometricBackground(),

          // Contenido principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSizes.spaceM),
                child: _buildMainCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fondo simple y limpio
  Widget _buildGeometricBackground() {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
    );
  }

  Widget _buildMainCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = AuthResponsive.getCardWidth(screenWidth);
    final horizontalPadding = AuthResponsive.getHorizontalPadding(screenWidth);

    return Container(
      constraints: BoxConstraints(maxWidth: cardWidth),
      child: Card(
        elevation: AuthConstants.cardElevation,
        shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding.clamp(
              AppSizes.spaceM,
              AppSizes.spaceXL,
            ),
            vertical: AppSizes.spaceXL,
          ),
          decoration: BoxDecoration(
            // Efecto glassmorphism sutil
            color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(AppSizes.radiusXL),
            border: Border.all(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              SizedBox(height: AppSizes.spaceXL),
              _buildForm(),
              SizedBox(height: AppSizes.spaceL),
              _buildActionButton(),
              SizedBox(height: AppSizes.spaceM),
              _buildDivider(),
              SizedBox(height: AppSizes.spaceM),
              _buildGoogleSignInButton(),
              SizedBox(height: AppSizes.spaceL),
              _buildModeToggle(),
              if (_isLoginMode) ...[
                SizedBox(height: AppSizes.spaceS),
                _buildForgotPassword(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo moderno con gradiente vibrante
        Container(
          height: AuthConstants.logoSize,
          width: AuthConstants.logoSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.6, 1.0],
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusL + 2),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        SizedBox(height: AppSizes.spaceL + 4),

        // Título principal con tipografía moderna
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).colorScheme.onSurface,
              Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ],
          ).createShader(bounds),
          child: Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(
                context,
              ).colorScheme.surface, // Requerido para ShaderMask
              letterSpacing: AuthConstants.titleLetterSpacing,
              height: 1.0,
              fontSize: AppSizes.fontSizeTitleXL,
            ),
          ),
        ),

        SizedBox(height: AppSizes.spaceS),

        // Subtítulo elegante con mejor contraste
        Text(
          _isLoginMode ? AppStrings.loginSubtitle : AppStrings.registerSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            fontSize: AppSizes.fontSizeL,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLoginMode) ...[
            _buildTextField(
              controller: _nameController,
              label: AppStrings.nameLabel,
              icon: Icons.person_outline_rounded,
              validator: _validateName,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: AppSizes.spaceM),
          ],

          _buildTextField(
            controller: _emailController,
            label: AppStrings.emailLabel,
            icon: Icons.email_outlined,
            validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),

          SizedBox(height: AppSizes.spaceM),

          _buildTextField(
            controller: _passwordController,
            label: AppStrings.passwordLabel,
            icon: Icons.lock_outline_rounded,
            validator: _validatePassword,
            obscureText: _obscurePassword,
            textInputAction: _isLoginMode
                ? TextInputAction.done
                : TextInputAction.next,
            onChanged: !_isLoginMode
                ? (value) {
                    _passwordNotifier.value = value;
                    setState(() {});
                  }
                : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            onFieldSubmitted: _isLoginMode ? (_) => _submitForm() : null,
          ),

          if (!_isLoginMode) ...[
            SizedBox(height: AppSizes.spaceS),
            _buildPasswordStrengthIndicator(),
            SizedBox(height: AppSizes.spaceM),

            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirmar contraseña',
              icon: Icons.lock_outline_rounded,
              validator: _validateConfirmPassword,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.next,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),

            SizedBox(height: AppSizes.spaceM),

            _buildCurrencySelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    void Function(String)? onFieldSubmitted,
    void Function(String)? onChanged,
  }) {
    return AuthTextField(
      controller: controller,
      label: label,
      icon: icon,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      suffixIcon: suffixIcon,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return ValueListenableBuilder<String>(
      valueListenable: _passwordNotifier,
      builder: (context, password, child) {
        return PasswordStrengthIndicator(password: password);
      },
    );
  }

  Widget _buildCurrencySelector() {
    return CurrencySelector(
      selectedCurrency: _selectedCurrency,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedCurrency = newValue;
          });
        }
      },
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeightL,
      child: ElevatedButton(
        onPressed: isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 12,
          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                _isLoginMode
                    ? AppStrings.loginButton
                    : AppStrings.registerButton,
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
            thickness: 0.8,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.spaceM),
          child: Text(
            'o continúa con',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
            thickness: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : _signInWithGoogle,
        icon: Image.asset('assets/google_logo.png', height: 22, width: 22),
        label: Text(AppStrings.continueWithGoogle),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Colors.black26, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 4,
          shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(
          _isLoginMode
              ? AppStrings.noAccount + " "
              : AppStrings.hasAccount + " ",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: isLoading ? null : _toggleMode,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _isLoginMode ? AppStrings.createAccount : AppStrings.signInHere,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: isLoading
          ? null
          : () {
              _showErrorSnackBar(AppStrings.featureInDevelopment);
            },
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.tertiary,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        AppStrings.forgotPassword,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          fontSize: 13,
        ),
      ),
    );
  }

  bool get isLoading => ref.watch(authViewModelProvider).isLoading;
}
