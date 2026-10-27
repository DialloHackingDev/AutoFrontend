import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_theme.dart';
import '../../widgets/brand_stripe.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _normalizePhone(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('224')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+224${cleaned.substring(1)}';
    return '+224$cleaned';
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final normalizedPhone = _normalizePhone(_phoneController.text);
      final success = await Provider.of<AuthProvider>(context, listen: false).login(
        normalizedPhone,
        _passwordController.text,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Provider.of<AuthProvider>(context, listen: false).errorMessage ?? 'Identifiants invalides ou erreur serveur')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/images/autoconnect_logo.png', height: 110),
                    const SizedBox(height: 20),
                    const BrandStripe(),
                    const SizedBox(height: 28),
                    Text(
                      'Bienvenue',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Connectez-vous pour réserver ou conduire avec AutoConnect.',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 15),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        hintText: '620 00 00 00',
                        prefixIcon: Icon(Icons.phone_outlined),
                        prefixText: '+224 ',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Entrez votre numéro de téléphone' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => authProvider.isLoading ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.length < 6 ? 'Au moins 6 caractères' : null,
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: authProvider.isLoading ? null : _submit,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('Se connecter'),
                    ),
                    const SizedBox(height: 28),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Nouveau sur AutoConnect ?', style: TextStyle(color: AppColors.inkMuted)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: const Text('Créer un compte gratuitement'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
