import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = CatspotTheme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? 'Explorer';

    return Scaffold(
      backgroundColor: tokens.colors.surfaceBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'Catspot',
                textAlign: TextAlign.center,
                style: tokens.typography.displayLarge.copyWith(
                  color: tokens.colors.brandPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back, $name',
                textAlign: TextAlign.center,
                style: tokens.typography.body.copyWith(
                  color: tokens.colors.inkSecondary,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.go('/scan'),
                icon: const Icon(Icons.camera_alt_outlined, size: 22),
                label: const Text('Scan for a Cat'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  textStyle: tokens.typography.label.copyWith(fontSize: 17),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/collection'),
                icon: const Icon(Icons.pets_outlined, size: 20),
                label: const Text('My Collection'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 48),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: Text(
                  'Sign out',
                  style: TextStyle(color: tokens.colors.inkTertiary),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
