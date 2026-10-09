import 'package:cross_platform_whiteboard/core/strings/app_strings.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_status.dart';
import 'package:cross_platform_whiteboard/features/session/presentation/controllers/session_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SessionPanel extends GetView<SessionController> {
  const SessionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final bool canHost = !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.windows;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.devices_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.sectionConnection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _SessionStatusLabel(status: controller.status.value),
                ],
              ),
              const SizedBox(height: 12),
              if (canHost) _buildHostControls(context) else _buildClientControls(context),
              if (controller.errorMessage.value.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage.value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHostControls(BuildContext context) {
    final SessionStatus status = controller.status.value;
    if (status != SessionStatus.hosting) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: status == SessionStatus.connecting
              ? null
              : controller.startHost,
          icon: const Icon(Icons.wifi_tethering_rounded),
          label: const Text(AppStrings.actionStartSession),
        ),
      );
    }

    final List<String> addresses = controller.hostAddresses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(AppStrings.messageWindowsHostReady),
        const SizedBox(height: 8),
        if (addresses.isEmpty)
          const Text(AppStrings.messageNoHostAddresses)
        else
          ...addresses.map(
            (String address) => SelectableText(
              '$address:${AppStrings.sessionPort}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: SelectableText(
                controller.sessionToken.value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            IconButton(
              tooltip: AppStrings.actionCopyCode,
              onPressed: () => Clipboard.setData(
                ClipboardData(text: controller.sessionToken.value),
              ),
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.messageKeepCodePrivate,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: controller.disconnect,
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text(AppStrings.actionStopSession),
        ),
      ],
    );
  }

  Widget _buildClientControls(BuildContext context) {
    final SessionStatus status = controller.status.value;
    if (status == SessionStatus.connected) {
      return Row(
        children: <Widget>[
          const Expanded(child: Text(AppStrings.messageConnectedToHost)),
          OutlinedButton(
            onPressed: controller.disconnect,
            child: const Text(AppStrings.actionDisconnectSession),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          onChanged: controller.setHostAddress,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: AppStrings.labelHostAddress,
            hintText: AppStrings.hintHostAddress,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: controller.setAccessCode,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: AppStrings.labelSessionCode,
            hintText: AppStrings.hintSessionCode,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                AppStrings.messageSameNetwork,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            FilledButton.icon(
              onPressed: status == SessionStatus.connecting
                  ? null
                  : controller.connect,
              icon: const Icon(Icons.link_rounded),
              label: const Text(AppStrings.actionConnectSession),
            ),
          ],
        ),
      ],
    );
  }
}

class _SessionStatusLabel extends StatelessWidget {
  const _SessionStatusLabel({required this.status});

  final SessionStatus status;

  @override
  Widget build(BuildContext context) {
    final String label = switch (status) {
      SessionStatus.disconnected => AppStrings.statusDisconnected,
      SessionStatus.connecting => AppStrings.statusConnecting,
      SessionStatus.hosting => AppStrings.statusHosting,
      SessionStatus.connected => AppStrings.statusConnected,
    };

    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
