import 'package:barcode_widget/barcode_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../services/model/login_model.dart';
import '../theme/brand_tokens.dart';
import 'brand_states.dart';

class BrandSheet extends StatelessWidget {
  const BrandSheet({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(tokens.radiusSm),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancelar'.tr()),
        ),
        FilledButton(onPressed: onConfirm, child: Text('aceptar'.tr())),
      ],
    );
  }
}

class AccountSwitcher extends StatefulWidget {
  const AccountSwitcher({
    super.key,
    required this.accounts,
    required this.activeAccount,
    required this.onSelect,
    required this.onDelete,
    required this.onAdd,
  });

  final List<UserAccount> accounts;
  final String activeAccount;
  final ValueChanged<UserAccount> onSelect;
  final ValueChanged<UserAccount> onDelete;
  final VoidCallback onAdd;

  @override
  State<AccountSwitcher> createState() => _AccountSwitcherState();
}

class _AccountSwitcherState extends State<AccountSwitcher> {
  UserAccount? _pendingDelete;

  @override
  Widget build(BuildContext context) {
    return BrandSheet(
      title: 'sus_cuentas'.tr(),
      children: [
        for (final account in widget.accounts)
          Column(
            children: [
              ListTile(
                onTap: () => widget.onSelect(account),
                leading: Icon(
                  account.userAccount == widget.activeAccount
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(account.nombre),
                subtitle: Text(account.userAccount),
                trailing: IconButton(
                  onPressed: () => setState(() => _pendingDelete = account),
                  icon: Icon(Icons.delete_outline, color: context.brand.danger),
                ),
              ),
              if (identical(_pendingDelete, account))
                Row(
                  children: [
                    Expanded(child: Text('confirme_borrar_cuenta'.tr())),
                    TextButton(
                      onPressed: () => setState(() => _pendingDelete = null),
                      child: Text('no'.tr()),
                    ),
                    FilledButton(
                      onPressed: () {
                        widget.onDelete(account);
                        setState(() => _pendingDelete = null);
                      },
                      child: Text('si'.tr()),
                    ),
                  ],
                ),
            ],
          ),
        OutlinedButton.icon(
          onPressed: widget.onAdd,
          icon: const Icon(Icons.add),
          label: Text('agregar_cuenta'.tr()),
        ),
      ],
    );
  }
}

class TipBubble extends StatelessWidget {
  const TipBubble({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.secondary,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: tokens.onSecondary),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close, color: tokens.onSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends BrandEmptyState {
  const EmptyState({
    super.key,
    required super.messageKey,
    super.icon,
  });
}

class CarnetQR extends StatelessWidget {
  const CarnetQR({super.key, required this.accountCode});

  final String accountCode;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: accountCode,
      image: true,
      child: BarcodeWidget(
        barcode: Barcode.qrCode(),
        data: accountCode,
        width: 160,
        height: 160,
        color: context.brand.text,
      ),
    );
  }
}
