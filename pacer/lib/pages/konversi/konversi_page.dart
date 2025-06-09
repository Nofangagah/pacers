import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

enum PaymentStatus { none, pending, success, failed }

class _MembershipPageState extends State<MembershipPage> {
  String selectedCurrency = 'IDR';
  Map<String, double> exchangeRates = {};
  bool isLoading = true;
  double basePriceIDR = 160000;
  
  // Payment state
  bool showPayment = false;
  bool showPaymentSuccess = false;
  bool showPaymentFailed = false;
  bool showPaymentProcessing = false;
  String selectedPaymentMethod = 'Credit Card';
  String transactionId = '';
  String paymentError = '';
  
  // Membership state
  bool isPremiumMember = false;
  bool isStandardMember = false;
  DateTime? membershipExpiry;
  String selectedPlan = 'Premium';
  bool isRenewal = false;

  // Scheduled payment
  DateTime? selectedPaymentDate;
  TimeOfDay? selectedPaymentTime;
  String selectedTimeZone = 'Asia/Jakarta';
  bool isScheduledPayment = false;

  // Payment status
  PaymentStatus paymentStatus = PaymentStatus.none;
  List<Map<String, dynamic>> scheduledPayments = [];

  final List<String> currencies = ['IDR', 'USD', 'EUR', 'JPY', 'GBP', 'AUD'];
  final List<String> paymentMethods = ['Credit Card', 'Bank Transfer', 'E-Wallet', 'Virtual Account'];
  
  final List<Map<String, String>> timeZones = [
    {'location': 'Jakarta', 'zone': 'Asia/Jakarta'},
    {'location': 'Tokyo', 'zone': 'Asia/Tokyo'},
    {'location': 'London', 'zone': 'Europe/London'},
    {'location': 'New York', 'zone': 'America/New_York'},
    {'location': 'Sydney', 'zone': 'Australia/Sydney'},
  ];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    fetchExchangeRates();
    transactionId = 'TRX-${DateTime.now().millisecondsSinceEpoch}';
    _loadMembershipStatus();
    _loadScheduledPayments();
  }

  Future<void> _loadMembershipStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isPremiumMember = prefs.getBool('isPremiumMember') ?? false;
      isStandardMember = prefs.getBool('isStandardMember') ?? false;
      membershipExpiry = DateTime.tryParse(prefs.getString('membershipExpiry') ?? '');
      
      if (membershipExpiry != null && membershipExpiry!.isBefore(DateTime.now())) {
        isPremiumMember = false;
        isStandardMember = false;
        _saveMembershipStatus(false, false);
      }
    });
  }

  Future<void> _saveMembershipStatus(bool premium, bool standard) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremiumMember', premium);
    await prefs.setBool('isStandardMember', standard);
    
    final newExpiry = membershipExpiry != null && membershipExpiry!.isAfter(DateTime.now()) && isRenewal
        ? membershipExpiry!.add(const Duration(days: 30))
        : DateTime.now().add(const Duration(days: 30));
    
    await prefs.setString('membershipExpiry', newExpiry.toIso8601String());
    
    setState(() {
      isPremiumMember = premium;
      isStandardMember = standard;
      membershipExpiry = newExpiry;
      isRenewal = false;
    });
  }

  Future<void> _cancelMembership() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremiumMember', false);
    await prefs.setBool('isStandardMember', false);
    await prefs.remove('membershipExpiry');
    
    setState(() {
      isPremiumMember = false;
      isStandardMember = false;
      membershipExpiry = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membership cancelled successfully')),
    );
  }

  Future<void> fetchExchangeRates() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/IDR'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          exchangeRates = data['rates'] ?? {};
          exchangeRates['IDR'] = 1.0;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load exchange rates");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        exchangeRates = {
          'IDR': 1.0,
          'USD': 0.000062,
          'EUR': 0.000057,
          'JPY': 0.0093,
          'GBP': 0.000049,
          'AUD': 0.000094,
        };
        isLoading = false;
      });
    }
  }

  Future<void> _loadScheduledPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final payments = prefs.getStringList('scheduledPayments') ?? [];
    
    setState(() {
      scheduledPayments = payments.map((p) => jsonDecode(p) as Map<String, dynamic>).toList();
      
      // Check for any pending payments that should have been processed
      final now = DateTime.now();
      for (var payment in scheduledPayments) {
        final scheduledTime = DateTime.parse(payment['scheduledTime']);
        if (scheduledTime.isBefore(now)) {
          if (payment['status'] == 'pending') {
            _processScheduledPayment(payment);
          }
        }
      }
    });
  }

  void startPaymentProcess(String plan) {
    selectedPaymentDate = null;
    selectedPaymentTime = null;
    isScheduledPayment = false;
    
    setState(() {
      showPayment = true;
      showPaymentFailed = false;
      showPaymentSuccess = false;
      selectedPlan = plan;
      isRenewal = isPremiumMember || isStandardMember;
      transactionId = 'TRX-${DateTime.now().millisecondsSinceEpoch}';
      paymentStatus = PaymentStatus.none;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedPaymentDate) {
      setState(() {
        selectedPaymentDate = picked;
        isScheduledPayment = true;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedPaymentTime = picked;
        isScheduledPayment = true;
      });
    }
  }

  String _formatScheduledPayment() {
    if (selectedPaymentDate == null || selectedPaymentTime == null) {
      return 'No schedule set';
    }
    
    final scheduledDate = DateTime(
      selectedPaymentDate!.year,
      selectedPaymentDate!.month,
      selectedPaymentDate!.day,
      selectedPaymentTime!.hour,
      selectedPaymentTime!.minute,
    );
    
    return DateFormat('dd MMM yyyy HH:mm').format(scheduledDate) + 
           ' ($selectedTimeZone)';
  }

  void _schedulePayment() {
    if (selectedPaymentDate == null || selectedPaymentTime == null) {
      setState(() {
        showPaymentFailed = true;
        paymentError = 'Please select both date and time for payment';
      });
      return;
    }

    final now = DateTime.now();
    final scheduledDateTime = DateTime(
      selectedPaymentDate!.year,
      selectedPaymentDate!.month,
      selectedPaymentDate!.day,
      selectedPaymentTime!.hour,
      selectedPaymentTime!.minute,
    );

    if (scheduledDateTime.isBefore(now)) {
      setState(() {
        showPaymentFailed = true;
        paymentError = 'Scheduled time must be in the future';
      });
      return;
    }

    final amount = selectedPlan == 'Premium' ? getConvertedPrice() : getConvertedPrice() * 0.7;
    
    final newPayment = {
      'id': 'TRX-${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount,
      'currency': selectedCurrency,
      'plan': selectedPlan,
      'scheduledTime': scheduledDateTime.toIso8601String(),
      'status': 'pending',
      'timeZone': selectedTimeZone,
      'paymentMethod': selectedPaymentMethod,
    };

    setState(() {
      scheduledPayments.add(newPayment);
      paymentStatus = PaymentStatus.pending;
      showPayment = false;
      transactionId = newPayment['id'] as String;
    });

    _saveScheduledPayment(newPayment);

    final duration = scheduledDateTime.difference(now);
    Future.delayed(duration, () {
      if (mounted) {
        _processScheduledPayment(newPayment);
      }
    });
  }

  Future<void> _saveScheduledPayment(Map<String, dynamic> payment) async {
    final prefs = await SharedPreferences.getInstance();
    final payments = prefs.getStringList('scheduledPayments') ?? [];
    payments.add(jsonEncode(payment));
    await prefs.setStringList('scheduledPayments', payments);
  }

  void _processScheduledPayment(Map<String, dynamic> payment) {
    final willPaymentFail = (DateTime.now().millisecondsSinceEpoch % 5 == 0);
    
    if (willPaymentFail) {
      _handleScheduledPaymentFailure(payment);
    } else {
      _handleScheduledPaymentSuccess(payment);
    }
  }

  void _handleScheduledPaymentSuccess(Map<String, dynamic> payment) {
    setState(() {
      paymentStatus = PaymentStatus.success;
      showPaymentSuccess = true;
      
      final index = scheduledPayments.indexWhere((p) => p['id'] == payment['id']);
      if (index != -1) {
        scheduledPayments[index]['status'] = 'success';
        _updateScheduledPaymentStatus(payment['id'], 'success');
      }
      
      if (payment['plan'] == 'Premium') {
        _saveMembershipStatus(true, false);
      } else {
        _saveMembershipStatus(false, true);
      }
    });
  }

  void _handleScheduledPaymentFailure(Map<String, dynamic> payment) {
    setState(() {
      paymentStatus = PaymentStatus.failed;
      showPaymentFailed = true;
      paymentError = 'Scheduled payment failed. Payment time has passed without successful transaction.';
      
      final index = scheduledPayments.indexWhere((p) => p['id'] == payment['id']);
      if (index != -1) {
        scheduledPayments[index]['status'] = 'failed';
        _updateScheduledPaymentStatus(payment['id'], 'failed');
      }
    });
  }

  Future<void> _updateScheduledPaymentStatus(String id, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final payments = prefs.getStringList('scheduledPayments') ?? [];
    
    final updatedPayments = payments.map((p) {
      final payment = jsonDecode(p) as Map<String, dynamic>;
      if (payment['id'] == id) {
        payment['status'] = status;
        return jsonEncode(payment);
      }
      return p;
    }).toList();
    
    await prefs.setStringList('scheduledPayments', updatedPayments);
  }

  void _cancelScheduledPayment(String id) async {
    setState(() {
      scheduledPayments.removeWhere((p) => p['id'] == id);
      paymentStatus = PaymentStatus.none;
    });
    
    final prefs = await SharedPreferences.getInstance();
    final payments = prefs.getStringList('scheduledPayments') ?? [];
    final updatedPayments = payments.where((p) {
      final payment = jsonDecode(p) as Map<String, dynamic>;
      return payment['id'] != id;
    }).toList();
    
    await prefs.setStringList('scheduledPayments', updatedPayments);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scheduled payment cancelled')),
    );
  }

  void resetPayment() {
    setState(() {
      showPayment = false;
      showPaymentSuccess = false;
      showPaymentFailed = false;
      showPaymentProcessing = false;
      selectedPaymentDate = null;
      selectedPaymentTime = null;
      isScheduledPayment = false;
      paymentStatus = PaymentStatus.none;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String formatTime(String timeZone) {
    final location = tz.getLocation(timeZone);
    final now = tz.TZDateTime.now(location);
    return DateFormat('HH:mm:ss').format(now);
  }

  double getConvertedPrice() {
    if (selectedCurrency == 'IDR') return basePriceIDR;
    if (exchangeRates[selectedCurrency] == null) return basePriceIDR;
    return basePriceIDR * exchangeRates[selectedCurrency]!;
  }

  String formatCurrency(double amount, String currency) {
    if (currency == 'IDR') {
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    } else {
      return NumberFormat.simpleCurrency(
        name: currency,
        decimalDigits: 2,
      ).format(amount);
    }
  }

  Widget _buildPendingPayment() {
    final pendingPayment = scheduledPayments.firstWhere(
      (p) => p['status'] == 'pending',
      orElse: () => {},
    );
    
    if (pendingPayment.isEmpty) return const SizedBox();
    
    final scheduledTime = DateTime.parse(pendingPayment['scheduledTime']);
    final formattedTime = DateFormat('dd MMM yyyy HH:mm').format(scheduledTime);
    final formattedAmount = formatCurrency(pendingPayment['amount'], pendingPayment['currency']);
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Payment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Plan: ${pendingPayment['plan']} Membership',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Amount: $formattedAmount',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Payment Method: ${pendingPayment['paymentMethod']}',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Scheduled for: $formattedTime (${pendingPayment['timeZone']})',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, snapshot) {
              final now = DateTime.now();
              final remaining = scheduledTime.difference(now);
              
              return Text(
                remaining.isNegative 
                    ? 'Payment time has arrived'
                    : 'Time remaining: ${_formatDuration(remaining)}',
                style: TextStyle(
                  fontSize: 16,
                  color: remaining.isNegative ? Colors.amber : Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _cancelScheduledPayment(pendingPayment['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancel Scheduled Payment'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text(
            'Display prices in:',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          const Spacer(),
          DropdownButton<String>(
            dropdownColor: Colors.grey[900],
            value: selectedCurrency,
            items: currencies.map((currency) {
              return DropdownMenuItem<String>(
                value: currency,
                child: Text(
                  currency,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedCurrency = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipStatus() {
    if (!isPremiumMember && !isStandardMember) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isPremiumMember ? 'Premium Member' : 'Standard Member',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Icon(
                isPremiumMember ? Icons.star : Icons.verified_user,
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (membershipExpiry != null)
            Text(
              'Expires on: ${DateFormat('dd MMM yyyy').format(membershipExpiry!)}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _cancelMembership,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text('Cancel Membership'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => startPaymentProcess(isPremiumMember ? 'Premium' : 'Standard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text('Renew Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard({
    required String title,
    required List<String> benefits,
    required double price,
    required String currency,
    required bool isFeatured,
  }) {
    final formattedPrice = formatCurrency(price, currency);

    return Container(
      decoration: BoxDecoration(
        color: isFeatured ? Colors.blue[900] : Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFeatured ? Colors.blue : Colors.grey,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isFeatured ? Colors.white : Colors.amber,
                ),
              ),
              if (isFeatured) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formattedPrice,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'per month',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          ...benefits.map((benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    benefit,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isFeatured ? Colors.amber : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => startPaymentProcess(title),
              child: Text(
                'Subscribe Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isFeatured ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Membership Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '• Cancel anytime with no hidden fees',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            '• All subscriptions auto-renew unless canceled',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '• Prices shown in $selectedCurrency. Actual charge may vary slightly based on current exchange rates.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: fetchExchangeRates,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Refresh Exchange Rates',
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(double amount) {
    final requiredAmount = formatCurrency(amount, selectedCurrency);
    final requiredAmountIDR = formatCurrency(basePriceIDR, 'IDR');
    
    return Column(
      children: [
        const Text(
          'Schedule Your Payment',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Plan: $selectedPlan Membership ${isRenewal ? '(Renewal)' : ''}',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Amount: $requiredAmount',
          style: const TextStyle(
            fontSize: 20,
            color: Colors.amber,
          ),
        ),
        if (selectedCurrency != 'IDR') ...[
          const SizedBox(height: 4),
          Text(
            '($requiredAmountIDR in IDR)',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
        const SizedBox(height: 24),
        
        // Payment Schedule Section
        const Text(
          'Select Payment Date and Time:',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
              ),
              child: Text(
                selectedPaymentDate == null 
                    ? 'Select Date'
                    : DateFormat('dd/MM/yyyy').format(selectedPaymentDate!),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => _selectTime(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
              ),
              child: Text(
                selectedPaymentTime == null 
                    ? 'Select Time'
                    : selectedPaymentTime!.format(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButton<String>(
          value: selectedTimeZone,
          dropdownColor: Colors.grey[900],
          items: timeZones.map((zone) {
            return DropdownMenuItem<String>(
              value: zone['zone'],
              child: Text(
                zone['location']!,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedTimeZone = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        Text(
          _formatScheduledPayment(),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 24),
        
        const Text(
          'Payment Method:',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: selectedPaymentMethod,
          dropdownColor: Colors.grey[900],
          items: paymentMethods.map((method) {
            return DropdownMenuItem<String>(
              value: method,
              child: Text(
                method,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedPaymentMethod = value;
              });
            }
          },
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: resetPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (selectedPaymentDate != null && selectedPaymentTime != null) 
                  ? _schedulePayment 
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (selectedPaymentDate != null && selectedPaymentTime != null) 
                    ? Colors.green 
                    : Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('Schedule Payment'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentProcessing() {
    final formattedAmount = formatCurrency(
      selectedPlan == 'Premium' ? getConvertedPrice() : getConvertedPrice() * 0.7,
      selectedCurrency
    );
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Scheduling your payment...',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Amount: $formattedAmount',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scheduled for: ${_formatScheduledPayment()}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Payment Method: $selectedPaymentMethod',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transaction ID: $transactionId',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSuccess() {
    final formattedAmount = formatCurrency(
      selectedPlan == 'Premium' ? getConvertedPrice() : getConvertedPrice() * 0.7,
      selectedCurrency
    );
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Payment Scheduled Successfully!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Amount: $formattedAmount',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scheduled for: ${_formatScheduledPayment()}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Payment Method: $selectedPaymentMethod',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Transaction ID: $transactionId',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: resetPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Back to Membership'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentFailed() {
    final formattedAmount = formatCurrency(
      selectedPlan == 'Premium' ? getConvertedPrice() : getConvertedPrice() * 0.7,
      selectedCurrency
    );
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Payment Scheduling Failed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Amount Attempted: $formattedAmount',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scheduled for: ${_formatScheduledPayment()}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            paymentError,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Transaction ID: $transactionId',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: resetPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showPaymentFailed = false;
                    showPayment = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeZonesCountdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Time in Different Zones:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...timeZones.map((zone) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                '${zone['location']}: ',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Text(
                    formatTime(zone['zone']!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final premiumPrice = getConvertedPrice();
    final standardPrice = premiumPrice * 0.7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Plans'),
        backgroundColor: Colors.black,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (paymentStatus == PaymentStatus.pending) _buildPendingPayment(),
                  if (!showPayment && !showPaymentSuccess && !showPaymentProcessing && !showPaymentFailed) ...[
                    _buildMembershipStatus(),
                    _buildCurrencySelector(),
                    const SizedBox(height: 24),
                    if (!isPremiumMember && !isStandardMember) ...[
                      _buildMembershipCard(
                        title: 'Premium',
                        benefits: [
                          'Access to all features',
                          'Ad-free experience',
                          'Priority support',
                          'Exclusive content'
                        ],
                        price: premiumPrice,
                        currency: selectedCurrency,
                        isFeatured: true,
                      ),
                      const SizedBox(height: 16),
                      _buildMembershipCard(
                        title: 'Standard',
                        benefits: [
                          'Access to basic features',
                          'Limited ads',
                          'Standard support',
                          'Regular content'
                        ],
                        price: standardPrice,
                        currency: selectedCurrency,
                        isFeatured: false,
                      ),
                      const SizedBox(height: 24),
                      _buildMembershipDetails(),
                      const SizedBox(height: 24),
                      _buildTimeZonesCountdown(),
                    ] else ...[
                      _buildMembershipDetails(),
                      const SizedBox(height: 24),
                      _buildTimeZonesCountdown(),
                    ],
                  ] else if (showPayment) ...[
                    _buildPaymentForm(selectedPlan == 'Premium' ? premiumPrice : standardPrice),
                  ] else if (showPaymentProcessing) ...[
                    _buildPaymentProcessing(),
                  ] else if (showPaymentSuccess) ...[
                    _buildPaymentSuccess(),
                  ] else if (showPaymentFailed) ...[
                    _buildPaymentFailed(),
                  ],
                ],
              ),
            ),
    );
  }
}