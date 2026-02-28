import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/controllers/lead/leadsController.dart';
import 'package:inhabit_realties/models/lead/LeadsModel.dart';
import 'package:inhabit_realties/pages/leads/add_lead_page.dart';
import 'package:inhabit_realties/pages/leads/widgets/lead_detail_header.dart';
import 'package:inhabit_realties/pages/leads/widgets/lead_info_section.dart';
import 'package:inhabit_realties/pages/leads/widgets/lead_contact_section.dart';
import 'package:inhabit_realties/pages/leads/widgets/lead_referral_section.dart';
import 'package:inhabit_realties/pages/leads/widgets/lead_assignment_section.dart';
import 'package:inhabit_realties/pages/leads/widgets/lead_notes_section.dart';
import 'package:inhabit_realties/pages/leads/widgets/lead_interested_property_section.dart';
import 'package:inhabit_realties/constants/status_utils.dart';

class LeadDetailsPage extends StatefulWidget {
  final LeadsModel lead;

  const LeadDetailsPage({super.key, required this.lead});

  @override
  State<LeadDetailsPage> createState() => _LeadDetailsPageState();
}

class _LeadDetailsPageState extends State<LeadDetailsPage>
    with SingleTickerProviderStateMixin {
  final LeadsController _leadsController = LeadsController();
  final bool _isLoading = false;
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isAppBarExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _isAppBarExpanded = _scrollController.hasClients &&
              _scrollController.offset > (200 - kToolbarHeight);
        });
      });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;
    final secondaryTextColor =
        isDark ? AppColors.greyColor : AppColors.greyColor2;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              LeadDetailHeader(
                lead: widget.lead,
                isExpanded: !_isAppBarExpanded,
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Lead Status and Designation Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.lead.fullName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.darkWhiteText
                                                : AppColors.lightDarkText,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Created on ${_formatDate(widget.lead.createdAt)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.greyColor,
                                          ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                            widget.lead.leadStatus),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        StatusUtils.getLeadStatusDisplayName(
                                            widget.lead.leadStatus),
                                        style: const TextStyle(
                                          color: AppColors.darkWhiteText,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getFollowUpStatusColor(
                                                widget.lead.followUpStatus)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _getFollowUpStatusColor(
                                                  widget.lead.followUpStatus)
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        StatusUtils
                                            .getFollowUpStatusDisplayName(
                                                widget.lead.followUpStatus),
                                        style: TextStyle(
                                          color: _getFollowUpStatusColor(
                                              widget.lead.followUpStatus),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Lead Information Section
                          LeadInfoSection(lead: widget.lead),
                          const SizedBox(height: 16),

                          // Contact Information Section
                          LeadContactSection(lead: widget.lead),
                          const SizedBox(height: 16),

                          // Interested Property Section
                          LeadInterestedPropertySection(lead: widget.lead),
                          const SizedBox(height: 16),

                          // Referral Information Section
                          LeadReferralSection(lead: widget.lead),
                          const SizedBox(height: 16),

                          // Assignment Information Section
                          LeadAssignmentSection(lead: widget.lead),
                          const SizedBox(height: 16),

                          // Notes Section
                          LeadNotesSection(lead: widget.lead),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Add bottom padding to prevent overflow
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.back,
                    color: isDark
                        ? AppColors.darkWhiteText
                        : AppColors.lightDarkText,
                  ),
                ),
              ),
            ),
          ),
          // Edit Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddLeadPage(lead: widget.lead),
                    ),
                  );
                  // Return true so the LeadsPage refreshes.
                  if (result == true && mounted) {
                    Navigator.pop(context, true);
                  }
                },
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.pencil,
                    color: AppColors.darkWhiteText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    return StatusUtils.getLeadStatusColor(status);
  }

  Color _getFollowUpStatusColor(String status) {
    return StatusUtils.getFollowUpStatusColor(status);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
