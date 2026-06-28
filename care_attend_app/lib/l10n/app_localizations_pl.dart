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

  @override
  String get batchUploadDesc =>
      'Prześlij plik CSV z maksymalnie 100 pacjentami. Wymagane: Age, Gender, AppointmentLeadTimeDays, SMSReceived, PriorDNACount, IMDDecile. Opcjonalne: Hypertension, Diabetes, Alcoholism, Disability.';

  @override
  String get batchScoring => 'Ocenianie…';

  @override
  String get batchPickCsv => 'Wybierz CSV i oceń';

  @override
  String batchFile(String filename) {
    return 'Plik: $filename';
  }

  @override
  String get batchReadError => 'Nie można odczytać pliku.';

  @override
  String get batchPatients => 'Pacjenci';

  @override
  String batchRow(String row) {
    return 'Wiersz $row';
  }

  @override
  String batchTopFactor(String factor) {
    return 'Główny czynnik: $factor';
  }

  @override
  String get ethicsFramework => 'Ramy etyczne';

  @override
  String get ethicsSubtitle =>
      'Mapowanie sześciu zasad NHS England (2024) z dowodami.';

  @override
  String get ethicsCvTitle => 'Walidacja krzyżowa (5-krotna)';

  @override
  String get ethicsCvDesc =>
      'Przedziały ufności 95% bootstrap i testy istotności McNemara.';

  @override
  String get ethicsCvRunning => 'Uruchamianie…';

  @override
  String get ethicsCvRun => 'Uruchom walidację krzyżową';

  @override
  String get ethicsMcnemar => 'Istotność McNemara';

  @override
  String get ethicsSignificant => '(istotne)';

  @override
  String get ethicsMeanF1 => 'Średnie F1';

  @override
  String get ethicsRecall => 'Czułość';

  @override
  String get ethicsRocAuc => 'ROC-AUC';

  @override
  String ethicsCi(String lo, String hi) {
    return '95% CI (F1): [$lo, $hi]';
  }

  @override
  String get nudgeTitle => 'Przypomnienie pacjenta';

  @override
  String get nudgeSubtitle =>
      'Wygeneruj spersonalizowaną, niestygmatyzującą wiadomość kontaktową.';

  @override
  String get nudgeName => 'Imię pacjenta (opcjonalnie)';

  @override
  String get nudgeAge => 'Wiek';

  @override
  String get nudgeImd => 'IMD (1-10)';

  @override
  String get nudgeLeadDays => 'Dni oczekiwania';

  @override
  String get nudgePriorDnas => 'Poprzednie nieobecności';

  @override
  String get nudgeSmsSent => 'Wysłano przypomnienie SMS';

  @override
  String get nudgeGenerating => 'Generowanie…';

  @override
  String get nudgeGenerate => 'Wygeneruj wiadomość';

  @override
  String get nudgeCopy => 'Kopiuj wiadomość';

  @override
  String get nudgeCopied => 'Wiadomość skopiowana do schowka.';

  @override
  String get nudgeUseAssessment => 'Użyj ostatniej oceny';

  @override
  String get nudgeNoAssessment =>
      'Najpierw wypełnij formularz oceny, a następnie wygeneruj przypomnienie.';

  @override
  String get adminTitle => 'Zarządzanie użytkownikami';

  @override
  String get adminSubtitle =>
      'Tylko administrator. Nowe rejestracje zaczynają jako użytkownicy tylko do odczytu — awansuj zaufanych współpracowników tutaj.';

  @override
  String get adminRoleUpdated => 'Rola zaktualizowana.';

  @override
  String get adminDeleteTitle => 'Usuń użytkownika';

  @override
  String adminDeleteConfirm(String username) {
    return 'Usunąć \"$username\"? Tej operacji nie można cofnąć.';
  }

  @override
  String get adminCancel => 'Anuluj';

  @override
  String get adminDelete => 'Usuń';

  @override
  String get adminDeleted => 'Usunięto.';

  @override
  String get adminRolePerms => 'Uprawnienia ról';

  @override
  String get adminFeature => 'Funkcja';

  @override
  String get adminRoleUser => 'Użytkownik';

  @override
  String get adminRoleStaff => 'Personel';

  @override
  String get adminRoleAdmin => 'Administrator';

  @override
  String get adminPermAssessment => 'Ocena + Wyniki';

  @override
  String get adminPermDashboard => 'Panel, Sloty, Przypomnienia';

  @override
  String get adminPermBias => 'Stronniczość, Etyka, Informacje o modelu';

  @override
  String get adminPermAudit => 'Dziennik audytu, Zarządzanie użytkownikami';

  @override
  String get adminRoleLabel => 'Rola:';

  @override
  String get adminSessionLogTitle => 'Dziennik sesji logowania';

  @override
  String get adminSessionLogSubtitle =>
      'Trwały zapis udanych logowań i wylogowań.';

  @override
  String get adminSessionEmpty => 'Brak zdarzeń sesji logowania.';

  @override
  String get adminSessionLogin => 'Logowanie';

  @override
  String get adminSessionLogout => 'Wylogowanie';

  @override
  String get adminSessionUnknownUser => 'Nieznany użytkownik';

  @override
  String get slotsTitle => 'Optymalizacja slotów';

  @override
  String get slotsSubtitle =>
      'Oszacuj ryzyko nieobecności dla slotu i czy można go nadrezerwować.';

  @override
  String get slotsSlotMins => 'Minuty slotu';

  @override
  String get slotsAnalysing => 'Analizowanie…';

  @override
  String get slotsAnalyse => 'Analizuj slot';

  @override
  String get slotsOverbookable => 'Możliwe do nadrezerwowania';

  @override
  String get slotsExpectedWaste => 'Oczekiwana strata';

  @override
  String get slotsRecoveryPotential => 'Potencjał odzyskania';

  @override
  String slotsRiskLine(String prob, String tier) {
    return '$prob% ryzyko nieobecności · $tier';
  }

  @override
  String get slotsCanOverbookLabel => 'Można nadrezerwować:';

  @override
  String get commonYes => 'Tak';

  @override
  String get commonNo => 'Nie';

  @override
  String slotsWastedMinutes(String min) {
    return 'Oczekiwane zmarnowane minuty: $min';
  }

  @override
  String get biasMonitorTitle => 'Panel monitorowania stronniczości etycznej';

  @override
  String get biasSubtitle =>
      'Wskaźniki sprawiedliwości w grupach cech chronionych. Próg: 0,10.';

  @override
  String get biasTabAge => 'Wiek';

  @override
  String get biasTabImd => 'IMD';

  @override
  String get biasAuditFailed =>
      'Audyt nie powiódł się. Sprawdź połączenie z serwerem.';

  @override
  String get biasExportAudit => 'Eksportuj audyt';

  @override
  String get biasOverallPerf => 'Ogólna wydajność modelu';

  @override
  String get biasF1 => 'Wynik F1';

  @override
  String get biasPrecision => 'Precyzja';

  @override
  String get biasSamples => 'Próbki';

  @override
  String get biasAgeGroup => 'Grupa wiekowa';

  @override
  String get biasImdBand => 'Pasmo IMD';

  @override
  String get biasDpDiff => 'RÓŻNICA PARYTETU DEMOGRAFICZNEGO';

  @override
  String get biasPass => 'Zaliczono';

  @override
  String get biasFail => 'Niezaliczono';

  @override
  String get biasBarPass => 'ZALICZONE';

  @override
  String get biasBarWarn => 'OSTRZEŻENIE';

  @override
  String get biasBarFail => 'NIEZALICZONE';

  @override
  String get biasNameAge => 'wiek';

  @override
  String get biasNameGender => 'płeć';

  @override
  String get biasNameImd => 'IMD';

  @override
  String get biasFailDp => 'parytet demograficzny';

  @override
  String get biasFailEo => 'wyrównane szanse';

  @override
  String get biasSummaryPass =>
      'Model wykazuje akceptowalną sprawiedliwość we wszystkich grupach cech chronionych. Wszystkie wskaźniki mieszczą się w progu 0,10.';

  @override
  String biasSummaryFail(String failures) {
    return 'Model wykazuje akceptowalną sprawiedliwość w większości grup wiekowych. Następujące przekraczają próg 0,10: $failures. Może to odzwierciedlać rzeczywiste ryzyko kliniczne, a nie stronniczość algorytmiczną.';
  }

  @override
  String get clinicTitle => 'Lista kliniki';

  @override
  String get clinicSubtitle =>
      'Oceniaj wizyty i śledź postęp działań kontaktowych.';

  @override
  String get clinicNoAppointments => 'Brak zaimportowanych wizyt na ten dzień.';

  @override
  String get clinicRefresh => 'Odśwież';

  @override
  String get clinicPatientId => 'ID pacjenta';

  @override
  String get clinicTime => 'Czas';

  @override
  String get clinicClinic => 'Klinika';

  @override
  String get clinicWorking => 'Trwa praca...';

  @override
  String get clinicAddAppointment => 'Dodaj wizytę';

  @override
  String get clinicBulkImport => 'Import zbiorczy JSON';

  @override
  String get clinicApptsJson => 'JSON wizyt';

  @override
  String get clinicImportJson => 'Importuj JSON';

  @override
  String get clinicApptsLabel => 'Wizyty';

  @override
  String get clinicActioned => 'Podjęto działanie';

  @override
  String get clinicNeedsAction => 'Wymaga działania';

  @override
  String get clinicStatus => 'Status';

  @override
  String clinicActionsCount(String count) {
    return '$count działań';
  }

  @override
  String clinicRemindersCount(String count) {
    return '$count przypomnień';
  }

  @override
  String get clinicNeedsOutreach => 'Wymaga działania kontaktowego';

  @override
  String get clinicReminder => 'Przypomnienie';

  @override
  String get clinicCall => 'Połączenie';

  @override
  String get clinicEnterPatientId => 'Wprowadź ID pacjenta.';

  @override
  String get clinicJsonInvalid => 'JSON wizyty jest nieprawidłowy.';

  @override
  String clinicImported(String count) {
    return 'Zaimportowano $count wizyt.';
  }

  @override
  String get clinicStatusUpdated => 'Status wizyty zaktualizowany.';

  @override
  String get clinicReminderScheduled => 'Przypomnienie zaplanowane.';

  @override
  String get clinicCallRecorded => 'Działanie połączenia zarejestrowane.';

  @override
  String get clinicStScheduled => 'Zaplanowano';

  @override
  String get clinicStConfirmed => 'Potwierdzono';

  @override
  String get clinicStAttended => 'Obecny';

  @override
  String get clinicStDna => 'DNA';

  @override
  String get clinicStCancelled => 'Anulowano';

  @override
  String get clinicStRescheduled => 'Przełożono';

  @override
  String get profileLogoutClear => 'Wyloguj się i wyczyść sesję';

  @override
  String get profileUsername => 'Nazwa użytkownika';

  @override
  String get profileRole => 'Rola';

  @override
  String get profileMemberSince => 'Członek od';

  @override
  String get profilePasswordChanged => 'Hasło zmieniono';

  @override
  String get profileNever => 'Nigdy';

  @override
  String get profileEdit => 'Edytuj profil';

  @override
  String get profileDisplayName => 'Wyświetlana nazwa';

  @override
  String get profileJobTitle => 'Stanowisko';

  @override
  String get profileDepartment => 'Dział';

  @override
  String get profilePronouns => 'Zaimki (np. ona/jej)';

  @override
  String get profilePhone => 'Telefon';

  @override
  String get profileBio => 'Biografia';

  @override
  String get profileSaving => 'Zapisywanie…';

  @override
  String get profileSaveBtn => 'Zapisz profil';

  @override
  String get profileChangePassword => 'Zmień hasło';

  @override
  String get profileCurrentPw => 'Obecne hasło';

  @override
  String get profileNewPw => 'Nowe hasło';

  @override
  String get profileConfirmPw => 'Potwierdź nowe hasło';

  @override
  String get profileUpdatePw => 'Aktualizuj hasło';

  @override
  String get profile2faTitle => 'Uwierzytelnianie dwuskładnikowe';

  @override
  String get profile2faEnabledBadge => 'WŁĄCZONE';

  @override
  String get profile2faDisabledBadge => 'WYŁĄCZONE';

  @override
  String get profile2faDesc =>
      'Dodaj jednorazowy kod czasowy z aplikacji uwierzytelniającej (Google Authenticator, Authy).';

  @override
  String get profile2faPwDisable => 'Hasło do wyłączenia';

  @override
  String get profile2faDisableBtn => 'Wyłącz 2FA';

  @override
  String get profile2faWait => 'Proszę czekać…';

  @override
  String get profile2faEnableBtn => 'Włącz 2FA';

  @override
  String get profile2faStep1 =>
      '1. Dodaj ten sekret do aplikacji uwierzytelniającej:';

  @override
  String get profile2faStep2 => '2. Wprowadź 6-cyfrowy kod, aby zweryfikować:';

  @override
  String get profile2faVerify => 'Zweryfikuj i włącz';

  @override
  String get profilePrivacy => 'Prywatność i ochrona danych';

  @override
  String get profilePrivGdprT => 'Zgodność z art. 5 ust. 1 lit. c) RODO';

  @override
  String get profilePrivGdprB =>
      'Minimalizacja danych — zbierane tylko niezbędne pola.';

  @override
  String get profilePrivSessionT => 'Przetwarzanie w ramach sesji';

  @override
  String get profilePrivSessionB =>
      'Brak przechowywania danych pacjentów. Czyszczone przy wylogowaniu.';

  @override
  String get profilePrivEncT => 'Szyfrowane uwierzytelnianie';

  @override
  String get profilePrivEncB =>
      'Hasła haszowane bcrypt; sesje wygasają przy bezczynności.';

  @override
  String get profilePrivShareT => 'Brak udostępniania danych stronom trzecim';

  @override
  String get profilePrivShareB =>
      'Całe przetwarzanie lokalne. Brak zewnętrznej analityki lub śledzenia.';

  @override
  String get profileViewPhoto => 'Zobacz zdjęcie';

  @override
  String get profileChangePhoto => 'Zmień zdjęcie';

  @override
  String get profileAddPhoto => 'Dodaj zdjęcie';

  @override
  String get profileRemovePhoto => 'Usuń zdjęcie';

  @override
  String get profilePhotoRemoved => 'Zdjęcie usunięte.';

  @override
  String get profileUnsupportedImage => 'Nieobsługiwany format obrazu.';

  @override
  String get profilePhotoUpdated => 'Zdjęcie zaktualizowane.';

  @override
  String get profileSaved => 'Profil zapisany.';

  @override
  String get profilePwDifferent =>
      'Nowe hasło musi różnić się od obecnego hasła';

  @override
  String get profilePwMismatch => 'Hasła nie pasują do siebie';

  @override
  String get profilePwChanged => 'Hasło zmienione pomyślnie';

  @override
  String get profile2faEnterCode =>
      'Wprowadź 6-cyfrowy kod z aplikacji uwierzytelniającej.';

  @override
  String get profile2faEnabled => 'Uwierzytelnianie dwuskładnikowe włączone.';

  @override
  String get profile2faEnterPw => 'Wprowadź hasło, aby wyłączyć 2FA.';

  @override
  String get profile2faDisabled => 'Uwierzytelnianie dwuskładnikowe wyłączone.';

  @override
  String get fpTitle => 'Zresetuj hasło';

  @override
  String get fpSubtitle =>
      'Wyślemy Ci e-mailem 6-cyfrowy kod do zresetowania hasła.';

  @override
  String get fpSending => 'Wysyłanie…';

  @override
  String get fpSendCode => 'Wyślij kod resetujący';

  @override
  String get fpCodeField => 'Kod 6-cyfrowy';

  @override
  String get fpResetting => 'Resetowanie…';

  @override
  String get fpResetBtn => 'Zresetuj hasło';

  @override
  String get fpResend => 'Wyślij kod ponownie';

  @override
  String get fpEnterEmail => 'Wprowadź swój adres e-mail.';

  @override
  String get fpEnterCode => 'Wprowadź kod resetujący.';

  @override
  String get fpResetDone => 'Hasło zresetowane! Zaloguj się.';

  @override
  String get fpCodeSent =>
      'Jeśli ten e-mail jest zarejestrowany, wysłano 6-cyfrowy kod.';

  @override
  String fpDevCode(String code) {
    return 'E-mail nieskonfigurowany — Twój kod testowy to $code';
  }

  @override
  String get offlineBanner =>
      'Jesteś offline — pociągnij, aby odświeżyć po ponownym połączeniu.';

  @override
  String get chatbotTitle => 'Care Attend AI';

  @override
  String get chatbotHint => 'Wpisz wiadomość…';

  @override
  String get chatbotSend => 'Wyślij';

  @override
  String get chatbotAssistant => 'Asystent';

  @override
  String get profilePhotoA11y => 'Zdjęcie profilowe. Dotknij, aby zmienić.';

  @override
  String get loadFailed =>
      'Nie udało się załadować. Pociągnij w dół lub spróbuj ponownie.';

  @override
  String get commonRetry => 'Spróbuj ponownie';

  @override
  String get resultCopy => 'Kopiuj';

  @override
  String get resultCopied => 'Skopiowano wynik do schowka';

  @override
  String get ageBannerEnhancedTitle => 'Zwiększona wrażliwość';

  @override
  String get ageBannerElevatedTitle => 'Podwyższona podatność';

  @override
  String get ageBannerEnhancedMsg =>
      'Pacjent ma 85+ lat — zastosuj zwiększoną wrażliwość i proaktywną ochronę przy działaniu na podstawie tego wyniku.';

  @override
  String get ageBannerElevatedMsg =>
      'Pacjent ma 65+ lat — podwyższona podatność; rozważ proaktywne wsparcie i przypomnienia.';

  @override
  String get navAssessment => 'Ocena';

  @override
  String get notifTitle => 'Powiadomienia';

  @override
  String get notifEmpty => 'Brak powiadomień';

  @override
  String get notifClearAll => 'Wyczyść wszystko';

  @override
  String get notifSignedIn => 'Zalogowano bezpiecznie';

  @override
  String get notifSignedInBody => 'Zalogowano do Care Attend.';

  @override
  String get notifAssessmentDone => 'Ocena zakończona';

  @override
  String notifAssessmentBody(String tier, String pct) {
    return 'Ryzyko $tier ($pct%) zapisane w tej sesji.';
  }

  @override
  String get notifIdleWarn => 'Ostrzeżenie o bezczynności';

  @override
  String get notifIdleWarnBody =>
      'Twoja sesja wkrótce się zakończy z powodu bezczynności.';
}
