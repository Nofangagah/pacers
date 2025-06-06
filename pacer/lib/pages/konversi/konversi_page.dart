import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CurrencyTimePage extends StatefulWidget {
  const CurrencyTimePage({super.key});

  @override
  State<CurrencyTimePage> createState() => _CurrencyTimePageState();
}

class _CurrencyTimePageState extends State<CurrencyTimePage> {
  String selectedBase = 'IDR';
  Map<String, double> exchangeRates = {};
  bool isLoading = true;

  final List<String> currencies = ['USD', 'EUR', 'IDR', 'JPY', 'GBP', 'AUD'];
  final List<String> targetCurrencies = ['IDR', 'EUR', 'JPY', 'GBP', 'AUD'];

  final List<Map<String, String>> timeZones = [
    {'location': 'Jakarta', 'zone': 'Asia/Jakarta'},
    {'location': 'Tokyo', 'zone': 'Asia/Tokyo'},
    {'location': 'London', 'zone': 'Europe/London'},
    {'location': 'New York', 'zone': 'America/New_York'},
    {'location': 'Sydney', 'zone': 'Australia/Sydney'},
  ];

  final TextEditingController amountController = TextEditingController(
    text: '1.0',
  );
  double amount = 1.0;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    fetchExchangeRates();
  }

  Future<void> fetchExchangeRates() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/$selectedBase'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          exchangeRates = {};
          for (var currency in targetCurrencies) {
            if (data['rates'][currency] != null && currency != selectedBase) {
              exchangeRates[currency] = data['rates'][currency];
            }
          }
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load exchange rates");
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  String formatTime(String location) {
    final locationTZ = tz.getLocation(location);
    final now = tz.TZDateTime.now(locationTZ);
    return DateFormat('HH:mm, dd MMM').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency & Time Info'),
        backgroundColor: Colors.black,
        centerTitle: true,
        automaticallyImplyLeading: false
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  _buildCurrencySelector(),
                  const SizedBox(height: 16),
                  _buildAmountInput(),
                  const SizedBox(height: 20),
                  const Text(
                    '💱 Exchange Rates',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildExchangeRateCards(),
                  const SizedBox(height: 32),
                  const Text(
                    '🕒 Time Zones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTimeZoneCards(),
                ],
              ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Row(
      children: [
        const Text(
          'Base Currency: ',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          dropdownColor: Colors.grey[900],
          value: selectedBase,
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
                selectedBase = value;
                fetchExchangeRates();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return TextField(
      controller: amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Amount',
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      onChanged: (value) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          setState(() {
            amount = parsed;
          });
        }
      },
    );
  }

  Widget _buildExchangeRateCards() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: exchangeRates.entries.map((entry) {
        final convertedAmount = entry.value * amount;
        final formatted = NumberFormat.simpleCurrency(
          name: entry.key,
          decimalDigits: 2,
        ).format(convertedAmount);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          width: MediaQuery.of(context).size.width / 2 - 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$amount $selectedBase → ${entry.key}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                formatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeZoneCards() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: timeZones.map((zone) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          width: MediaQuery.of(context).size.width / 2 - 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                zone['location']!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                formatTime(zone['zone']!),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
