import "dart:async";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";
import "../../models/lobby.dart";
import "../../services/auth_service.dart";
import "../../services/lobby_service.dart";
import "../../services/session_service.dart";
import "../../theme/unicart_theme.dart";
import "../../widgets/unicart_ui.dart";
import "../admin/admin_dashboard_screen.dart";
import "../auth/login_screen.dart";
import "../auth/verify_pau_screen.dart";

class LobbyScreen extends StatefulWidget {
  final String token;

  const LobbyScreen({super.key, required this.token});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  Lobby? lobby;
  bool isLoading = true;
  bool isBusy = false;
  String? error;

  Map<String, dynamic>? meData;
  Map<String, dynamic>? myItemsData;
  Map<String, dynamic>? myHistoryData;
  Map<String, dynamic>? mainDetailsData;

  String? pendingPaymentReference;
  String? pendingPaymentUrl;
  final Map<int, String> _pendingItemUrls = {};

  Timer? _pollTimer;

  final TextEditingController itemLinkController = TextEditingController();
  final TextEditingController itemAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    itemLinkController.dispose();
    itemAmountController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) loadAll(silent: true);
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<bool> _openPaymentUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return false;
    }

    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: "_blank",
      );
    } catch (_) {
      try {
        return await launchUrl(
          uri,
          webOnlyWindowName: "_blank",
        );
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> loadAll({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        error = null;
      });
    }

    try {
      Map<String, dynamic>? me;
      Map<String, dynamic>? myItems;
      Map<String, dynamic>? myHistory;
      Map<String, dynamic>? details;

      // Start every independent dashboard request together. The old version
      // waited for each request one-by-one, so four normal network round trips
      // became one long chain.
      Future<Map<String, dynamic>?> safe(
        Future<Map<String, dynamic>> request,
      ) async {
        try {
          return await request;
        } catch (_) {
          return null;
        }
      }

      final meFuture = AuthService.me(widget.token);
      final detailsFuture = safe(
        LobbyService.mainLobbyDetails(widget.token),
      );
      final itemsFuture = safe(
        LobbyService.myMainLobbyItems(widget.token),
      );
      final historyFuture = safe(
        LobbyService.myBatchHistory(widget.token),
      );

      try {
        me = await meFuture;
      } catch (e) {
        final raw = e.toString();
        if (raw.contains("401") ||
            raw.contains("Invalid token") ||
            raw.contains("not found")) {
          if (!silent && mounted) setState(() => isLoading = false);
          await _tryAutoRelogin();
          return;
        }
      }

      final dashboardResults = await Future.wait<Map<String, dynamic>?>([
        detailsFuture,
        itemsFuture,
        historyFuture,
      ]);
      details = dashboardResults[0];
      myItems = dashboardResults[1];
      myHistory = dashboardResults[2];

      if (!mounted) return;

      setState(() {
        meData = me;
        myItemsData = myItems;
        myHistoryData = myHistory;
        mainDetailsData = details;

        if (details != null) {
          lobby = Lobby(
            lobbyId: details["lobby_id"] as int? ?? 0,
            status: details["status"]?.toString() ?? "open",
            currentItemAmount:
                (details["current_item_amount"] as num?)?.toInt() ?? 0,
            targetItemAmount:
                (details["target_item_amount"] as num?)?.toInt() ?? 0,
            memberCount: details["member_count"] as int? ?? 0,
          );
        }

        final backendRef = details?["pending_payment_reference"]?.toString();
        final backendPaymentUrl =
            details?["pending_payment_authorization_url"]?.toString();
        if (backendRef != null && backendRef.isNotEmpty) {
          pendingPaymentReference = backendRef;
          if (backendPaymentUrl != null && backendPaymentUrl.isNotEmpty) {
            pendingPaymentUrl = backendPaymentUrl;
          }
        } else if (details?["has_pending_payment"] != true) {
          pendingPaymentReference = null;
          pendingPaymentUrl = null;
        }

        _pendingItemUrls.clear();
        final backendItems = myItems?["items"] as List? ?? const [];
        for (final rawItem in backendItems) {
          if (rawItem is! Map) continue;
          final itemId = (rawItem["item_id"] as num?)?.toInt();
          final itemStatus = rawItem["item_payment_status"]?.toString();
          final itemPaymentUrl =
              rawItem["item_payment_authorization_url"]?.toString();
          if (itemId != null &&
              itemStatus == "pending" &&
              itemPaymentUrl != null &&
              itemPaymentUrl.isNotEmpty) {
            _pendingItemUrls[itemId] = itemPaymentUrl;
          }
        }
      });

      final hasPending =
          details?["has_pending_payment"] == true ||
          pendingPaymentReference != null;
      final hasItemPending =
          (myItems?["items"] as List? ?? []).any(
            (i) => i is Map && i["item_payment_status"] == "pending",
          );

      if (hasPending || hasItemPending) {
        _startPolling();
      } else {
        _stopPolling();
      }
    } catch (e) {
      if (!silent && mounted) setState(() => error = e.toString());
    } finally {
      if (mounted && !silent) setState(() => isLoading = false);
    }
  }

  Future<void> logout() async {
    _stopPolling();

    // Start server-side revocation immediately, but do not make the user stare
    // at the lobby while a slow/cold network request finishes. This is SPA
    // navigation, so the revocation request can continue after we show Login.
    unawaited(
      AuthService.logout(widget.token).catchError((_) {}),
    );

    await SessionService.clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _tryAutoRelogin() async {
    if (!mounted) return;

    // Never replay a stored password. If the server says the bearer session is
    // expired or revoked, clear it locally and require a normal login.
    await SessionService.clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> openVerifyScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VerifyPauScreen(token: widget.token)),
    );
    if (result == true) unawaited(loadAll(silent: true));
  }

  Future<void> openAdminDashboard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminDashboardScreen(token: widget.token),
      ),
    );
    unawaited(loadAll(silent: true));
  }

  Future<void> startEntryFeePayment() async {
    setState(() => isBusy = true);
    try {
      final response =
          await LobbyService.initializeEntryFeePayment(widget.token);
      final reference = response["reference"]?.toString();
      final authUrl = response["authorization_url"]?.toString();

      setState(() {
        pendingPaymentReference = reference;
        pendingPaymentUrl = authUrl;
      });

      if (authUrl != null && authUrl.isNotEmpty) {
        _startPolling();
        final launched = await _openPaymentUrl(authUrl);
        showMessage(
          launched
              ? "Flutterwave opened. Pay, then tap ‘I've Paid’ when you return."
              : "Could not open the payment page. Use ‘Open Flutterwave’ below to try again.",
          isWarning: !launched,
        );
      }
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> verifyEntryFeePayment() async {
    final reference = pendingPaymentReference;
    if (reference == null || reference.isEmpty) {
      showMessage("No pending payment found. Try refreshing.");
      return;
    }

    setState(() => isBusy = true);
    try {
      final response = await LobbyService.verifyEntryFeePayment(
        widget.token,
        reference: reference,
      );

      if (response["status"]?.toString() == "success") {
        setState(() {
          pendingPaymentReference = null;
          pendingPaymentUrl = null;
        });
        _stopPolling();
        showMessage(
          "Payment confirmed! You've joined the lobby.",
          isSuccess: true,
        );
      } else {
        showMessage(
          response["message"]?.toString() ??
              "Payment not confirmed yet. Try again in a moment.",
          isWarning: true,
        );
      }
      await loadAll();
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> reopenPaymentLink() async {
    // Ask the backend for the authoritative checkout every time. A fresh
    // pending checkout is restored; an expired checkout is safely reconciled
    // with Flutterwave and replaced with a new reference/link when appropriate.
    setState(() => isBusy = true);
    try {
      final response =
          await LobbyService.initializeEntryFeePayment(widget.token);
      final reference = response["reference"]?.toString();
      final authUrl = response["authorization_url"]?.toString();

      if (authUrl == null || authUrl.isEmpty) {
        await loadAll();
        showMessage(
          "Flutterwave did not return a checkout link. Try again in a moment.",
          isWarning: true,
        );
        return;
      }

      if (mounted) {
        setState(() {
          pendingPaymentReference = reference;
          pendingPaymentUrl = authUrl;
        });
      }

      _startPolling();
      final launched = await _openPaymentUrl(authUrl);
      if (!launched) {
        showMessage(
          "Could not open Flutterwave. Try the checkout button again.",
          isWarning: true,
        );
      }
      await loadAll();
    } catch (e) {
      await loadAll();
      final message = e.toString().replaceFirst("Exception: ", "");
      final recovered = message.toLowerCase().contains("already completed");
      showMessage(
        message,
        isSuccess: recovered,
        isWarning: !recovered,
      );
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> leaveLobby() async {
    final confirmed = await _showConfirmationSheet(
      icon: Icons.exit_to_app_rounded,
      color: UniCartColors.danger,
      title: "Leave this lobby?",
      message:
          "Your entry fee is non-refundable. Unpaid items will be removed and you will need to pay again to rejoin.",
      confirmLabel: "Leave lobby",
    );

    if (confirmed != true) return;

    setState(() => isBusy = true);
    try {
      final response = await LobbyService.leaveLobby(widget.token);
      await loadAll();
      showMessage(response["message"]?.toString() ?? "Left lobby.");
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> addItem() async {
    final amountRaw = double.tryParse(itemAmountController.text.trim());
    final amount = amountRaw != null
        ? double.parse(amountRaw.toStringAsFixed(2))
        : null;
    final itemLink = itemLinkController.text.trim();

    if (itemLink.isEmpty || amount == null || amount <= 0) {
      showMessage("Enter a valid product link and guest price.");
      return;
    }

    final parsedLink = Uri.tryParse(itemLink);
    final hasValidWebScheme = parsedLink != null &&
        (parsedLink.scheme == "https" || parsedLink.scheme == "http") &&
        parsedLink.host.isNotEmpty;
    if (!hasValidWebScheme) {
      showMessage(
        "Paste the full product URL, including https:// (for example: https://www.temu.com/...).",
        isWarning: true,
      );
      return;
    }

    setState(() => isBusy = true);
    try {
      final response = await LobbyService.addItem(
        widget.token,
        itemLink: itemLink,
        itemAmount: amount.toInt(),
      );
      itemLinkController.clear();
      itemAmountController.clear();
      await loadAll();
      showMessage(
        response["message"]?.toString() ??
            "Item added. Pay for it to lock it in.",
        isSuccess: true,
      );
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> removeItem(int itemId) async {
    setState(() => isBusy = true);
    try {
      final response =
          await LobbyService.removeItem(widget.token, itemId: itemId);
      await loadAll();
      showMessage(response["message"]?.toString() ?? "Item removed.");
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> payForItem(int itemId) async {
    final confirmed = await _showGuestPriceSheet();
    if (confirmed != true) return;

    setState(() => isBusy = true);
    try {
      final response = await LobbyService.initializeItemPayment(
        widget.token,
        itemId: itemId,
      );
      final authUrl = response["authorization_url"]?.toString();

      if (authUrl != null && authUrl.isNotEmpty) {
        setState(() => _pendingItemUrls[itemId] = authUrl);
        _startPolling();
        final launched = await _openPaymentUrl(authUrl);
        showMessage(
          launched
              ? "Flutterwave opened. Return here and verify the payment when you're done."
              : "Could not open Flutterwave. Use the Open Flutterwave action on the item.",
          isWarning: !launched,
        );
      }
      await loadAll();
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> verifyItemPayment(String reference) async {
    setState(() => isBusy = true);
    try {
      final response = await LobbyService.verifyItemPayment(
        widget.token,
        reference: reference,
      );
      await loadAll();
      final paid = response["payment_status"]?.toString() == "paid";
      showMessage(
        paid
            ? "Item locked in!"
            : response["message"]?.toString() ?? "Not confirmed yet.",
        isSuccess: paid,
        isWarning: !paid,
      );
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
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

  Future<bool?> _showConfirmationSheet({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
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
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.26)),
                  ),
                  child: Icon(icon, color: color, size: 23),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: UniCartColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: UniCartColors.textSecondary,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: UniCartPrimaryButton(
                        outlined: true,
                        accentColor: UniCartColors.textSecondary,
                        minHeight: 50,
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: UniCartPrimaryButton(
                        accentColor: color,
                        minHeight: 50,
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: Text(confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showGuestPriceSheet() {
    const checks = [
      "I browsed this product while logged out of Temu.",
      "I used a private or incognito window.",
      "The submitted amount matches the guest price I saw.",
      "I understand item payments are non-refundable.",
    ];

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
                    icon: Icons.shield_outlined,
                    label: "Payment check",
                    color: UniCartColors.warning,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Confirm the guest price",
                    style: TextStyle(
                      color: UniCartColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    "UniCart standardises items using the logged-out guest price. Confirm every point below before paying.",
                    style: TextStyle(
                      color: UniCartColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...checks.map(
                    (check) => Padding(
                      padding: const EdgeInsets.only(bottom: 11),
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
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              check,
                              style: const TextStyle(
                                color: UniCartColors.textPrimary,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const UniCartInfoBanner(
                    color: UniCartColors.danger,
                    icon: Icons.gavel_rounded,
                    title: "No-refund policy",
                    message:
                        "A personalised or fabricated price is a policy violation and may be removed without refund.",
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: UniCartPrimaryButton(
                          outlined: true,
                          accentColor: UniCartColors.textSecondary,
                          minHeight: 50,
                          onPressed: () => Navigator.pop(sheetContext, false),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: UniCartPrimaryButton(
                          minHeight: 50,
                          onPressed: () => Navigator.pop(sheetContext, true),
                          child: const Text("Price is correct — Pay"),
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
    final isVerified = meData?["is_student_verified"] == true;
    final isAdmin = meData?["is_admin"] == true;
    final studentEmail = meData?["student_pau_email"]?.toString();
    final accountEmail = meData?["email"]?.toString() ??
        (isLoading ? "Loading…" : "Connecting…");

    final rawItems = (myItemsData?["items"] as List?) ?? [];
    final activeItems = rawItems
        .where(
          (i) => i is Map<String, dynamic> && i["is_active"] == true,
        )
        .cast<Map<String, dynamic>>()
        .toList();

    final historyBatches =
        ((myHistoryData?["batches"] as List?) ?? [])
            .cast<Map<String, dynamic>>();
    final hasJoined = mainDetailsData?["has_joined"] == true;
    final hasPendingPayment =
        mainDetailsData?["has_pending_payment"] == true ||
        pendingPaymentReference != null;
    final entryFeeAmount = mainDetailsData?["entry_fee_amount"] ?? 2000;

    final progress = (lobby == null || lobby!.targetItemAmount == 0)
        ? 0.0
        : (lobby!.currentItemAmount / lobby!.targetItemAmount)
            .clamp(0.0, 1.0);

    return Scaffold(
      body: UniCartBackdrop(
        safeArea: false,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: isLoading
                    ? const _LobbyLoadingState()
                    : RefreshIndicator(
                        color: UniCartColors.primarySoft,
                        backgroundColor: UniCartColors.surfaceRaised,
                        onRefresh: loadAll,
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
                                            title: "Could not refresh everything",
                                            message: error,
                                          ),
                                          const SizedBox(height: 14),
                                        ],
                                        _buildVaultHero(progress),
                                        const SizedBox(height: 14),
                                        _buildMetrics(),
                                        const SizedBox(height: 14),
                                        _responsivePair(
                                          constraints.maxWidth,
                                          _buildAccountCard(
                                            accountEmail: accountEmail,
                                            studentEmail: studentEmail,
                                            isVerified: isVerified,
                                            isAdmin: isAdmin,
                                          ),
                                          _buildLobbyAccessCard(
                                            isVerified: isVerified,
                                            hasJoined: hasJoined,
                                            hasPendingPayment:
                                                hasPendingPayment,
                                            entryFeeAmount: entryFeeAmount,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        _buildAddItemCard(hasJoined),
                                        const SizedBox(height: 14),
                                        _buildItemsCard(activeItems),
                                        const SizedBox(height: 14),
                                        _buildHistoryCard(historyBatches),
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
          const UniCartLogoMark(size: 38),
          const SizedBox(width: 11),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "UniCart",
                style: TextStyle(
                  color: UniCartColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.45,
                ),
              ),
              Text(
                "Campus group buying",
                style: TextStyle(
                  color: UniCartColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_pollTimer != null) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
          ],
          UniCartIconButton(
            icon: Icons.refresh_rounded,
            tooltip: "Refresh",
            onPressed: isLoading ? null : loadAll,
          ),
          const SizedBox(width: 8),
          UniCartIconButton(
            icon: Icons.logout_rounded,
            tooltip: "Log out",
            foregroundColor: UniCartColors.danger,
            onPressed: logout,
          ),
        ],
      ),
    );
  }

  Widget _buildVaultHero(double progress) {
    final status = lobby?.status ?? "open";
    final statusColor = _lobbyStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102657), Color(0xFF091634), Color(0xFF0B1220)],
        ),
        borderRadius: BorderRadius.circular(UniCartRadius.xxl),
        border: Border.all(
          color: UniCartColors.primaryBright.withValues(alpha: 0.30),
        ),
        boxShadow: const [
          BoxShadow(
            color: UniCartColors.primaryGlow,
            blurRadius: 34,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const UniCartEyebrow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: "Live vault",
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Lobby #${lobby?.lobbyId ?? "—"}",
                      style: const TextStyle(
                        color: UniCartColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Pay together. Reach the target. Move the batch forward.",
                      style: TextStyle(
                        color: UniCartColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              UniCartStatusPill(
                label: _prettyStatus(status),
                color: statusColor,
                icon: _statusIcon(status),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "₦${lobby?.currentItemAmount ?? 0}",
                style: const TextStyle(
                  color: UniCartColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                "${(progress * 100).toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: UniCartColors.primarySoft,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFF0A1630),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  UniCartColors.primaryBright,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            "Target ₦${lobby?.targetItemAmount ?? 0}",
            style: const TextStyle(
              color: UniCartColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    final itemCount = myItemsData?["item_count"] ?? 0;
    final myTotal = myItemsData?["total_item_amount"] ?? 0;
    final remaining = ((lobby?.targetItemAmount ?? 0) -
            (lobby?.currentItemAmount ?? 0))
        .clamp(0, 1 << 31);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        if (compact) {
          return Row(
            children: [
              Expanded(
                child: UniCartMetricCard(
                  label: "Remaining",
                  value: "₦$remaining",
                  caption: "To trigger",
                  icon: Icons.flag_outlined,
                  accent: UniCartColors.primarySoft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: UniCartMetricCard(
                  label: "My items",
                  value: "$itemCount",
                  caption: "In the batch",
                  icon: Icons.inventory_2_outlined,
                  accent: UniCartColors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: UniCartMetricCard(
                  label: "My paid",
                  value: "₦$myTotal",
                  caption: "Locked total",
                  icon: Icons.payments_outlined,
                  accent: UniCartColors.success,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: UniCartMetricCard(
                label: "Remaining",
                value: "₦$remaining",
                caption: "Needed before this batch triggers",
                icon: Icons.flag_outlined,
                accent: UniCartColors.primarySoft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: UniCartMetricCard(
                label: "My items",
                value: "$itemCount",
                caption: "Your items in the current lobby",
                icon: Icons.inventory_2_outlined,
                accent: UniCartColors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: UniCartMetricCard(
                label: "My paid total",
                value: "₦$myTotal",
                caption: "Value already locked into the vault",
                icon: Icons.payments_outlined,
                accent: UniCartColors.success,
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

  Widget _buildAccountCard({
    required String accountEmail,
    required String? studentEmail,
    required bool isVerified,
    required bool isAdmin,
  }) {
    return UniCartPanel(
      color: UniCartColors.surface.withValues(alpha: 0.92),
      borderColor: UniCartColors.border.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UniCartSectionTitle(
            title: "Your account",
            subtitle: "Identity and campus access",
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A6E), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: UniCartColors.primaryBright.withValues(alpha: 0.34),
                  ),
                ),
                child: Text(
                  accountEmail.isNotEmpty
                      ? accountEmail[0].toUpperCase()
                      : "U",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accountEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: UniCartColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (studentEmail != null && studentEmail.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        isVerified
                            ? studentEmail
                            : "$studentEmail · pending verification",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: UniCartColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        UniCartStatusPill(
                          label: isVerified ? "PAU verified" : "Not verified",
                          color: isVerified
                              ? UniCartColors.success
                              : UniCartColors.warning,
                          icon: isVerified
                              ? Icons.verified_rounded
                              : Icons.school_outlined,
                        ),
                        if (isAdmin)
                          const UniCartStatusPill(
                            label: "Admin",
                            color: UniCartColors.purple,
                            icon: Icons.admin_panel_settings_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          UniCartPrimaryButton(
            outlined: true,
            accentColor: UniCartColors.primarySoft,
            leadingIcon: Icons.school_outlined,
            minHeight: 48,
            onPressed: isBusy ? null : openVerifyScreen,
            child: Text(
              isVerified ? "Update PAU verification" : "Verify PAU email",
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 9),
            UniCartPrimaryButton(
              accentColor: UniCartColors.purple,
              leadingIcon: Icons.admin_panel_settings_outlined,
              minHeight: 48,
              onPressed: isBusy ? null : openAdminDashboard,
              child: const Text("Open admin dashboard"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLobbyAccessCard({
    required bool isVerified,
    required bool hasJoined,
    required bool hasPendingPayment,
    required dynamic entryFeeAmount,
  }) {
    return UniCartPanel(
      color: UniCartColors.surface.withValues(alpha: 0.92),
      borderColor: UniCartColors.border.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UniCartSectionTitle(
            title: "Lobby access",
            subtitle: "Pay the entry fee once to unlock this batch",
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniInfo("Lobby", "#${lobby?.lobbyId ?? "—"}"),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniInfo("Status", _prettyStatus(lobby?.status ?? "—")),
              ),
              const SizedBox(width: 8),
              Expanded(child: _miniInfo("Entry fee", "₦$entryFeeAmount")),
            ],
          ),
          const SizedBox(height: 16),
          if (!isVerified)
            const UniCartInfoBanner(
              color: UniCartColors.warning,
              icon: Icons.lock_outline_rounded,
              title: "PAU verification required",
              message: "Verify your university email before joining a lobby.",
            )
          else if (hasJoined)
            const UniCartInfoBanner(
              color: UniCartColors.success,
              icon: Icons.check_circle_rounded,
              title: "You are in this lobby",
              message: "Add items below and pay for each one you want locked into the batch.",
            )
          else if (hasPendingPayment) ...[
            UniCartInfoBanner(
              color: UniCartColors.primarySoft,
              icon: Icons.hourglass_bottom_rounded,
              title: "Entry payment pending",
              message: pendingPaymentReference == null
                  ? "Complete the Flutterwave payment and confirm it here."
                  : "Reference: $pendingPaymentReference",
            ),
            const SizedBox(height: 12),
            UniCartPrimaryButton(
              leadingIcon: Icons.verified_rounded,
              loading: isBusy,
              onPressed: isBusy ? null : verifyEntryFeePayment,
              child: const Text("I've Paid — Confirm now"),
            ),
            const SizedBox(height: 9),
            UniCartPrimaryButton(
              outlined: true,
              accentColor: UniCartColors.primarySoft,
              leadingIcon: Icons.open_in_new_rounded,
              minHeight: 48,
              onPressed: isBusy ? null : reopenPaymentLink,
              child: const Text("Refresh / reopen Flutterwave"),
            ),
          ] else
            UniCartPrimaryButton(
              leadingIcon: Icons.credit_card_rounded,
              loading: isBusy,
              onPressed: isBusy || !isVerified ? null : startEntryFeePayment,
              child: Text("Pay ₦$entryFeeAmount to join"),
            ),
          if (hasJoined) ...[
            const SizedBox(height: 10),
            UniCartPrimaryButton(
              outlined: true,
              accentColor: UniCartColors.danger,
              leadingIcon: Icons.exit_to_app_rounded,
              minHeight: 48,
              onPressed: isBusy ? null : leaveLobby,
              child: const Text("Leave lobby"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddItemCard(bool hasJoined) {
    return UniCartPanel(
      color: UniCartColors.surface.withValues(alpha: 0.92),
      borderColor: UniCartColors.border.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UniCartSectionTitle(
            title: "Add an item",
            subtitle: "Submit the guest price, then pay to lock the item into the vault",
          ),
          const SizedBox(height: 16),
          const UniCartInfoBanner(
            color: UniCartColors.warning,
            icon: Icons.visibility_off_outlined,
            title: "Use guest pricing",
            message:
                "Log out of Temu or use a private/incognito window. Submit the price visible to a guest — not a personalised price.",
          ),
          const SizedBox(height: 10),
          const UniCartInfoBanner(
            color: UniCartColors.danger,
            icon: Icons.gavel_rounded,
            title: "Item payments are non-refundable",
            message:
                "Items removed for fraudulent prices or policy violations will not be refunded.",
          ),
          const SizedBox(height: 16),
          TextField(
            controller: itemLinkController,
            style: const TextStyle(color: UniCartColors.textPrimary),
            decoration: const InputDecoration(
              labelText: "Product link",
              hintText: "https://…",
              prefixIcon: Icon(Icons.link_rounded),
              helperText: "Open the product as a logged-out guest before checking its price.",
              helperStyle: TextStyle(
                color: UniCartColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: itemAmountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: UniCartColors.textPrimary),
            decoration: const InputDecoration(
              labelText: "Guest price (₦)",
              hintText: "e.g. 8500",
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 16),
          UniCartPrimaryButton(
            leadingIcon: Icons.add_rounded,
            loading: isBusy,
            onPressed: isBusy || !hasJoined ? null : addItem,
            child: const Text("Add item"),
          ),
          if (!hasJoined) ...[
            const SizedBox(height: 9),
            const Text(
              "Join the lobby first to add items.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: UniCartColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard(List<Map<String, dynamic>> activeItems) {
    return UniCartPanel(
      color: UniCartColors.surface.withValues(alpha: 0.92),
      borderColor: UniCartColors.border.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UniCartSectionTitle(
            title: "My active items",
            subtitle:
                "Only paid items are locked in. Unpaid items are removed when the batch triggers.",
            trailing: activeItems.isEmpty
                ? null
                : UniCartStatusPill(
                    label:
                        "${activeItems.length} item${activeItems.length == 1 ? "" : "s"}",
                    color: UniCartColors.primarySoft,
                    icon: Icons.inventory_2_outlined,
                  ),
          ),
          const SizedBox(height: 16),
          if (activeItems.isEmpty)
            _emptyState(
              icon: Icons.shopping_bag_outlined,
              title: "No active items yet",
              message: "Add a product above and pay for it to lock it into the batch.",
            )
          else
            ...activeItems.map(_buildItemTile),
        ],
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    final itemId = item["item_id"] as int;
    final itemLink = item["item_link"]?.toString() ?? "";
    final itemAmount = item["item_amount"] ?? 0;
    final paymentStatus = item["item_payment_status"]?.toString() ?? "unpaid";
    final isLocked = item["is_locked"] == true;
    final isPaid = item["is_paid"] == true;
    final reference = item["item_payment_reference"]?.toString();

    final accent = isPaid
        ? UniCartColors.success
        : paymentStatus == "pending"
            ? UniCartColors.warning
            : UniCartColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: UniCartColors.surfaceRaised,
        borderRadius: BorderRadius.circular(UniCartRadius.lg),
        border: Border.all(
          color: accent == UniCartColors.border
              ? UniCartColors.border
              : accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: UniCartColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPaid ? Icons.lock_rounded : Icons.shopping_bag_outlined,
                  size: 19,
                  color: isPaid
                      ? UniCartColors.success
                      : UniCartColors.primarySoft,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemLink,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: UniCartColors.textPrimary,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "₦$itemAmount",
                      style: const TextStyle(
                        color: UniCartColors.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _paymentStatusPill(paymentStatus, isPaid),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!isLocked)
                _itemAction(
                  label: "Pay for item",
                  icon: Icons.payment_rounded,
                  color: UniCartColors.primarySoft,
                  onTap: isBusy ? null : () => payForItem(itemId),
                ),
              if (paymentStatus == "pending" && reference != null) ...[
                _itemAction(
                  label: "Verify payment",
                  icon: Icons.verified_rounded,
                  color: UniCartColors.success,
                  onTap: isBusy
                      ? null
                      : () => verifyItemPayment(reference),
                ),
                _itemAction(
                  label: "Open Flutterwave",
                  icon: Icons.open_in_new_rounded,
                  color: UniCartColors.primarySoft,
                  onTap: isBusy
                      ? null
                      : () async {
                          final url = _pendingItemUrls[itemId];
                          if (url != null && url.isNotEmpty) {
                            await _openPaymentUrl(url);
                          } else {
                            await payForItem(itemId);
                          }
                        },
                ),
              ],
              if (!isLocked)
                _itemAction(
                  label: "Remove",
                  icon: Icons.delete_outline_rounded,
                  color: UniCartColors.danger,
                  onTap: isBusy ? null : () => removeItem(itemId),
                ),
              if (isPaid)
                const UniCartStatusPill(
                  label: "Locked in vault",
                  color: UniCartColors.success,
                  icon: Icons.lock_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemAction({
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

  Widget _buildHistoryCard(List<Map<String, dynamic>> batches) {
    return UniCartPanel(
      color: UniCartColors.surface.withValues(alpha: 0.92),
      borderColor: UniCartColors.border.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UniCartSectionTitle(
            title: "Batch history",
            subtitle: "Track batches you've participated in from trigger to delivery",
          ),
          const SizedBox(height: 16),
          if (batches.isEmpty)
            _emptyState(
              icon: Icons.history_rounded,
              title: "No batch history yet",
              message: "Triggered and completed batches will appear here.",
            )
          else
            ...batches.map(_buildHistoryTile),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> batch) {
    final status = batch["status"]?.toString() ?? "";
    final color = _lobbyStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: UniCartColors.surfaceRaised,
        borderRadius: BorderRadius.circular(UniCartRadius.lg),
        border: Border.all(color: UniCartColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Batch #${batch["lobby_id"]}",
                  style: const TextStyle(
                    color: UniCartColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              UniCartStatusPill(
                label: _prettyStatus(status),
                color: color,
                icon: _statusIcon(status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _statusDescription(status),
            style: const TextStyle(
              color: UniCartColors.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          _buildBatchProgress(status),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _softInfo(
                "Final ₦${batch["final_item_amount"]} / ₦${batch["target_item_amount"]}",
              ),
              _softInfo("My items ${batch["my_item_count"]}"),
              _softInfo("My total ₦${batch["my_total_item_amount"]}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatchProgress(String status) {
    const stages = ["triggered", "processing", "in_transit", "completed"];
    final currentIndex = stages.indexOf(status);

    return Row(
      children: List.generate(stages.length * 2 - 1, (index) {
        if (index.isOdd) {
          final leftStage = index ~/ 2;
          final done = currentIndex > leftStage;
          return Expanded(
            child: Container(
              height: 2,
              color: done
                  ? UniCartColors.success.withValues(alpha: 0.55)
                  : UniCartColors.divider,
            ),
          );
        }

        final stageIndex = index ~/ 2;
        final stage = stages[stageIndex];
        final done = currentIndex >= stageIndex;
        final color = done
            ? _lobbyStatusColor(stage)
            : UniCartColors.textMuted;

        return Tooltip(
          message: _prettyStatus(stage),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: done ? 0.14 : 0.07),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.32)),
            ),
            child: Icon(_statusIcon(stage), size: 14, color: color),
          ),
        );
      }),
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

  Widget _softInfo(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: UniCartColors.surfaceSoft.withValues(alpha: 0.72),
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

  Widget _paymentStatusPill(String status, bool isPaid) {
    if (isPaid || status == "paid") {
      return const UniCartStatusPill(
        label: "Paid & locked",
        color: UniCartColors.success,
        icon: Icons.lock_rounded,
      );
    }
    if (status == "pending") {
      return const UniCartStatusPill(
        label: "Pending",
        color: UniCartColors.warning,
        icon: Icons.hourglass_bottom_rounded,
      );
    }
    if (status == "failed" || status == "abandoned") {
      return const UniCartStatusPill(
        label: "Failed",
        color: UniCartColors.danger,
        icon: Icons.error_outline_rounded,
      );
    }
    return const UniCartStatusPill(
      label: "Unpaid",
      color: UniCartColors.textSecondary,
      icon: Icons.radio_button_unchecked_rounded,
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

  String _prettyStatus(String status) {
    return const {
          "triggered": "Target reached",
          "processing": "Processing",
          "in_transit": "In transit",
          "completed": "Delivered",
          "open": "Open",
        }[status] ??
        status;
  }

  String _statusDescription(String status) {
    return const {
          "triggered": "The vault reached its target. Admin is preparing the group order.",
          "processing": "The group order is being reviewed and placed.",
          "in_transit": "The batch is on its way.",
          "completed": "This batch has been delivered.",
        }[status] ??
        "Batch status update.";
  }

  Color _lobbyStatusColor(String status) {
    return const {
          "triggered": UniCartColors.warning,
          "processing": UniCartColors.primarySoft,
          "in_transit": UniCartColors.purple,
          "completed": UniCartColors.success,
          "open": UniCartColors.success,
        }[status] ??
        UniCartColors.textSecondary;
  }

  IconData _statusIcon(String status) {
    return const {
          "triggered": Icons.flag_outlined,
          "processing": Icons.inventory_2_outlined,
          "in_transit": Icons.local_shipping_outlined,
          "completed": Icons.check_circle_outline,
          "open": Icons.lock_open_rounded,
        }[status] ??
        Icons.info_outline_rounded;
  }
}

class _LobbyLoadingState extends StatelessWidget {
  const _LobbyLoadingState();

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
            "Loading your lobby",
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
