// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Care Attend';

  @override
  String get appSubtitle => 'NHS Predykcyjna Ocena Ryzyka';

  @override
  String get welcomeBack => 'Witaj ponownie';

  @override
  String get signInDesc => 'Zaloguj się, aby uzyskać dostęp do panelu praktyki';

  @override
  String get emailAddress => 'E-mail lub nazwa użytkownika';

  @override
  String get password => 'Hasło';

  @override
  String get login => 'ZALOGUJ SIĘ';

  @override
  String get createAccount => 'UTWÓRZ NOWE KONTO';

  @override
  String get backToLogin => 'POWRÓT DO LOGOWANIA';

  @override
  String get dataProtection => 'Informacja o ochronie danych';

  @override
  String get noDataStored =>
      'Dane pacjentów nie są przechowywane na tym urządzeniu.';

  @override
  String get sessionCleared => 'Wszystkie dane sesji są usuwane po zamknięciu.';

  @override
  String get gdprCompliant => 'Zgodność z art. 5 ust. 1 lit. c) RODO.';

  @override
  String get patientAssessment => 'Ocena pacjenta';

  @override
  String get riskDashboard => 'Panel ryzyka';

  @override
  String get batchUpload => 'Przesyłanie wsadowe';

  @override
  String get biasMonitor => 'Monitor stronniczości';

  @override
  String get demographics => 'DANE DEMOGRAFICZNE';

  @override
  String get appointmentDetails => 'SZCZEGÓŁY WIZYTY';

  @override
  String get clinicalFlags => 'FLAGI KLINICZNE';

  @override
  String get socialContext => 'KONTEKST SPOŁECZNY';

  @override
  String get assessRisk => 'OCEŃ RYZYKO';

  @override
  String get age => 'Wiek (0-120)';

  @override
  String get gender => 'Płeć';

  @override
  String get leadTime => 'Czas oczekiwania (dni)';

  @override
  String get priorDNA => 'Poprzednie nieobecności';

  @override
  String get smsReceived => 'Otrzymano przypomnienie SMS';

  @override
  String get hypertension => 'Nadciśnienie';

  @override
  String get diabetes => 'Cukrzyca';

  @override
  String get alcoholism => 'Uzależnienie od alkoholu';

  @override
  String get disability => 'Zarejestrowana niepełnosprawność';

  @override
  String get imdDecile => 'Decyl IMD (1-10)';

  @override
  String get riskLevel => 'Poziom ryzyka DNA';

  @override
  String get whyThisScore => 'Dlaczego ten wynik? (SHAP)';

  @override
  String get increasesRisk => 'Zwiększa ryzyko';

  @override
  String get reducesRisk => 'Zmniejsza ryzyko';

  @override
  String get interventions => 'Zalecane interwencje';

  @override
  String get newAssessment => 'Nowa ocena';

  @override
  String get biasDashboard => 'Panel stronniczości';

  @override
  String get exportPDF => 'EKSPORTUJ RAPORT AUDYTU PDF';

  @override
  String get runAudit => 'Uruchom audyt stronniczości';

  @override
  String get riskHistory => 'Historia ryzyka (sesja)';

  @override
  String get highRisk => 'WYSOKIE RYZYKO';

  @override
  String get mediumRisk => 'ŚREDNIE RYZYKO';

  @override
  String get lowRisk => 'NISKIE RYZYKO';

  @override
  String get navResults => 'Wyniki';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navClinic => 'Lista kliniki';

  @override
  String get navMore => 'Więcej';

  @override
  String get navEthics => 'Etyka';

  @override
  String get navSlots => 'Optymalizacja slotów';

  @override
  String get navNudge => 'Przypomnienie dla pacjenta';

  @override
  String get navAdmin => 'Zarządzanie użytkownikami';

  @override
  String get personalAccount => 'Konto osobiste';

  @override
  String get logout => 'Wyloguj';

  @override
  String get language => 'Język';

  @override
  String get rememberMe => 'Zapamiętaj mnie';

  @override
  String get forgotPassword => 'Nie pamiętasz hasła?';

  @override
  String get orText => 'LUB';

  @override
  String get assessmentIntro =>
      'Wprowadź dane pacjenta, aby wygenerować prognozę ryzyka nieobecności z wyjaśnialnymi wynikami AI.';

  @override
  String get autofill => 'Autouzupełnianie';

  @override
  String get carerProxy => 'Pełnomocnik opiekuna / rodziny';

  @override
  String get female => 'Kobieta';

  @override
  String get male => 'Mężczyzna';

  @override
  String ageGroupLine(String group) {
    return 'Grupa wiekowa: $group (obliczono automatycznie)';
  }

  @override
  String get aboutTool => 'O tym narzędziu';

  @override
  String get aboutToolDesc =>
      'Care Attend wykorzystuje uczenie maszynowe do prognozowania ryzyka nieobecności. Prognozy wyjaśniane przez SHAP. System monitoruje stronniczość demograficzną.';

  @override
  String get dataHandling =>
      'Przetwarzanie danych: brak przechowywania danych pacjenta. Tylko sesja. Zgodność z art. 5 ust. 1 lit. c) RODO.';

  @override
  String get noAssessmentYet => 'Brak oceny';

  @override
  String get noAssessmentDesc => 'Wykonaj ocenę pacjenta, aby zobaczyć wyniki.';

  @override
  String get goToAssessment => 'Przejdź do oceny';

  @override
  String get plainEnglishSummary => 'Podsumowanie prostym językiem';

  @override
  String get exportReport => 'Eksportuj raport';

  @override
  String get feedbackQuestion => 'Czy ta prognoza była trafna?';

  @override
  String get feedbackDesc => 'Twoja opinia poprawia śledzenie dokładności.';

  @override
  String get feedbackAttended => 'Obecny';

  @override
  String get feedbackDna => 'Nieobecny';

  @override
  String get feedbackCorrect => 'Poprawna';

  @override
  String get feedbackIncorrect => 'Błędna';

  @override
  String feedbackRecorded(String outcome) {
    return 'Zapisano opinię: $outcome';
  }

  @override
  String get practiceDashboard => 'Panel praktyki';

  @override
  String get practiceOverview => 'Ogólny przegląd ocen i wyników w praktyce.';

  @override
  String get statTotal => 'Łącznie';

  @override
  String get statHigh => 'Wysokie';

  @override
  String get statMedium => 'Średnie';

  @override
  String get statLow => 'Niskie';

  @override
  String get averageRisk => 'Średnie ryzyko';

  @override
  String get recentAssessments => 'Ostatnie oceny';

  @override
  String get noAssessmentsYet => 'Brak ocen. Najpierw wykonaj ocenę pacjenta.';

  @override
  String get operationalOutcomes => 'Wyniki operacyjne';
}
