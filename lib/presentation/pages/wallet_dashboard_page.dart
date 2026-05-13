import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'transaction_detail_page.dart';

class WalletDashboardPage extends StatelessWidget {
  const WalletDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome back', style: TextStyle(color: Colors.black38, fontSize: 14)),
            const Text('My Wallet', style: TextStyle(color: Color(0xFF1E293B), fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            _buildBalanceCard(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildMiniStat('Income', '\$4,280', LucideIcons.arrowDownLeft, Colors.emerald)),
                const SizedBox(width: 16),
                Expanded(child: _buildMiniStat('Spending', '\$1,940', LucideIcons.arrowUpRight, Colors.redAccent)),
              ],
            ),
            const SizedBox(height: 24),
            _buildWeeklyActivity(),
            const SizedBox(height: 24),
            _buildBiometricBanner(),
            const SizedBox(height: 24),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black12)),
          child: IconButton(icon: const Icon(LucideIcons.shieldCheck, color: Color(0xFF1E293B), size: 20), onPressed: () {}),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF15191C), borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Balance', style: TextStyle(color: Colors.white60, fontSize: 14)),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(LucideIcons.fingerprint, color: Colors.emerald, size: 20)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('\$12,480.90', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildPill('Available funds', Colors.white.withOpacity(0.1), Colors.white),
              const SizedBox(width: 12),
              _buildPill('+3.8% this month', Colors.emerald.withOpacity(0.2), Colors.emerald),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Weekly activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: const Text('This week', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar('Mon', 0.4), _buildBar('Tue', 0.7), _buildBar('Wed', 0.5), _buildBar('Thu', 0.9), _buildBar('Fri', 0.6), _buildBar('Sat', 0.8), _buildBar('Sun', 0.5),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double height) {
    return Column(
      children: [
        Container(width: 32, height: 100 * height, decoration: BoxDecoration(color: Colors.emerald, borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBiometricBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.emerald, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(LucideIcons.fingerprint, color: Colors.white, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Biometric authentication', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Face ID enabled for payments.', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.emerald, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionDetailPage())), child: const Text('View all', style: TextStyle(color: Colors.emerald, fontWeight: FontWeight.bold))),
          ],
        ),
        _buildActivityItem('Apple Services', 'Today • 8:42 AM', '-\$12.99', Colors.redAccent),
        _buildActivityItem('Salary Deposit', 'Yesterday • 9:12 AM', '+\$2,800', Colors.emerald),
      ],
    );
  }

  Widget _buildActivityItem(String title, String sub, String amount, Color amountCol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(16)), child: const Icon(LucideIcons.shoppingBag, size: 18)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(sub, style: const TextStyle(color: Colors.black38, fontSize: 11))])),
          Text(amount, style: TextStyle(color: amountCol, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
