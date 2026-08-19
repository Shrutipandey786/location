const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '..', '..', 'mobile', 'lib', 'screens', 'map_overview_screen.dart');
let content = fs.readFileSync(filePath, 'utf8');

// 1. Remove "(You)" suffix from carousel
content = content.replace('"$userName (You)"', 'userName');

// 2. Remove "(App User)" suffix from details card
content = content.replace('"$userName (App User)"', 'userName');

// 3. Simplify _buildUserLocationDetailsCard to remove details info section
const oldCardRegex = /Widget _buildUserLocationDetailsCard\(bool isDark, String userName, String userEmail, String initials\) \{[\s\S]*?Widget _buildPeerLocationDetailsCard/;

const newCardCode = `Widget _buildUserLocationDetailsCard(bool isDark, String userName, String userEmail, String initials) {
    return Card(
      elevation: 6,
      color: (isDark ? AppTheme.darkCard : Colors.white).withOpacity(0.96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryIndigo,
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (userEmail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeerLocationDetailsCard`;

if (oldCardRegex.test(content)) {
  content = content.replace(oldCardRegex, newCardCode);
  fs.writeFileSync(filePath, content, 'utf8');
  console.log('Successfully updated map_overview_screen.dart!');
} else {
  console.error('Failed to match _buildUserLocationDetailsCard regex.');
}
