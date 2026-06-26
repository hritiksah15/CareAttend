// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Care Attend';

  @override
  String get appSubtitle => 'NHS Predictive Risk Assessment';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInDesc => 'Sign in to access your practice dashboard';

  @override
  String get emailAddress => 'Email or Username';

  @override
  String get password => 'Password';

  @override
  String get login => 'LOG IN';

  @override
  String get createAccount => 'CREATE NEW ACCOUNT';

  @override
  String get backToLogin => 'BACK TO LOGIN';

  @override
  String get dataProtection => 'Data Protection Notice';

  @override
  String get noDataStored => 'No patient data is stored on this device.';

  @override
  String get sessionCleared => 'All session data is cleared on close.';

  @override
  String get gdprCompliant => 'GDPR Article 5(1)(c) compliant.';

  @override
  String get patientAssessment => 'Patient Assessment';

  @override
  String get riskDashboard => 'Risk Dashboard';

  @override
  String get batchUpload => 'Batch Upload';

  @override
  String get biasMonitor => 'Bias Monitor';

  @override
  String get demographics => 'DEMOGRAPHICS';

  @override
  String get appointmentDetails => 'APPOINTMENT DETAILS';

  @override
  String get clinicalFlags => 'CLINICAL FLAGS';

  @override
  String get socialContext => 'SOCIAL CONTEXT';

  @override
  String get assessRisk => 'ASSESS RISK';

  @override
  String get age => 'Age (0-120)';

  @override
  String get gender => 'Gender';

  @override
  String get leadTime => 'Lead Time (days)';

  @override
  String get priorDNA => 'Prior DNA Count';

  @override
  String get smsReceived => 'SMS Reminder Received';

  @override
  String get hypertension => 'Hypertension';

  @override
  String get diabetes => 'Diabetes';

  @override
  String get alcoholism => 'Alcohol Dependency';

  @override
  String get disability => 'Registered Disability';

  @override
  String get imdDecile => 'IMD Decile (1-10)';

  @override
  String get riskLevel => 'DNA Risk Level';

  @override
  String get whyThisScore => 'Why This Score? (SHAP)';

  @override
  String get increasesRisk => 'Increases Risk';

  @override
  String get reducesRisk => 'Reduces Risk';

  @override
  String get interventions => 'Recommended Interventions';

  @override
  String get newAssessment => 'New Assessment';

  @override
  String get biasDashboard => 'Bias Dashboard';

  @override
  String get exportPDF => 'EXPORT PDF AUDIT REPORT';

  @override
  String get runAudit => 'Run Bias Audit';

  @override
  String get riskHistory => 'Risk History (Session)';

  @override
  String get highRisk => 'HIGH RISK';

  @override
  String get mediumRisk => 'MEDIUM RISK';

  @override
  String get lowRisk => 'LOW RISK';

  @override
  String get navResults => 'Results';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navClinic => 'Clinic List';

  @override
  String get navMore => 'More';

  @override
  String get navEthics => 'Ethics';

  @override
  String get navSlots => 'Slot Optimisation';

  @override
  String get navNudge => 'Patient Nudge';

  @override
  String get navAdmin => 'User Management';

  @override
  String get personalAccount => 'Personal Account';

  @override
  String get logout => 'Log Out';

  @override
  String get language => 'Language';
}
