import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/profiles/providers/profile_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Athlete profile setup — multi-step onboarding flow for first-time athletes.
class AthleteSetupScreen extends ConsumerStatefulWidget {
  const AthleteSetupScreen({super.key});

  @override
  ConsumerState<AthleteSetupScreen> createState() => _AthleteSetupScreenState();
}

class _AthleteSetupScreenState extends ConsumerState<AthleteSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _teamController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _cityController = TextEditingController();

  int _currentStep = 0;
  final List<String> _selectedSports = [];
  final List<String> _selectedPositions = [];
  String? _dominantFoot;
  AvailabilityStatus _availability = AvailabilityStatus.openToTrials;
  String? _country;

  final List<String> _availableSports = [
    'Football', 'Basketball', 'Netball', 'Athletics', 'Rugby',
    'Swimming', 'Boxing', 'Volleyball', 'Cricket', 'Tennis',
  ];

  final List<String> _footballPositions = [
    'Goalkeeper', 'Defender', 'Midfielder', 'Striker', 'Winger',
  ];

  final List<String> _availableCountries = [
    'Uganda', 'Kenya', 'Tanzania', 'Rwanda', 'Burundi',
    'South Sudan', 'DRC', 'Ethiopia',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _teamController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  Future<void> _handleComplete() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    setState(() => _isSaving = true);

    final profile = Athlete(
      id: '', // assigned by the database
      userId: authState.user.id,
      displayName: _nameController.text.trim().isEmpty
          ? authState.user.name
          : _nameController.text.trim(),
      sports: _selectedSports,
      positions: _selectedPositions,
      height: double.tryParse(_heightController.text.trim()),
      weight: double.tryParse(_weightController.text.trim()),
      dominantFootHand: _dominantFoot,
      currentTeam: _teamController.text.trim().isEmpty ? null : _teamController.text.trim(),
      country: _country,
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      availabilityStatus: _availability,
    );

    final error = await ref.read(profileProvider.notifier).createProfile(profile);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $error')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully!')),
    );
    context.go(AppRouter.discover);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _isSaving
              ? null
              : () {
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
                    _handleComplete();
                  }
                },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep < 3 ? 'Continue' : 'Save Profile'),
                  ),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _isSaving ? null : details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              ),
            );
          },
          steps: [
            // Step 1: Basic info
            Step(
              title: const Text('Basic Info'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Sports (multi-select)
                  Text('Sport(s)', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _availableSports.map((sport) {
                      final selected = _selectedSports.contains(sport);
                      return FilterChip(
                        label: Text(sport),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedSports.add(sport);
                            } else {
                              _selectedSports.remove(sport);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Positions
                  Text('Position(s)', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _footballPositions.map((pos) {
                      final selected = _selectedPositions.contains(pos);
                      return FilterChip(
                        label: Text(pos),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedPositions.add(pos);
                            } else {
                              _selectedPositions.remove(pos);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
            ),

            // Step 2: Physical attributes
            Step(
              title: const Text('Attributes'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      prefixIcon: Icon(Icons.straighten),
                      hintText: 'e.g. 175',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      prefixIcon: Icon(Icons.monitor_weight),
                      hintText: 'e.g. 70',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Text('Dominant Foot/Hand', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Right'),
                        selected: _dominantFoot == 'Right',
                        onSelected: (_) => setState(() => _dominantFoot = 'Right'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Left'),
                        selected: _dominantFoot == 'Left',
                        onSelected: (_) => setState(() => _dominantFoot = 'Left'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Both'),
                        selected: _dominantFoot == 'Both',
                        onSelected: (_) => setState(() => _dominantFoot = 'Both'),
                      ),
                    ],
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
            ),

            // Step 3: Team and location
            Step(
              title: const Text('Team & Location'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _teamController,
                    decoration: const InputDecoration(
                      labelText: 'Current Team / Academy',
                      prefixIcon: Icon(Icons.group),
                      hintText: 'e.g. Kampala City FC',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Country', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _country,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.public),
                    ),
                    items: _availableCountries
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _country = v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                      hintText: 'e.g. Kampala',
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 2,
            ),

            // Step 4: Bio and availability
            Step(
              title: const Text('Bio & Availability'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Short Bio',
                      prefixIcon: Icon(Icons.info_outline),
                      hintText: 'Tell recruiters about yourself...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Text('Availability', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...AvailabilityStatus.values.map((status) {
                    final label = switch (status) {
                      AvailabilityStatus.openToTrials => 'Open to Trials',
                      AvailabilityStatus.currentlyContracted => 'Currently Contracted',
                      AvailabilityStatus.notAvailable => 'Not Available',
                    };
                    return RadioListTile<AvailabilityStatus>(
                      title: Text(label),
                      value: status,
                      groupValue: _availability,
                      onChanged: (v) => setState(() => _availability = v!),
                    );
                  }),
                ],
              ),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }
}