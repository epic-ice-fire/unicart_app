import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "../../services/lobby_service.dart";
import "../../theme/unicart_theme.dart";
import "../../widgets/unicart_ui.dart";

class AdminDashboardScreen extends StatefulWidget {
  final String token;

  const AdminDashboardScreen({super.key, required this.token});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool isLoading = true;
  bool isBusy = false;
  String? error;
  Map<String, dynamic>? dashboardData;
  final TextEditingController targetController = TextEditingController();
  final Set<int> _expandedBatches = {};

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  @override
  void dispose() {
    targetController.dispose();
    super.dispose();
  }

  Future<void> loadDashboard() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await LobbyService.adminDashboard(widget.token);
      final openLobby = data["current_open_lobby"] as Map<String, dynamic>?;
      if (openLobby != null) {
        targetController.text =
            (openLobby["target_item_amount"] ?? "").toString();
      }
      if (mounted) setState(() => dashboardData = data);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> updateMov() async {
    final mov = int.tryParse(targetController.text.trim());
    if (mov == null || mov <= 0) {
      showMessage("Enter a valid MOV.");
      return;
    }

    setState(() => isBusy = true);
    try {
      await LobbyService.adminUpdateOpenLobbyTarget(
        widget.token,
        targetItemAmount: mov,
      );
      await loadDashboard();
      showMessage("MOV updated successfully.", isSuccess: true);
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> updateBatchStatus({
    required int lobbyId,
    required String newStatus,
  }) async {
    setState(() => isBusy = true);
    try {
      await LobbyService.adminUpdateBatchStatus(
        widget.token,
        lobbyId: lobbyId,
        newStatus: newStatus,
      );
      await loadDashboard();
      showMessage("Batch status updated.", isSuccess: true);
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> forceRemoveItem(
    int itemId,
    String itemLink,
    bool isPaid,
  ) async {
    final confirmed = await _showForceRemoveSheet(
      itemLink: itemLink,
      isPaid: isPaid,
    );
    if (confirmed != true) return;

    setState(() => isBusy = true);
    try {
      final result = await LobbyService.adminForceRemoveItem(
        widget.token,
        itemId: itemId,
      );
      await loadDashboard();

      final isUnderfunded = result["lobby_is_underfunded"] == true;
      final gap = result["underfunded_gap"] ?? 0;

      if (isUnderfunded) {
        showMessage(
          "Item #$itemId removed. The batch is now ₦$gap below target due to removal.",
          isWarning: true,
        );
      } else {
        showMessage(
          "Item #$itemId removed successfully.",
          isSuccess: true,
        );
      }
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> copyItemLink(String link) async {
    if (link.trim().isEmpty) {
      showMessage("No item link.");
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    showMessage("Link copied.", isSuccess: true);
  }

  void showMessage(
    String message, {
    bool isSuccess = false,
    bool isWarning = false,
  }) {
    if (!mounted) return;
    showUniCartSnack(
      context,
      message,
      success: isSuccess,
      warning: isWarning,
    );
  }

  String prettyStatus(String status) {
    switch (status) {
      case "triggered":
        return "Triggered";
      case "processing":
        return "Processing";
      case "in_transit":
        return "In Transit";
      case "completed":
        return "Completed";
      case "open":
        return "Open";
      case "paid":
        return "Paid";
      case "pending":
        return "Pending";
      case "failed":
        return "Failed";
      case "abandoned":
        return "Abandoned";
      case "unpaid":
        return "Unpaid";
      default:
        return status;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case "triggered":
        return UniCartColors.warning;
      case "processing":
        return UniCartColors.primarySoft;
      case "in_transit":
        return UniCartColors.purple;
      case "completed":
      case "paid":
        return UniCartColors.success;
      case "pending":
        return UniCartColors.warning;
      case "failed":
      case "abandoned":
        return UniCartColors.danger;
      default:
        return UniCartColors.textSecondary;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case "triggered":
        return Icons.flag_outlined;
      case "processing":
        return Icons.inventory_2_outlined;
      case "in_transit":
        return Icons.local_shipping_outlined;
      case "completed":
        return Icons.check_circle_outline;
      case "open":
        return Icons.lock_open_outlined;
      case "paid":
        return Icons.lock_outline;
      case "pending":
        return Icons.hourglass_bottom_outlined;
      case "failed":
      case "abandoned":
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  Widget buildStatusBadge(String status) {
    return UniCartStatusPill(
      label: prettyStatus(status),
      color: statusColor(status),
      icon: statusIcon(status),
    );
  }

  Widget buildUnderfundedBanner(int gap) {
    return UniCartInfoBanner(
      color: UniCartColors.warning,
      icon: Icons.warning_amber_rounded,
      title: "Batch underfunded after fraud removal",
      message:
          "A paid item was removed after this batch triggered. The batch is now ₦$gap below the original target, but the remaining paid items must still be processed. The affected user has been notified.",
    );
  }

  Widget buildItemLabel(String label) {
    Color color;
    IconData icon;

    switch (label) {
      case "PAID (LOCKED)":
        color = UniCartColors.success;
        icon = Icons.lock_rounded;
        break;
      case "REMOVED":
        color = UniCartColors.danger;
        icon = Icons.remove_circle_outline_rounded;
        break;
      case "PAYMENT PENDING":
        color = UniCartColors.warning;
        icon = Icons.hourglass_bottom_rounded;
        break;
      default:
        color = UniCartColors.textSecondary;
        icon = Icons.circle_outlined;
    }

    return UniCartStatusPill(label: label, color: color, icon: icon);
  }

  Widget infoPill(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: UniCartColors.surfaceSoft.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: UniCartColors.border),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: UniCartColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> startProcessingWithPriceCheck({
    required int lobbyId,
    required List<Map<String, dynamic>> items,
  }) async {
    final paidItems = items
        .where(
          (i) => i["is_paid"] == true && i["is_active"] == true,
        )
        .toList();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            initialChildSize: 0.82,
            minChildSize: 0.55,
            maxChildSize: 0.94,
            expand: false,
            builder: (context, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: UniCartColors.surfaceRaised,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(UniCartRadius.xxl),
                  ),
                  border: Border(
                    top: BorderSide(color: UniCartColors.border),
                  ),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: UniCartColors.textMuted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const UniCartEyebrow(
                      icon: Icons.fact_check_outlined,
                      label: "Required admin check",
                      color: UniCartColors.primarySoft,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Verify prices before processing",
                      style: TextStyle(
                        color: UniCartColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      "UniCart uses guest-price standardisation. Before processing, verify every paid item on Temu while logged out or in a private window.",
                      style: TextStyle(
                        color: UniCartColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Paid items in this batch",
                      style: TextStyle(
                        color: UniCartColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (paidItems.isEmpty)
                      const UniCartInfoBanner(
                        color: UniCartColors.warning,
                        icon: Icons.inventory_2_outlined,
                        title: "No paid items found",
                        message: "Check this batch before changing its status.",
                      )
                    else
                      ...paidItems.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: UniCartColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: UniCartColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["item_link"]?.toString() ?? "Unknown link",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: UniCartColors.textPrimary,
                                  fontSize: 12,
                                  height: 1.4,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  infoPill(
                                    item["user_email"]?.toString() ?? "Unknown user",
                                  ),
                                  UniCartStatusPill(
                                    label:
                                        "₦${item["item_amount"]} guest price",
                                    color: UniCartColors.success,
                                    icon: Icons.payments_outlined,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      "Admin checklist",
                      style: TextStyle(
                        color: UniCartColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...[
                      "I am logged out of Temu or using a private window.",
                      "I checked every paid item link as a guest.",
                      "The submitted prices match the guest prices I can see.",
                      "Any discrepancies have already been force-removed.",
                      "I am ready to place the group order.",
                    ].map(_checkRow),
                    const SizedBox(height: 12),
                    const UniCartInfoBanner(
                      color: UniCartColors.danger,
                      icon: Icons.lock_outline_rounded,
                      title: "Status change is operationally significant",
                      message:
                          "Starting processing confirms that guest prices were manually verified for the remaining paid items.",
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: UniCartPrimaryButton(
                            outlined: true,
                            accentColor: UniCartColors.textSecondary,
                            minHeight: 50,
                            onPressed: () =>
                                Navigator.pop(sheetContext, false),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: UniCartPrimaryButton(
                            minHeight: 50,
                            leadingIcon: Icons.play_circle_outline_rounded,
                            onPressed: () =>
                                Navigator.pop(sheetContext, true),
                            child: const Text("Start processing"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (confirmed != true) return;
    await updateBatchStatus(lobbyId: lobbyId, newStatus: "processing");
  }

  Widget _checkRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: UniCartColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: UniCartColors.primary.withValues(alpha: 0.28),
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 15,
              color: UniCartColors.primarySoft,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: UniCartColors.textPrimary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBatchActionButtons(Map<String, dynamic> batch) {
    final status = batch["status"]?.toString() ?? "";
    final lobbyId = batch["lobby_id"] as int;
    final items = ((batch["items"] as List?) ?? [])
        .cast<Map<String, dynamic>>();

    if (status == "triggered") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UniCartInfoBanner(
            color: UniCartColors.primarySoft,
            icon: Icons.fact_check_outlined,
            title: "Verify guest prices before processing",
            message:
                "Open each paid item while logged out of Temu. Force-remove any discrepancy before starting processing.",
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 300,
              child: UniCartPrimaryButton(
                leadingIcon: Icons.fact_check_outlined,
                onPressed: isBusy
                    ? null
                    : () => startProcessingWithPriceCheck(
                          lobbyId: lobbyId,
                          items: items,
                        ),
                child: const Text("Verify prices & start processing"),
              ),
            ),
          ),
        ],
      );
    }

    if (status == "processing") {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 220,
          child: UniCartPrimaryButton(
            accentColor: UniCartColors.purple,
            leadingIcon: Icons.local_shipping_outlined,
            onPressed: isBusy
                ? null
                : () => updateBatchStatus(
                      lobbyId: lobbyId,
                      newStatus: "in_transit",
                    ),
            child: const Text("Mark in transit"),
          ),
        ),
      );
    }

    if (status == "in_transit") {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 220,
          child: UniCartPrimaryButton(
            accentColor: UniCartColors.success,
            leadingIcon: Icons.check_circle_outline,
            onPressed: isBusy
                ? null
                : () => updateBatchStatus(
                      lobbyId: lobbyId,
                      newStatus: "completed",
                    ),
            child: const Text("Mark completed"),
          ),
        ),
      );
    }

    if (status == "completed") {
      return const Align(
        alignment: Alignment.centerRight,
        child: UniCartStatusPill(
          label: "Completed",
          color: UniCartColors.success,
          icon: Icons.check_circle_outline,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<bool?> _showForceRemoveSheet({
    required String itemLink,
    required bool isPaid,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              decoration: const BoxDecoration(
                color: UniCartColors.surfaceRaised,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(UniCartRadius.xxl),
                ),
                border: Border(
                  top: BorderSide(color: UniCartColors.border),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: UniCartColors.textMuted,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const UniCartEyebrow(
                    icon: Icons.delete_forever_outlined,
                    label: "Admin enforcement",
                    color: UniCartColors.danger,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Remove item from this batch?",
                    style: TextStyle(
                      color: UniCartColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: UniCartColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: UniCartColors.border),
                    ),
                    child: Text(
                      itemLink,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: UniCartColors.textPrimary,
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isPaid) ...[
                    const UniCartInfoBanner(
                      color: UniCartColors.warning,
                      icon: Icons.payments_outlined,
                      title: "This item has already been paid",
                      message:
                          "Removing it will not issue a refund and can push the batch below its original target.",
                    ),
                    const SizedBox(height: 10),
                  ],
                  const UniCartInfoBanner(
                    color: UniCartColors.danger,
                    icon: Icons.gavel_rounded,
                    title: "No-refund policy",
                    message:
                        "Proceed only when the item breaches UniCart rules, such as fraudulent submissions or fabricated amounts. The user will be notified by email.",
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: UniCartPrimaryButton(
                          outlined: true,
                          accentColor: UniCartColors.textSecondary,
                          minHeight: 50,
                          onPressed: () =>
                              Navigator.pop(sheetContext, false),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: UniCartPrimaryButton(
                          accentColor: UniCartColors.danger,
                          minHeight: 50,
                          leadingIcon: Icons.delete_forever_outlined,
                          onPressed: () => Navigator.pop(sheetContext, true),
                          child: const Text("Remove — no refund"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final openLobby =
        dashboardData?["current_open_lobby"] as Map<String, dynamic>?;
    final triggeredBatches =
        ((dashboardData?["triggered_batches"] as List?) ?? [])
            .cast<Map<String, dynamic>>();
    final triggeredCount = dashboardData?["triggered_batch_count"] ?? 0;

    return Scaffold(
      body: UniCartBackdrop(
        safeArea: false,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: isLoading
                    ? const _AdminLoadingState()
                    : RefreshIndicator(
                        color: UniCartColors.primarySoft,
                        backgroundColor: UniCartColors.surfaceRaised,
                        onRefresh: loadDashboard,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final horizontalPadding = constraints.maxWidth >= 900
                                ? 28.0
                                : constraints.maxWidth >= 600
                                    ? 20.0
                                    : 14.0;

                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                18,
                                horizontalPadding,
                                42,
                              ),
                              children: [
                                Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 1180),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (error != null) ...[
                                          UniCartInfoBanner(
                                            color: UniCartColors.danger,
                                            icon: Icons.error_outline_rounded,
                                            title: "Admin dashboard error",
                                            message: error,
                                          ),
                                          const SizedBox(height: 14),
                                        ],
                                        _buildAdminHero(
                                          openLobby,
                                          triggeredCount,
                                        ),
                                        const SizedBox(height: 14),
                                        _buildAdminMetrics(
                                          openLobby,
                                          triggeredBatches,
                                        ),
                                        const SizedBox(height: 14),
                                        _responsivePair(
                                          constraints.maxWidth,
                                          _buildOpenLobbyCard(openLobby),
                                          _buildMovCard(openLobby),
                                        ),
                                        const SizedBox(height: 14),
                                        _buildPipelineCard(triggeredBatches),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: UniCartColors.background.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: UniCartColors.divider),
        ),
      ),
      child: Row(
        children: [
          UniCartIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: "Back to lobby",
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const UniCartEyebrow(
            icon: Icons.admin_panel_settings_rounded,
            label: "Admin",
            color: UniCartColors.purple,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Operations dashboard",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: UniCartColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          UniCartIconButton(
            icon: Icons.refresh_rounded,
            tooltip: "Refresh",
            onPressed: isLoading || isBusy ? null : loadDashboard,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHero(
    Map<String, dynamic>? openLobby,
    dynamic triggeredCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF21124C), Color(0xFF111B45), Color(0xFF0B1220)],
        ),
        borderRadius: BorderRadius.circular(UniCartRadius.xxl),
        border: Border.all(
          color: UniCartColors.purple.withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: UniCartColors.purple.withValues(alpha: 0.16),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const UniCartEyebrow(
            icon: Icons.hub_outlined,
            label: "Batch control centre",
            color: UniCartColors.purple,
          ),
          const SizedBox(height: 15),
          const Text(
            "Operate UniCart without losing the batch context.",
            style: TextStyle(
              color: UniCartColors.textPrimary,
              fontSize: 26,
              height: 1.14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.75,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            "Review the live lobby, verify guest prices, handle fraud removals, and move every triggered batch through fulfilment.",
            style: TextStyle(
              color: UniCartColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              UniCartStatusPill(
                label: "Lobby #${openLobby?["lobby_id"] ?? "—"}",
                color: UniCartColors.primarySoft,
                icon: Icons.storefront_outlined,
              ),
              UniCartStatusPill(
                label: prettyStatus(
                  openLobby?["status"]?.toString() ?? "Unknown",
                ),
                color: statusColor(
                  openLobby?["status"]?.toString() ?? "",
                ),
                icon: statusIcon(
                  openLobby?["status"]?.toString() ?? "",
                ),
              ),
              UniCartStatusPill(
                label: "$triggeredCount pipeline batches",
                color: UniCartColors.purple,
                icon: Icons.inventory_2_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMetrics(
    Map<String, dynamic>? openLobby,
    List<Map<String, dynamic>> batches,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final memberCount = openLobby?["member_count"] ?? 0;
        final current = openLobby?["current_item_amount"] ?? 0;
        final target = openLobby?["target_item_amount"] ?? 0;
        final underfundedCount =
            batches.where((batch) => batch["is_underfunded"] == true).length;

        return Row(
          children: [
            Expanded(
              child: UniCartMetricCard(
                label: "Open members",
                value: "$memberCount",
                caption: "Current lobby",
                icon: Icons.people_outline_rounded,
                accent: UniCartColors.primarySoft,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: UniCartMetricCard(
                label: "Open vault",
                value: "₦$current",
                caption: "Target ₦$target",
                icon: Icons.account_balance_wallet_outlined,
                accent: UniCartColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: UniCartMetricCard(
                label: "Pipeline",
                value: "${batches.length}",
                caption: underfundedCount == 0
                    ? "No funding warnings"
                    : "$underfundedCount underfunded",
                icon: Icons.route_outlined,
                accent: underfundedCount == 0
                    ? UniCartColors.purple
                    : UniCartColors.warning,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _responsivePair(double width, Widget left, Widget right) {
    if (width >= 820) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 14),
          Expanded(child: right),
        ],
      );
    }

    return Column(
      children: [
        left,
        const SizedBox(height: 14),
        right,
      ],
    );
  }

  Widget _buildOpenLobbyCard(Map<String, dynamic>? openLobby) {
    if (openLobby == null) {
      return UniCartPanel(
        color: UniCartColors.surface.withValues(alpha: 0.92),
        borderColor: UniCartColors.border.withValues(alpha: 0.72),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UniCartSectionTitle(
              title: "Current open lobby",
              subtitle: "The lobby students are currently joining",
            ),
            SizedBox(height: 16),
            UniCartInfoBanner(
              color: UniCartColors.warning,
              icon: Icons.storefront_outlined,
              title: "No open lobby found",
              message: "Refresh the dashboard after the next lobby is created.",
            ),
          ],
        ),
      );
    }

    final target = (openLobby["target_item_amount"] as num?)?.toDouble() ?? 0;
    final current =
        (openLobby["current_item_amount"] as num?)?.toDouble() ?? 0;
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return UniCartPanel(
      color: UniCartColors.surface.withValues(alpha: 0.92),
      borderColor: UniCartColors.border.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UniCartSectionTitle(
            title: "Current open lobby",
            subtitle: "Lobby #${openLobby["lobby_id"]}",
            trailing: buildStatusBadge(
              openLobby["status"]?.toString() ?? "open",
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _miniInfo(
                  "Members",
                  "${openLobby["member_count"] ?? 0}",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniInfo(
                  "Paid total",
                  "₦${openLobby["current_item_amount"] ?? 0}",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniInfo(
                  "Target",
                  "₦${openLobby["target_item_amount"] ?? 0}",
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Vault progress",
                style: TextStyle(
                  color: UniCartColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "${(progress * 100).toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: UniCartColors.primarySoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 9,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: UniCartColors.surfaceSoft,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  UniCartColors.primaryBright,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovCard(Map<String, dynamic>? openLobby) {
    return UniCartPanel(
      color: UniCartColors.surface.withValues(alpha: 0.92),
      borderColor: UniCartColors.border.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UniCartSectionTitle(
            title: "MOV / target control",
            subtitle: "Update the target for the current open lobby",
          ),
          const SizedBox(height: 18),
          TextField(
            controller: targetController,
            enabled: openLobby != null && !isBusy,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: UniCartColors.textPrimary),
            decoration: const InputDecoration(
              labelText: "Target amount (₦)",
              hintText: "e.g. 50000",
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 14),
          UniCartPrimaryButton(
            leadingIcon: Icons.tune_rounded,
            loading: isBusy,
            onPressed: openLobby == null || isBusy ? null : updateMov,
            child: const Text("Update MOV"),
          ),
          const SizedBox(height: 10),
          const UniCartInfoBanner(
            color: UniCartColors.primarySoft,
            icon: Icons.info_outline_rounded,
            title: "Target affects the live vault",
            message:
                "Students see this target immediately after the dashboard refreshes.",
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineCard(List<Map<String, dynamic>> batches) {
    return UniCartPanel(
      color: UniCartColors.surface.withValues(alpha: 0.92),
      borderColor: UniCartColors.border.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UniCartSectionTitle(
            title: "Batch pipeline",
            subtitle:
                "Triggered → processing → in transit → completed. Review guest prices before progressing a triggered batch.",
            trailing: batches.isEmpty
                ? null
                : UniCartStatusPill(
                    label: "${batches.length} batch${batches.length == 1 ? "" : "es"}",
                    color: UniCartColors.purple,
                    icon: Icons.inventory_2_outlined,
                  ),
          ),
          const SizedBox(height: 18),
          _buildPipelineLegend(),
          const SizedBox(height: 18),
          if (batches.isEmpty)
            _emptyState(
              icon: Icons.inventory_2_outlined,
              title: "No batches in the pipeline",
              message: "Triggered batches will appear here.",
            )
          else
            ...batches.map(_buildBatchTile),
        ],
      ),
    );
  }

  Widget _buildPipelineLegend() {
    const stages = [
      ("Triggered", UniCartColors.warning, Icons.flag_rounded),
      ("Processing", UniCartColors.primarySoft, Icons.settings_rounded),
      ("In transit", UniCartColors.purple, Icons.local_shipping_rounded),
      ("Delivered", UniCartColors.success, Icons.check_circle_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: List.generate(stages.length * 2 - 1, (index) {
            if (index.isOdd) {
              return Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: UniCartColors.divider,
                ),
              );
            }

            final stage = stages[index ~/ 2];
            return Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: stage.$2.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: stage.$2.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Icon(stage.$3, size: 17, color: stage.$2),
                ),
                const SizedBox(height: 5),
                Text(
                  stage.$1,
                  style: TextStyle(
                    color: stage.$2,
                    fontSize: constraints.maxWidth < 520 ? 8 : 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildBatchTile(Map<String, dynamic> batch) {
    final lobbyId = batch["lobby_id"] as int;
    final status = batch["status"]?.toString() ?? "";
    final items = ((batch["items"] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final isUnderfunded = batch["is_underfunded"] == true;
    final underfundedGap = batch["underfunded_gap"] as int? ?? 0;
    final isExpanded = _expandedBatches.contains(lobbyId);
    final color = statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: UniCartColors.surfaceRaised,
        borderRadius: BorderRadius.circular(UniCartRadius.lg),
        border: Border.all(
          color: isUnderfunded
              ? UniCartColors.warning.withValues(alpha: 0.45)
              : UniCartColors.border,
          width: isUnderfunded ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(UniCartRadius.lg),
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedBatches.remove(lobbyId);
                  } else {
                    _expandedBatches.add(lobbyId);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Icon(
                            statusIcon(status),
                            size: 19,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Batch #$lobbyId",
                                style: const TextStyle(
                                  color: UniCartColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "Paid total ₦${batch["final_item_amount"]} / ₦${batch["target_item_amount"]}",
                                style: const TextStyle(
                                  color: UniCartColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        buildStatusBadge(status),
                        const SizedBox(width: 7),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: UniCartColors.textSecondary,
                        ),
                      ],
                    ),
                    if (isUnderfunded) ...[
                      const SizedBox(height: 10),
                      UniCartStatusPill(
                        label: "Underfunded by ₦$underfundedGap",
                        color: UniCartColors.warning,
                        icon: Icons.warning_amber_rounded,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isUnderfunded) ...[
                    buildUnderfundedBanner(underfundedGap),
                    const SizedBox(height: 12),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      buildStatusBadge(status),
                      infoPill("Members ${batch["member_count"] ?? 0}"),
                      infoPill("Items ${items.length}"),
                      infoPill(
                        "Paying members ${batch["paid_member_count"] ?? 0}",
                      ),
                      infoPill(
                        "Entry fee revenue ₦${batch["paid_total_ngn"] ?? 0}",
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  buildBatchActionButtons(batch),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 14),
                  const UniCartSectionTitle(
                    title: "Items in this batch",
                    subtitle:
                        "Copy a link to verify the guest price. Force-remove policy violations only.",
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    _emptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: "No items found",
                      message: "This batch currently has no item records.",
                    )
                  else
                    ...items.map(_buildAdminItemTile),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminItemTile(Map<String, dynamic> item) {
    final itemId = item["item_id"] as int? ?? 0;
    final itemLink = item["item_link"]?.toString() ?? "";
    final itemAmount = item["item_amount"] ?? 0;
    final userEmail = item["user_email"]?.toString() ?? "Unknown";
    final itemLabel = item["item_label"]?.toString() ?? "ACTIVE";
    final paymentStatus =
        item["item_payment_status"]?.toString() ?? "unpaid";
    final paymentAmount = item["item_payment_amount_ngn"] ?? 0;
    final isLocked = item["is_locked"] == true;
    final isPaid = item["is_paid"] == true;
    final isActive = item["is_active"] == true;
    final reference = item["item_payment_reference"]?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? UniCartColors.surface
            : UniCartColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? (isPaid
                  ? UniCartColors.success.withValues(alpha: 0.28)
                  : UniCartColors.border)
              : UniCartColors.danger.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  itemLink,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: UniCartColors.textPrimary,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              buildItemLabel(itemLabel),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              infoPill("₦$itemAmount"),
              infoPill(userEmail),
              infoPill("Payment ₦$paymentAmount"),
              UniCartStatusPill(
                label: prettyStatus(paymentStatus),
                color: statusColor(paymentStatus),
                icon: statusIcon(paymentStatus),
              ),
              UniCartStatusPill(
                label: isLocked ? "Locked" : "Unlocked",
                color: isLocked
                    ? UniCartColors.success
                    : UniCartColors.textSecondary,
                icon: isLocked
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
              ),
              if (reference != null && reference.isNotEmpty)
                infoPill("Ref $reference"),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _smallAction(
                label: "Copy link",
                icon: Icons.copy_outlined,
                color: UniCartColors.primarySoft,
                onTap: isBusy ? null : () => copyItemLink(itemLink),
              ),
              if (isActive)
                _smallAction(
                  label: "Force remove",
                  icon: Icons.delete_forever_outlined,
                  color: UniCartColors.danger,
                  onTap: isBusy
                      ? null
                      : () => forceRemoveItem(itemId, itemLink, isPaid),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: color.withValues(alpha: onTap == null ? 0.04 : 0.09),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withValues(alpha: 0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: UniCartColors.surfaceRaised,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: UniCartColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: UniCartColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: UniCartColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: UniCartColors.surfaceRaised,
        borderRadius: BorderRadius.circular(UniCartRadius.lg),
        border: Border.all(color: UniCartColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: UniCartColors.surfaceSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 25, color: UniCartColors.textMuted),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: UniCartColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: UniCartColors.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminLoadingState extends StatelessWidget {
  const _AdminLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.3),
          ),
          SizedBox(height: 13),
          Text(
            "Loading operations",
            style: TextStyle(
              color: UniCartColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
