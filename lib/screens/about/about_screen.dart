// lib/screens/about/about_screen.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: Text("aboutTitle".tr()),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F7B6C).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_rounded,
                size: 64,
                color: Color(0xFF0F7B6C),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "aboutTitle".tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "aboutIntro".tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF4A4A4A),
            ),
          ),
          const SizedBox(height: 40),
          Card(
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.04),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                title: Text(
                  "howItWorksTitle".tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F7B6C),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "howItWorksSubtitle".tr(),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                children: [
                  _buildStep(1, Icons.add_circle_outline, "step1Title".tr(),
                      "step1Desc".tr()),
                  _buildStep(2, Icons.share_outlined, "step2Title".tr(),
                      "step2Desc".tr()),
                  _buildStep(3, Icons.group_add_outlined, "step3Title".tr(),
                      "step3Desc".tr()),
                  _buildStep(4, Icons.settings_outlined, "step4Title".tr(),
                      "step4Desc".tr()),
                  _buildStep(5, Icons.format_list_numbered_rounded,
                      "step5Title".tr(), "step5Desc".tr()),
                  _buildStep(6, Icons.play_circle_outline, "step6Title".tr(),
                      "step6Desc".tr()),
                  _buildStep(7, Icons.payments_outlined, "step7Title".tr(),
                      "step7Desc".tr()),
                  _buildStep(8, Icons.verified_outlined, "step8Title".tr(),
                      "step8Desc".tr(),
                      isLast: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.04),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                title: Text(
                  "faqTitle".tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F7B6C),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "faqSubtitle".tr(),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                children: [
                  _buildFaqItem("faqQ1".tr(), "faqA1".tr()),
                  _buildFaqItem("faqQ2".tr(), "faqA2".tr()),
                  _buildFaqItem("faqQ3".tr(), "faqA3".tr(), isLast: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStep(int number, IconData icon, String title, String desc,
      {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFF0F7B6C).withValues(alpha: 0.12),
              child: Text(
                number.toString(),
                style: const TextStyle(
                    color: Color(0xFF0F7B6C),
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
            if (!isLast)
              Container(
                width: 2.5,
                height: 26,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: const Color(0xFF0F7B6C)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1A1A1A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                      color: Color(0xFF4A4A4A), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem(String question, String answerStr,
      {bool isLast = false}) {
    List<String> answerLines = answerStr.split('\n');

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF0F7B6C),
          collapsedIconColor: Colors.grey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
          title: Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1A1A1A),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          expandedAlignment: Alignment.centerLeft,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...answerLines.map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding:
                              EdgeInsets.only(top: 6.0, left: 4.0, right: 8.0),
                          child: Icon(Icons.circle,
                              size: 6, color: Color(0xFF0F7B6C)),
                        ),
                        Expanded(
                          child: Text(
                            line.trim(),
                            style: const TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
