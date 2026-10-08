import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../shared/widgets/widgets.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import 'auth_validator.dart';
import 'providers/auth_provider.dart';

/// Registration screen for creating a new account.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final authProvider = context.read<AuthProvider>();
    // Prevent duplicate registration requests while one is in progress.
    if (authProvider.isLoading) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // 1) Firebase Authentication: create the Firebase Auth user first.
    final uid = await authProvider.register(
      name: name,
      email: email,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (uid == null) {
      AppUtils.showSnackBar(
        context,
        authProvider.errorMessage ?? AppStrings.error,
        isError: true,
      );
      return;
    }

    // 2) Only after Auth succeeds, create the Firestore profile document.
    final profileProvider = context.read<ProfileProvider>();
    await profileProvider.createProfile(
      UserProfile(uid: uid, fullName: name, email: email),
    );

    if (!mounted) return;

    AppUtils.showSnackBar(context, AppStrings.registerSuccess);
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.registerTitle),
        automaticallyImplyLeading: !authProvider.isLoading,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.registerSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingXl),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: AppDecorations.inputDecoration(
                      labelText: AppStrings.fullNameLabel,
                      hintText: AppStrings.fullNameHint,
                      prefixIcon: Icons.person_outline,
                    ),
                    validator: AuthValidator.validateName,
                  ),
                  const SizedBox(height: AppSizes.paddingMd),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: AppDecorations.inputDecoration(
                      labelText: AppStrings.emailLabel,
                      hintText: AppStrings.emailHint,
                      prefixIcon: Icons.email_outlined,
                    ),
                    validator: AuthValidator.validateEmail,
                  ),
                  const SizedBox(height: AppSizes.paddingMd),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: AppDecorations.inputDecoration(
                      labelText: AppStrings.passwordLabel,
                      hintText: AppStrings.passwordHint,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: AuthValidator.validatePassword,
                  ),
                  const SizedBox(height: AppSizes.paddingMd),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: AppDecorations.inputDecoration(
                      labelText: AppStrings.confirmPasswordLabel,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) => AuthValidator.validateConfirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    onFieldSubmitted: (_) => _handleRegister(),
                  ),
                  const SizedBox(height: AppSizes.paddingLg),
                  PrimaryButton(
                    label: AppStrings.registerButton,
                    isLoading: authProvider.isLoading,
                    icon: Icons.person_add_alt,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: AppSizes.paddingLg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        AppStrings.haveAccount,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () {
                                Navigator.of(context)
                                    .pushReplacementNamed(AppRoutes.login);
                              },
                        child: const Text(AppStrings.loginButton),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
