import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// Full-screen auth page shown when logged out. Email/password is primary,
/// with a register toggle and a dev-login escape hatch.
class LoginPage extends StatefulWidget {
  final AppState state;
  const LoginPage({super.key, required this.state});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _obscure = true;

  AppState get _state => widget.state;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_state.busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    final password = _password.text;
    if (_register) {
      _state.register(_name.text.trim(), email, password);
    } else {
      _state.loginWithEmail(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _state,
          builder: (context, _) {
            final busy = _state.busy;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
              children: [
                _hero(),
                const SizedBox(height: 18),
                if (_state.error != null) ErrorCard(message: _state.error!),
                ShadowCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Kicker(_register ? 'Create account' : 'Welcome back'),
                        const SizedBox(height: 8),
                        Text(
                          _register
                              ? 'Sign up to save reels'
                              : 'Log in to save reels',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_register) ...[
                          _field(
                            controller: _name,
                            hint: 'Your name',
                            keyboardType: TextInputType.name,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 10),
                        ],
                        _field(
                          controller: _email,
                          hint: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Email is required';
                            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(value)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        _field(
                          controller: _password,
                          hint: 'Password',
                          obscure: _obscure,
                          keyboardType: TextInputType.visiblePassword,
                          onSubmitted: (_) => _submit(),
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: ink,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) {
                            if ((v ?? '').isEmpty) return 'Password is required';
                            if (_register && (v ?? '').length < 8) {
                              return 'At least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: busy ? null : _submit,
                            icon: busy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _register ? Icons.person_add : Icons.login,
                                  ),
                            label: Text(_register ? 'Create account' : 'Log in'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: busy
                                ? null
                                : () {
                                    _state.clearError();
                                    setState(() => _register = !_register);
                                  },
                            child: Text(
                              _register
                                  ? 'Have an account? Log in'
                                  : 'New here? Create an account',
                            ),
                          ),
                        ),
                        const Divider(color: ink, height: 24, thickness: 1),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: busy ? null : _state.loginDev,
                            icon: const Icon(Icons.code),
                            label: const Text('Use dev login'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hero() {
    return ShadowCard(
      color: ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
            child: const Icon(Icons.restaurant_menu, color: ink),
          ),
          const SizedBox(height: 24),
          const Text(
            'theeta.in',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              height: 0.95,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Save reels, and let AI resolve the food spot.',
            style: TextStyle(
              color: Color(0xFFFFE3B5),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffix,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: ink, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: ink, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }
}
