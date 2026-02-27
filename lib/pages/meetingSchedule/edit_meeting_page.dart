import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/services/meeting_schedule_service.dart';
import 'package:inhabit_realties/models/meeting_schedule_model.dart';
import 'package:inhabit_realties/pages/widgets/formTextField.dart';
import 'package:inhabit_realties/pages/widgets/appSpinner.dart';
import 'package:inhabit_realties/controllers/meeting_schedule_status/meeting_schedule_status_controller.dart';
import 'package:inhabit_realties/models/meetingSchedule/MeetingScheduleStatusModel.dart';
import 'package:inhabit_realties/pages/widgets/appSnackBar.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class EditMeetingPage extends StatefulWidget {
  final MeetingSchedule meeting;

  const EditMeetingPage({super.key, required this.meeting});

  @override
  State<EditMeetingPage> createState() => _EditMeetingPageState();
}

class _EditMeetingPageState extends State<EditMeetingPage> {
  final _formKey = GlobalKey<FormState>();
  final MeetingScheduleService _meetingService = MeetingScheduleService();
  final MeetingScheduleStatusController _statusController =
      MeetingScheduleStatusController();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();

  // Form data
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  String? _selectedStatus;
  List<MeetingScheduleStatusModel> _statuses = [];
  bool _isLoading = false;
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadStatuses();
  }

  void _initializeForm() {
    _titleController.text = widget.meeting.title;
    _descriptionController.text = widget.meeting.description ?? '';
    _notesController.text = widget.meeting.notes ?? '';
    _durationController.text = widget.meeting.duration ?? '';

    // Parse meeting date and time
    if (widget.meeting.meetingDate != null) {
      _selectedDate = DateTime.parse(widget.meeting.meetingDate!);
    }

    if (widget.meeting.startTime != null) {
      final timeParts = widget.meeting.startTime!.split(':');
      _selectedStartTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }

    if (widget.meeting.endTime != null) {
      final timeParts = widget.meeting.endTime!.split(':');
      _selectedEndTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }

    // Handle status field properly
    if (widget.meeting.status is Map<String, dynamic>) {
      _selectedStatus = widget.meeting.status['id'];
    } else if (widget.meeting.status is String) {
      _selectedStatus = widget.meeting.status;
    }
  }

  Future<void> _loadStatuses() async {
    try {
      final result = await _statusController.getAllMeetingScheduleStatuses();
      final List<dynamic> statusesData = result['data'] ?? [];
      setState(() {
        _statuses = statusesData
            .map((json) => MeetingScheduleStatusModel.fromJson(json))
            .toList();
        _isDataLoading = false;
      });
    } catch (e) {
      setState(() {
        _isDataLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(
          const Duration(days: 30)), // Allow past dates for rescheduling
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              hourMinuteTextStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              helpTextStyle: const TextStyle(fontSize: 12),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(0.8),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != _selectedStartTime) {
      setState(() {
        _selectedStartTime = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              hourMinuteTextStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              helpTextStyle: const TextStyle(fontSize: 12),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(0.8),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  Future<void> _updateMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDate == null || _selectedStartTime == null) {
      AppSnackBar.showSnackBar(
        context,
        'Error',
        'Please select meeting date and start time',
        ContentType.failure,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final meetingData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'meetingDate': _selectedDate!.toIso8601String().split('T')[0],
        'startTime':
            '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}',
        'endTime': _selectedEndTime != null
            ? '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'duration': _durationController.text.isNotEmpty
            ? _durationController.text
            : null,
        'status': _selectedStatus,
        'customerId': widget.meeting.customerId,
        'notes': _notesController.text,
      };

      final result =
          await _meetingService.updateMeeting(widget.meeting.id, meetingData);

      if (mounted) {
        AppSnackBar.showSnackBar(
          context,
          'Success',
          'Meeting updated successfully',
          ContentType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          'Error updating meeting: $e',
          ContentType.failure,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelMeeting() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Meeting'),
        content: const Text(
            'Are you sure you want to cancel this meeting? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _meetingService.deleteMeeting(widget.meeting.id);

        if (mounted) {
          AppSnackBar.showSnackBar(
            context,
            'Success',
            'Meeting cancelled successfully',
            ContentType.success,
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showSnackBar(
            context,
            'Error',
            'Error cancelling meeting: $e',
            ContentType.failure,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Basic Information'),
          FormTextField(
            textEditingController: _titleController,
            labelText: 'Meeting Title *',
            prefixIcon: CupertinoIcons.calendar,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a meeting title';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
            child: TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: Icon(CupertinoIcons.doc_text),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              enableInteractiveSelection: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Date & Time'),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meeting Date',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.calendar, color: textColor),
                            const SizedBox(width: 8),
                            Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Select Date',
                              style: TextStyle(color: textColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Time',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectStartTime(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.clock, color: textColor),
                            const SizedBox(width: 8),
                            Text(
                              _selectedStartTime != null
                                  ? _selectedStartTime!.format(context)
                                  : 'Select Time',
                              style: TextStyle(color: textColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'End Time (Optional)',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectEndTime(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.clock, color: textColor),
                      const SizedBox(width: 8),
                      Text(
                        _selectedEndTime != null
                            ? _selectedEndTime!.format(context)
                            : 'Select End Time (Optional)',
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    if (_statuses.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Status'),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status *',
                prefixIcon: Icon(CupertinoIcons.flag),
                border: OutlineInputBorder(),
              ),
              items: _statuses.map((status) {
                return DropdownMenuItem(
                  value: status.id,
                  child: Text(status.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a status';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Additional Information'),
          FormTextField(
            textEditingController: _durationController,
            labelText: 'Duration (Optional)',
            prefixIcon: CupertinoIcons.time,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
            child: TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(CupertinoIcons.doc_text),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Meeting',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _updateMeeting,
              child: Text(
                'Save',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isDataLoading
          ? const Center(child: AppSpinner())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    _buildDateTimeSection(),
                    _buildStatusSection(),
                    _buildAdditionalInfoSection(),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lightDanger,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _isLoading ? null : _cancelMeeting,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Cancel Meeting'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }
}
