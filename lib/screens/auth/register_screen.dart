import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_add, size: 80, color: Color(0xFF1E3A8A)),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value!.isEmpty ? 'Entrez votre nom' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: 'ex: +224620000000',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Entrez votre numéro' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                obscureText: true,
                validator: (value) => value!.length < 6 ? 'Minimum 6 caractères' : null,
              ),
              const SizedBox(height: 24),
              const Text('Type de compte :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<UserRole>(
                      title: const Text('Passager'),
                      value: UserRole.PASSAGER,
                      groupValue: _selectedRole,
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    const Divider(height: 1),
                    RadioListTile<UserRole>(
                      title: const Text('Chauffeur'),
                      value: UserRole.CHAUFFEUR,
                      groupValue: _selectedRole,
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                  ],
                ),
              ),
              if (_selectedRole == UserRole.CHAUFFEUR) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _licenseController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de permis de conduire',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => _selectedRole == UserRole.CHAUFFEUR && value!.isEmpty ? 'Requis pour les chauffeurs' : null,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: authProvider.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: authProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('S\'inscrire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Déjà un compte ? Connectez-vous'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
