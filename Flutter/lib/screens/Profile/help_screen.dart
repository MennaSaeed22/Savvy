import 'package:flutter/material.dart';
import '../globals.dart';
import '../../widgets/app_header.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  bool isFaqSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: "Help & FAQS",
              arrowVisible: true,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: OffWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Column(
                  children: [
                  Text('How can we help you?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                      )),
                    const SizedBox(height: 20),
                    // Animated Toggle Tabs
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Stack(
                        children: [
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            alignment: isFaqSelected
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.4,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isFaqSelected = true;
                                    });
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'FAQ',
                                      style: TextStyle(
                                        color: isFaqSelected
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isFaqSelected = false;
                                    });
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Contact Us',
                                      style: TextStyle(
                                        color: isFaqSelected
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: isFaqSelected
                          ? _buildFaqContent()
                          : _buildContactContent(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// FAQ List with expandable answers
Widget _buildFaqContent() {
  final List<Map<String, String>> faqData = [
    {
      "question": "How to use Savvy?",
      "answer":
          "You can use Savvy by signing up and navigating through the dashboard to track your expenses, set budgets, and more."
    },
    {
      "question": "How to contact support?",
      "answer": "You can contact support through the Contact Us tab."
    },
    {
      "question": "How can I reset my password if I forget it?",
      "answer":
          "Use the 'Forgot Password' option on the login screen to reset your password via email."
    },
    {
      "question": "Are there any privacy or data security measures in place?",
      "answer":
          "Yes, we use end-to-end encryption and follow strict data privacy policies."
    },
    {
      "question": "How can I delete my account?",
      "answer":
          "Go to Settings > Account > Delete Account. Follow the prompts to confirm."
    },
    {
      "question": "How do I access my expense history?",
      "answer":
          "Navigate to the 'Transactions' tab in the app to view all past transactions."
    },
  ];

  return ListView.builder(
    itemCount: faqData.length,
    itemBuilder: (context, index) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
            childrenPadding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            title: Text(
              faqData[index]["question"]!,
              style: const TextStyle(color: secondaryColor),
            ),
            trailing:
                const Icon(Icons.keyboard_arrow_down, color: secondaryColor),
            collapsedBackgroundColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            children: [
              Text(faqData[index]["answer"]!),
            ],
          ),
        ),
      );
    },
  );
}

  // Contact Us options list
  Widget _buildContactContent() {
    final List<Map<String, dynamic>> contactOptions = [
      {"icon": Icons.email, "label": "Email Us"}
    ];
    return ListView.separated(
      itemCount: contactOptions.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(contactOptions[index]["icon"], color: primaryColor),
          title: Text(contactOptions[index]["label"]),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/Email',
            );
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(),
    );
  }
}
