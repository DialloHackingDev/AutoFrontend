import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../core/app_theme.dart';
import '../../widgets/brand_stripe.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  UserRole _selectedRole = UserRole.PASSAGER;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
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
      final success = await Provider.of<AuthProvider>(context, listen: false).register(
        nom: _nameController.text,
        telephone: normalizedPhone,
        password: _passwordController.text,
        role: _selectedRole.toString().split('.').last,
        numeroPermis: _selectedRole == UserRole.CHAUFFEUR ? _licenseController.text : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte créé avec succès !')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Provider.of<AuthProvider>(context, listen: false).errorMessage ?? 'Erreur lors de l\'inscription. Vérifiez vos informations.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDriver = _selectedRole == UserRole.CHAUFFEUR;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/images/autoconnect_logo.png', height: 72),
                    const SizedBox(height: 16),
                    const BrandStripe(),
                    const SizedBox(height: 24),
                    const Text(
                      'Vous êtes…',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _RoleCard(
                            icon: Icons.hail,
                            title: 'Passager',
                            subtitle: 'Je voyage',
                            selected: !isDriver,
                            onTap: () => setState(() => _selectedRole = UserRole.PASSAGER),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleCard(
                            icon: Icons.directions_car_filled,
                            title: 'Chauffeur',
                            subtitle: 'Je conduis',
                            selected: isDriver,
                            onTap: () => setState(() => _selectedRole = UserRole.CHAUFFEUR),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Entrez votre nom' : null,
                    ),
                    const SizedBox(height: 16),
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
                      textInputAction: isDriver ? TextInputAction.next : TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        helperText: 'Au moins 6 caractères',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6 ? 'Au moins 6 caractères' : null,
                    ),
                    if (isDriver) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _licenseController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de permis de conduire',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) =>
                            isDriver && (value == null || value.trim().isEmpty) ? 'Requis pour les chauffeurs' : null,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Votre permis sera vérifié par un administrateur avant votre premier trajet. Vous serez notifié.',
                                style: TextStyle(fontSize: 13, color: AppColors.ink),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: authProvider.isLoading ? null : _submit,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(isDriver ? 'Créer mon compte chauffeur' : 'Créer mon compte'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('J’ai déjà un compte — Se connecter'),
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

/// Carte de choix du type de compte : grande zone tactile, icône explicite.
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 34, color: selected ? AppColors.primary : AppColors.inkMuted),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
