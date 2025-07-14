// lib/features/shared/widgets/token_debug_widget.dart
import 'package:flutter/material.dart';
import '../../../di/injection.dart';
import '../../../core/services/token_manager.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class TokenDebugWidget extends StatefulWidget {
  const TokenDebugWidget({Key? key}) : super(key: key);

  @override
  State<TokenDebugWidget> createState() => _TokenDebugWidgetState();
}

class _TokenDebugWidgetState extends State<TokenDebugWidget> {
  Map<String, dynamic> tokenInfo = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTokenInfo();
  }

  Future<void> _loadTokenInfo() async {
    setState(() => isLoading = true);
    
    try {
      final tokenManager = getIt<TokenManager>();
      final info = await tokenManager.getTokenInfo();
      
      setState(() {
        tokenInfo = info;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading token info: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _clearTokens() async {
    try {
      final tokenManager = getIt<TokenManager>();
      await tokenManager.clearAllTokens();
      await _loadTokenInfo();
      _showSnackBar('Tokens eliminados correctamente', AppColors.success);
    } catch (e) {
      _showSnackBar('Error eliminando tokens: $e', AppColors.error);
    }
  }

  Future<void> _debugTokens() async {
    try {
      final tokenManager = getIt<TokenManager>();
      await tokenManager.debugTokenInfo();
      _showSnackBar('Debug info en consola', AppColors.info);
    } catch (e) {
      _showSnackBar('Error en debug: $e', AppColors.error);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Debug de Tokens',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
                onPressed: _loadTokenInfo,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else ...[
            _buildTokenInfoRow('Tiene Access Token', tokenInfo['hasAccessToken']?.toString() ?? 'false'),
            _buildTokenInfoRow('Tiene Refresh Token', tokenInfo['hasRefreshToken']?.toString() ?? 'false'),
            _buildTokenInfoRow('Token Expirado', tokenInfo['isExpired']?.toString() ?? 'unknown'),
            _buildTokenInfoRow('User ID', tokenInfo['userId']?.toString() ?? 'null'),
            _buildTokenInfoRow('Fecha Expiración', tokenInfo['expiryDate']?.toString() ?? 'null'),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _debugTokens,
                    icon: Icon(Icons.terminal, size: 16),
                    label: Text('Debug'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearTokens,
                    icon: Icon(Icons.delete_outline, size: 16),
                    label: Text('Limpiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTokenInfoRow(String label, String value) {
    Color valueColor = AppColors.textSecondary;
    if (value == 'true') {
      valueColor = AppColors.success;
    } else if (value == 'false') {
      valueColor = AppColors.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}