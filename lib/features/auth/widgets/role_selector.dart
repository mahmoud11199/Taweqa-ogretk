import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user_model.dart';

class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final DriverType? selectedDriverType;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<DriverType?> onDriverTypeChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    this.selectedDriverType,
    required this.onRoleChanged,
    required this.onDriverTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                icon: Icons.person_outline,
                label: 'راكب',
                isSelected: selectedRole == 'passenger',
                onTap: () => onRoleChanged('passenger'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleCard(
                icon: Icons.directions_car_outlined,
                label: 'سائق',
                isSelected: selectedRole == 'driver',
                onTap: () => onRoleChanged('driver'),
              ),
            ),
          ],
        ),
        if (selectedRole == 'driver') ...[
          const SizedBox(height: 16),
          const Text(
            'نوع المركبة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.meterMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: DriverType.values.map((type) {
              final isSelected = selectedDriverType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onDriverTypeChanged(type),
                  child: Container(
                    margin: EdgeInsets.only(
                      left: type == DriverType.private ? 4 : 0,
                      right: type == DriverType.motorcycle ? 4 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.meterPrimary.withAlpha(30)
                          : AppTheme.meterCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.meterPrimary
                            : AppTheme.meterCard,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      type.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.meterPrimary
                            : AppTheme.meterMuted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.meterPrimary.withAlpha(30)
              : AppTheme.meterCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.meterPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? AppTheme.meterPrimary : AppTheme.meterMuted,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.meterPrimary : AppTheme.meterMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
