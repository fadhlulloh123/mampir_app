import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'place_form_widgets.dart';

Future<bool> showCreateAdminDialog(
  BuildContext context, {
  required String token,
  required String supabaseUrl,
  required String supabaseAnonKey,
}) async {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscurePass = true;
  bool obscureConfirm = true;
  bool submitting = false;
  String? formError;

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final navyCard = isDark ? const Color(0xFF162035) : Colors.white;
  final navyBorder = isDark ? const Color(0xFF263353) : const Color(0xFFE2E8F0);
  final navyInput = isDark ? const Color(0xFF131B30) : const Color(0xFFF1F5F9);
  final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
  final textSecondary = isDark ? Colors.white70 : const Color(0xFF475569);
  final textMuted = isDark ? Colors.white54 : const Color(0xFF94A3B8);
  const amberPrimary = Color(0xFFD99B25);

  final created = await showDialog<bool>(
    context: context,
    barrierDismissible: !submitting,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        Future<void> submit() async {
          final displayName = nameController.text.trim();
          final email = emailController.text.trim().toLowerCase();
          final password = passwordController.text;
          final confirm = confirmController.text;

          if (displayName.isEmpty) {
            setModalState(() => formError = 'Nama lengkap admin wajib diisi.');
            return;
          }
          if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
            setModalState(() => formError = 'Format email admin tidak valid.');
            return;
          }
          if (password.length < 6) {
            setModalState(
              () => formError = 'Kata sandi minimal 6 karakter.',
            );
            return;
          }
          if (password != confirm) {
            setModalState(
              () => formError = 'Konfirmasi kata sandi tidak cocok.',
            );
            return;
          }

          setModalState(() {
            submitting = true;
            formError = null;
          });

          try {
            // 1. Prioritaskan Edge Function create-admin (otomatis email_confirm & role admin)
            final fnResp = await http.post(
              Uri.parse('$supabaseUrl/functions/v1/create-admin'),
              headers: {
                'apikey': supabaseAnonKey,
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'email': email,
                'password': password,
                'display_name': displayName,
              }),
            );

            if (fnResp.statusCode >= 200 && fnResp.statusCode < 300) {
              if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
              return;
            }

            // Jika Edge Function belum dideploy (404), gunakan fallback Auth SignUp + REST
            if (fnResp.statusCode != 404) {
              String msg = 'Gagal membuat akun admin (${fnResp.statusCode}).';
              try {
                final decoded = jsonDecode(fnResp.body);
                if (decoded is Map && decoded['error'] != null) {
                  msg = '${decoded['error']}';
                }
              } catch (_) {}
              throw Exception(msg);
            }

            // 2. Fallback: Supabase Auth SignUp
            final signUpResp = await http.post(
              Uri.parse('$supabaseUrl/auth/v1/signup'),
              headers: {
                'apikey': supabaseAnonKey,
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'email': email,
                'password': password,
                'data': {
                  'display_name': displayName,
                  'full_name': displayName,
                  'role': 'admin',
                },
              }),
            );

            if (signUpResp.statusCode < 200 || signUpResp.statusCode >= 300) {
              String msg =
                  'Gagal mendaftarkan akun (${signUpResp.statusCode}).';
              try {
                final decoded = jsonDecode(signUpResp.body);
                if (decoded is Map) {
                  msg =
                      '${decoded['msg'] ?? decoded['error_description'] ?? decoded['error'] ?? msg}';
                }
              } catch (_) {}
              throw Exception(msg);
            }

            String? createdUserId;
            try {
              final decoded = jsonDecode(signUpResp.body);
              if (decoded is Map<String, dynamic>) {
                createdUserId =
                    (decoded['user']?['id'] ?? decoded['id']) as String?;
              }
            } catch (_) {}

            // 3. Pastikan role = 'admin' di tabel user_profiles
            if (createdUserId != null && createdUserId.isNotEmpty) {
              await http.post(
                Uri.parse(
                  '$supabaseUrl/rest/v1/user_profiles?on_conflict=id',
                ),
                headers: {
                  'apikey': supabaseAnonKey,
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                  'Prefer': 'resolution=merge-duplicates,return=minimal',
                },
                body: jsonEncode({
                  'id': createdUserId,
                  'display_name': displayName,
                  'role': 'admin',
                }),
              );
            }

            // 4. Catat ke log aktivitas Supabase
            await http.post(
              Uri.parse('$supabaseUrl/rest/v1/user_activities'),
              headers: {
                'apikey': supabaseAnonKey,
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal',
              },
              body: jsonEncode({
                'email': email,
                if (createdUserId != null && createdUserId.isNotEmpty)
                  'user_id': createdUserId,
                'action': 'ADMIN_CREATED',
                'details':
                    'Akun admin baru "$displayName" ($email) ditambahkan melalui Admin Dashboard',
              }),
            );

            if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
          } catch (e) {
            setModalState(() {
              submitting = false;
              formError = e.toString().replaceFirst('Exception: ', '');
            });
          }
        }

        return AlertDialog(
          backgroundColor: navyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: navyBorder, width: 1.5),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: amberPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: amberPrimary.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: amberPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambah Akun Admin Baru',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Daftarkan administrator baru yang langsung aktif di Supabase & daftar akun',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: submitting ? null : () => Navigator.pop(dialogCtx, false),
                icon: Icon(Icons.close_rounded, color: textMuted),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildDialogSectionHeader(
                    'IDENTITAS & KREDENSIAL ADMIN',
                    Icons.verified_user_outlined,
                    amberPrimary,
                    navyBorder,
                  ),
                  buildDialogCard(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameController,
                          enabled: !submitting,
                          style: TextStyle(color: textPrimary),
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap Admin *',
                            hintText: 'Mis. Admin Purwokerto 2',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: emailController,
                          enabled: !submitting,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: textPrimary),
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email Admin *',
                            hintText: 'admin2@mampir.id',
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: passwordController,
                          enabled: !submitting,
                          obscureText: obscurePass,
                          style: TextStyle(color: textPrimary),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi *',
                            hintText: 'Minimal 6 karakter',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setModalState(
                                () => obscurePass = !obscurePass,
                              ),
                              icon: Icon(
                                obscurePass
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: confirmController,
                          enabled: !submitting,
                          obscureText: obscureConfirm,
                          style: TextStyle(color: textPrimary),
                          onSubmitted: (_) => submitting ? null : submit(),
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Kata Sandi *',
                            hintText: 'Ulangi kata sandi',
                            prefixIcon: const Icon(
                              Icons.lock_reset_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setModalState(
                                () => obscureConfirm = !obscureConfirm,
                              ),
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: amberPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: amberPrimary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                size: 18,
                                color: amberPrimary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Role otomatis diset sebagai Administrator dan tercatat di Daftar Akun & Linimasa Aktivitas.',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    navyInput,
                    navyBorder,
                  ),
                  if (formError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formError!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: navyBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              onPressed: submitting ? null : () => Navigator.pop(dialogCtx, false),
              child: Text('Batal', style: TextStyle(color: textSecondary)),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: amberPrimary,
                foregroundColor: isDark
                    ? const Color(0xFF0D1326)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: submitting ? null : submit,
              icon: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0D1326),
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: Text(
                submitting ? 'Menyimpan...' : 'Buat Akun Admin',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ),
  );

  return created == true;
}
