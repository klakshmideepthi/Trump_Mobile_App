import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/theme.dart';

class InternationalLongDistanceView extends StatefulWidget {
  const InternationalLongDistanceView({super.key});

  @override
  State<InternationalLongDistanceView> createState() =>
      _InternationalLongDistanceViewState();
}

class _InternationalLongDistanceViewState
    extends State<InternationalLongDistanceView> {
  final TextEditingController _searchController = TextEditingController();

  // Sample of key countries with their limits
  final List<CountryLimit> _countryLimits = [
    CountryLimit(country: "Afghanistan", minutes: "30"),
    CountryLimit(country: "Afghanistan - Cellular", minutes: "40"),
    CountryLimit(country: "Algeria", minutes: "Unlimited"),
    CountryLimit(country: "Algeria - Cellular", minutes: "10"),
    CountryLimit(country: "Argentina", minutes: "Unlimited"),
    CountryLimit(country: "Argentina - Cellular", minutes: "Unlimited"),
    CountryLimit(country: "Australia", minutes: "Unlimited"),
    CountryLimit(country: "Australia - Cellular", minutes: "Unlimited"),
    CountryLimit(country: "Austria", minutes: "Unlimited"),
    CountryLimit(country: "Canada", minutes: "Unlimited"),
    CountryLimit(country: "China", minutes: "Unlimited"),
    CountryLimit(country: "China - Cellular", minutes: "Unlimited"),
    CountryLimit(country: "France", minutes: "Unlimited"),
    CountryLimit(country: "France - Cellular", minutes: "Unlimited"),
    CountryLimit(country: "Germany", minutes: "Unlimited"),
    CountryLimit(country: "Germany - Cellular", minutes: "Unlimited"),
    CountryLimit(country: "India", minutes: "Unlimited"),
    CountryLimit(country: "India - Cellular", minutes: "Unlimited"),
    CountryLimit(country: "Japan", minutes: "Unlimited"),
    CountryLimit(country: "Japan - Cellular", minutes: "Unlimited"),
    CountryLimit(country: "Mexico", minutes: "Unlimited"),
    CountryLimit(country: "South Korea", minutes: "Unlimited"),
    CountryLimit(country: "United Kingdom", minutes: "Unlimited"),
    CountryLimit(country: "United Kingdom - Cellular", minutes: "Unlimited"),
  ];

  List<CountryLimit> get _filteredCountries {
    if (_searchController.text.isEmpty) {
      return _countryLimits;
    }
    return _countryLimits
        .where((country) => country.country
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall() async {
    final uri = Uri.parse('tel:8888786745');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make phone call')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('International Calling'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.blueGradient,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),

            const SizedBox(height: 24),

            // Features Section
            _buildFeaturesSection(),

            const SizedBox(height: 24),

            // Military Families Section
            _buildMilitaryFamiliesSection(),

            const SizedBox(height: 24),

            // Country Rates Section
            _buildCountryRatesSection(),

            const SizedBox(height: 24),

            // Contact Section
            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stay connected to family, friends, and business partners across the globe with LinkUp Mobile\'s International Long Distance service. Whether it\'s a quick call or regular communication, we make it easy and affordable to reach over 200 countries worldwide.',
          style: GoogleFonts.montserrat(
            fontSize: AppTheme.fontSizeBody,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      children: [
        _buildFeatureCard(
          icon: Icons.bar_chart,
          title: 'Clear Rates. No Surprises.',
          description:
              'As part of your LinkUp Mobile plan you receive unlimited international calling to over 100 countries.',
        ),
        const SizedBox(height: 20),
        _buildFeatureCard(
          icon: Icons.language,
          title: 'Wide Global Coverage',
          description:
              'Our International Long Distance service allows you to call landlines and mobile numbers in over 200 destinations, including North America, Europe, Asia, and more.',
        ),
        const SizedBox(height: 20),
        _buildFeatureCard(
          icon: Icons.check_circle,
          title: 'Simple Activation',
          description:
              'International Long Distance is automatically available on your LinkUp Mobile account. Just dial your international number and stay connected — no extra setup or activation needed.',
        ),
        const SizedBox(height: 20),
        _buildFeatureCard(
          icon: Icons.phone,
          title: 'Stay Connected Worldwide',
          description:
              'Whether you travel for business or stay in touch with loved ones abroad, LinkUp Mobile makes international calling easy, reliable, and affordable.',
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
        border: Border.all(
          color: Colors.grey[300]!,
          width: AppTheme.borderWidthDefault,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppTheme.iconSizeLarge,
            color: AppTheme.secondBlue,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: AppTheme.fontSizeOptionTitle,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.appText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: AppTheme.fontSizeBody,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilitaryFamiliesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
        border: Border.all(
          color: Colors.grey[300]!,
          width: AppTheme.borderWidthDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The Sacrifices of Our Military Families',
            style: GoogleFonts.montserrat(
              fontSize: AppTheme.fontSizeSectionTitle,
              fontWeight: FontWeight.bold,
              color: AppTheme.appText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'At LinkUp Mobile, we honor the sacrifice of our military families. That\'s why our plan makes it easy and affordable for service members and their loved ones to stay connected — whether stationed at home or overseas. With free international texting, discounted international calling, and reliable global coverage, you can share life\'s important moments no matter where duty calls. Because when you\'re serving our country, you deserve to stay close to the ones who matter most.',
            style: GoogleFonts.montserrat(
              fontSize: AppTheme.fontSizeBody,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryRatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country Rates & Limits',
          style: GoogleFonts.montserrat(
            fontSize: AppTheme.fontSizeSectionTitle,
            fontWeight: FontWeight.bold,
            color: AppTheme.appText,
          ),
        ),
        const SizedBox(height: 16),

        // Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.borderColor,
              width: AppTheme.borderWidthDefault,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search countries...',
                    hintStyle: GoogleFonts.montserrat(
                      color: Colors.grey[600],
                      fontSize: AppTheme.fontSizeBody,
                    ),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.montserrat(
                    fontSize: AppTheme.fontSizeBody,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Country List
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[300]!,
              width: AppTheme.borderWidthDefault,
            ),
          ),
          child: Column(
            children: [
              // Header Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Destination (Country)',
                        style: GoogleFonts.montserrat(
                          fontSize: AppTheme.fontSizeBody,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.appText,
                        ),
                      ),
                    ),
                    Text(
                      'Max Cap (Minutes)',
                      style: GoogleFonts.montserrat(
                        fontSize: AppTheme.fontSizeBody,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.appText,
                      ),
                    ),
                  ],
                ),
              ),

              // Country Rows
              ..._filteredCountries.asMap().entries.map((entry) {
                final index = entry.key;
                final country = entry.value;
                final isLast = index == _filteredCountries.length - 1;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              country.country,
                              style: GoogleFonts.montserrat(
                                fontSize: AppTheme.fontSizeBody,
                                color: AppTheme.appText,
                              ),
                            ),
                          ),
                          Text(
                            country.minutes,
                            style: GoogleFonts.montserrat(
                              fontSize: AppTheme.fontSizeBody,
                              fontWeight: FontWeight.w500,
                              color: country.minutes == 'Unlimited'
                                  ? AppTheme.secondBlue
                                  : AppTheme.appText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey[300],
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: AppTheme.borderWidthDefault,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Have Questions?',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.appText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Contact Customer Care for more details on rates, coverage, and supported countries.',
            style: GoogleFonts.montserrat(
              fontSize: AppTheme.fontSizeBody,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.blueGradient,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusButton),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _makePhoneCall,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusButton),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Call (888) 878-6745',
                        style: GoogleFonts.montserrat(
                          fontSize: AppTheme.fontSizeButton,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class CountryLimit {
  final String country;
  final String minutes;

  CountryLimit({required this.country, required this.minutes});
}

