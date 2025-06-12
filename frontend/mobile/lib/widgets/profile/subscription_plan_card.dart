import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final bool isCurrent;
  final VoidCallback onPressed;

  const SubscriptionPlanCard({
    Key? key,
    required this.title,
    required this.price,
    required this.features,
    required this.isCurrent,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCurrent ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCurrent ? AppColors.primaryColor : Colors.grey.shade300,
          width: isCurrent ? 2 : 1,
        ),
      ),
      color:
          isCurrent ? AppColors.primaryColor.withOpacity(0.07) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? AppColors.primaryColor : Colors.black,
                  ),
                ),
                if (isCurrent)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '현재 플랜',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isCurrent ? AppColors.primaryColor : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...features.map((f) => Row(
                  children: [
                    Icon(Icons.check, color: AppColors.primaryColor, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrent ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCurrent ? Colors.grey.shade300 : AppColors.primaryColor,
                  foregroundColor: isCurrent ? Colors.black54 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isCurrent ? '이용 중' : '이 플랜 선택',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
