import '../../../core/constants/app_constants.dart';

/// Strongly-typed string and content configuration for Auth screens
/// Adheres strictly to: No hardcoded values or raw data in widget trees
class AuthContentData {
  // Common
  static String get appName => AppConstants.appName;
  static const String appTagline = 'Intelligent Wealth & EMI Command';
  static const String exploreGuest = 'Explore App';

  // Login
  static const String loginWelcomeTitle = 'Welcome Back';
  static const String loginWelcomeSubtitle = 'Sign in to access your financial intelligence vault';
  static const String loginEmailLabel = 'EMAIL OR PHONE NUMBER';
  static const String loginEmailHint = 'Enter email or phone number';
  static const String loginPasswordLabel = 'PASSWORD';
  static const String loginPasswordHint = 'Enter your password';
  static const String rememberMe = 'Remember me';
  static const String forgotPassword = 'Forgot Password?';
  static const String signInButton = 'Sign In';
  static const String orContinueWith = 'OR CONTINUE WITH';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String createAccountLink = 'Create New';
  static const String googleLabel = 'Google';
  static const String appleLabel = 'Apple';

  // Register
  static const String registerTitle = 'Create Your Account';
  static const String registerSubtitle = 'Join thousands tracking cashflow with zero late fees';
  static const String registerNameLabel = 'FULL NAME';
  static const String registerNameHint = 'Enter your full name';
  static const String registerEmailLabel = 'EMAIL ADDRESS';
  static const String registerEmailHint = 'Enter your email address';
  static const String registerPhoneLabel = 'WHATSAPP / MOBILE NUMBER';
  static const String registerPhoneHint = '10-digit mobile number';
  static const String registerPasswordLabel = 'PASSWORD';
  static const String registerPasswordHint = 'Min. 6 characters';
  static const String registerConfirmPasswordLabel = 'CONFIRM PASSWORD';
  static const String registerConfirmPasswordHint = 'Re-enter your password';
  static const String registerButton = 'Create Free Account';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String signInLink = 'Sign In';

  // Forgot Password
  static const String forgotTitle = 'Recover Password';
  static const String forgotSubtitle = "Enter your registered email address or mobile. We'll dispatch a 6-digit security verification code.";
  static const String forgotEmailLabel = 'REGISTERED EMAIL / PHONE';
  static const String forgotEmailHint = 'Enter registered email or phone';
  static const String forgotSubmitButton = 'Send 6-Digit Code';
  static const String backToSignIn = 'Back to Sign In';

  // OTP Verification
  static const String otpTitle = 'Two-Step Verification';
  static const String otpSubtitle = 'Enter the 6-digit verification code sent to';
  static const String otpDemoNotice = 'Demo Security Code: 2 8 4 7 1 9';
  static const String otpResendCountdown = 'Resend code in ';
  static const String otpResendButton = 'Resend Code';
  static const String otpVerifyButton = 'Verify & Proceed';

  // Reset Password
  static const String resetTitle = 'Set New Password';
  static const String resetSubtitle = 'Create a secure new password to protect your financial vault.';
  static const String resetNewPasswordLabel = 'NEW PASSWORD';
  static const String resetNewPasswordHint = 'Enter new password';
  static const String resetConfirmPasswordLabel = 'CONFIRM NEW PASSWORD';
  static const String resetConfirmPasswordHint = 'Re-enter new password';
  static const String resetSubmitButton = 'Update Password & Sign In';

  // Validation Messages
  static const String errorFillRequired = 'Please fill in all required fields';
  static const String errorPasswordMismatch = 'Passwords do not match';
  static const String errorPasswordLength = 'Password must be at least 6 characters';
  static const String errorInvalidCredentials = 'Invalid email or password';
  static const String errorInvalidOtp = 'Please enter all 6 digits of the verification code';
  static const String successOtpVerified = 'OTP verified successfully!';
  static const String successPasswordReset = 'Password updated successfully! Please sign in.';
}
