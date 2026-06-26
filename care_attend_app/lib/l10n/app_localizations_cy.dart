// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Welsh (`cy`).
class AppLocalizationsCy extends AppLocalizations {
  AppLocalizationsCy([String locale = 'cy']) : super(locale);

  @override
  String get appTitle => 'Care Attend';

  @override
  String get appSubtitle => 'Asesiad Risg Rhagfynegol GIG';

  @override
  String get welcomeBack => 'Croeso Nôl';

  @override
  String get signInDesc => 'Mewngofnodwch i gyrchu eich dangosfwrdd practis';

  @override
  String get emailAddress => 'E-bost neu Enw Defnyddiwr';

  @override
  String get password => 'Cyfrinair';

  @override
  String get login => 'MEWNGOFNODI';

  @override
  String get createAccount => 'CREU CYFRIF NEWYDD';

  @override
  String get backToLogin => 'YN ÔL I FEWNGOFNODI';

  @override
  String get dataProtection => 'Hysbysiad Diogelu Data';

  @override
  String get noDataStored =>
      'Nid yw data cleifion yn cael ei storio ar y ddyfais hon.';

  @override
  String get sessionCleared =>
      'Mae holl ddata sesiwn yn cael ei glirio ar gau.';

  @override
  String get gdprCompliant => 'Yn cydymffurfio ag Erthygl 5(1)(c) GDPR.';

  @override
  String get patientAssessment => 'Asesiad Claf';

  @override
  String get riskDashboard => 'Dangosfwrdd Risg';

  @override
  String get batchUpload => 'Uwchlwytho Swp';

  @override
  String get biasMonitor => 'Monitor Rhagfarn';

  @override
  String get demographics => 'DEMOGRAFFEG';

  @override
  String get appointmentDetails => 'MANYLION APWYNTIAD';

  @override
  String get clinicalFlags => 'BANERI CLINIGOL';

  @override
  String get socialContext => 'CYDESTUN CYMDEITHASOL';

  @override
  String get assessRisk => 'ASESU RISG';

  @override
  String get age => 'Oedran (0-120)';

  @override
  String get gender => 'Rhyw';

  @override
  String get leadTime => 'Amser Arwain (dyddiau)';

  @override
  String get priorDNA => 'Cyfrif DNA Blaenorol';

  @override
  String get smsReceived => 'Nodyn SMS wedi\'i Dderbyn';

  @override
  String get hypertension => 'Gorbwysedd';

  @override
  String get diabetes => 'Diabetes';

  @override
  String get alcoholism => 'Dibyniaeth Alcohol';

  @override
  String get disability => 'Anabledd Cofrestredig';

  @override
  String get imdDecile => 'Degfed IMD (1-10)';

  @override
  String get riskLevel => 'Lefel Risg DNA';

  @override
  String get whyThisScore => 'Pam y Sgôr Hon? (SHAP)';

  @override
  String get increasesRisk => 'Yn Cynyddu Risg';

  @override
  String get reducesRisk => 'Yn Lleihau Risg';

  @override
  String get interventions => 'Ymyriadau a Argymhellir';

  @override
  String get newAssessment => 'Asesiad Newydd';

  @override
  String get biasDashboard => 'Dangosfwrdd Rhagfarn';

  @override
  String get exportPDF => 'ALLFORIO ADRODDIAD ARCHWILIAD PDF';

  @override
  String get runAudit => 'Rhedeg Archwiliad Rhagfarn';

  @override
  String get riskHistory => 'Hanes Risg (Sesiwn)';

  @override
  String get highRisk => 'RISG UCHEL';

  @override
  String get mediumRisk => 'RISG CANOLIG';

  @override
  String get lowRisk => 'RISG ISEL';

  @override
  String get navResults => 'Canlyniadau';

  @override
  String get navDashboard => 'Dangosfwrdd';

  @override
  String get navClinic => 'Rhestr Clinig';

  @override
  String get navMore => 'Mwy';

  @override
  String get navEthics => 'Moeseg';

  @override
  String get navSlots => 'Slotiau';

  @override
  String get navNudge => 'Anogwr Claf';

  @override
  String get navAdmin => 'Rheoli Defnyddwyr';

  @override
  String get personalAccount => 'Cyfrif Personol';

  @override
  String get logout => 'Allgofnodi';

  @override
  String get language => 'Iaith';

  @override
  String get rememberMe => 'Cofiwch fi';

  @override
  String get forgotPassword => 'Anghofio cyfrinair?';

  @override
  String get orText => 'NEU';

  @override
  String get assessmentIntro =>
      'Rhowch fanylion y claf i gynhyrchu rhagfynegiad risg DNA gydag allbynnau AI esboniadwy.';

  @override
  String get autofill => 'Llenwi\'n awtomatig';

  @override
  String get carerProxy => 'Dirprwy Gofalwr / Teulu';

  @override
  String get female => 'Benyw';

  @override
  String get male => 'Gwryw';

  @override
  String ageGroupLine(String group) {
    return 'Grŵp Oedran: $group (cyfrifo\'n awtomatig)';
  }

  @override
  String get aboutTool => 'Am yr Offeryn Hwn';

  @override
  String get aboutToolDesc =>
      'Mae Care Attend yn defnyddio dysgu peirianyddol i ragfynegi risg DNA. Esbonnir rhagfynegiadau drwy SHAP. Mae\'r system yn monitro am ragfarn ddemograffig.';

  @override
  String get dataHandling =>
      'Trin Data: Ni storir data cleifion. Sesiwn yn unig. Yn cydymffurfio ag Erthygl 5(1)(c) GDPR.';
}
