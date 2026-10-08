import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../shared/widgets/widgets.dart';
import 'auth_validator.dart';
import 'providers/auth_provider.dart';

/// Forgot password screen for sending a password reset email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendPasswordResetEmail(
      _emailController.text,
    );

    if (!mounted) return;

    if (success) {
      AppUtils.showSnackBar(context, AppStrings.resetEmailSent);
      Navigator.of(context).pop();
    } else {
      AppUtils.showSnackBar(
        context,
        authProvider.errorMessage ?? AppStrings.error,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.forgotPasswordTitle),
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
                    AppStrings.forgotPasswordSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingXl),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    decoration: AppDecorations.inputDecoration(
                      labelText: AppStrings.emailLabel,
                      hintText: AppStrings.emailHint,
                      prefixIcon: Icons.email_outlined,
                    ),
                    validator: AuthValidator.validateEmail,
                    onFieldSubmitted: (_) => _handleReset(),
                  ),
                  const SizedBox(height: AppSizes.paddingLg),
                  PrimaryButton(
                    label: AppStrings.forgotPasswordButton,
                    isLoading: authProvider.isLoading,
                    icon: Icons.send,
                    onPressed: _handleReset,
                  ),
                  const SizedBox(height: AppSizes.paddingMd),
                  TextButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () {
                            Navigator.of(context)
                                .pushReplacementNamed(AppRoutes.login);
                          },
                    child: const Text(AppStrings.backToLogin),
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
