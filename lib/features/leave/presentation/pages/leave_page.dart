import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../../../dashboard/data/models/employee_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../domain/repositories/leave_repository.dart';
import '../../domain/services/leave_validation_service.dart';
import '../bloc/leave_bloc.dart';
import '../bloc/leave_event.dart';
import '../bloc/leave_state.dart';

const Color _navy = Color(0xFF172554);
const Color _indigo = Color(0xFF4F46E5);
const Color _teal = Color(0xFF0D9488);
const Color _background = Color(0xFFF4F6FB);
const Color _secondaryText = Color(0xFF64748B);
const Color _border = Color(0xFFE2E8F0);

class LeavePage extends StatelessWidget {
  final EmployeeModel employee;
  final LeaveRepository repository;
  final LeaveValidationService validationService;

  const LeavePage({
    super.key,
    required this.employee,
    required this.repository,
    required this.validationService,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeaveBloc(
        repository: repository,
        validationService: validationService,
        employeeId: employee.id,
      )..add(const LeaveLoadRequested()),
      child: _LeaveView(employee: employee),
    );
  }
}

class _LeaveView extends StatefulWidget {
  final EmployeeModel employee;

  const _LeaveView({required this.employee});

  @override
  State<_LeaveView> createState() => _LeaveViewState();
}

class _LeaveViewState extends State<_LeaveView> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String _selectedType = 'Casual';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _dateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  int get _requestedDays {
    if (_startDate == null || _endDate == null) return 0;

    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _selectDate({required bool isStart}) async {
    final now = DateTime.now();
    final selectedDate = isStart ? _startDate : _endDate;

    final initialDate =
        selectedDate != null &&
            !selectedDate.isBefore(DateTime(now.year, now.month, now.day))
        ? selectedDate
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _indigo,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startDate = picked;

        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  void _submit(LeaveState state) {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      _showMessage('Please select your leave dates.');
      return;
    }

    context.read<LeaveBloc>().add(
      LeaveSubmitRequested(
        employeeId: widget.employee.id,
        timezone: widget.employee.office.timezone,
        type: _selectedType,
        startDate: _dateString(_startDate!),
        endDate: _dateString(_endDate!),
        reason: _reasonController.text.trim(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeaveBloc, LeaveState>(
      listenWhen: (previous, current) =>
          previous.message != current.message ||
          previous.error != current.error,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: _teal,
              behavior: SnackBarBehavior.floating,
            ),
          );

          _reasonController.clear();

          setState(() {
            _startDate = null;
            _endDate = null;
            _selectedType = 'Casual';
          });
        }

        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _navy,
          elevation: 0,
          title: const Text(
            'Leave Management',
            style: TextStyle(
              color: _navy,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: BlocBuilder<LeaveBloc, LeaveState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: _indigo,
              onRefresh: () async {
                context.read<LeaveBloc>().add(const LeaveRefreshRequested());
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(),

                  const SizedBox(height: 20),

                  _buildBalanceCard(state),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    'Apply for Leave',
                    'Submit a new leave request',
                    Icons.edit_calendar_rounded,
                  ),

                  const SizedBox(height: 16),

                  _buildApplicationForm(state),

                  const SizedBox(height: 30),

                  _buildSectionTitle(
                    'Leave History',
                    'Your previous leave applications',
                    Icons.history_rounded,
                  ),

                  const SizedBox(height: 16),

                  _buildLeaveHistory(state),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage your time off',
          style: TextStyle(
            color: _navy,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'View your balance and request leave easily.',
          style: TextStyle(color: _secondaryText, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(LeaveState state) {
    final balance = state.balance?.balance;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _indigo.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.beach_access_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Available Leave Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance?.toString() ?? '--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 7),
                child: Text(
                  'days remaining',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const Spacer(),
              if (state.isLoading)
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: SpinKitThreeBounce(color: Color(0xFF6366F1), size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          const Text(
            'Your leave balance is shared across Casual and Sick leave.',
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _indigo.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: _indigo, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: _secondaryText, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationForm(LeaveState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Leave Type'),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _LeaveTypeOption(
                    title: 'Casual Leave',
                    selected: _selectedType == 'Casual',
                    icon: Icons.event_available_rounded,
                    onTap: () {
                      setState(() => _selectedType = 'Casual');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LeaveTypeOption(
                    title: 'Sick Leave',
                    selected: _selectedType == 'Sick',
                    icon: Icons.medical_services_outlined,
                    onTap: () {
                      setState(() => _selectedType = 'Sick');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            _fieldLabel('Start Date'),
            const SizedBox(height: 9),
            _DateField(
              date: _startDate,
              hint: 'Select start date',
              onTap: () => _selectDate(isStart: true),
            ),

            const SizedBox(height: 17),

            _fieldLabel('End Date'),
            const SizedBox(height: 9),
            _DateField(
              date: _endDate,
              hint: 'Select end date',
              onTap: _startDate == null
                  ? null
                  : () => _selectDate(isStart: false),
            ),

            if (_requestedDays > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _indigo.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: _indigo,
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '$_requestedDays ${_requestedDays == 1 ? 'day' : 'days'} requested',
                        style: const TextStyle(
                          color: _indigo,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 22),

            _fieldLabel('Reason for Leave'),
            const SizedBox(height: 9),

            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Explain why you need leave...',
                hintStyle: const TextStyle(color: _secondaryText, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: _indigo),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return 'Please enter at least 10 characters.';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: state.isSubmitting ? null : () => _submit(state),
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 30,
                        height: 30,
                        child: SpinKitThreeBounce(
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  state.isSubmitting ? 'Submitting...' : 'Submit Leave Request',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _indigo,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _secondaryText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveHistory(LeaveState state) {
    if (state.requests.isEmpty && state.isLoading) {
      return const SizedBox(
      width: double.infinity,
      height: 100,
      child: Center(
        child: SpinKitThreeBounce(
          color: Color(0xFF6366F1),
          size: 22,
        ),
      ),
    );
    }

    if (state.requests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: const Column(
          children: [
            Icon(Icons.event_note_rounded, size: 38, color: _secondaryText),
            SizedBox(height: 10),
            Text(
              'No leave requests yet',
              style: TextStyle(
                color: _navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Your submitted leave applications will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondaryText, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: state.requests.map((request) {
        return _LeaveRequestCard(request: request);
      }).toList(),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _navy,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LeaveTypeOption extends StatelessWidget {
  final String title;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _LeaveTypeOption({
    required this.title,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? _indigo.withValues(alpha: 0.07)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? _indigo : _border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? _indigo : _secondaryText, size: 19),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? _indigo : _secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime? date;
  final String hint;
  final VoidCallback? onTap;

  const _DateField({
    required this.date,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: _indigo, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date == null ? hint : DateFormat('dd MMM yyyy').format(date!),
                style: TextStyle(
                  color: date == null ? _secondaryText : _navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveRequestCard extends StatelessWidget {
  final LeaveRequestModel request;

  const _LeaveRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final status = request.status.toLowerCase();

    final statusColor = switch (status) {
      'approved' => _teal,
      'rejected' => Colors.red.shade700,
      _ => const Color(0xFFD97706),
    };

    final start = DateTime.parse(request.startDate);
    final end = DateTime.parse(request.endDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${request.type} Leave',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: _secondaryText,
                size: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${DateFormat('dd MMM yyyy').format(start)} - '
                  '${DateFormat('dd MMM yyyy').format(end)}',
                  style: const TextStyle(color: _secondaryText, fontSize: 11),
                ),
              ),
              Text(
                '${request.days} ${request.days == 1 ? 'day' : 'days'}',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.reason,
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
