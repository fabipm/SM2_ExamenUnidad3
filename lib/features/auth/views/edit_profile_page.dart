import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/exceptions/error_handler.dart';
import '../models/edit_profile_model.dart';
import '../models/user_profile_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/edit_profile_viewmodel.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _edadController = TextEditingController();
  final _ocupacionController = TextEditingController();
  final _ingresoController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _edadController.dispose();
    _ocupacionController.dispose();
    _ingresoController.dispose();
    super.dispose();
  }

  void _initializeForm(UserProfileModel? userProfile) {
    if (!_isInitialized && userProfile != null) {
      _usernameController.text = userProfile.username;
      _edadController.text = userProfile.edad?.toString() ?? '';
      _ocupacionController.text = userProfile.ocupacion ?? '';
      _ingresoController.text =
          userProfile.ingresoMensualAprox?.toStringAsFixed(2) ?? '';

      // Inicializar el provider con los datos actuales
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(editProfileProvider.notifier)
            .initializeFromUserProfile(userProfile);
      });

      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final editProfileState = ref.watch(editProfileProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);

    // Escuchar cambios en el estado de edición de perfil
    ref.listen(editProfileProvider, (previous, next) {
      if (next.status == EditProfileStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.white),
                SizedBox(width: AppSizes.spaceXS),
                Flexible(child: Text('Perfil actualizado exitosamente')),
              ],
            ),
            backgroundColor: AppColors.greenJade,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            action: SnackBarAction(
              label: 'OK',
              textColor: AppColors.white,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
        context.pop(); // Regresar a la página anterior
      } else if (next.status == EditProfileStatus.error) {
        // ✅ ERROR HANDLING CENTRALIZADO - Manejo robusto de errores
        String errorMessage;

        if (next.errorMessage != null) {
          // Si ya tenemos un mensaje de error, verificar si viene del ErrorHandler
          errorMessage = next.errorMessage!;
        } else {
          // Si no hay mensaje, usar ErrorHandler para generar uno consistente
          final handledException = ErrorHandler.handleError(
            Exception('Error desconocido en edición de perfil'),
            StackTrace.current,
          );
          errorMessage = handledException.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: AppColors.white),
                SizedBox(width: AppSizes.spaceXS),
                Flexible(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: AppColors.redCoral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: AppColors.white,
              onPressed: () => _handleSave(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          AppStrings.editProfile,
          style: TextStyle(
            color: AppColors.white,
            fontSize: AppSizes.fontSizeTitleM,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: AppSizes.elevationLow,
        backgroundColor: AppColors.blueClassic,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => _handleCancel(context),
        ),
      ),
      body: userProfileAsync.when(
        data: (userProfile) {
          _initializeForm(userProfile);

          return _buildForm(context, editProfileState, userProfile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          // ✅ ERROR HANDLING CENTRALIZADO - Usar ErrorHandler con AppException
          AppException handledException;

          if (error is AppException) {
            // Si ya es una AppException, mantenerla para preservar el tipo específico
            handledException = error;
          } else {
            // Si no, procesarla con ErrorHandler para convertirla a AppException
            handledException = ErrorHandler.handleError(error, stackTrace);
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.redCoral),
                SizedBox(height: AppSizes.spaceM),
                Text(
                  handledException.message, // ✅ Usar mensaje del ErrorHandler
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.spaceXS),
                Text(
                  AppStrings.errorTryAgain,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: AppSizes.spaceXL),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(currentUserProfileProvider),
                  icon: Icon(Icons.refresh),
                  label: Text(AppStrings.retry),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    editProfileState,
    UserProfileModel? userProfile,
  ) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.spaceXL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar del usuario
              _buildProfileAvatar(context, userProfile),

              SizedBox(height: AppSizes.spaceXXL),

              // Campo de nombre de usuario
              _buildUsernameField(context, editProfileState),

              SizedBox(height: AppSizes.spaceL),

              // Campo de edad
              _buildEdadField(context),

              SizedBox(height: AppSizes.spaceL),

              // Campo de ocupación
              _buildOcupacionField(context),

              SizedBox(height: AppSizes.spaceL),

              // Campo de ingreso mensual
              _buildIngresoMensualField(context),

              SizedBox(height: AppSizes.spaceL),

              // Información del email (solo lectura)
              _buildEmailField(context, userProfile),

              SizedBox(height: AppSizes.spaceXXL),

              // 🆕 SECCIÓN DE DATOS DEMOGRÁFICOS
              _buildDemographicSection(context),

              SizedBox(height: AppSizes.spaceXXL),

              // Mostrar errores de validación
              if (editProfileState.validationErrors.isNotEmpty)
                _buildValidationErrors(
                  context,
                  editProfileState.validationErrors,
                ),

              // Mostrar error general
              if (editProfileState.errorMessage != null)
                _buildErrorMessage(context, editProfileState.errorMessage!),

              // Botón de guardar
              _buildSaveButton(context, editProfileState),

              SizedBox(height: AppSizes.spaceM),

              // Botón de cancelar
              _buildCancelButton(context),

              // Espaciado adicional al final
              SizedBox(height: AppSizes.spaceXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(
    BuildContext context,
    UserProfileModel? userProfile,
  ) {
    final currentUser = ref.watch(currentUserProvider);
    final editState = ref.watch(editProfileProvider);
    final isLoading = editState.status == EditProfileStatus.loading;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: AppSizes.fabCenterSize,
            backgroundColor: AppColors.blueClassic.withOpacity(0.1),
            child: isLoading
                ? CircularProgressIndicator(
                    color: AppColors.blueClassic,
                    strokeWidth: 3,
                  )
                : currentUser?.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      currentUser!.photoUrl!,
                      width: AppSizes.balanceCardHeight,
                      height: AppSizes.balanceCardHeight,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: AppSizes.fabCenterSize,
                          color: AppColors.blueClassic,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: AppSizes.fabCenterSize,
                    color: AppColors.blueClassic,
                  ),
          ),
          if (!isLoading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: IconButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (mounted) {
                            _showPhotoOptions(context);
                          }
                        },
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUsernameField(BuildContext context, editProfileState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nombre de usuario',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            hintText: 'Ingresa tu nombre de usuario',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          validator: FormValidators.validateUsername,
          onChanged: (value) {
            ref.read(editProfileProvider.notifier).updateUsername(value);
          },
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildEdadField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edad',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _edadController,
          decoration: InputDecoration(
            hintText: 'Ingresa tu edad (opcional)',
            prefixIcon: const Icon(Icons.cake_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          validator: (value) {
            // CAMPO OPCIONAL - no requerido
            if (value == null || value.trim().isEmpty) {
              return null; // Permitir valores vacíos
            }
            final edad = int.tryParse(value);
            if (edad == null) {
              return 'Ingresa una edad válida';
            }
            if (edad <= 0 || edad > 120) {
              return 'La edad debe estar entre 1 y 120 años';
            }
            return null;
          },
          onChanged: (value) {
            ref.read(editProfileProvider.notifier).updateEdadFromString(value);
          },
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildOcupacionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ocupación',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ocupacionController,
          decoration: InputDecoration(
            hintText: 'Ej: Estudiante, Ingeniero, etc. (opcional)',
            prefixIcon: const Icon(Icons.work_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(50),
            FilteringTextInputFormatter.allow(
              RegExp(r'[a-zA-ZñÑáéíóúÁÉÍÓÚüÜ\s]'),
            ),
          ],
          validator: (value) {
            // CAMPO OPCIONAL - no requerido
            if (value == null || value.trim().isEmpty) {
              return null; // Permitir valores vacíos
            }
            if (value.trim().length < 2) {
              return 'La ocupación debe tener al menos 2 caracteres';
            }
            if (value.trim().length > 50) {
              return 'La ocupación no puede tener más de 50 caracteres';
            }
            return null;
          },
          onChanged: (value) {
            ref
                .read(editProfileProvider.notifier)
                .updateOcupacion(value.trim());
          },
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildIngresoMensualField(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final userCurrency = userProfileAsync.value?.currency ?? 'S/';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingreso Mensual Aproximado',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ingresoController,
          decoration: InputDecoration(
            hintText: 'Ej: 2500.00 (opcional)',
            prefixIcon: const Icon(Icons.monetization_on_outlined),
            suffixText: userCurrency,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            LengthLimitingTextInputFormatter(
              12,
            ), // Para números grandes pero razonables
          ],
          validator: (value) {
            // CAMPO OPCIONAL - no requerido
            if (value == null || value.trim().isEmpty) {
              return null; // Permitir valores vacíos
            }
            final ingreso = double.tryParse(value.replaceAll(',', ''));
            if (ingreso == null) {
              return 'Ingresa un monto válido';
            }
            if (ingreso < 0) {
              return 'El ingreso no puede ser negativo';
            }
            if (ingreso > 999999999) {
              return 'El monto es demasiado alto';
            }
            return null;
          },
          onChanged: (value) {
            ref
                .read(editProfileProvider.notifier)
                .updateIngresoMensualAproxFromString(value);
          },
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 4),
        Text(
          'Monto aproximado en $userCurrency (opcional)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(BuildContext context, UserProfileModel? userProfile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correo electrónico',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: userProfile?.email ?? '',
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          enabled: false,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'El correo electrónico no se puede modificar',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildValidationErrors(BuildContext context, List<String> errors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Errores de validación:',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.map(
            (error) => Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 4),
              child: Text(
                '• $error',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 SECCIÓN COMPLETA DE DATOS DEMOGRÁFICOS
  Widget _buildDemographicSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Row(
          children: [
            Icon(Icons.people_outline, color: AppColors.blueClassic, size: 24),
            SizedBox(width: AppSizes.spaceXS),
            Text(
              'Información Demográfica',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.blueClassic,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSizes.spaceXS),
        Text(
          'Ayúdanos a personalizar tu análisis financiero con IA',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.greyDark),
        ),
        SizedBox(height: AppSizes.spaceL),

        // Estado Civil
        _buildEstadoCivilField(context),
        SizedBox(height: AppSizes.spaceL),

        // Tiene Hijos
        _buildTieneHijosField(context),
        SizedBox(height: AppSizes.spaceL),

        // Número de Dependientes
        _buildNumeroDependientesField(context),
        SizedBox(height: AppSizes.spaceL),

        // Nivel de Educación
        _buildNivelEducacionField(context),
        SizedBox(height: AppSizes.spaceL),

        // Objetivos Financieros
        _buildObjetivosFinancierosField(context),
      ],
    );
  }

  Widget _buildEstadoCivilField(BuildContext context) {
    final editState = ref.watch(editProfileProvider);
    final estadoCivilActual = editState.profile.estadoCivil;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado Civil',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSizes.spaceXS),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                'Soltero/a',
                'Casado/a',
                'Divorciado/a',
                'Viudo/a',
                'Unión Libre',
              ].map((estado) {
                final isSelected = estadoCivilActual == estado;
                return ChoiceChip(
                  label: Text(estado),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref
                        .read(editProfileProvider.notifier)
                        .updateEstadoCivil(selected ? estado : null);
                  },
                  selectedColor: AppColors.blueClassic.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.blueClassic
                        : AppColors.greyDark,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildTieneHijosField(BuildContext context) {
    final editState = ref.watch(editProfileProvider);
    final tieneHijos = editState.profile.tieneHijos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Tienes hijos?',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSizes.spaceXS),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check,
                      size: 18,
                      color: tieneHijos == true
                          ? AppColors.greenJade
                          : AppColors.greyDark,
                    ),
                    SizedBox(width: 4),
                    Text('Sí'),
                  ],
                ),
                selected: tieneHijos == true,
                onSelected: (selected) {
                  ref.read(editProfileProvider.notifier).updateTieneHijos(true);
                },
                selectedColor: AppColors.greenJade.withOpacity(0.2),
              ),
            ),
            SizedBox(width: AppSizes.spaceM),
            Expanded(
              child: ChoiceChip(
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.close,
                      size: 18,
                      color: tieneHijos == false
                          ? AppColors.redCoral
                          : AppColors.greyDark,
                    ),
                    SizedBox(width: 4),
                    Text('No'),
                  ],
                ),
                selected: tieneHijos == false,
                onSelected: (selected) {
                  ref
                      .read(editProfileProvider.notifier)
                      .updateTieneHijos(false);
                },
                selectedColor: AppColors.greyLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumeroDependientesField(BuildContext context) {
    final editState = ref.watch(editProfileProvider);
    final numeroDependientes = editState.profile.numeroDependientes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Número de Dependientes Económicos',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSizes.spaceXS),
        Text(
          'Personas que dependen económicamente de ti (hijos, padres, etc.)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.greyDark),
        ),
        SizedBox(height: AppSizes.spaceXS),
        TextFormField(
          initialValue: numeroDependientes?.toString() ?? '',
          decoration: InputDecoration(
            hintText: '0',
            prefixIcon: Icon(Icons.family_restroom_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          onChanged: (value) {
            ref
                .read(editProfileProvider.notifier)
                .updateNumeroDependientesFromString(value);
          },
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildNivelEducacionField(BuildContext context) {
    final editState = ref.watch(editProfileProvider);
    final nivelEducacion = editState.profile.nivelEducacion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nivel de Educación',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSizes.spaceXS),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                'Primaria',
                'Secundaria',
                'Técnico',
                'Universitario',
                'Posgrado',
              ].map((nivel) {
                final isSelected = nivelEducacion == nivel;
                return ChoiceChip(
                  label: Text(nivel),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref
                        .read(editProfileProvider.notifier)
                        .updateNivelEducacion(selected ? nivel : null);
                  },
                  selectedColor: AppColors.blueClassic.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.blueClassic
                        : AppColors.greyDark,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildObjetivosFinancierosField(BuildContext context) {
    final editState = ref.watch(editProfileProvider);
    final objetivos = editState.profile.objetivosFinancieros ?? [];

    final objetivosDisponibles = {
      'Ahorro': Icons.savings_outlined,
      'Inversión': Icons.trending_up,
      'Pagar Deudas': Icons.money_off,
      'Comprar Vivienda': Icons.home_outlined,
      'Educación': Icons.school_outlined,
      'Retiro': Icons.elderly_outlined,
      'Viajes': Icons.flight_outlined,
      'Emergencias': Icons.health_and_safety_outlined,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objetivos Financieros',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSizes.spaceXS),
        Text(
          'Selecciona todos los que apliquen',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.greyDark),
        ),
        SizedBox(height: AppSizes.spaceXS),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: objetivosDisponibles.entries.map((entry) {
            final objetivo = entry.key;
            final icon = entry.value;
            final isSelected = objetivos.contains(objetivo);

            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? AppColors.blueClassic
                        : AppColors.greyDark,
                  ),
                  SizedBox(width: 4),
                  Text(objetivo),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                ref
                    .read(editProfileProvider.notifier)
                    .toggleObjetivoFinanciero(objetivo);
              },
              selectedColor: AppColors.blueClassic.withOpacity(0.2),
              checkmarkColor: AppColors.blueClassic,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.blueClassic : AppColors.greyDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context, String errorMessage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, editProfileState) {
    final isLoading = editProfileState.status == EditProfileStatus.loading;

    return ElevatedButton(
      onPressed: isLoading ? null : _handleSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blueClassic,
        foregroundColor: AppColors.white,
        padding: EdgeInsets.symmetric(vertical: AppSizes.spaceM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        elevation: AppSizes.elevationMedium,
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            )
          : Text(
              'Guardar Cambios',
              style: TextStyle(
                fontSize: AppSizes.fontSizeM,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _handleCancel(context),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: AppSizes.spaceM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        side: BorderSide(color: AppColors.greyDark),
      ),
      child: Text(
        'Cancelar',
        style: TextStyle(
          fontSize: AppSizes.fontSizeM,
          fontWeight: FontWeight.w600,
          color: AppColors.greyDark,
        ),
      ),
    );
  }

  void _handleCancel(BuildContext context) async {
    final userProfileAsync = ref.read(currentUserProfileProvider);

    if (userProfileAsync.hasValue) {
      final hasChanges = ref
          .read(editProfileProvider.notifier)
          .hasChanges(userProfileAsync.value);

      if (hasChanges) {
        final shouldDiscard = await _showDiscardChangesDialog(context);
        if (shouldDiscard && mounted) {
          context.pop();
        }
      } else {
        context.pop();
      }
    } else {
      // Si está cargando o hay error, simplemente salir
      context.pop();
    }
  }

  Future<bool> _showDiscardChangesDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_outlined, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Cambios sin guardar'),
              ],
            ),
            content: const Text(
              '¿Estás seguro de que deseas descartar los cambios realizados?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continuar editando'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Descartar cambios'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleSave() async {
    // Limpiar errores previos
    ref.read(editProfileProvider.notifier).clearErrors();

    if (_formKey.currentState?.validate() ?? false) {
      // Mostrar indicador de carga
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        final success = await ref
            .read(editProfileProvider.notifier)
            .saveProfile();

        if (success && mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Flexible(child: Text('Perfil actualizado exitosamente')),
                ],
              ),
              backgroundColor: AppColors.greenJade,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
            ),
          );

          // Volver a la página anterior
          if (mounted) context.pop();
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: AppColors.white),
                  const SizedBox(width: 8),
                  Flexible(child: Text('Error al guardar: ${e.toString()}')),
                ],
              ),
              backgroundColor: AppColors.redCoral,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              action: SnackBarAction(
                label: 'Reintentar',
                textColor: AppColors.white,
                onPressed: () => _handleSave(),
              ),
            ),
          );
        }
      }
    } else {
      // Si hay errores de validación, mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_outlined, color: Colors.white),
              SizedBox(width: 8),
              Flexible(
                child: Text('Por favor corrige los errores en el formulario'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPhotoOptions(BuildContext context) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cambiar foto de perfil',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Tomar foto'),
                    onTap: () {
                      Navigator.pop(context);
                      _takePicture();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Elegir de galería'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromGallery();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Eliminar foto'),
                    onTap: () {
                      Navigator.pop(context);
                      _deletePhoto();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _takePicture() async {
    try {
      await ref.read(editProfileProvider.notifier).pickImageFromCamera();
      if (mounted) {
        _handleImageResult();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _pickFromGallery() async {
    try {
      await ref.read(editProfileProvider.notifier).pickImageFromGallery();
      if (mounted) {
        _handleImageResult();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _deletePhoto() async {
    try {
      await ref.read(editProfileProvider.notifier).deleteProfilePhoto();
      if (mounted) {
        _handleImageResult();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleImageResult() {
    if (!mounted) return;

    final editState = ref.read(editProfileProvider);

    if (editState.status == EditProfileStatus.error &&
        editState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editState.errorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (editState.status == EditProfileStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Foto actualizada correctamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
