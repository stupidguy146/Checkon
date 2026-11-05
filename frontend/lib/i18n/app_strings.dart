/// Localized UI strings + API error-code messages for TH/EN.
/// Resolve via AppStrings.of(lang). Parameterized text uses methods.
class AppStrings {
  final String lang; // 'th' | 'en'
  const AppStrings(this.lang);

  bool get _th => lang == 'th';
  String _t(String th, String en) => _th ? th : en;

  // ---------- generic ----------
  String get appTitle => _t('เช็คก่อน', 'Checkon');
  String get appTagline =>
      _t('จัดการของใช้ในบ้าน ให้ชีวิตง่ายขึ้น', 'Home Consumable Tracker');
  String get save => _t('บันทึก', 'Save');
  String get cancel => _t('ยกเลิก', 'Cancel');
  String get retry => _t('ลองใหม่', 'Retry');
  String get pieces => _t('ชิ้น', 'pcs');
  String get bahtSymbol => '฿';

  // ---------- auth: login ----------
  String get welcomeBack => _t('ยินดีต้อนรับกลับ', 'Welcome back');
  String get loginSubtitle => _t('เข้าสู่ระบบเพื่อจัดการรายการซื้อของ',
      'Sign in to manage your shopping list');
  String get email => _t('อีเมล', 'Email');
  String get emailOrUsername => _t('อีเมลหรือชื่อผู้ใช้', 'Email or username');
  String get enterIdentifier =>
      _t('กรอกอีเมลหรือชื่อผู้ใช้', 'Enter email or username');
  String get password => _t('รหัสผ่าน', 'Password');
  String get signIn => _t('เข้าสู่ระบบ', 'Sign in');
  String get noAccount => _t('ยังไม่มีบัญชี?', "Don't have an account?");
  String get signUp => _t('สมัครสมาชิก', 'Sign up');
  String get forgotPassword => _t('ลืมรหัสผ่าน?', 'Forgot password?');
  String get invalidEmail => _t('กรอกอีเมลให้ถูกต้อง', 'Enter a valid email');
  String get enterPassword => _t('กรอกรหัสผ่าน', 'Enter your password');

  // ---------- auth: register ----------
  String get createAccount => _t('สร้างบัญชีใหม่', 'Create account');
  String get registerSubtitle => _t('เริ่มจัดการรายการซื้อของใช้ในบ้านของคุณ',
      'Start managing your household shopping list');
  String get registerJourneyProfile => _t('ข้อมูลบัญชี', 'Account details');
  String get registerJourneyPassword => _t('ตั้งรหัสผ่าน', 'Set password');
  String get displayName => _t('ชื่อที่แสดง', 'Display name');
  String get enterDisplayName => _t('กรอกชื่อที่แสดง', 'Enter a display name');
  String get firstName => _t('ชื่อจริง', 'First name');
  String get lastName => _t('นามสกุล', 'Last name');
  String get username => _t('ชื่อผู้ใช้ (username)', 'Username');
  String get enterFirstName => _t('กรอกชื่อจริง', 'Enter your first name');
  String get enterLastName => _t('กรอกนามสกุล', 'Enter your last name');
  String get usernameRule => _t('username ต้องยาว 3-30 ตัว (a-z, 0-9, . _ -)',
      'Username must be 3-30 chars (a-z, 0-9, . _ -)');
  String get confirmPassword => _t('ยืนยันรหัสผ่าน', 'Confirm password');
  String get passwordMin8 =>
      _t('รหัสผ่าน (อย่างน้อย 8 ตัว)', 'Password (min 8 chars)');
  String get passwordMin8Rule =>
      _t('รหัสผ่านต้องยาวอย่างน้อย 8 ตัว', 'Password must be at least 8 chars');
  String get haveAccount => _t('มีบัญชีอยู่แล้ว?', 'Already have an account?');

  // ---------- auth: title (honorific) ----------
  String get title => _t('คำนำหน้า', 'Title');
  String get selectTitle => _t('เลือกคำนำหน้า', 'Select a title');
  String titleLabel(String code) {
    switch (code) {
      case 'mr':
        return _t('นาย', 'Mr.');
      case 'mrs':
        return _t('นาง', 'Mrs.');
      case 'ms':
        return _t('นางสาว', 'Ms.');
      default:
        return _t('ไม่ระบุ', 'Unspecified');
    }
  }

  String get continueLabel => _t('ถัดไป', 'Continue');

  // ---------- auth: OTP verification ----------
  String get verifyEmailTitle => _t('ยืนยันอีเมล', 'Verify your email');
  String otpSentTo(String email) => _t(
      'เราได้ส่งรหัส 6 หลักไปที่\n$email', 'We sent a 6-digit code to\n$email');
  String get enterOtp => _t('กรอกรหัส OTP', 'Enter the OTP code');
  String get otpMustBe6 =>
      _t('รหัสต้องเป็นตัวเลข 6 หลัก', 'Code must be 6 digits');
  String get verifyOtpButton => _t('ยืนยันรหัส', 'Verify code');
  String get didntGetCode => _t('ไม่ได้รับรหัส?', "Didn't get the code?");
  String get resendOtp => _t('ส่งรหัสใหม่', 'Resend code');
  String resendOtpIn(int sec) =>
      _t('ส่งรหัสใหม่ได้ใน $sec วินาที', 'Resend in $sec s');
  String get otpResent => _t('ส่งรหัสใหม่แล้ว', 'A new code has been sent');
  String get otpDevHint => _t('(dev: ดูรหัสใน console ของ auth-service)',
      '(dev: see the code in the auth-service console)');

  // ---------- auth: set password (after OTP) ----------
  String get setPasswordTitle => _t('ตั้งรหัสผ่าน', 'Set your password');
  String get setPasswordSubtitle => _t('ตั้งรหัสผ่านเพื่อเข้าใช้งานบัญชีของคุณ',
      'Create a password to secure your account');
  String get passwordLabel => _t('รหัสผ่าน', 'Password');
  String get passwordRequirements =>
      _t('เงื่อนไขรหัสผ่าน', 'Password requirements');
  String get ruleMinLength =>
      _t('อย่างน้อย 8 ตัวอักษร', 'At least 8 characters');
  String get ruleUppercase =>
      _t('มีตัวพิมพ์ใหญ่ (A-Z)', 'An uppercase letter (A-Z)');
  String get ruleLowercase =>
      _t('มีตัวพิมพ์เล็ก (a-z)', 'A lowercase letter (a-z)');
  String get ruleDigit => _t('มีตัวเลข (0-9)', 'A number (0-9)');
  String get ruleSpecial =>
      _t('มีอักขระพิเศษ (!@#\$...)', 'A special character (!@#\$...)');
  String get passwordStrength => _t('ระดับความปลอดภัย', 'Password strength');
  String get strengthWeak => _t('อ่อน', 'Weak');
  String get strengthFair => _t('พอใช้', 'Fair');
  String get strengthGood => _t('ดี', 'Good');
  String get strengthStrong => _t('แข็งแรง', 'Strong');
  String get passwordTooWeak => _t(
      'รหัสผ่านยังไม่ผ่านเงื่อนไข', 'Password does not meet the requirements');
  String get createAccountButton => _t('สร้างบัญชี', 'Create account');

  // ---------- auth: PIN & biometric ----------
  String get setupPinTitle => _t('ตั้งรหัส PIN', 'Set up a PIN');
  String get setupPinSubtitle => _t('ตั้ง PIN 6 หลักสำหรับปลดล็อกแอป',
      'Create a 6-digit PIN to unlock the app');
  String get confirmPinTitle => _t('ยืนยันรหัส PIN', 'Confirm your PIN');
  String get confirmPinSubtitle =>
      _t('กรอก PIN อีกครั้งเพื่อยืนยัน', 'Enter your PIN again to confirm');
  String get pinMismatch =>
      _t('PIN ไม่ตรงกัน ลองใหม่', 'PINs do not match, try again');
  String get enterPinTitle => _t('กรอกรหัส PIN', 'Enter your PIN');
  String get enterSixDigitPin =>
      _t('กรุณาใส่ PIN 6 ตัว', 'Enter your 6-digit PIN');
  String get wrongPin => _t('PIN ไม่ถูกต้อง', 'Incorrect PIN');
  String get useBiometric =>
      _t('ใช้ลายนิ้วมือ / สแกนใบหน้า', 'Use fingerprint / face');
  String get enableBiometric =>
      _t('เปิดใช้ลายนิ้วมือ / สแกนใบหน้า', 'Enable fingerprint / face unlock');
  String get biometricReason =>
      _t('ยืนยันตัวตนเพื่อปลดล็อกแอป', 'Authenticate to unlock the app');
  String get skipForNow => _t('ข้ามไปก่อน', 'Skip for now');
  String get finish => _t('เสร็จสิ้น', 'Finish');
  String get unlock => _t('ปลดล็อก', 'Unlock');
  String get biometricNotAvailable => _t(
      'อุปกรณ์นี้ไม่รองรับการสแกนลายนิ้วมือ/ใบหน้า',
      'Biometric unlock is not available on this device');

  // ---------- auth: change PIN (menu) ----------
  String get changePin => _t('เปลี่ยนรหัส PIN', 'Change PIN');
  String get changePinMenu => _t('PIN และการปลดล็อก', 'PIN & app lock');
  String get enterCurrentPin => _t('กรอก PIN ปัจจุบัน', 'Enter current PIN');
  String get enterCurrentPinSubtitle => _t('ยืนยัน PIN เดิมก่อนตั้งรหัสใหม่',
      'Confirm your current PIN before setting a new one');
  String get pinChanged => _t('เปลี่ยน PIN สำเร็จ', 'PIN updated');

  // ---------- auth: change password ----------
  String get security => _t('ความปลอดภัย', 'Security');
  String get changePassword => _t('เปลี่ยนรหัสผ่าน', 'Change password');
  String get oldPassword => _t('รหัสผ่านเดิม', 'Current password');
  String get enterOldPassword =>
      _t('กรอกรหัสผ่านเดิม', 'Enter current password');
  String get newPasswordMin8 =>
      _t('รหัสผ่านใหม่ (อย่างน้อย 8 ตัว)', 'New password (min 8 chars)');
  String get newPasswordMin8Rule => _t('รหัสผ่านใหม่ต้องยาวอย่างน้อย 8 ตัว',
      'New password must be at least 8 chars');
  String get confirmNewPassword =>
      _t('ยืนยันรหัสผ่านใหม่', 'Confirm new password');
  String get passwordsNotMatch =>
      _t('รหัสผ่านไม่ตรงกัน', 'Passwords do not match');
  String get saveNewPassword => _t('บันทึกรหัสผ่านใหม่', 'Save new password');
  String get changePasswordSuccess =>
      _t('เปลี่ยนรหัสผ่านสำเร็จ', 'Password changed');
  String get logout => _t('ออกจากระบบ', 'Log out');

  // ---------- auth: forgot / reset ----------
  String get forgotTitle => _t('ลืมรหัสผ่าน', 'Forgot password');
  String get forgotHint => _t(
      'กรอกอีเมลของคุณ เราจะส่งลิงก์รีเซ็ตรหัสผ่านไปให้',
      "Enter your email and we'll send a reset link");
  String get sendResetLink => _t('ส่งลิงก์รีเซ็ต', 'Send reset link');
  String get resetSentInfo => _t(
      'ถ้ามีบัญชีนี้อยู่ ระบบได้ส่งอีเมลรีเซ็ตให้แล้ว\n(dev: ดูลิงก์/preview ใน console ของ auth-service)',
      'If the account exists, a reset email has been sent\n(dev: see the link/preview in the auth-service console)');
  String get haveTokenAlready =>
      _t('ฉันมีรหัส (token) แล้ว', 'I already have a token');
  String get resetTitle => _t('ตั้งรหัสผ่านใหม่', 'Reset password');
  String get tokenFromEmail => _t('รหัส (token) จากอีเมล', 'Token from email');
  String get enterToken => _t('กรอก token', 'Enter the token');
  String get resetSuccess => _t('ตั้งรหัสผ่านใหม่สำเร็จ เข้าสู่ระบบได้เลย',
      'Password reset — you can sign in now');

  // ---------- email verification ----------
  String get emailNotVerified =>
      _t('อีเมลยังไม่ได้ยืนยัน', 'Email not verified');
  String get verificationSent => _t(
      'ส่งอีเมลยืนยันแล้ว ตรวจกล่องจดหมาย (dev: ดู preview ใน console)',
      'Verification email sent, check your inbox (dev: see preview in console)');
  String get resend => _t('ส่งอีกครั้ง', 'Resend');
  String get sending => _t('กำลังส่ง…', 'Sending…');
  String get sendFailed => _t('ส่งไม่สำเร็จ', 'Failed to send');

  // ---------- month list ----------
  String get monthlySummary => _t('สรุปทุกเดือน', 'Monthly summary');
  String get totalSpent => _t('ยอดรวมสะสม', 'Total spent');
  String get monthsCount => _t('จำนวนเดือน', 'Months');
  String get totalItems => _t('รวมรายการ', 'Items');
  String get noMonths => _t('ยังไม่มีเดือน', 'No months yet');
  String get noMonthsHint => _t('กดปุ่ม + ด้านล่างเพื่อเพิ่มเดือนแรกของคุณ',
      'Tap + below to add your first month');
  String get addMonth => _t('เพิ่มเดือน', 'Add month');
  String get newMonth => _t('เพิ่มเดือนใหม่', 'New month');
  String get monthLabel => _t('เดือน', 'Month');
  String get yearCE => _t('ปี (ค.ศ.)', 'Year');
  String get noteOptional => _t('โน้ต (ไม่บังคับ)', 'Note (optional)');
  String monthN(int m) => _t('เดือน $m', 'Month $m');
  String itemsCount(int n) => _t('$n รายการ', '$n items');
  String quantityCount(int n) => _t('$n ชิ้น', '$n pcs');

  // ---------- month detail ----------
  String get monthSummaryTitle => _t('สรุปยอดเดือนนี้', 'This month');
  String get total => _t('ยอดรวม', 'Total');
  String get itemsLabel => _t('รายการ', 'Items');
  String get piecesLabel => _t('ชิ้น', 'Pcs');
  String get noItems => _t('ยังไม่มีรายการ', 'No items yet');
  String get noItemsHint =>
      _t('กดปุ่ม + เพื่อเพิ่มของชิ้นแรก', 'Tap + to add the first item');
  String get addItem => _t('เพิ่มรายการ', 'Add item');
  String get addItemTitle => _t('เพิ่มสินค้า', 'Add item');
  String get editItemTitle => _t('แก้ไขสินค้า', 'Edit item');
  String get itemName => _t('ชื่อสินค้า', 'Item name');
  String get lettersNumbersSpacesOnly => _t(
      'ใช้ได้เฉพาะตัวอักษร ตัวเลข และเว้นวรรค',
      'Use letters, numbers, and spaces only');
  String get lettersOnly =>
      _t('ใช้ได้เฉพาะตัวอักษรและเว้นวรรค', 'Use letters and spaces only');
  String get decimalNumberOnly =>
      _t('กรอกเป็นตัวเลขทศนิยมเท่านั้น', 'Enter a decimal number only');
  String get priceRequired => _t('กรอกราคาเป็นตัวเลข ไม่เกิน 2 ตำแหน่งทศนิยม',
      'Enter a price with up to 2 decimal places');
  String get positiveIntegerOnly => _t(
      'กรอกเป็นจำนวนเต็มที่มากกว่า 0', 'Enter a whole number greater than 0');
  String get priceFormat => _t('กรอกราคาเป็นตัวเลข ไม่เกิน 2 ตำแหน่งทศนิยม',
      'Enter a number with no more than 2 decimal places');
  String get scanBarcode => _t('สแกนบาร์โค้ด', 'Scan barcode');
  String get addItemHow =>
      _t('เพิ่มสินค้าอย่างไร?', 'How do you want to add an item?');
  String get scanBarcodeOption => _t('สแกนบาร์โค้ด', 'Scan a barcode');
  String get scanBarcodeOptionHint => _t(
      'ใช้กล้องสแกนแล้วเติมข้อมูลให้อัตโนมัติ',
      'Use the camera and auto-fill the details');
  String get manualEntryOption => _t('กรอกเอง', 'Enter manually');
  String get manualEntryOptionHint =>
      _t('กรอกข้อมูลสินค้าด้วยตัวเอง', 'Fill in the product details yourself');
  String get pointCameraAtBarcode => _t('วางบาร์โค้ดสินค้าไว้ในกรอบกล้อง',
      'Point the camera at a product barcode');
  String get cameraPermissionDenied => _t(
      'ไม่ได้รับอนุญาตให้ใช้กล้อง\nเปิดสิทธิ์กล้องให้แอปในหน้าตั้งค่า',
      'Camera permission denied.\nEnable camera access for this app in Settings.');
  String get cameraError => _t('เปิดกล้องไม่ได้ ลองใหม่อีกครั้ง',
      'Unable to open the camera. Please try again.');
  String scannedBarcode(String code) => _t('บาร์โค้ด: $code', 'Barcode: $code');
  String get barcodeLookupNotFound => _t(
      'ไม่พบข้อมูลสินค้า กรอกข้อมูลเองได้เลย',
      'Product not found. You can enter the details manually.');
  String get barcodeLookupSuccess => _t(
      'เติมข้อมูลสินค้าแล้ว ตรวจสอบก่อนกดบันทึก',
      'Product details filled in. Review them before saving.');
  String get quantity => _t('จำนวน', 'Quantity');
  String get increaseQuantity => _t('เพิ่มจำนวน', 'Increase quantity');
  String get decreaseQuantity => _t('ลดจำนวน', 'Decrease quantity');
  String get unitPrice => _t('ราคา (บาท)', 'Price (THB)');
  String get pickExpiry =>
      _t('เลือกวันหมดอายุ (ไม่บังคับ)', 'Pick expiry date (optional)');
  String expiryOn(String d) => _t('หมด: $d', 'Exp: $d');
  String expireShort(String d) => _t('หมด $d', 'Exp $d');
  String overdueDays(int d) => _t('เลยมา $d วัน', '$d days overdue');

  // ---------- notifications ----------
  String get notiExpiringTitle => _t('ของใกล้หมดอายุ', 'Items expiring soon');
  String notiExpiringBody(String name, int days) {
    if (days == 0) return _t('$name จะหมดอายุวันนี้', '$name expires today');
    if (days == 1) {
      return _t('$name จะหมดอายุพรุ่งนี้', '$name expires tomorrow');
    }
    return _t('$name จะหมดอายุในอีก $days วัน', '$name expires in $days days');
  }

  String notiExpiredBody(String name) =>
      _t('$name หมดอายุแล้ว', '$name has expired');

  // recurring (re-buy) variants — a decision nudge, not an expiry warning
  String get notiRecurringTitle =>
      _t('ของซื้อประจำใกล้ครบรอบ', 'Time to re-buy?');
  String notiRecurringBody(String name, int days) {
    if (days <= 0) {
      return _t('$name น่าจะใช้หมดแล้ว — จะซื้ออีกไหม?',
          '$name is likely used up — buy again?');
    }
    if (days == 1) {
      return _t('$name ใกล้หมดแล้ว — จะซื้ออีกไหม?',
          '$name is almost out — buy again?');
    }
    return _t('$name จะใช้หมดในอีก $days วัน — จะซื้ออีกไหม?',
        '$name runs out in $days days — buy again?');
  }

  String get notificationsTitle => _t('การแจ้งเตือน', 'Notifications');
  String get notificationsSubtitle =>
      _t('ของใกล้หมดอายุ', 'Items expiring soon');
  String get noNotifications =>
      _t('ยังไม่มีของใกล้หมดอายุ', 'Nothing expiring soon');
  String get noNotificationsHint => _t(
      'เราจะเตือนเมื่อมีของใกล้หมดอายุภายใน 3 วัน',
      "We'll remind you when items are within 3 days of expiring");
  String get notifRead => _t('อ่านแล้ว', 'Read');
  String get notifUnread => _t('ใหม่', 'New');
  String get notifMarkAllRead => _t('อ่านทั้งหมด', 'Mark all read');
  String get notifMarkRead => _t('ทำเป็นอ่านแล้ว', 'Mark as read');
  String get notifFilterAll => _t('ทั้งหมด', 'All');
  String get notifFilterUnread => _t('ยังไม่อ่าน', 'Unread');
  String get noUnreadNotifications =>
      _t('ไม่มีรายการที่ยังไม่อ่าน', 'No unread notifications');
  // short, emphasised "when it expires" used on the notification chip
  String get expiresTodayShort => _t('หมดวันนี้', 'Expires today');
  String get expiresTomorrowShort => _t('หมดพรุ่งนี้', 'Expires tomorrow');
  String expiresInDaysShort(int d) => _t('อีก $d วัน', 'in $d days');
  String expiredAgoShort(int d) =>
      _t('เลยมาแล้ว $d วัน', 'expired $d days ago');
  // notification day-group headers
  String get notifToday => _t('วันนี้', 'Today');
  String get notifYesterday => _t('เมื่อวาน', 'Yesterday');
  String notifReceivedAt(String time) => _t('แจ้งเมื่อ $time', 'at $time');

  // ---------- item fields (household item) ----------
  String get itemsTitle => _t('ของใช้', 'Items');
  String get itemsMonthSubtitle =>
      _t('ของใช้ในเดือนนี้', 'What you have this month');
  String get noItemsThisMonth =>
      _t('ยังไม่มีของใช้ในเดือนนี้', 'No items in use this month');
  String get noItemsThisMonthHint => _t(
      'ของที่ซื้อเดือนนี้ หรือยังใช้ไม่หมดจากเดือนก่อน จะแสดงที่นี่',
      'Items bought this month, or still in use from before, appear here');
  String get searchItems => _t('ค้นหาสินค้า...', 'Search items...');
  String get noMatchingItems =>
      _t('ไม่พบรายการที่ค้นหา', 'No matching items found');
  String get noMatchingItemsHint =>
      _t('ลองเปลี่ยนคำค้นหาหรือหมวดหมู่', 'Try a different search or category');
  String get clearFilters => _t('ล้างตัวกรอง', 'Clear filters');
  String get categoryLabel => _t('หมวดหมู่', 'Category');
  String get categoryAll => _t('ทั้งหมด', 'All');
  String get sizeLabel => _t('ขนาด', 'Size');
  String get unitFieldLabel => _t('หน่วย', 'Unit');
  String get storeLabel => _t('ร้านค้าที่ซื้อ', 'Store');
  String get purchaseDateLabel => _t('วันที่ซื้อ', 'Purchase date');
  String get buyerLabel => _t('ผู้ซื้อ', 'Buyer');
  String get expiryLabel => _t('วันหมดอายุ', 'Expiry date');
  String get recurringLabel =>
      _t('ซื้อประจำ (แจ้งเตือน)', 'Recurring (notify)');
  String get recurringHint => _t('เตือนให้ตัดสินใจซื้อซ้ำเมื่อใกล้ครบรอบการใช้',
      'Reminds you to re-buy when the usage cycle is almost up');
  String get recurringDaysLabel =>
      _t('ใช้หมดภายในกี่วัน', 'Used up within (days)');
  String get recurringDaysHint => _t('เช่น 7', 'e.g. 7');
  String get daysUnit => _t('วัน', 'days');
  String get recurringDaysInvalid =>
      _t('กรอกจำนวนวัน 1–3650', 'Enter 1–3650 days');
  String recurringPreview(String date) => _t(
      'ระบบจะเตือนให้ซื้อซ้ำประมาณวันที่ $date',
      "We'll remind you to re-buy around $date");
  String get markOutButton => _t('หมดแล้ว', 'Used up');
  String get markedOutDone =>
      _t('ย้ายไปรายการควรซื้อแล้ว', 'Moved to the shopping list');
  String get changePhoto => _t('เปลี่ยนรูปภาพ', 'Change photo');
  String get noItemsYet => _t('ยังไม่มีของใช้', 'No items yet');
  String get noItemsYetHint =>
      _t('กดปุ่ม + เพื่อเพิ่มสินค้าชิ้นแรก', 'Tap + to add your first item');
  String get itemSaved => _t('บันทึกสินค้าแล้ว', 'Item saved');
  String get deleteItem => _t('ลบสินค้า', 'Delete item');
  String get deleteItemConfirmTitle => _t('ลบสินค้า?', 'Delete item?');
  String deleteItemConfirmMessage(String name) => _t(
      'คุณต้องการลบ "$name" ใช่ไหม? การลบนี้ย้อนกลับไม่ได้',
      'Delete "$name"? This cannot be undone.');
  String get delete => _t('ลบ', 'Delete');
  String get itemDeleted => _t('ลบสินค้าแล้ว', 'Item deleted');
  String get purchaseHistory => _t('ประวัติการซื้อ', 'Purchase history');
  String categoryName(String c) {
    switch (c) {
      case 'laundry':
        return _t('ซักล้าง', 'Laundry');
      case 'kitchen':
        return _t('ห้องครัว', 'Kitchen');
      case 'bathroom':
        return _t('ห้องน้ำ', 'Bathroom');
      case 'food':
        return _t('อาหารและเครื่องดื่ม', 'Food & drink');
      case 'personal':
        return _t('ของใช้ส่วนตัว', 'Personal');
      default:
        return _t('อื่นๆ', 'Other');
    }
  }

  // ---------- expiring soon ----------
  String get notifications => _t('แจ้งเตือน', 'Alerts');
  String get expiringTitle => _t('ของใกล้หมดอายุ', 'Expiring soon');
  String get noExpiring => _t('ไม่มีของใกล้หมด', 'Nothing expiring');

  // ---------- stock status (4 แบบ) ----------
  String get statusNormal => _t('ปกติ', 'In stock');
  String get statusLow => _t('ใกล้หมด', 'Low');
  String get statusShouldBuy => _t('ควรซื้อ', 'Buy soon');
  String get statusOut => _t('หมดแล้ว', 'Out');
  String noExpiringHint(int days) => _t(
      'ไม่มีรายการที่จะหมดอายุภายใน $days วัน 🎉',
      'No items expiring within $days days 🎉');
  String withinDays(int d) => _t('≤ $d วัน', '≤ $d days');
  String daysLeft(int d) => _t('อีก $d วัน', '$d days left');
  String expiryWithQty(String d, int qty) =>
      _t('หมด: $d · $qty ชิ้น', 'Exp: $d · $qty pcs');
  String noExpiryWithQty(int qty) =>
      _t('ไม่ระบุวันหมด · $qty ชิ้น', 'No expiry · $qty pcs');

  // ---------- profile ----------
  String get myProfile => _t('โปรไฟล์ของฉัน', 'My profile');
  String get editProfile => _t('แก้ไขโปรไฟล์', 'Edit profile');
  String get statusField => _t('สถานะ / คำอธิบายตัวเอง', 'Status / bio');
  String get pickBirthDate => _t('เลือกวันเดือนปีเกิด', 'Pick birth date');
  String birthDateOn(String d) => _t('วันเกิด: $d', 'Birthday: $d');
  String get removePhoto => _t('ลบรูป', 'Remove photo');
  String get profileSaved => _t('บันทึกโปรไฟล์แล้ว', 'Profile saved');
  String get profileSaveFailed => _t('บันทึกไม่สำเร็จ', 'Save failed');

  // ---------- budget ----------
  String get budgetTitle => _t('งบประมาณ', 'Budget');
  String get expectedSpend => _t('ค่าใช้จ่ายทั้งหมด', 'Total spend');
  String get setBudget => _t('ตั้งงบประมาณ', 'Set budget');
  String get budgetField => _t('งบประมาณ (บาท)', 'Budget (THB)');
  String get spendByMonth => _t('ค่าใช้จ่ายรายเดือน', 'Spend by month');
  String get spendByCategory =>
      _t('ค่าใช้จ่ายตามหมวดหมู่', 'Spend by category');
  String get noBudgetData =>
      _t('ยังไม่มีข้อมูลค่าใช้จ่าย', 'No spending data yet');
  String ofBudgetUsed(String pct) =>
      _t('ใช้ไป $pct% ของงบ', '$pct% of budget used');
  String get save2 => _t('บันทึก', 'Save');

  // ---------- to-buy (shopping checklist) ----------
  String get toBuyTitle => _t('ต้องซื้อ', 'To buy');
  String get toBuyEmpty => _t('ไม่มีของที่ต้องซื้อ 🎉', 'Nothing to buy 🎉');
  String get toBuyEmptyHint =>
      _t('ของใช้ทุกชิ้นยังมีเพียงพอ', 'All your items are well stocked');
  String get toBuyOutSection => _t('หมดแล้ว', 'Out of stock');
  String get toBuyLowSection => _t('ใกล้หมด', 'Running low');
  String get selectAll => _t('เลือกทั้งหมด', 'Select all');
  String get buyButton => _t('ซื้อ', 'Buy');
  String selectedItems(int count) =>
      _t('เลือกแล้ว $count รายการ', '$count selected');
  String buySelected(int count) =>
      _t('ซื้อรายการที่เลือก ($count)', 'Buy selected ($count)');
  String purchaseBatchSaved(int count) =>
      _t('บันทึกการซื้อแล้ว $count รายการ', 'Recorded $count purchases');
  String get checkout => _t('ส่งซื้อ / ซื้อแล้ว', 'Mark as bought');
  String checkoutDone(int n) =>
      _t('ทำเครื่องหมายซื้อแล้ว $n รายการ', 'Marked $n items as bought');
  String get selectItemsFirst =>
      _t('เลือกรายการที่จะซื้อก่อน', 'Select items to buy first');

  // ---------- common error prefixes ----------
  String get cannotConnect => _t('เชื่อมต่อไม่ได้', 'Cannot connect');
  String errorWith(Object e) => _t('เกิดข้อผิดพลาด: $e', 'Error: $e');

  // ---------- language ----------
  String get language => _t('ภาษา', 'Language');
  String get thai => _t('ไทย', 'Thai');
  String get english => _t('อังกฤษ', 'English');

  // ---------- settings ----------
  String get settings => _t('ตั้งค่า', 'Settings');
  String get logoutConfirmTitle => _t('ออกจากระบบ?', 'Log out?');
  String get logoutConfirmMessage =>
      _t('คุณต้องการออกจากระบบใช่ไหม', 'Are you sure you want to log out?');
  String get theme => _t('ธีม', 'Theme');
  String get themeLight => _t('สว่าง', 'Light');
  String get themeDark => _t('มืด', 'Dark');
  String get themeSystem => _t('ตามระบบ', 'System');
  String get appearance => _t('การแสดงผล', 'Appearance');

  // ---------- bottom navigation ----------
  String get navHome => _t('หน้าหลัก', 'Home');
  String get navItems => _t('ของใช้', 'Items');
  String get navToBuy => _t('ต้องซื้อ', 'To buy');
  String get navBudget => _t('งบประมาณ', 'Budget');
  String get navMenu => _t('เมนู', 'Menu');

  // ---------- home dashboard ----------
  String greeting(String name) => name.isEmpty
      ? _t('สวัสดี 👋', 'Hi 👋')
      : _t('สวัสดี, $name 👋', 'Hi, $name 👋');
  String get homeQuestion =>
      _t('บ้านของเราเป็นอย่างไรบ้าง?', "How's your home today?");
  String get statAllItems => _t('ของใช้ทั้งหมด', 'All items');
  String get statLowItems => _t('ใกล้หมด', 'Low stock');
  String get statItemsUnit => _t('รายการ', 'items');
  String get toManage => _t('รายการที่ต้องจัดการ', 'Needs attention');
  String get seeAll => _t('ดูทั้งหมด', 'See all');
  String get nothingToManage =>
      _t('ไม่มีรายการที่ต้องจัดการ 🎉', 'Nothing needs attention 🎉');
  String get monthlyBudget => _t('งบประมาณเดือนนี้', "This month's spend");
  String get fromBudget => _t('จากงบประมาณ', 'of budget');
  String get addProduct => _t('เพิ่มสินค้า', 'Add item');
  String get comingSoon => _t('เร็ว ๆ นี้', 'Coming soon');
  String get comingSoonHint =>
      _t('ฟีเจอร์นี้กำลังพัฒนา', 'This feature is coming soon');

  // ---------- product master + purchases (redesign) ----------
  // menu entries
  String get productsMenu => _t('คลังสินค้า', 'Product catalogue');
  String get productsMenuHint =>
      _t('ดูของทั้งหมดที่มี + สถานะ', 'All your products + status');

  // product master list
  String get productMasterTitle => _t('คลังสินค้า', 'Product catalogue');
  String get searchProducts => _t('ค้นหาสินค้า...', 'Search products...');
  String get noProductsYet => _t('ยังไม่มีสินค้า', 'No products yet');
  String get noProductsYetHint =>
      _t('กดปุ่ม + เพื่อเพิ่มสินค้าชิ้นแรก', 'Tap + to add your first product');
  String get noMatchingProducts =>
      _t('ไม่พบสินค้าที่ค้นหา', 'No matching products');
  String get recurringBadge => _t('ซื้อประจำ', 'Recurring');

  // product status (master, user-driven)
  String get productStatusInStock => _t('มีของ', 'In stock');
  String get productStatusLow => _t('ใกล้หมด', 'Low');
  String get productStatusOut => _t('หมดแล้ว', 'Out');

  // ---------- add flow (new product vs record purchase) ----------
  String get addFlowTitle =>
      _t('เพิ่มเข้าของใช้อย่างไร?', 'How do you want to add?');
  String get addNewProductOption =>
      _t('สร้างสินค้าใหม่', 'Create a new product');
  String get addNewProductOptionHint => _t('เพิ่มสินค้าที่ยังไม่มีในคลัง',
      'Add a product not in your catalogue yet');
  String get recordPurchaseOption =>
      _t('บันทึกการซื้อของที่มีอยู่', 'Record a purchase');
  String get recordPurchaseOptionHint => _t(
      'เลือกสินค้าที่มีอยู่แล้ว แล้วบันทึกการซื้อครั้งใหม่',
      'Pick an existing product and log a new purchase');
  String get createProductHow =>
      _t('สร้างสินค้าใหม่อย่างไร?', 'How do you want to create it?');

  // ---------- record purchase screen ----------
  String get recordPurchaseTitle => _t('บันทึกการซื้อ', 'Record purchase');
  String get pickProduct => _t('เลือกสินค้า', 'Pick a product');
  String get purchaseDetails => _t('รายละเอียดการซื้อ', 'Purchase details');
  String get purchaseSaved => _t('บันทึกการซื้อแล้ว', 'Purchase recorded');
  String get changeProduct => _t('เปลี่ยนสินค้า', 'Change product');

  // ---------- product detail screen ----------
  String get productDetailTitle => _t('รายละเอียดสินค้า', 'Product details');
  String get editProductTitle => _t('แก้ไขสินค้า', 'Edit product');
  String get productUpdated => _t('แก้ไขสินค้าแล้ว', 'Product updated');
  String get saveChanges => _t('บันทึกการแก้ไข', 'Save changes');
  String get pricePerUnit => _t('ราคาต่อชิ้น', 'Price per item');
  String get noPriceHistory =>
      _t('ยังไม่มีข้อมูลราคา', 'No price information yet');
  String get productSize => _t('ขนาดสินค้า', 'Product size');
  String get statusSection => _t('สถานะ', 'Status');
  String get statusActionHint => _t('แตะปุ่มเพื่อเปลี่ยนสถานะสินค้า',
      'Tap a button to change product status');
  String get currentStatus => _t('สถานะปัจจุบัน', 'Current status');
  String get markLowButton => _t('ใกล้หมด', 'Running low');
  String get markInStockButton => _t('เติมแล้ว / มีของ', 'Restocked');
  String get statusUpdated => _t('อัปเดตสถานะแล้ว', 'Status updated');
  String get productLowReminderTitle => _t('ของใกล้หมด', 'Running low');
  String productLowReminderBody(String name) => _t(
      '$name ใกล้หมดแล้ว อย่าลืมซื้อ',
      '$name is running low. Remember to buy it.');
  String get productOutReminderTitle => _t('ของหมดแล้ว', 'Out of stock');
  String productOutReminderBody(String name) =>
      _t('$name หมดแล้ว อย่าลืมซื้อ', '$name is out. Remember to buy it.');
  String get noPurchaseHistory =>
      _t('ยังไม่มีประวัติการซื้อ', 'No purchase history yet');
  String get recordPurchaseAction => _t('บันทึกการซื้อ', 'Record a purchase');

  // delete product
  String get deleteProductConfirmTitle => _t('ลบสินค้า?', 'Delete product?');
  String deleteProductConfirmMessage(String name) => _t(
      'คุณต้องการลบ "$name" และประวัติการซื้อทั้งหมดใช่ไหม? การลบนี้ย้อนกลับไม่ได้',
      'Delete "$name" and all its purchase history? This cannot be undone.');
  String get productDeleted => _t('ลบสินค้าแล้ว', 'Product deleted');
  String get removeProductFromMonthTitle =>
      _t('ลบสินค้าในเดือนนี้?', 'Delete for this month?');
  String removeProductFromMonthMessage(String name, String month) => _t(
        'ลบ "$name" ออกจากรายการของใช้เดือน $month ใช่ไหม?',
        'Remove "$name" from the items list for $month?',
      );
  String get productRemovedFromMonth =>
      _t('นำสินค้าออกจากรายการเดือนนี้แล้ว', 'Product removed from this month');

  // add product screen
  String get addProductTitle => _t('เพิ่มสินค้า', 'Add product');
  String get productInfoSection => _t('ข้อมูลสินค้า', 'Product information');
  String get firstPurchaseSection =>
      _t('การซื้อครั้งแรก (ไม่บังคับ)', 'First purchase (optional)');
  String get firstPurchaseHint => _t(
      'บันทึกการซื้อครั้งแรกไปพร้อมกัน เว้นว่างไว้ได้ถ้ายังไม่ได้ซื้อ',
      'Record the first purchase too. Leave blank if not bought yet.');
  String get enterProductName => _t('กรอกชื่อสินค้า', 'Enter the product name');
  String get productSaved => _t('เพิ่มสินค้าแล้ว', 'Product added');

  // monthly summary (shown inside the budget tab)
  String get grandTotalLabel => _t('ยอดรวม', 'Total spend');
  String get totalPurchasesLabel => _t('จำนวนครั้ง', 'Purchases');
  String get totalQtyLabel => _t('รวมจำนวน', 'Total qty');
  String get byBuyerTitle => _t('แยกตามผู้ซื้อ', 'By buyer');
  String get purchasesThisMonth =>
      _t('รายการซื้อเดือนนี้', 'Purchases this month');
  String get noPurchasesThisMonth =>
      _t('ยังไม่มีการซื้อในเดือนนี้', 'No purchases this month');
  String get prevMonth => _t('เดือนก่อน', 'Previous month');
  String get nextMonth => _t('เดือนถัดไป', 'Next month');
  String get selectMonth => _t('เลือกเดือน', 'Select month');
  String get unknownBuyer => _t('ไม่ระบุผู้ซื้อ', 'Unknown buyer');
  String purchasedOn(String d) => _t('ซื้อเมื่อ $d', 'Bought $d');

  /// Resolve a backend error { domain, code, message } into a localized string.
  /// Falls back to the backend-provided English message, then a generic text.
  String errorForCode(String? code, {String? fallback}) {
    final map = _th ? _errorsTh : _errorsEn;
    if (code != null && map.containsKey(code)) return map[code]!;
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return _t('เกิดข้อผิดพลาด', 'Something went wrong');
  }

  static const _errorsTh = <String, String>{
    // auth
    'EMAIL_ALREADY_USED': 'อีเมลนี้ถูกใช้งานแล้ว',
    'INVALID_CREDENTIALS': 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
    'USER_NOT_FOUND': 'ไม่พบผู้ใช้',
    'INVALID_REFRESH_TOKEN': 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่',
    'MISSING_ACCESS_TOKEN': 'กรุณาเข้าสู่ระบบ',
    'INVALID_ACCESS_TOKEN': 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่',
    'WRONG_OLD_PASSWORD': 'รหัสผ่านเดิมไม่ถูกต้อง',
    'INVALID_VERIFY_TOKEN': 'ลิงก์ยืนยันไม่ถูกต้องหรือหมดอายุ',
    'INVALID_RESET_TOKEN': 'ลิงก์รีเซ็ตไม่ถูกต้องหรือหมดอายุ',
    'PENDING_NOT_FOUND': 'ไม่พบคำขอสมัครสำหรับอีเมลนี้ กรุณาสมัครใหม่',
    'INVALID_OTP': 'รหัส OTP ไม่ถูกต้อง',
    'OTP_EXPIRED': 'รหัส OTP หมดอายุแล้ว กรุณาขอรหัสใหม่',
    'TOO_MANY_OTP_ATTEMPTS': 'กรอกผิดหลายครั้งเกินไป กรุณาขอรหัสใหม่',
    'EMAIL_NOT_VERIFIED': 'กรุณายืนยันอีเมลด้วยรหัส OTP ก่อน',
    'INVALID_SETUP_TICKET': 'เซสชันตั้งรหัสผ่านหมดอายุ กรุณาเริ่มใหม่',
    // catalog / analytics
    'MONTH_NOT_FOUND': 'ไม่พบเดือนที่ระบุ',
    'ITEM_NOT_FOUND': 'ไม่พบรายการที่ระบุ',
    'MISSING_SSO_ID': 'กรุณาเข้าสู่ระบบ',
    'USERNAME_TAKEN': 'ชื่อผู้ใช้นี้ถูกใช้แล้ว',
    'PROFILE_NOT_FOUND': 'ไม่พบโปรไฟล์',
    'PROFILE_PROVISION_FAILED': 'สร้างโปรไฟล์ไม่สำเร็จ ลองใหม่อีกครั้ง',
    'UPSTREAM_UNAVAILABLE': 'บริการขัดข้องชั่วคราว ลองใหม่อีกครั้ง',
    // shared
    'VALIDATION_ERROR': 'ข้อมูลไม่ถูกต้อง',
    'INTERNAL_ERROR': 'เกิดข้อผิดพลาดภายในระบบ',
  };

  static const _errorsEn = <String, String>{
    'EMAIL_ALREADY_USED': 'This email is already in use',
    'INVALID_CREDENTIALS': 'Invalid email or password',
    'USER_NOT_FOUND': 'User not found',
    'INVALID_REFRESH_TOKEN': 'Session expired, please sign in again',
    'MISSING_ACCESS_TOKEN': 'Please sign in',
    'INVALID_ACCESS_TOKEN': 'Session expired, please sign in again',
    'WRONG_OLD_PASSWORD': 'Current password is incorrect',
    'INVALID_VERIFY_TOKEN': 'Verification link is invalid or expired',
    'INVALID_RESET_TOKEN': 'Reset link is invalid or expired',
    'PENDING_NOT_FOUND':
        'No pending registration for this email, please sign up again',
    'INVALID_OTP': 'The OTP code is incorrect',
    'OTP_EXPIRED': 'The OTP code has expired, request a new one',
    'TOO_MANY_OTP_ATTEMPTS': 'Too many incorrect attempts, request a new code',
    'EMAIL_NOT_VERIFIED': 'Please verify your email with the OTP first',
    'INVALID_SETUP_TICKET': 'Setup session expired, please start over',
    'MONTH_NOT_FOUND': 'Month not found',
    'ITEM_NOT_FOUND': 'Item not found',
    'MISSING_SSO_ID': 'Please sign in',
    'USERNAME_TAKEN': 'This username is already taken',
    'PROFILE_NOT_FOUND': 'Profile not found',
    'PROFILE_PROVISION_FAILED': 'Could not create profile, try again',
    'UPSTREAM_UNAVAILABLE': 'Service temporarily unavailable, try again',
    'VALIDATION_ERROR': 'Invalid data',
    'INTERNAL_ERROR': 'Internal error',
  };
}
